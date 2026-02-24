@Tags(['unit'])
library;

import 'dart:convert';

import '../../helpers/test_imports.dart';
import '../../helpers/test_db.dart';

import 'package:drift/drift.dart' as drift;
import 'package:taskly_data/db.dart';
import 'package:taskly_data/id.dart';
import 'package:taskly_data/src/features/my_day/repositories/my_day_decision_event_repository_impl.dart';
import 'package:taskly_data/src/repositories/routine_repository.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/time.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('RoutineRepository', () {
    testSafe('create inserts routine row', () async {
      final db = createAutoClosingDb();
      await _seedProject(db);

      final repo = RoutineRepository(
        driftDb: db,
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      await repo.create(
        name: 'Hydrate',
        projectId: 'project-1',
        periodType: RoutinePeriodType.week,
        scheduleMode: RoutineScheduleMode.flexible,
        targetCount: 3,
        scheduleDays: const [1, 3, 5],
      );

      final rows = await db.select(db.routinesTable).get();
      expect(rows, hasLength(1));
      expect(rows.single.name, 'Hydrate');
    });

    testSafe('recordCompletion and removeLatestCompletionForDay', () async {
      final db = createAutoClosingDb();
      await _seedProject(db);

      final repo = RoutineRepository(
        driftDb: db,
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      await repo.create(
        name: 'Stretch',
        projectId: 'project-1',
        periodType: RoutinePeriodType.week,
        scheduleMode: RoutineScheduleMode.flexible,
        targetCount: 2,
      );
      final routineId = (await db.select(db.routinesTable).getSingle()).id;
      await db
          .into(db.routineChecklistItemsTable)
          .insert(
            RoutineChecklistItemsTableCompanion.insert(
              id: 'item-1',
              routineId: routineId,
              title: 'step 1',
              sortIndex: 0,
            ),
          );
      await db
          .into(db.routineChecklistItemsTable)
          .insert(
            RoutineChecklistItemsTableCompanion.insert(
              id: 'item-2',
              routineId: routineId,
              title: 'step 2',
              sortIndex: 1,
            ),
          );
      await db
          .into(db.routineChecklistItemStateTable)
          .insert(
            RoutineChecklistItemStateTableCompanion.insert(
              id: 'state-1',
              routineId: routineId,
              checklistItemId: 'item-1',
              periodType: 'week',
              windowKey: DateTime.utc(2025, 1, 13),
              isChecked: const drift.Value(true),
            ),
          );

      await repo.recordCompletion(
        routineId: routineId,
        completedAtUtc: DateTime.utc(2025, 1, 15, 12),
        completedDayLocal: DateTime.utc(2025, 1, 15),
      );
      final removed = await repo.removeLatestCompletionForDay(
        routineId: routineId,
        dayKeyUtc: DateTime.utc(2025, 1, 15),
      );

      expect(removed, isTrue);
      final completions = await repo.getCompletions();
      expect(completions, isEmpty);

      final events = await db.select(db.checklistEventsTable).get();
      expect(events, hasLength(1));
      final event = events.single;
      expect(event.parentType, 'routine');
      expect(event.parentId, routineId);
      expect(event.scopePeriodType, 'week');
      expect(event.scopeDate, DateTime.utc(2025, 1, 13));
      expect(event.eventType, 'parent_logged');

      final metrics = jsonDecode(event.metricsJson) as Map<String, dynamic>;
      expect(metrics['checked_items'], 1);
      expect(metrics['total_items'], 2);
      expect(metrics['completion_ratio'], 0.5);
      expect(metrics['completed_with_all_items'], false);
    });

    testSafe('routine value is inherited from project primary value', () async {
      final db = createAutoClosingDb();
      await _seedProject(db);

      final repo = RoutineRepository(
        driftDb: db,
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      await repo.create(
        name: 'Hydrate',
        projectId: 'project-1',
        periodType: RoutinePeriodType.week,
        scheduleMode: RoutineScheduleMode.flexible,
        targetCount: 3,
      );

      final routine = await repo.getAll();
      expect(routine, hasLength(1));
      expect(routine.single.value?.id, 'value-1');
    });

    testSafe(
      'getAll excludes inactive when includeInactive is false and get/watch by id handle missing',
      () async {
        final db = createAutoClosingDb();
        await _seedProject(db);
        final repo = RoutineRepository(
          driftDb: db,
          idGenerator: IdGenerator.withUserId('user-1'),
        );

        await repo.create(
          name: 'A',
          projectId: 'project-1',
          periodType: RoutinePeriodType.week,
          scheduleMode: RoutineScheduleMode.flexible,
          targetCount: 1,
          isActive: false,
        );
        await repo.create(
          name: 'B',
          projectId: 'project-1',
          periodType: RoutinePeriodType.week,
          scheduleMode: RoutineScheduleMode.flexible,
          targetCount: 1,
          isActive: true,
        );

        final activeOnly = await repo.getAll(includeInactive: false);
        expect(activeOnly, hasLength(1));
        expect(activeOnly.single.name, 'B');

        final missingById = await repo.getById('missing');
        expect(missingById, isNull);

        final watchedMissing = await repo.watchById('missing').first;
        expect(watchedMissing, isNull);
      },
    );

    testSafe(
      'update applies nullable fields and checklist normalization limit',
      () async {
        final db = createAutoClosingDb();
        await _seedProject(db);
        final repo = RoutineRepository(
          driftDb: db,
          idGenerator: IdGenerator.withUserId('user-1'),
        );

        await repo.create(
          name: 'Hydrate',
          projectId: 'project-1',
          periodType: RoutinePeriodType.week,
          scheduleMode: RoutineScheduleMode.flexible,
          targetCount: 2,
          checklistTitles: const [' one ', '', 'two'],
        );
        final id = (await db.select(db.routinesTable).getSingle()).id;

        final manyTitles = List<String>.generate(30, (i) => ' item-$i ');
        await repo.update(
          id: id,
          name: 'Hydrate+',
          projectId: 'project-1',
          periodType: RoutinePeriodType.month,
          scheduleMode: RoutineScheduleMode.scheduled,
          targetCount: 7,
          scheduleDays: const [1, 2],
          scheduleMonthDays: const [10, 20],
          scheduleTimeMinutes: 450,
          minSpacingDays: 3,
          restDayBuffer: 1,
          isActive: false,
          pausedUntilUtc: DateTime.utc(2025, 1, 20),
          checklistTitles: manyTitles,
        );

        final row = await db.select(db.routinesTable).getSingle();
        expect(row.name, 'Hydrate+');
        expect(row.scheduleDays, const [1, 2]);
        expect(row.scheduleMonthDays, const [10, 20]);
        expect(row.scheduleTimeMinutes, 450);
        expect(row.minSpacingDays, 3);
        expect(row.restDayBuffer, 1);
        expect(row.isActive, isFalse);
        expect(row.pausedUntil, DateTime.utc(2025, 1, 20));

        final items =
            await (db.select(db.routineChecklistItemsTable)
                  ..where((t) => t.routineId.equals(id))
                  ..orderBy([
                    (t) => drift.OrderingTerm(expression: t.sortIndex),
                  ]))
                .get();
        expect(items.length, 20);
        expect(items.first.title, 'item-0');
        expect(items.last.title, 'item-19');
      },
    );

    testSafe('recordSkip deduplicates same routine/period/day', () async {
      final db = createAutoClosingDb();
      await _seedProject(db);
      final repo = RoutineRepository(
        driftDb: db,
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      await repo.create(
        name: 'Stretch',
        projectId: 'project-1',
        periodType: RoutinePeriodType.week,
        scheduleMode: RoutineScheduleMode.flexible,
        targetCount: 1,
      );
      final routineId = (await db.select(db.routinesTable).getSingle()).id;

      await repo.recordSkip(
        routineId: routineId,
        periodType: RoutineSkipPeriodType.week,
        periodKeyUtc: DateTime.utc(2025, 1, 15, 13),
      );
      await repo.recordSkip(
        routineId: routineId,
        periodType: RoutineSkipPeriodType.week,
        periodKeyUtc: DateTime.utc(2025, 1, 15, 23, 30),
      );

      final skips = await repo.getSkips();
      expect(skips, hasLength(1));
    });

    testSafe(
      'recordCompletion emits PMD completed event when routine is in today picks',
      () async {
        final db = createAutoClosingDb();
        final ids = IdGenerator.withUserId('user-1');
        await _seedProject(db);
        final decisionRepo = MyDayDecisionEventRepositoryImpl(
          driftDb: db,
          ids: ids,
        );
        final repo = RoutineRepository(
          driftDb: db,
          idGenerator: ids,
          decisionEventsRepository: decisionRepo,
        );

        await repo.create(
          name: 'Gym',
          projectId: 'project-1',
          periodType: RoutinePeriodType.week,
          scheduleMode: RoutineScheduleMode.scheduled,
          targetCount: 2,
        );
        final routineId = (await db.select(db.routinesTable).getSingle()).id;

        final completedAt = DateTime.utc(2026, 2, 24, 8, 0);
        final dayKey = dateOnly(completedAt);
        final dayId = ids.myDayDayId(dayUtc: dayKey);

        await db
            .into(db.myDayDaysTable)
            .insert(
              MyDayDaysTableCompanion.insert(
                id: dayId,
                dayUtc: dayKey,
              ),
            );
        await db
            .into(db.myDayPicksTable)
            .insert(
              MyDayPicksTableCompanion.insert(
                id: ids.myDayPickId(
                  dayId: dayId,
                  targetType: 'routine',
                  targetId: routineId,
                ),
                dayId: dayId,
                routineId: drift.Value(routineId),
                bucket: 'routine',
                sortIndex: 0,
                pickedAt: completedAt,
              ),
            );

        await repo.recordCompletion(
          routineId: routineId,
          completedAtUtc: completedAt,
          completedDayLocal: DateTime.utc(2026, 2, 24),
        );

        final completion = await db
            .select(db.routineCompletionsTable)
            .getSingle();
        expect(completion.completedWeekdayLocal, 2);
        expect(completion.timezoneOffsetMinutes, isNotNull);

        final events = await db.select(db.myDayDecisionEventsTable).get();
        expect(events, hasLength(1));
        final event = events.single;
        expect(event.entityType, 'routine');
        expect(event.entityId, routineId);
        expect(event.action, 'completed');
        expect(event.shelf, 'routine_scheduled');
      },
    );

    testSafe('removeLatestCompletionForDay returns false when none', () async {
      final db = createAutoClosingDb();
      await _seedProject(db);
      final repo = RoutineRepository(
        driftDb: db,
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      final removed = await repo.removeLatestCompletionForDay(
        routineId: 'missing',
        dayKeyUtc: DateTime.utc(2025, 1, 15),
      );
      expect(removed, isFalse);
    });

    testSafe('delete removes routine row', () async {
      final db = createAutoClosingDb();
      await _seedProject(db);
      final repo = RoutineRepository(
        driftDb: db,
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      await repo.create(
        name: 'Delete me',
        projectId: 'project-1',
        periodType: RoutinePeriodType.week,
        scheduleMode: RoutineScheduleMode.flexible,
        targetCount: 1,
      );
      final id = (await db.select(db.routinesTable).getSingle()).id;

      await repo.delete(id);

      final rows = await db.select(db.routinesTable).get();
      expect(rows, isEmpty);
    });
  });
}

Future<void> _seedProject(AppDatabase db) async {
  await db
      .into(db.valueTable)
      .insert(
        ValueTableCompanion.insert(
          id: 'value-1',
          name: 'Health',
          color: '#00AA88',
        ),
      );

  await db
      .into(db.projectTable)
      .insert(
        ProjectTableCompanion.insert(
          id: drift.Value('project-1'),
          name: 'Health',
          completed: false,
          primaryValueId: const drift.Value('value-1'),
        ),
      );
}
