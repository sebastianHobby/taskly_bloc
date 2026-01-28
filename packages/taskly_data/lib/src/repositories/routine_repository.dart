import 'package:drift/drift.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_data/src/errors/failure_guard.dart';
import 'package:taskly_data/src/id/id_generator.dart';
import 'package:taskly_data/src/infrastructure/drift/drift_database.dart';
import 'package:taskly_data/src/infrastructure/powersync/crud_metadata.dart';
import 'package:taskly_data/src/mappers/drift_to_domain.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/telemetry.dart';
import 'package:taskly_domain/time.dart' show Clock, systemClock;

final class RoutineRepository implements RoutineRepositoryContract {
  RoutineRepository({
    required AppDatabase driftDb,
    required IdGenerator idGenerator,
    Clock clock = systemClock,
  }) : _db = driftDb,
       _ids = idGenerator,
       _clock = clock;

  final AppDatabase _db;
  final IdGenerator _ids;
  final Clock _clock;

  @override
  Stream<List<Routine>> watchAll({bool includeInactive = true}) {
    final routines$ = (_db.select(
      _db.routinesTable,
    )..orderBy([(t) => OrderingTerm(expression: t.name)])).watch();
    final values$ = _db.select(_db.valueTable).watch();

    return Rx.combineLatest2(routines$, values$, (
      List<RoutinesTableData> routineRows,
      List<ValueTableData> valueRows,
    ) {
      return _mapRoutines(
        routineRows,
        valueRows,
        includeInactive: includeInactive,
      );
    });
  }

  @override
  Future<List<Routine>> getAll({bool includeInactive = true}) async {
    final routineRows = await (_db.select(
      _db.routinesTable,
    )..orderBy([(t) => OrderingTerm(expression: t.name)])).get();
    final valueRows = await _db.select(_db.valueTable).get();

    return _mapRoutines(
      routineRows,
      valueRows,
      includeInactive: includeInactive,
    );
  }

  @override
  Stream<Routine?> watchById(String id) {
    return watchAll(includeInactive: true).map((routines) {
      for (final routine in routines) {
        if (routine.id == id) return routine;
      }
      return null;
    });
  }

  @override
  Future<Routine?> getById(String id) async {
    final routines = await getAll(includeInactive: true);
    for (final routine in routines) {
      if (routine.id == id) return routine;
    }
    return null;
  }

  @override
  Future<void> create({
    required String name,
    required String valueId,
    required RoutineType routineType,
    required int targetCount,
    List<int> scheduleDays = const <int>[],
    int? minSpacingDays,
    int? restDayBuffer,
    List<int> preferredWeeks = const <int>[],
    int? fixedDayOfMonth,
    int? fixedWeekday,
    int? fixedWeekOfMonth,
    bool isActive = true,
    DateTime? pausedUntilUtc,
    OperationContext? context,
  }) async {
    return FailureGuard.run(
      () async {
        final now = _clock.nowUtc();
        final psMetadata = encodeCrudMetadata(context, clock: _clock);

        await _db
            .into(_db.routinesTable)
            .insert(
              RoutinesTableCompanion.insert(
                id: _ids.routineId(),
                name: name,
                valueId: valueId,
                routineType: routineType.storageKey,
                targetCount: targetCount,
                scheduleDays: Value(scheduleDays.isEmpty ? null : scheduleDays),
                minSpacingDays: Value(minSpacingDays),
                restDayBuffer: Value(restDayBuffer),
                preferredWeeks: Value(
                  preferredWeeks.isEmpty ? null : preferredWeeks,
                ),
                fixedDayOfMonth: Value(fixedDayOfMonth),
                fixedWeekday: Value(fixedWeekday),
                fixedWeekOfMonth: Value(fixedWeekOfMonth),
                isActive: Value(isActive),
                pausedUntil: Value(dateOnlyOrNull(pausedUntilUtc)),
                createdAt: Value(now),
                updatedAt: Value(now),
                psMetadata: Value(psMetadata),
              ),
              mode: InsertMode.insert,
            );
      },
      area: 'data.routines',
      opName: 'create',
      context: context,
    );
  }

  @override
  Future<void> update({
    required String id,
    required String name,
    required String valueId,
    required RoutineType routineType,
    required int targetCount,
    List<int>? scheduleDays,
    int? minSpacingDays,
    int? restDayBuffer,
    List<int>? preferredWeeks,
    int? fixedDayOfMonth,
    int? fixedWeekday,
    int? fixedWeekOfMonth,
    bool? isActive,
    DateTime? pausedUntilUtc,
    OperationContext? context,
  }) async {
    return FailureGuard.run(
      () async {
        final now = _clock.nowUtc();
        final psMetadata = encodeCrudMetadata(context, clock: _clock);

        await (_db.update(
          _db.routinesTable,
        )..where((t) => t.id.equals(id))).write(
          RoutinesTableCompanion(
            name: Value(name),
            valueId: Value(valueId),
            routineType: Value(routineType.storageKey),
            targetCount: Value(targetCount),
            scheduleDays: scheduleDays == null
                ? const Value.absent()
                : Value(scheduleDays),
            minSpacingDays: Value(minSpacingDays),
            restDayBuffer: Value(restDayBuffer),
            preferredWeeks: preferredWeeks == null
                ? const Value.absent()
                : Value(preferredWeeks),
            fixedDayOfMonth: Value(fixedDayOfMonth),
            fixedWeekday: Value(fixedWeekday),
            fixedWeekOfMonth: Value(fixedWeekOfMonth),
            isActive: isActive == null ? const Value.absent() : Value(isActive),
            pausedUntil: Value(dateOnlyOrNull(pausedUntilUtc)),
            updatedAt: Value(now),
            psMetadata: psMetadata == null
                ? const Value.absent()
                : Value(psMetadata),
          ),
        );
      },
      area: 'data.routines',
      opName: 'update',
      context: context,
    );
  }

  @override
  Future<void> delete(String id, {OperationContext? context}) async {
    return FailureGuard.run(
      () async {
        await (_db.delete(
          _db.routinesTable,
        )..where((t) => t.id.equals(id))).go();
      },
      area: 'data.routines',
      opName: 'delete',
      context: context,
    );
  }

  @override
  Stream<List<RoutineCompletion>> watchCompletions() {
    final query = _db.select(_db.routineCompletionsTable)
      ..orderBy([(t) => OrderingTerm(expression: t.completedAt)]);
    return query.watch().map(
      (rows) => rows.map(routineCompletionFromTable).toList(growable: false),
    );
  }

  @override
  Stream<List<RoutineSkip>> watchSkips() {
    final query = _db.select(_db.routineSkipsTable)
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]);
    return query.watch().map(
      (rows) => rows.map(routineSkipFromTable).toList(growable: false),
    );
  }

  @override
  Future<List<RoutineCompletion>> getCompletions() async {
    final rows = await (_db.select(
      _db.routineCompletionsTable,
    )..orderBy([(t) => OrderingTerm(expression: t.completedAt)])).get();
    return rows.map(routineCompletionFromTable).toList(growable: false);
  }

  @override
  Future<List<RoutineSkip>> getSkips() async {
    final rows = await (_db.select(
      _db.routineSkipsTable,
    )..orderBy([(t) => OrderingTerm(expression: t.createdAt)])).get();
    return rows.map(routineSkipFromTable).toList(growable: false);
  }

  @override
  Future<void> recordCompletion({
    required String routineId,
    DateTime? completedAtUtc,
    OperationContext? context,
  }) async {
    return FailureGuard.run(
      () async {
        final now = _clock.nowUtc();
        final psMetadata = encodeCrudMetadata(context, clock: _clock);

        await _db
            .into(_db.routineCompletionsTable)
            .insert(
              RoutineCompletionsTableCompanion.insert(
                id: _ids.routineCompletionId(),
                routineId: routineId,
                completedAt: completedAtUtc ?? now,
                createdAt: Value(now),
                psMetadata: Value(psMetadata),
              ),
              mode: InsertMode.insert,
            );
      },
      area: 'data.routines',
      opName: 'recordCompletion',
      context: context,
    );
  }

  @override
  Future<void> recordSkip({
    required String routineId,
    required RoutineSkipPeriodType periodType,
    required DateTime periodKeyUtc,
    OperationContext? context,
  }) async {
    return FailureGuard.run(
      () async {
        final now = _clock.nowUtc();
        final psMetadata = encodeCrudMetadata(context, clock: _clock);
        final normalizedKey = dateOnly(periodKeyUtc);

        final existing =
            await (_db.select(_db.routineSkipsTable)
                  ..where((t) => t.routineId.equals(routineId))
                  ..where((t) => t.periodType.equals(periodType.name))
                  ..where(
                    (t) => t.periodKey.equals(encodeDateOnly(normalizedKey)),
                  ))
                .getSingleOrNull();

        if (existing != null) return;

        await _db
            .into(_db.routineSkipsTable)
            .insert(
              RoutineSkipsTableCompanion.insert(
                id: _ids.routineSkipId(),
                routineId: routineId,
                periodType: periodType.name,
                periodKey: normalizedKey,
                createdAt: Value(now),
                psMetadata: Value(psMetadata),
              ),
              mode: InsertMode.insert,
            );
      },
      area: 'data.routines',
      opName: 'recordSkip',
      context: context,
    );
  }

  List<Routine> _mapRoutines(
    List<RoutinesTableData> routineRows,
    List<ValueTableData> valueRows, {
    required bool includeInactive,
  }) {
    final valuesById = {
      for (final value in valueRows) value.id: valueFromTable(value),
    };

    final routines = <Routine>[];
    for (final row in routineRows) {
      if (!includeInactive && !row.isActive) continue;
      routines.add(routineFromTable(row, value: valuesById[row.valueId]));
    }

    return routines;
  }
}
