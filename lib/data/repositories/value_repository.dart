import 'package:drift/drift.dart' as drift_pkg;
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart' as drift;
import 'package:taskly_bloc/data/id/id_generator.dart';
import 'package:taskly_bloc/data/repositories/repository_exceptions.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/interfaces/value_repository_contract.dart';
import 'package:taskly_bloc/data/mappers/drift_to_domain.dart';
import 'package:taskly_bloc/domain/queries/value_predicate.dart';
import 'package:taskly_bloc/domain/queries/value_query.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';
import 'package:taskly_bloc/domain/models/value_priority.dart';

class ValueRepository implements ValueRepositoryContract {
  ValueRepository({
    required this.driftDb,
    required this.idGenerator,
  });
  final drift.AppDatabase driftDb;
  final IdGenerator idGenerator;

  Stream<List<drift.ValueTableData>> get _valueStream =>
      (driftDb.select(
            driftDb.valueTable,
          )..orderBy([
            (l) => drift_pkg.OrderingTerm(
              expression: l.priority,
              mode: drift_pkg.OrderingMode.desc,
            ),
            (l) => drift_pkg.OrderingTerm(expression: l.name),
          ]))
          .watch();

  Future<List<drift.ValueTableData>> get _valueList =>
      (driftDb.select(
            driftDb.valueTable,
          )..orderBy([
            (l) => drift_pkg.OrderingTerm(
              expression: l.priority,
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
    if (query == null) {
      return _valueStream.map((rows) => rows.map(valueFromTable).toList());
    }

    final select = driftDb.select(driftDb.valueTable);
    final where = _whereExpressionFromFilter(query.filter);
    if (where != null) select.where((_) => where);
    select.orderBy([
      (l) => drift_pkg.OrderingTerm(
        expression: l.priority,
        mode: drift_pkg.OrderingMode.desc,
      ),
      (l) => drift_pkg.OrderingTerm(expression: l.name),
    ]);
    return select.watch().map((rows) => rows.map(valueFromTable).toList());
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
        expression: l.priority,
        mode: drift_pkg.OrderingMode.desc,
      ),
      (l) => drift_pkg.OrderingTerm(expression: l.name),
    ]);
    final rows = await select.get();
    return rows.map(valueFromTable).toList();
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

  Future<void> _updateValue(drift.ValueTableCompanion updateCompanion) async {
    await driftDb.update(driftDb.valueTable).replace(updateCompanion);
  }

  Future<int> _deleteValue(drift.ValueTableCompanion deleteCompanion) async {
    return driftDb.delete(driftDb.valueTable).delete(deleteCompanion);
  }

  Future<int> _createValue(drift.ValueTableCompanion createCompanion) {
    return driftDb.into(driftDb.valueTable).insert(createCompanion);
  }

  @override
  Future<void> create({
    required String name,
    required String color,
    ValuePriority priority = ValuePriority.medium,
    String? iconName,
  }) async {
    talker.debug('[ValueRepository] create: name="$name", priority=$priority');
    final now = DateTime.now();

    // Generate deterministic v5 ID
    final id = idGenerator.valueId(name: name);

    await _createValue(
      drift.ValueTableCompanion(
        id: drift_pkg.Value(id),
        name: drift_pkg.Value(name),
        color: drift_pkg.Value(color),
        priority: drift_pkg.Value(priority),
        iconName: drift_pkg.Value(iconName),
        createdAt: drift_pkg.Value(now),
        updatedAt: drift_pkg.Value(now),
      ),
    );
  }

  @override
  Future<void> update({
    required String id,
    required String name,
    required String color,
    ValuePriority? priority,
    String? iconName,
  }) async {
    talker.debug('[ValueRepository] update: id=$id, name="$name"');
    final existing = await _getValueById(id);
    if (existing == null) {
      talker.warning('[ValueRepository] update failed: value not found id=$id');
      throw RepositoryNotFoundException('No value found to update');
    }

    final now = DateTime.now();
    await _updateValue(
      drift.ValueTableCompanion(
        id: drift_pkg.Value(id),
        name: drift_pkg.Value(name),
        color: drift_pkg.Value(color),
        priority: priority != null
            ? drift_pkg.Value(priority)
            : const drift_pkg.Value<ValuePriority>.absent(),
        iconName: drift_pkg.Value(iconName),
        updatedAt: drift_pkg.Value(now),
      ),
    );
  }

  @override
  Future<void> delete(String id) async {
    talker.debug('[ValueRepository] delete: id=$id');
    await _deleteValue(drift.ValueTableCompanion(id: drift_pkg.Value(id)));
  }

  @override
  Future<void> updateLastReviewedAt({
    required String id,
    required DateTime reviewedAt,
  }) async {
    talker.debug('[ValueRepository] updateLastReviewedAt: id=$id');
    final existing = await _getValueById(id);
    if (existing == null) {
      talker.warning(
        '[ValueRepository] updateLastReviewedAt failed: value not found id=$id',
      );
      throw RepositoryNotFoundException('No value found to update');
    }

    await (driftDb.update(
      driftDb.valueTable,
    )..where((l) => l.id.equals(id))).write(
      drift.ValueTableCompanion(
        lastReviewedAt: drift_pkg.Value(reviewedAt),
        updatedAt: drift_pkg.Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> addValueToTask({
    required String taskId,
    required String valueId,
  }) async {
    // Check if value association already exists
    final existing =
        await (driftDb.select(driftDb.taskValuesTable)..where(
              (tl) => tl.taskId.equals(taskId) & tl.valueId.equals(valueId),
            ))
            .getSingleOrNull();

    if (existing != null) return; // Already exists

    // Generate deterministic v5 ID for junction
    final junctionId = idGenerator.taskValueId(
      taskId: taskId,
      valueId: valueId,
    );

    // Add new value association
    await driftDb
        .into(driftDb.taskValuesTable)
        .insert(
          drift.TaskValuesTableCompanion(
            id: drift_pkg.Value(junctionId),
            taskId: drift_pkg.Value(taskId),
            valueId: drift_pkg.Value(valueId),
          ),
          mode: drift_pkg.InsertMode.insertOrIgnore,
        );
  }

  @override
  Future<void> removeValueFromTask({
    required String taskId,
    required String valueId,
  }) async {
    await (driftDb.delete(
          driftDb.taskValuesTable,
        )..where((tl) => tl.taskId.equals(taskId) & tl.valueId.equals(valueId)))
        .go();
  }
}
