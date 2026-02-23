@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';
import '../../helpers/test_db.dart';

import 'package:drift/drift.dart' as drift;
import 'package:taskly_data/db.dart';
import 'package:taskly_data/id.dart';
import 'package:taskly_data/src/repositories/routine_repository.dart';
import 'package:taskly_domain/routines.dart';

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

      await repo.recordCompletion(
        routineId: routineId,
        completedAtUtc: DateTime.utc(2025, 1, 15, 12),
      );
      final removed = await repo.removeLatestCompletionForDay(
        routineId: routineId,
        dayKeyUtc: DateTime.utc(2025, 1, 15),
      );

      expect(removed, isTrue);
      final completions = await repo.getCompletions();
      expect(completions, isEmpty);
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
