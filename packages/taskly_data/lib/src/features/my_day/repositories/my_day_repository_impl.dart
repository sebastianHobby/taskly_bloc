import 'package:drift/drift.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_data/src/id/id_generator.dart';
import 'package:taskly_data/src/infrastructure/drift/drift_database.dart';
import 'package:taskly_data/src/infrastructure/powersync/crud_metadata.dart';
import 'package:taskly_domain/my_day.dart' as domain;
import 'package:taskly_domain/telemetry.dart';
import 'package:taskly_domain/time.dart';

final class MyDayRepositoryImpl implements domain.MyDayRepositoryContract {
  MyDayRepositoryImpl({required AppDatabase driftDb, required IdGenerator ids})
    : _db = driftDb,
      _ids = ids;

  final AppDatabase _db;
  final IdGenerator _ids;

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
    >(
      dayRow$,
      picks$,
      (dayRow, pickRows) {
        return domain.MyDayDayPicks(
          dayKeyUtc: dayUtc,
          ritualCompletedAtUtc: dayRow?.ritualCompletedAt,
          picks: pickRows.map(_pickFromRow).toList(growable: false),
        );
      },
    );
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
      'values' => domain.MyDayPickBucket.values,
      'routine' => domain.MyDayPickBucket.routine,
      'due' => domain.MyDayPickBucket.due,
      'starts' => domain.MyDayPickBucket.starts,
      'manual' => domain.MyDayPickBucket.manual,
      _ => throw StateError('Unknown My Day pick bucket: $raw'),
    };
  }

  @override
  Future<void> setDayPicks({
    required DateTime dayKeyUtc,
    required DateTime ritualCompletedAtUtc,
    required List<domain.MyDayPick> picks,
    required OperationContext context,
  }) async {
    final userId = _ids.userId;
    final nowUtc = DateTime.now().toUtc();

    final dayUtc = dateOnly(dayKeyUtc);
    final dayId = _ids.myDayDayId(dayUtc: dayUtc);

    final psMetadata = encodeCrudMetadata(context);

    await _db.transaction(() async {
      // Ensure day row exists.
      await _db
          .into(_db.myDayDaysTable)
          .insert(
            MyDayDaysTableCompanion.insert(
              id: dayId,
              userId: Value(userId),
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
                userId: Value(userId),
                dayId: dayId,
                taskId: Value(taskId),
                routineId: Value(routineId),
                bucket: pick.bucket.name,
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
  }

  @override
  Future<void> appendPick({
    required DateTime dayKeyUtc,
    required String taskId,
    required domain.MyDayPickBucket bucket,
    required OperationContext context,
  }) async {
    final userId = _ids.userId;
    final nowUtc = DateTime.now().toUtc();

    final dayUtc = dateOnly(dayKeyUtc);
    final dayId = _ids.myDayDayId(dayUtc: dayUtc);

    final psMetadata = encodeCrudMetadata(context);

    await _db.transaction(() async {
      // Ensure day row exists (append is only valid after confirmation, but
      // we keep this defensive).
      await _db
          .into(_db.myDayDaysTable)
          .insert(
            MyDayDaysTableCompanion.insert(
              id: dayId,
              userId: Value(userId),
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
              userId: Value(userId),
              dayId: dayId,
              taskId: Value(taskId),
              bucket: bucket.name,
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

    await _db.transaction(() async {
      await (_db.delete(
        _db.myDayPicksTable,
      )..where((t) => t.dayId.equals(dayId))).go();

      await (_db.delete(
        _db.myDayDaysTable,
      )..where((t) => t.id.equals(dayId))).go();
    });
  }
}
