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
import 'package:taskly_domain/time.dart'
    show Clock, dateOnly, dateOnlyOrNull, encodeDateOnly, systemClock;

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
    final projects$ = _db.select(_db.projectTable).watch();
    final values$ = _db.select(_db.valueTable).watch();

    return Rx.combineLatest3(
      routines$,
      projects$,
      values$,
      (routineRows, projectRows, valueRows) => _mapRoutines(
        routineRows,
        projectRows,
        valueRows,
        includeInactive: includeInactive,
      ),
    );
  }

  @override
  Future<List<Routine>> getAll({bool includeInactive = true}) async {
    final routineRows = await (_db.select(
      _db.routinesTable,
    )..orderBy([(t) => OrderingTerm(expression: t.name)])).get();
    final projectRows = await _db.select(_db.projectTable).get();
    final valueRows = await _db.select(_db.valueTable).get();

    return _mapRoutines(
      routineRows,
      projectRows,
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
    required String projectId,
    required RoutinePeriodType periodType,
    required RoutineScheduleMode scheduleMode,
    required int targetCount,
    List<int> scheduleDays = const <int>[],
    List<int> scheduleMonthDays = const <int>[],
    int? scheduleTimeMinutes,
    int? minSpacingDays,
    int? restDayBuffer,
    bool isActive = true,
    DateTime? pausedUntilUtc,
    List<String> checklistTitles = const <String>[],
    OperationContext? context,
  }) async {
    return FailureGuard.run(
      () async {
        final now = _clock.nowUtc();
        final psMetadata = encodeCrudMetadata(context, clock: _clock);

        final routineId = _ids.routineId();
        await _db.transaction(() async {
          await _db
              .into(_db.routinesTable)
              .insert(
                RoutinesTableCompanion.insert(
                  id: routineId,
                  name: name,
                  projectId: projectId,
                  periodType: periodType.name,
                  scheduleMode: scheduleMode.name,
                  targetCount: targetCount,
                  scheduleDays: Value(
                    scheduleDays.isEmpty ? null : scheduleDays,
                  ),
                  scheduleMonthDays: Value(
                    scheduleMonthDays.isEmpty ? null : scheduleMonthDays,
                  ),
                  scheduleTimeMinutes: Value(scheduleTimeMinutes),
                  minSpacingDays: Value(minSpacingDays),
                  restDayBuffer: Value(restDayBuffer),
                  isActive: Value(isActive),
                  pausedUntil: Value(dateOnlyOrNull(pausedUntilUtc)),
                  createdAt: Value(now),
                  updatedAt: Value(now),
                  psMetadata: Value(psMetadata),
                ),
                mode: InsertMode.insert,
              );
          await _replaceRoutineChecklistItems(
            routineId: routineId,
            titlesInOrder: checklistTitles,
            now: now,
            psMetadata: psMetadata,
          );
        });
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
    required String projectId,
    required RoutinePeriodType periodType,
    required RoutineScheduleMode scheduleMode,
    required int targetCount,
    List<int>? scheduleDays,
    List<int>? scheduleMonthDays,
    int? scheduleTimeMinutes,
    int? minSpacingDays,
    int? restDayBuffer,
    bool? isActive,
    DateTime? pausedUntilUtc,
    List<String> checklistTitles = const <String>[],
    OperationContext? context,
  }) async {
    return FailureGuard.run(
      () async {
        final now = _clock.nowUtc();
        final psMetadata = encodeCrudMetadata(context, clock: _clock);

        await _db.transaction(() async {
          await (_db.update(
            _db.routinesTable,
          )..where((t) => t.id.equals(id))).write(
            RoutinesTableCompanion(
              name: Value(name),
              projectId: Value(projectId),
              periodType: Value(periodType.name),
              scheduleMode: Value(scheduleMode.name),
              targetCount: Value(targetCount),
              scheduleDays: scheduleDays == null
                  ? const Value.absent()
                  : Value(scheduleDays),
              scheduleMonthDays: scheduleMonthDays == null
                  ? const Value.absent()
                  : Value(scheduleMonthDays),
              scheduleTimeMinutes: scheduleTimeMinutes == null
                  ? const Value.absent()
                  : Value(scheduleTimeMinutes),
              minSpacingDays: Value(minSpacingDays),
              restDayBuffer: Value(restDayBuffer),
              isActive: isActive == null
                  ? const Value.absent()
                  : Value(isActive),
              pausedUntil: Value(dateOnlyOrNull(pausedUntilUtc)),
              updatedAt: Value(now),
              psMetadata: psMetadata == null
                  ? const Value.absent()
                  : Value(psMetadata),
            ),
          );
          await _replaceRoutineChecklistItems(
            routineId: id,
            titlesInOrder: checklistTitles,
            now: now,
            psMetadata: psMetadata,
          );
        });
      },
      area: 'data.routines',
      opName: 'update',
      context: context,
    );
  }

  Future<void> _replaceRoutineChecklistItems({
    required String routineId,
    required List<String> titlesInOrder,
    required DateTime now,
    required String? psMetadata,
  }) async {
    final normalized = titlesInOrder
        .map((title) => title.trim())
        .where((title) => title.isNotEmpty)
        .take(20)
        .toList(growable: false);

    await (_db.delete(
      _db.routineChecklistItemsTable,
    )..where((t) => t.routineId.equals(routineId))).go();

    for (var i = 0; i < normalized.length; i += 1) {
      await _db
          .into(_db.routineChecklistItemsTable)
          .insert(
            RoutineChecklistItemsTableCompanion.insert(
              id: _ids.routineChecklistItemId(),
              routineId: routineId,
              title: normalized[i],
              sortIndex: i,
              createdAt: Value(now),
              updatedAt: Value(now),
              psMetadata: Value(psMetadata),
            ),
            mode: InsertMode.insert,
          );
    }
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
    DateTime? completedDayLocal,
    int? completedTimeLocalMinutes,
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
                completedDayLocal: Value(dateOnlyOrNull(completedDayLocal)),
                completedTimeLocalMinutes: Value(completedTimeLocalMinutes),
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
  Future<bool> removeLatestCompletionForDay({
    required String routineId,
    required DateTime dayKeyUtc,
    OperationContext? context,
  }) async {
    return FailureGuard.run(
      () async {
        final dayStart = dateOnly(dayKeyUtc);
        final dayEnd = dayStart.add(const Duration(days: 1));

        final query = _db.select(_db.routineCompletionsTable)
          ..where((t) => t.routineId.equals(routineId))
          ..where((t) => t.completedAt.isBiggerOrEqualValue(dayStart))
          ..where((t) => t.completedAt.isSmallerThanValue(dayEnd))
          ..orderBy([
            (t) => OrderingTerm(
              expression: t.completedAt,
              mode: OrderingMode.desc,
            ),
          ])
          ..limit(1);

        final latest = await query.getSingleOrNull();
        if (latest == null) return false;

        await (_db.delete(
          _db.routineCompletionsTable,
        )..where((t) => t.id.equals(latest.id))).go();

        return true;
      },
      area: 'data.routines',
      opName: 'removeLatestCompletionForDay',
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
    List<ProjectTableData> projectRows,
    List<ValueTableData> valueRows, {
    required bool includeInactive,
  }) {
    final valuesById = {
      for (final value in valueRows) value.id: valueFromTable(value),
    };
    final projectsById = {
      for (final project in projectRows) project.id: project,
    };

    final routines = <Routine>[];
    for (final row in routineRows) {
      if (!includeInactive && !row.isActive) continue;
      final project = projectsById[row.projectId];
      final primaryValueId = project?.primaryValueId;
      routines.add(
        routineFromTable(
          row,
          value: primaryValueId == null ? null : valuesById[primaryValueId],
        ),
      );
    }

    return routines;
  }
}
