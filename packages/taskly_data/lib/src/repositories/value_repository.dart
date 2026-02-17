import 'dart:async';

import 'package:drift/drift.dart' as drift_pkg;
import 'package:taskly_core/logging.dart';
import 'package:taskly_data/src/errors/failure_guard.dart';
import 'package:taskly_data/src/infrastructure/drift/drift_database.dart'
    as drift;
import 'package:taskly_data/src/infrastructure/powersync/crud_metadata.dart';
import 'package:taskly_data/src/id/id_generator.dart';
import 'package:taskly_data/src/repositories/query_stream_cache.dart';
import 'package:taskly_data/src/repositories/repository_exceptions.dart';
import 'package:taskly_data/src/mappers/drift_to_domain.dart';
import 'package:taskly_domain/taskly_domain.dart';
import 'package:taskly_domain/time.dart' show Clock, systemClock;

class ValueRepository implements ValueRepositoryContract {
  ValueRepository({
    required this.driftDb,
    required this.idGenerator,
    Clock clock = systemClock,
  }) : _clock = clock;
  final drift.AppDatabase driftDb;
  final IdGenerator idGenerator;
  final Clock _clock;

  final QueryStreamCache<ValueQuery, List<Value>> _sharedWatchAllCache =
      QueryStreamCache(maxEntries: 16);

  drift_pkg.Expression<int> _prioritySortExpr(drift.ValueTable l) {
    // `ValueTable.priority` is stored as a text enum (low/medium/high). Ordering
    // lexicographically does not match domain priority ordering, so we map it to
    // a numeric rank for correct sorting.
    return drift_pkg.CustomExpression<int>(
      'CASE priority '
      "WHEN 'high' THEN 2 "
      "WHEN 'medium' THEN 1 "
      "WHEN 'low' THEN 0 "
      'ELSE -1 END',
    );
  }

  Stream<List<drift.ValueTableData>> get _valueStream =>
      (driftDb.select(driftDb.valueTable)..orderBy([
            (l) => drift_pkg.OrderingTerm(
              expression: _prioritySortExpr(l),
              mode: drift_pkg.OrderingMode.desc,
            ),
            (l) => drift_pkg.OrderingTerm(expression: l.name),
          ]))
          .watch();

  Future<List<drift.ValueTableData>> get _valueList =>
      (driftDb.select(driftDb.valueTable)..orderBy([
            (l) => drift_pkg.OrderingTerm(
              expression: _prioritySortExpr(l),
              mode: drift_pkg.OrderingMode.desc,
            ),
            (l) => drift_pkg.OrderingTerm(expression: l.name),
          ]))
          .get();

  Future<drift.ValueTableData?> _getValueById(String id) {
    return (driftDb.select(
      driftDb.valueTable,
    )..where((l) => l.id.equals(id))).getSingleOrNull();
  }

  // Domain-aware read methods
  @override
  Stream<List<Value>> watchAll([ValueQuery? query]) {
    final normalizedQuery = query ?? ValueQuery.all();
    final cacheHit = _sharedWatchAllCache.containsKey(normalizedQuery);

    Stream<List<Value>> instrumented(
      Stream<List<Value>> source, {
      required bool hasFilter,
    }) {
      final fields = <String, Object?>{
        'hasFilter': hasFilter,
        'cacheHit': cacheHit,
      };

      // We intentionally keep this lightweight:
      // - routine log on subscribe/first emission
      // - routine log if first emission is delayed (helps identify loading lag)
      // - error is captured via AppLog.handleStructured
      return Stream<List<Value>>.multi((controller) {
        late final StreamSubscription<List<Value>> sub;
        var hasFirstEmission = false;
        Timer? delayedFirstEmissionTimer;

        void cancelDelayTimer() {
          delayedFirstEmissionTimer?.cancel();
          delayedFirstEmissionTimer = null;
        }

        controller.onCancel = () async {
          cancelDelayTimer();
          await sub.cancel();
        };

        AppLog.routineStructured(
          'data.value',
          'watchAll subscribed',
          fields: fields,
        );

        delayedFirstEmissionTimer = Timer(const Duration(seconds: 2), () {
          if (hasFirstEmission) return;
          AppLog.routineStructured(
            'data.value',
            'watchAll first emission delayed',
            fields: <String, Object?>{...fields, 'delayMs': 2000},
          );
        });

        sub = source.listen(
          (values) {
            if (!hasFirstEmission) {
              hasFirstEmission = true;
              cancelDelayTimer();
              AppLog.routineStructured(
                'data.value',
                'watchAll first emission',
                fields: <String, Object?>{...fields, 'count': values.length},
              );
            }
            controller.add(values);
          },
          onError: (Object error, StackTrace stackTrace) {
            cancelDelayTimer();
            AppLog.handleStructured(
              'data.value',
              'watchAll stream error',
              error,
              stackTrace,
              fields,
            );
            controller.addError(error, stackTrace);
          },
          onDone: () {
            cancelDelayTimer();
            controller.close();
          },
        );
      });
    }

    return _sharedWatchAllCache.getOrCreate(normalizedQuery, () {
      // Fast path: no filter.
      if (normalizedQuery.filter.shared.isEmpty &&
          normalizedQuery.filter.orGroups.isEmpty) {
        final stream = _valueStream.map(
          (rows) => rows.map(valueFromTable).toList(),
        );
        return instrumented(stream, hasFilter: false);
      }

      final select = driftDb.select(driftDb.valueTable);
      final where = _whereExpressionFromFilter(normalizedQuery.filter);
      if (where != null) select.where((_) => where);
      select.orderBy([
        (l) => drift_pkg.OrderingTerm(
          expression: _prioritySortExpr(l),
          mode: drift_pkg.OrderingMode.desc,
        ),
        (l) => drift_pkg.OrderingTerm(expression: l.name),
      ]);
      final stream = select.watch().map(
        (rows) => rows.map(valueFromTable).toList(),
      );
      return instrumented(stream, hasFilter: true);
    });
  }

  @override
  Future<List<Value>> getAll([ValueQuery? query]) async {
    if (query == null) {
      return (await _valueList).map(valueFromTable).toList();
    }

    final select = driftDb.select(driftDb.valueTable);
    final where = _whereExpressionFromFilter(query.filter);
    if (where != null) select.where((_) => where);
    select.orderBy([
      (l) => drift_pkg.OrderingTerm(
        expression: _prioritySortExpr(l),
        mode: drift_pkg.OrderingMode.desc,
      ),
      (l) => drift_pkg.OrderingTerm(expression: l.name),
    ]);
    final rows = await select.get();
    return rows.map(valueFromTable).toList();
  }

  @override
  Future<int> getCount() async {
    final countExp = driftDb.valueTable.id.count();
    final query = driftDb.selectOnly(driftDb.valueTable)
      ..addColumns([countExp]);
    final row = await query.getSingleOrNull();
    return row == null ? 0 : (row.read(countExp) ?? 0);
  }

  @override
  Stream<Value?> watchById(String id) =>
      (driftDb.select(driftDb.valueTable)..where((l) => l.id.equals(id)))
          .watch()
          .map((rows) => rows.isEmpty ? null : valueFromTable(rows.first));

  @override
  Future<Value?> getById(String id) async {
    final data = await _getValueById(id);
    return data == null ? null : valueFromTable(data);
  }

  @override
  Future<List<Value>> getValuesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final rows = await (driftDb.select(
      driftDb.valueTable,
    )..where((l) => l.id.isIn(ids))).get();
    return rows.map(valueFromTable).toList();
  }

  drift_pkg.Expression<bool>? _whereExpressionFromFilter(
    QueryFilter<ValuePredicate> filter,
  ) {
    if (filter.shared.isEmpty && filter.orGroups.isEmpty) return null;

    drift_pkg.Expression<bool>? result;

    // Apply shared predicates (AND)
    for (final predicate in filter.shared) {
      final expr = _predicateToExpression(predicate);
      result = result == null ? expr : result & expr;
    }

    // Apply orGroups (OR of AND groups)
    if (filter.orGroups.isNotEmpty) {
      drift_pkg.Expression<bool>? orResult;
      for (final group in filter.orGroups) {
        drift_pkg.Expression<bool>? groupExpr;
        for (final predicate in group) {
          final expr = _predicateToExpression(predicate);
          groupExpr = groupExpr == null ? expr : groupExpr & expr;
        }
        if (groupExpr != null) {
          orResult = orResult == null ? groupExpr : orResult | groupExpr;
        }
      }
      if (orResult != null) {
        result = result == null ? orResult : result & orResult;
      }
    }

    return result;
  }

  drift_pkg.Expression<bool> _predicateToExpression(ValuePredicate predicate) {
    final l = driftDb.valueTable;
    return switch (predicate) {
      ValueNamePredicate(:final value, :final operator) =>
        _namePredicateToExpression(value, operator),
      ValueColorPredicate(:final colorHex) => l.color.equals(colorHex),
      ValueIdPredicate(:final valueId) => l.id.equals(valueId),
      ValueIdsPredicate(:final valueIds) => l.id.isIn(valueIds),
    };
  }

  drift_pkg.Expression<bool> _namePredicateToExpression(
    String value,
    StringOperator op,
  ) {
    final l = driftDb.valueTable;
    return switch (op) {
      StringOperator.equals => l.name.equals(value),
      StringOperator.contains => l.name.contains(value),
      StringOperator.startsWith => l.name.like('$value%'),
      StringOperator.endsWith => l.name.like('%$value'),
      StringOperator.isNull => l.name.isNull(),
      StringOperator.isNotNull => l.name.isNotNull(),
    };
  }

  Future<bool> _updateValue(drift.ValueTableCompanion updateCompanion) {
    return driftDb.update(driftDb.valueTable).replace(updateCompanion);
  }

  Future<int> _deleteValue(drift.ValueTableCompanion deleteCompanion) async {
    return driftDb.delete(driftDb.valueTable).delete(deleteCompanion);
  }

  Future<int> _createValue(drift.ValueTableCompanion createCompanion) {
    return driftDb.into(driftDb.valueTable).insert(createCompanion);
  }

  String _normalizeColorOrThrow(String input) {
    final trimmed = input.trim();
    final normalized = trimmed.startsWith('#') ? trimmed : '#$trimmed';
    final isValid = RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(normalized);
    if (!isValid) {
      throw RepositoryValidationException(
        'Invalid color hex "$input". Expected "#RRGGBB" (or "RRGGBB").',
      );
    }
    return normalized;
  }

  @override
  Future<void> create({
    required String name,
    required String color,
    ValuePriority priority = ValuePriority.medium,
    String? iconName,
    OperationContext? context,
  }) async {
    return FailureGuard.run(
      () async {
        talker.debug(
          '[ValueRepository] create: name="$name", priority=$priority',
        );
        final now = _clock.nowUtc();

        final normalizedColor = _normalizeColorOrThrow(color);

        // Generate deterministic v5 ID
        final id = idGenerator.valueId(name: name);

        AppLog.routineStructured(
          'data.value',
          'create requested',
          fields: <String, Object?>{
            'id': id,
            'name': name,
            'color': normalizedColor,
            'iconName': iconName,
            'priority': priority.name,
          },
        );

        final psMetadata = encodeCrudMetadata(context, clock: _clock);

        await _createValue(
          drift.ValueTableCompanion(
            id: drift_pkg.Value(id),
            name: drift_pkg.Value(name),
            color: drift_pkg.Value(normalizedColor),
            priority: drift_pkg.Value(priority),
            iconName: drift_pkg.Value(iconName),
            psMetadata: psMetadata == null
                ? const drift_pkg.Value<String?>.absent()
                : drift_pkg.Value(psMetadata),
            createdAt: drift_pkg.Value(now),
            updatedAt: drift_pkg.Value(now),
          ),
        );

        AppLog.routineStructured(
          'data.value',
          'create inserted',
          fields: <String, Object?>{'id': id, 'name': name},
        );
      },
      area: 'data.value',
      opName: 'create',
      context: context,
    );
  }

  @override
  Future<void> update({
    required String id,
    required String name,
    required String color,
    ValuePriority? priority,
    String? iconName,
    OperationContext? context,
  }) async {
    return FailureGuard.run(
      () async {
        talker.debug('[ValueRepository] update: id=$id, name="$name"');
        final existing = await _getValueById(id);
        if (existing == null) {
          AppLog.routineStructured(
            'data.value',
            'update skipped; value not found',
            fields: <String, Object?>{'id': id},
          );
          throw RepositoryNotFoundException('No value found to update');
        }

        final normalizedColor = _normalizeColorOrThrow(color);

        final now = _clock.nowUtc();

        final psMetadata = encodeCrudMetadata(context, clock: _clock);
        final didUpdate = await _updateValue(
          drift.ValueTableCompanion(
            id: drift_pkg.Value(id),
            name: drift_pkg.Value(name),
            color: drift_pkg.Value(normalizedColor),
            priority: priority != null
                ? drift_pkg.Value(priority)
                : const drift_pkg.Value<ValuePriority>.absent(),
            iconName: drift_pkg.Value(iconName),
            psMetadata: psMetadata == null
                ? const drift_pkg.Value<String?>.absent()
                : drift_pkg.Value(psMetadata),
            updatedAt: drift_pkg.Value(now),
          ),
        );

        final after = await _getValueById(id);
        AppLog.routineStructured(
          'data.value',
          'update applied',
          fields: <String, Object?>{
            'id': id,
            'didUpdate': didUpdate,
            'name': name,
            'color': normalizedColor,
            'iconName': iconName,
            'priority': priority?.name,
            'dbName': after?.name,
            'dbColor': after?.color,
            'dbIconName': after?.iconName,
            'dbPriority': after?.priority?.name,
            'dbUpdatedAt': after?.updatedAt.toIso8601String(),
          },
        );
      },
      area: 'data.value',
      opName: 'update',
      context: context,
    );
  }

  @override
  Future<void> delete(String id, {OperationContext? context}) async {
    return FailureGuard.run(
      () async {
        talker.debug('[ValueRepository] delete: id=$id');

        await _deleteValue(drift.ValueTableCompanion(id: drift_pkg.Value(id)));
      },
      area: 'data.value',
      opName: 'delete',
      context: context,
    );
  }
}
