import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:taskly_data/src/id/id_generator.dart';
import 'package:taskly_data/src/infrastructure/drift/drift_database.dart';
import 'package:taskly_data/src/infrastructure/powersync/crud_metadata.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/my_day.dart';
import 'package:taskly_domain/telemetry.dart';
import 'package:taskly_domain/time.dart';

final class MyDayDecisionEventRepositoryImpl
    implements MyDayDecisionEventRepositoryContract {
  MyDayDecisionEventRepositoryImpl({
    required AppDatabase driftDb,
    required IdGenerator ids,
    Clock clock = systemClock,
  }) : _db = driftDb,
       _ids = ids,
       _clock = clock;

  final AppDatabase _db;
  final IdGenerator _ids;
  final Clock _clock;

  @override
  Future<void> append(
    MyDayDecisionEvent event, {
    OperationContext? context,
  }) async {
    await appendAll([event], context: context);
  }

  @override
  Future<void> appendAll(
    List<MyDayDecisionEvent> events, {
    OperationContext? context,
  }) async {
    if (events.isEmpty) return;
    final psMetadata = encodeCrudMetadata(context, clock: _clock);
    await _db.transaction(() async {
      for (final event in events) {
        await _db
            .into(_db.myDayDecisionEventsTable)
            .insert(
              MyDayDecisionEventsTableCompanion.insert(
                id: event.id.trim().isEmpty
                    ? _ids.myDayDecisionEventId()
                    : event.id,
                dayKeyUtc: dateOnly(event.dayKeyUtc),
                entityType: event.entityType.name,
                entityId: event.entityId,
                shelf: _shelfToDb(event.shelf),
                action: event.action.name,
                actionAtUtc: event.actionAtUtc.toUtc(),
                deferKind: Value(_deferKindToDb(event.deferKind)),
                fromDayKey: Value(dateOnlyOrNull(event.fromDayKey)),
                toDayKey: Value(dateOnlyOrNull(event.toDayKey)),
                suggestionRank: Value(event.suggestionRank),
                metaJson: Value(
                  event.meta == null ? null : jsonEncode(event.meta),
                ),
                createdAt: Value(_clock.nowUtc()),
                psMetadata: Value(psMetadata),
              ),
              mode: InsertMode.insert,
            );
      }
    });
  }

  @override
  Future<List<MyDayShelfRate>> getKeepRateByShelf({
    required DateRange range,
  }) async {
    return _rateByShelf(
      range: range,
      numeratorActionPredicate: "action = 'kept'",
    );
  }

  @override
  Future<List<MyDayShelfRate>> getDeferRateByShelf({
    required DateRange range,
  }) async {
    return _rateByShelf(
      range: range,
      numeratorActionPredicate: "action IN ('deferred','snoozed')",
    );
  }

  Future<List<MyDayShelfRate>> _rateByShelf({
    required DateRange range,
    required String numeratorActionPredicate,
  }) async {
    final rows = await _db
        .customSelect(
          '''
      SELECT
        shelf AS shelf,
        SUM(CASE WHEN $numeratorActionPredicate THEN 1 ELSE 0 END) AS numerator,
        SUM(CASE WHEN action IN ('kept','deferred','snoozed','removed') THEN 1 ELSE 0 END) AS denominator
      FROM my_day_decision_events
      WHERE action_at_utc >= ? AND action_at_utc <= ?
      GROUP BY shelf
      ''',
          variables: [
            Variable(range.start.toUtc()),
            Variable(range.end.toUtc()),
          ],
          readsFrom: {_db.myDayDecisionEventsTable},
        )
        .get();

    return rows
        .map((row) {
          final shelfRaw = row.read<String>('shelf');
          final numerator = row.read<int?>('numerator') ?? 0;
          final denominator = row.read<int?>('denominator') ?? 0;
          return MyDayShelfRate(
            shelf: _shelfFromDb(shelfRaw),
            numerator: numerator,
            denominator: denominator,
          );
        })
        .toList(growable: false);
  }

  @override
  Future<List<MyDayEntityDeferCount>> getEntityDeferCounts({
    required DateRange range,
    required MyDayDecisionEntityType entityType,
    int limit = 50,
  }) async {
    final rows = await _db
        .customSelect(
          '''
      SELECT
        entity_id AS entity_id,
        SUM(CASE WHEN action = 'deferred' THEN 1 ELSE 0 END) AS defer_count,
        SUM(CASE WHEN action = 'snoozed' THEN 1 ELSE 0 END) AS snooze_count
      FROM my_day_decision_events
      WHERE entity_type = ?
        AND action_at_utc >= ?
        AND action_at_utc <= ?
        AND action IN ('deferred','snoozed')
      GROUP BY entity_id
      ORDER BY (SUM(CASE WHEN action = 'deferred' THEN 1 ELSE 0 END) + SUM(CASE WHEN action = 'snoozed' THEN 1 ELSE 0 END)) DESC, entity_id ASC
      LIMIT ?
      ''',
          variables: [
            Variable(entityType.name),
            Variable(range.start.toUtc()),
            Variable(range.end.toUtc()),
            Variable(limit.clamp(1, 500)),
          ],
          readsFrom: {_db.myDayDecisionEventsTable},
        )
        .get();

    return rows
        .map(
          (row) => MyDayEntityDeferCount(
            entityType: entityType,
            entityId: row.read<String>('entity_id'),
            deferCount: row.read<int?>('defer_count') ?? 0,
            snoozeCount: row.read<int?>('snooze_count') ?? 0,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<RoutineWeekdayStat>> getRoutineTopCompletionWeekdays({
    required DateRange range,
    int topPerRoutine = 2,
    int limitRoutines = 50,
  }) async {
    final rows = await _db
        .customSelect(
          '''
      WITH ranked AS (
        SELECT
          rc.routine_id AS routine_id,
          COALESCE(rc.completed_weekday_local, CAST(strftime('%w', rc.completed_day_local) AS INTEGER)) AS weekday_local,
          COUNT(*) AS cnt,
          ROW_NUMBER() OVER (
            PARTITION BY rc.routine_id
            ORDER BY COUNT(*) DESC, COALESCE(rc.completed_weekday_local, CAST(strftime('%w', rc.completed_day_local) AS INTEGER)) ASC
          ) AS rn
        FROM routine_completions rc
        WHERE rc.completed_at >= ? AND rc.completed_at <= ?
        GROUP BY rc.routine_id, COALESCE(rc.completed_weekday_local, CAST(strftime('%w', rc.completed_day_local) AS INTEGER))
      ),
      top_routines AS (
        SELECT routine_id
        FROM ranked
        GROUP BY routine_id
        ORDER BY SUM(cnt) DESC, routine_id ASC
        LIMIT ?
      )
      SELECT r.routine_id AS routine_id, r.weekday_local AS weekday_local, r.cnt AS cnt
      FROM ranked r
      INNER JOIN top_routines t ON t.routine_id = r.routine_id
      WHERE r.rn <= ?
      ORDER BY r.routine_id ASC, r.cnt DESC, r.weekday_local ASC
      ''',
          variables: [
            Variable(range.start.toUtc()),
            Variable(range.end.toUtc()),
            Variable(limitRoutines.clamp(1, 500)),
            Variable(topPerRoutine.clamp(1, 7)),
          ],
          readsFrom: {_db.routineCompletionsTable},
        )
        .get();

    return rows
        .map(
          (row) => RoutineWeekdayStat(
            routineId: row.read<String>('routine_id'),
            weekdayLocal: _normalizeWeekday(
              row.read<int?>('weekday_local') ?? 1,
            ),
            count: row.read<int?>('cnt') ?? 0,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<DeferredThenCompletedLagMetric>> getDeferredThenCompletedLag({
    required DateRange range,
    int limit = 50,
  }) async {
    final deferredRows = await _db
        .customSelect(
          '''
      SELECT entity_type, entity_id, action_at_utc
      FROM my_day_decision_events
      WHERE action_at_utc >= ? AND action_at_utc <= ?
        AND action IN ('deferred','snoozed')
      ORDER BY entity_type, entity_id, action_at_utc
      ''',
          variables: [
            Variable(range.start.toUtc()),
            Variable(range.end.toUtc()),
          ],
          readsFrom: {_db.myDayDecisionEventsTable},
        )
        .get();

    final completedRows = await _db
        .customSelect(
          '''
      SELECT entity_type, entity_id, action_at_utc
      FROM my_day_decision_events
      WHERE action_at_utc >= ? AND action_at_utc <= ?
        AND action = 'completed'
      ORDER BY entity_type, entity_id, action_at_utc
      ''',
          variables: [
            Variable(range.start.toUtc()),
            Variable(range.end.toUtc()),
          ],
          readsFrom: {_db.myDayDecisionEventsTable},
        )
        .get();

    final completionsByEntity = <String, List<DateTime>>{};
    for (final row in completedRows) {
      final key =
          '${row.read<String>('entity_type')}:${row.read<String>('entity_id')}';
      (completionsByEntity[key] ??= <DateTime>[]).add(
        row.read<DateTime>('action_at_utc').toUtc(),
      );
    }

    final lagsByEntity = <String, List<Duration>>{};
    for (final row in deferredRows) {
      final entityType = row.read<String>('entity_type');
      final entityId = row.read<String>('entity_id');
      final deferredAt = row.read<DateTime>('action_at_utc').toUtc();
      final key = '$entityType:$entityId';
      final completions = completionsByEntity[key];
      if (completions == null || completions.isEmpty) continue;
      final completion = completions.firstWhere(
        (c) => !c.isBefore(deferredAt),
        orElse: () => DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
      if (completion.millisecondsSinceEpoch == 0) continue;
      (lagsByEntity[key] ??= <Duration>[]).add(
        completion.difference(deferredAt),
      );
    }

    final metrics = <DeferredThenCompletedLagMetric>[];
    for (final entry in lagsByEntity.entries) {
      final key = entry.key;
      final parts = key.split(':');
      if (parts.length != 2) continue;
      final durations = entry.value..sort((a, b) => a.compareTo(b));
      if (durations.isEmpty) continue;
      final sampleSize = durations.length;
      final median = _percentile(durations, 0.5);
      final p75 = _percentile(durations, 0.75);
      final within7Days = durations
          .where((d) => d <= const Duration(days: 7))
          .length;
      metrics.add(
        DeferredThenCompletedLagMetric(
          entityType: parts.first == 'routine'
              ? MyDayDecisionEntityType.routine
              : MyDayDecisionEntityType.task,
          entityId: parts.last,
          sampleSize: sampleSize,
          medianLagHours: median.inMinutes / 60,
          p75LagHours: p75.inMinutes / 60,
          completedWithin7DaysRate: sampleSize == 0
              ? 0
              : within7Days / sampleSize,
        ),
      );
    }

    metrics.sort((a, b) => b.sampleSize.compareTo(a.sampleSize));
    final bounded = metrics.take(limit.clamp(1, 500)).toList(growable: false);
    return bounded;
  }

  Duration _percentile(List<Duration> durations, double p) {
    final clamped = p.clamp(0, 1).toDouble();
    if (durations.isEmpty) return Duration.zero;
    final index = ((durations.length - 1) * clamped).round();
    return durations[index];
  }

  int _normalizeWeekday(int value) {
    // SQLite strftime('%w') uses 0=Sunday. Convert to 1..7 (Mon..Sun).
    if (value == 0) return 7;
    return value.clamp(1, 7);
  }

  String _shelfToDb(MyDayDecisionShelf shelf) {
    return switch (shelf) {
      MyDayDecisionShelf.due => 'due',
      MyDayDecisionShelf.planned => 'planned',
      MyDayDecisionShelf.routineScheduled => 'routine_scheduled',
      MyDayDecisionShelf.routineFlexible => 'routine_flexible',
      MyDayDecisionShelf.suggestion => 'suggestion',
    };
  }

  MyDayDecisionShelf _shelfFromDb(String raw) {
    return switch (raw) {
      'due' => MyDayDecisionShelf.due,
      'planned' => MyDayDecisionShelf.planned,
      'routine_scheduled' => MyDayDecisionShelf.routineScheduled,
      'routine_flexible' => MyDayDecisionShelf.routineFlexible,
      _ => MyDayDecisionShelf.suggestion,
    };
  }

  String? _deferKindToDb(MyDayDecisionDeferKind? kind) {
    return switch (kind) {
      null => null,
      MyDayDecisionDeferKind.deadlineReschedule => 'deadline_reschedule',
      MyDayDecisionDeferKind.startReschedule => 'start_reschedule',
      MyDayDecisionDeferKind.snooze => 'snooze',
    };
  }
}
