import 'package:drift/drift.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_data/src/errors/failure_guard.dart';
import 'package:taskly_data/src/id/id_generator.dart';
import 'package:taskly_data/src/infrastructure/drift/drift_database.dart';
import 'package:taskly_data/src/infrastructure/powersync/crud_metadata.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/my_day.dart' as domain;
import 'package:taskly_domain/my_day.dart';
import 'package:taskly_domain/telemetry.dart';
import 'package:taskly_domain/time.dart' show Clock, dateOnly, systemClock;

final class MyDayRepositoryImpl implements domain.MyDayRepositoryContract {
  MyDayRepositoryImpl({
    required AppDatabase driftDb,
    required IdGenerator ids,
    required MyDayDecisionEventRepositoryContract decisionEventsRepository,
    Clock clock = systemClock,
  }) : _db = driftDb,
       _ids = ids,
       _decisionEventsRepository = decisionEventsRepository,
       _clock = clock;

  final AppDatabase _db;
  final IdGenerator _ids;
  final MyDayDecisionEventRepositoryContract _decisionEventsRepository;
  final Clock _clock;

  @override
  Stream<domain.MyDayDayPicks> watchDay(DateTime dayKeyUtc) {
    final dayUtc = dateOnly(dayKeyUtc);
    final dayId = _ids.myDayDayId(dayUtc: dayUtc);

    final dayRow$ = (_db.select(
      _db.myDayDaysTable,
    )..where((t) => t.id.equals(dayId))).watchSingleOrNull();

    final picks$ =
        (_db.select(_db.myDayPicksTable)
              ..where((t) => t.dayId.equals(dayId))
              ..orderBy([(t) => OrderingTerm(expression: t.sortIndex)]))
            .watch();

    return Rx.combineLatest2<
      MyDayDaysTableData?,
      List<MyDayPicksTableData>,
      domain.MyDayDayPicks
    >(dayRow$, picks$, (dayRow, pickRows) {
      return domain.MyDayDayPicks(
        dayKeyUtc: dayUtc,
        ritualCompletedAtUtc: dayRow?.ritualCompletedAt,
        picks: pickRows.map(_pickFromRow).toList(growable: false),
      );
    });
  }

  @override
  Future<domain.MyDayDayPicks> loadDay(DateTime dayKeyUtc) async {
    final dayUtc = dateOnly(dayKeyUtc);
    final dayId = _ids.myDayDayId(dayUtc: dayUtc);

    final dayRow = await (_db.select(
      _db.myDayDaysTable,
    )..where((t) => t.id.equals(dayId))).getSingleOrNull();

    final pickRows =
        await (_db.select(_db.myDayPicksTable)
              ..where((t) => t.dayId.equals(dayId))
              ..orderBy([(t) => OrderingTerm(expression: t.sortIndex)]))
            .get();

    return domain.MyDayDayPicks(
      dayKeyUtc: dayUtc,
      ritualCompletedAtUtc: dayRow?.ritualCompletedAt,
      picks: pickRows.map(_pickFromRow).toList(growable: false),
    );
  }

  domain.MyDayPick _pickFromRow(MyDayPicksTableData row) {
    final routineId = row.routineId;
    if (routineId != null) {
      return domain.MyDayPick.routine(
        routineId: routineId,
        bucket: _bucketFromDb(row.bucket),
        sortIndex: row.sortIndex,
        pickedAtUtc: row.pickedAt.toUtc(),
        qualifyingValueId: row.qualifyingValueId,
      );
    }

    final taskId = row.taskId;
    if (taskId == null) {
      throw StateError('My Day pick is missing task_id and routine_id.');
    }

    return domain.MyDayPick.task(
      taskId: taskId,
      bucket: _bucketFromDb(row.bucket),
      sortIndex: row.sortIndex,
      pickedAtUtc: row.pickedAt.toUtc(),
      suggestionRank: row.suggestionRank,
      qualifyingValueId: row.qualifyingValueId,
      reasonCodes: row.reasonCodes ?? const <String>[],
    );
  }

  domain.MyDayPickBucket _bucketFromDb(String raw) {
    return switch (raw) {
      'values' => domain.MyDayPickBucket.valueSuggestions,
      'valueSuggestions' => domain.MyDayPickBucket.valueSuggestions,
      'routine' => domain.MyDayPickBucket.routine,
      'due' => domain.MyDayPickBucket.due,
      'starts' => domain.MyDayPickBucket.starts,
      'manual' => domain.MyDayPickBucket.manual,
      _ => throw StateError('Unknown My Day pick bucket: $raw'),
    };
  }

  String _bucketToDb(domain.MyDayPickBucket bucket) {
    return switch (bucket) {
      domain.MyDayPickBucket.valueSuggestions => 'values',
      domain.MyDayPickBucket.routine => 'routine',
      domain.MyDayPickBucket.due => 'due',
      domain.MyDayPickBucket.starts => 'starts',
      domain.MyDayPickBucket.manual => 'manual',
    };
  }

  MyDayDecisionShelf _shelfForTaskBucket(domain.MyDayPickBucket bucket) {
    return switch (bucket) {
      domain.MyDayPickBucket.due => MyDayDecisionShelf.due,
      domain.MyDayPickBucket.starts => MyDayDecisionShelf.planned,
      domain.MyDayPickBucket.valueSuggestions => MyDayDecisionShelf.suggestion,
      domain.MyDayPickBucket.manual => MyDayDecisionShelf.planned,
      domain.MyDayPickBucket.routine => MyDayDecisionShelf.planned,
    };
  }

  @override
  Future<void> setDayPicks({
    required DateTime dayKeyUtc,
    required DateTime ritualCompletedAtUtc,
    required List<domain.MyDayPick> picks,
    required OperationContext context,
  }) async {
    final nowUtc = _clock.nowUtc();

    final dayUtc = dateOnly(dayKeyUtc);
    final dayId = _ids.myDayDayId(dayUtc: dayUtc);

    final psMetadata = encodeCrudMetadata(context, clock: _clock);
    final actionAtUtc = _clock.nowUtc();

    final previousRows = await (_db.select(
      _db.myDayPicksTable,
    )..where((t) => t.dayId.equals(dayId))).get();

    await _db.transaction(() async {
      // Ensure day row exists.
      await _db
          .into(_db.myDayDaysTable)
          .insert(
            MyDayDaysTableCompanion.insert(
              id: dayId,
              dayUtc: dayUtc,
              ritualCompletedAt: Value(ritualCompletedAtUtc.toUtc()),
              createdAt: Value(nowUtc),
              updatedAt: Value(nowUtc),
              psMetadata: Value(psMetadata),
            ),
            mode: InsertMode.insertOrIgnore,
          );

      // Always update ritual completion timestamp (idempotent confirm).
      await (_db.update(
        _db.myDayDaysTable,
      )..where((t) => t.id.equals(dayId))).write(
        MyDayDaysTableCompanion(
          ritualCompletedAt: Value(ritualCompletedAtUtc.toUtc()),
          updatedAt: Value(nowUtc),
          psMetadata: Value(psMetadata),
        ),
      );

      // Replace picks for the day.
      await (_db.delete(
        _db.myDayPicksTable,
      )..where((t) => t.dayId.equals(dayId))).go();

      for (final pick in picks) {
        final targetType = pick.targetType.name;
        final targetId = pick.targetId;
        final taskId = pick.taskId;
        final routineId = pick.routineId;

        await _db
            .into(_db.myDayPicksTable)
            .insert(
              MyDayPicksTableCompanion.insert(
                id: _ids.myDayPickId(
                  dayId: dayId,
                  targetType: targetType,
                  targetId: targetId,
                ),
                dayId: dayId,
                taskId: Value(taskId),
                routineId: Value(routineId),
                bucket: _bucketToDb(pick.bucket),
                sortIndex: pick.sortIndex,
                pickedAt: pick.pickedAtUtc.toUtc(),
                suggestionRank: Value(pick.suggestionRank),
                qualifyingValueId: Value(pick.qualifyingValueId),
                reasonCodes: Value(
                  pick.reasonCodes.isEmpty ? null : pick.reasonCodes,
                ),
                createdAt: Value(nowUtc),
                updatedAt: Value(nowUtc),
                psMetadata: Value(psMetadata),
              ),
              mode: InsertMode.insert,
            );
      }
    });

    final routineIds = <String>{
      ...picks.map((p) => p.routineId).whereType<String>(),
      ...previousRows.map((r) => r.routineId).whereType<String>(),
    }.toList(growable: false);
    final routineModeById = <String, String>{};
    if (routineIds.isNotEmpty) {
      final rows = await (_db.select(
        _db.routinesTable,
      )..where((r) => r.id.isIn(routineIds))).get();
      for (final row in rows) {
        routineModeById[row.id] = row.scheduleMode;
      }
    }

    MyDayDecisionShelf shelfForRoutineId(String routineId) {
      final mode = routineModeById[routineId];
      return mode == 'scheduled'
          ? MyDayDecisionShelf.routineScheduled
          : MyDayDecisionShelf.routineFlexible;
    }

    final nextKeys = <String>{
      for (final pick in picks) '${pick.targetType.name}:${pick.targetId}',
    };
    final previousKeys = <String>{
      for (final row in previousRows)
        row.taskId != null
            ? 'task:${row.taskId!}'
            : 'routine:${row.routineId!}',
    };
    final removedKeys = previousKeys.difference(nextKeys);

    final keptEvents = <MyDayDecisionEvent>[
      for (final pick in picks)
        MyDayDecisionEvent(
          id: _ids.myDayDecisionEventId(),
          dayKeyUtc: dayUtc,
          entityType: pick.targetType == domain.MyDayPickTargetType.task
              ? MyDayDecisionEntityType.task
              : MyDayDecisionEntityType.routine,
          entityId: pick.targetId,
          shelf: pick.targetType == domain.MyDayPickTargetType.task
              ? _shelfForTaskBucket(pick.bucket)
              : shelfForRoutineId(pick.targetId),
          action: MyDayDecisionAction.kept,
          actionAtUtc: actionAtUtc,
          suggestionRank: pick.suggestionRank,
        ),
    ];

    final removedEvents = <MyDayDecisionEvent>[
      for (final row in previousRows)
        if (removedKeys.contains(
          row.taskId != null
              ? 'task:${row.taskId!}'
              : 'routine:${row.routineId!}',
        ))
          MyDayDecisionEvent(
            id: _ids.myDayDecisionEventId(),
            dayKeyUtc: dayUtc,
            entityType: row.taskId != null
                ? MyDayDecisionEntityType.task
                : MyDayDecisionEntityType.routine,
            entityId: row.taskId ?? row.routineId!,
            shelf: row.taskId != null
                ? _shelfForTaskBucket(_bucketFromDb(row.bucket))
                : shelfForRoutineId(row.routineId!),
            action: MyDayDecisionAction.removed,
            actionAtUtc: actionAtUtc,
            suggestionRank: row.suggestionRank,
          ),
    ];

    await _decisionEventsRepository.appendAll(
      [...keptEvents, ...removedEvents],
      context: context,
    );
  }

  @override
  Future<void> appendPick({
    required DateTime dayKeyUtc,
    required String taskId,
    required domain.MyDayPickBucket bucket,
    required OperationContext context,
  }) async {
    final nowUtc = _clock.nowUtc();

    final dayUtc = dateOnly(dayKeyUtc);
    final dayId = _ids.myDayDayId(dayUtc: dayUtc);

    final psMetadata = encodeCrudMetadata(context, clock: _clock);

    await _db.transaction(() async {
      // Ensure day row exists (append is only valid after confirmation, but
      // we keep this defensive).
      await _db
          .into(_db.myDayDaysTable)
          .insert(
            MyDayDaysTableCompanion.insert(
              id: dayId,
              dayUtc: dayUtc,
              ritualCompletedAt: Value(nowUtc),
              createdAt: Value(nowUtc),
              updatedAt: Value(nowUtc),
              psMetadata: Value(psMetadata),
            ),
            mode: InsertMode.insertOrIgnore,
          );

      final existing =
          await (_db.select(_db.myDayPicksTable)
                ..where((t) => t.dayId.equals(dayId) & t.taskId.equals(taskId)))
              .getSingleOrNull();
      if (existing != null) return;

      final last =
          await (_db.select(_db.myDayPicksTable)
                ..where((t) => t.dayId.equals(dayId))
                ..orderBy([
                  (t) => OrderingTerm(
                    expression: t.sortIndex,
                    mode: OrderingMode.desc,
                  ),
                ])
                ..limit(1))
              .getSingleOrNull();

      final nextIndex = (last?.sortIndex ?? -1) + 1;

      await _db
          .into(_db.myDayPicksTable)
          .insert(
            MyDayPicksTableCompanion.insert(
              id: _ids.myDayPickId(
                dayId: dayId,
                targetType: domain.MyDayPickTargetType.task.name,
                targetId: taskId,
              ),
              dayId: dayId,
              taskId: Value(taskId),
              bucket: _bucketToDb(bucket),
              sortIndex: nextIndex,
              pickedAt: nowUtc,
              createdAt: Value(nowUtc),
              updatedAt: Value(nowUtc),
              psMetadata: Value(psMetadata),
            ),
            mode: InsertMode.insert,
          );
    });
  }

  @override
  Future<void> clearDay({
    required DateTime dayKeyUtc,
    OperationContext? context,
  }) async {
    final dayUtc = dateOnly(dayKeyUtc);
    final dayId = _ids.myDayDayId(dayUtc: dayUtc);

    await FailureGuard.run(
      () async {
        await _db.transaction(() async {
          await (_db.delete(
            _db.myDayPicksTable,
          )..where((t) => t.dayId.equals(dayId))).go();

          await (_db.delete(
            _db.myDayDaysTable,
          )..where((t) => t.id.equals(dayId))).go();
        });
      },
      area: 'data.my_day',
      opName: 'clearDay',
      context: context,
    );
  }
}
