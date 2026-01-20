import 'package:drift/drift.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_data/src/id/id_generator.dart';
import 'package:taskly_data/src/infrastructure/drift/drift_database.dart';
import 'package:taskly_data/src/infrastructure/powersync/crud_metadata.dart';
import 'package:taskly_domain/my_day.dart' as domain;
import 'package:taskly_domain/telemetry.dart';
import 'package:taskly_domain/time.dart';

final class _DayRowChange {
  const _DayRowChange({required this.previous, required this.current});

  final MyDayDaysTableData? previous;
  final MyDayDaysTableData? current;
}

String _safeMetaPreview(String? raw) {
  if (raw == null || raw.isEmpty) return '<null>';
  const max = 140;
  if (raw.length <= max) return raw;
  return '${raw.substring(0, max)}…(${raw.length} chars)';
}

String _formatDayRow(MyDayDaysTableData? row) {
  if (row == null) return '<null>';
  final ritual = row.ritualCompletedAt?.toUtc().toIso8601String() ?? '<null>';
  final created = row.createdAt.toUtc().toIso8601String();
  final updated = row.updatedAt.toUtc().toIso8601String();
  final meta = _safeMetaPreview(row.psMetadata);
  return 'id=${row.id} dayUtc=${row.dayUtc} ritualCompletedAtUtc=$ritual createdAtUtc=$created updatedAtUtc=$updated psMetadata=$meta';
}

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

    final tracedDayRow$ = dayRow$
        .scan<_DayRowChange>(
          (acc, row, _) => _DayRowChange(previous: acc.current, current: row),
          const _DayRowChange(previous: null, current: null),
        )
        .doOnData((change) {
          final prevRitual = change.previous?.ritualCompletedAt;
          final nextRitual = change.current?.ritualCompletedAt;
          final ritualChanged = prevRitual != nextRitual;

          // High-signal only: log when ritualCompletedAt flips or when a row
          // appears/disappears (helps attribute CDC/sync overwrites).
          final appearedOrGone =
              (change.previous == null) != (change.current == null);
          if (!ritualChanged && !appearedOrGone) return;

          myDayTrace(
            '[MyDayRepository.watchDay] dayId=$dayId dayKeyUtc=${dayUtc.toIso8601String()} dayRow ${_formatDayRow(change.previous)} -> ${_formatDayRow(change.current)}',
          );
        })
        .map((c) => c.current);

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
      tracedDayRow$,
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
    return domain.MyDayPick(
      taskId: row.taskId,
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
      'planned' => domain.MyDayPickBucket.planned,
      'due' => domain.MyDayPickBucket.due,
      'starts' => domain.MyDayPickBucket.starts,
      'focus' => domain.MyDayPickBucket.focus,
      _ => domain.MyDayPickBucket.focus,
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

    myDayTrace(
      '[MyDayRepository.setDayPicks] start correlationId=${context.correlationId} intent=${context.intent} operation=${context.operation} dayId=$dayId dayKeyUtc=${dayUtc.toIso8601String()} ritualCompletedAtUtc=${ritualCompletedAtUtc.toUtc().toIso8601String()} pickedCount=${picks.length} psMetadata=${_safeMetaPreview(psMetadata)}',
    );

    await _db.transaction(() async {
      final before = await (_db.select(
        _db.myDayDaysTable,
      )..where((t) => t.id.equals(dayId))).getSingleOrNull();
      myDayTrace(
        '[MyDayRepository.setDayPicks] beforeWrite correlationId=${context.correlationId} dayRow=${_formatDayRow(before)}',
      );

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

      final afterDay = await (_db.select(
        _db.myDayDaysTable,
      )..where((t) => t.id.equals(dayId))).getSingleOrNull();
      myDayTrace(
        '[MyDayRepository.setDayPicks] afterDayWrite correlationId=${context.correlationId} dayRow=${_formatDayRow(afterDay)}',
      );

      // Replace picks for the day.
      await (_db.delete(
        _db.myDayPicksTable,
      )..where((t) => t.dayId.equals(dayId))).go();

      for (final pick in picks) {
        await _db
            .into(_db.myDayPicksTable)
            .insert(
              MyDayPicksTableCompanion.insert(
                id: _ids.myDayPickId(dayId: dayId, taskId: pick.taskId),
                userId: Value(userId),
                dayId: dayId,
                taskId: pick.taskId,
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

    myDayTrace(
      '[MyDayRepository.setDayPicks] done correlationId=${context.correlationId} dayId=$dayId dayKeyUtc=${dayUtc.toIso8601String()} pickedCount=${picks.length}',
    );
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

    myDayTrace(
      '[MyDayRepository.appendPick] start correlationId=${context.correlationId} intent=${context.intent} operation=${context.operation} dayId=$dayId dayKeyUtc=${dayUtc.toIso8601String()} taskId=$taskId bucket=${bucket.name} psMetadata=${_safeMetaPreview(psMetadata)}',
    );

    await _db.transaction(() async {
      final before = await (_db.select(
        _db.myDayDaysTable,
      )..where((t) => t.id.equals(dayId))).getSingleOrNull();
      myDayTrace(
        '[MyDayRepository.appendPick] beforeWrite correlationId=${context.correlationId} dayRow=${_formatDayRow(before)}',
      );

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

      final after = await (_db.select(
        _db.myDayDaysTable,
      )..where((t) => t.id.equals(dayId))).getSingleOrNull();
      myDayTrace(
        '[MyDayRepository.appendPick] afterEnsureDay correlationId=${context.correlationId} dayRow=${_formatDayRow(after)}',
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
              id: _ids.myDayPickId(dayId: dayId, taskId: taskId),
              userId: Value(userId),
              dayId: dayId,
              taskId: taskId,
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

    myDayTrace(
      '[MyDayRepository.appendPick] done correlationId=${context.correlationId} dayId=$dayId dayKeyUtc=${dayUtc.toIso8601String()} taskId=$taskId',
    );
  }
}
