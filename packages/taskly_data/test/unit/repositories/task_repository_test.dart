@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';
import '../../helpers/test_db.dart';
import '../../helpers/fixed_clock.dart';

import 'package:drift/drift.dart' as drift;
import 'package:matcher/matcher.dart' as matcher;
import 'package:taskly_data/db.dart';
import 'package:taskly_data/id.dart';
import 'package:taskly_data/src/repositories/task_repository.dart';
import 'package:taskly_domain/taskly_domain.dart' hide Value;

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('TaskRepository', () {
    testSafe('create normalizes projectId and writes task', () async {
      final db = createAutoClosingDb();
      final expander = _FakeOccurrenceExpander();
      final writeHelper = _FakeOccurrenceWriteHelper();
      final repo = TaskRepository(
        driftDb: db,
        occurrenceExpander: expander,
        occurrenceWriteHelper: writeHelper,
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      await repo.create(name: 'Task', projectId: '  ');

      final row = await db.select(db.taskTable).getSingle();
      expect(row.projectId, matcher.isNull);
      expect(row.overridePrimaryValueId, matcher.isNull);
      expect(row.overrideSecondaryValueId, matcher.isNull);
    });

    testSafe('create rejects values when projectId is missing', () async {
      final db = createAutoClosingDb();
      final repo = TaskRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      expect(
        () => repo.create(name: 'Task', projectId: '  ', valueIds: ['v1']),
        throwsA(isA<InputValidationFailure>()),
      );
    });

    testSafe('create rejects duplicate override values', () async {
      final db = createAutoClosingDb();
      final repo = TaskRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      expect(
        () => repo.create(name: 'Task', valueIds: ['v1', 'v1']),
        throwsA(isA<InputValidationFailure>()),
      );
    });

    testSafe('create rejects more than two override values', () async {
      final db = createAutoClosingDb();
      final repo = TaskRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      expect(
        () => repo.create(name: 'Task', valueIds: ['v1', 'v2', 'v3']),
        throwsA(isA<InputValidationFailure>()),
      );
    });

    testSafe('update throws when task not found', () async {
      final db = createAutoClosingDb();
      final repo = TaskRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      expect(
        () => repo.update(id: 'missing', name: 'Task', completed: false),
        throwsA(isA<NotFoundFailure>()),
      );
    });

    testSafe('update rejects duplicate override values', () async {
      final db = createAutoClosingDb();
      final repo = TaskRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      await repo.create(name: 'Task');
      final row = await db.select(db.taskTable).getSingle();

      expect(
        () => repo.update(
          id: row.id,
          name: 'Task',
          completed: false,
          valueIds: ['v1', 'v1'],
        ),
        throwsA(isA<InputValidationFailure>()),
      );
    });

    testSafe('bulkRescheduleDeadlines returns count on no-op update', () async {
      final db = createAutoClosingDb();
      final fixedNow = DateTime.utc(2026, 2, 9, 12);
      final deadlineDay = DateTime.utc(2026, 2, 10);
      final repo = TaskRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
        clock: FixedClock(fixedNow),
      );

      await repo.create(name: 'Task A', deadlineDate: deadlineDay);
      await repo.create(name: 'Task B', deadlineDate: deadlineDay);
      final ids = (await db.select(db.taskTable).get())
          .map((t) => t.id)
          .toList();

      final updated = await repo.bulkRescheduleDeadlines(
        taskIds: ids,
        deadlineDate: deadlineDay,
      );

      expect(updated, equals(ids.length));
      final rows = await db.select(db.taskTable).get();
      expect(rows.map((r) => r.deadlineDate).toSet(), equals({deadlineDay}));
    });

    testSafe('bulkRescheduleStarts returns count on no-op update', () async {
      final db = createAutoClosingDb();
      final fixedNow = DateTime.utc(2026, 2, 9, 12);
      final startDay = DateTime.utc(2026, 2, 11);
      final repo = TaskRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
        clock: FixedClock(fixedNow),
      );

      await repo.create(name: 'Task A', startDate: startDay);
      await repo.create(name: 'Task B', startDate: startDay);
      final ids = (await db.select(db.taskTable).get())
          .map((t) => t.id)
          .toList();

      final updated = await repo.bulkRescheduleStarts(
        taskIds: ids,
        startDate: startDay,
      );

      expect(updated, equals(ids.length));
      final rows = await db.select(db.taskTable).get();
      expect(rows.map((r) => r.startDate).toSet(), equals({startDay}));
    });

    testSafe('setPinned updates pinned state', () async {
      final db = createAutoClosingDb();
      final repo = TaskRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      await repo.create(name: 'Task');
      final row = await db.select(db.taskTable).getSingle();

      await repo.setPinned(id: row.id, isPinned: true);

      final updated = await db.select(db.taskTable).getSingle();
      expect(updated.isPinned, isTrue);
    });

    testSafe('delete removes task', () async {
      final db = createAutoClosingDb();
      final repo = TaskRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      await repo.create(name: 'Task');
      final row = await db.select(db.taskTable).getSingle();

      await repo.delete(row.id);

      final remaining = await db.select(db.taskTable).get();
      expect(remaining, isEmpty);
    });

    testSafe('watchAllCount respects filters', () async {
      final db = createAutoClosingDb();
      final repo = TaskRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      await db
          .into(db.taskTable)
          .insert(
            TaskTableCompanion.insert(
              id: const drift.Value('t1'),
              name: 'A',
              completed: const drift.Value(true),
            ),
          );
      await db
          .into(db.taskTable)
          .insert(
            TaskTableCompanion.insert(
              id: const drift.Value('t2'),
              name: 'B',
              completed: const drift.Value(false),
            ),
          );

      final query = TaskQuery(
        filter: const QueryFilter<TaskPredicate>(
          shared: [
            TaskBoolPredicate(
              field: TaskBoolField.completed,
              operator: BoolOperator.isTrue,
            ),
          ],
        ),
      );

      final count = await repo.watchAllCount(query).first;
      expect(count, equals(1));
    });

    testSafe('watchAll caches inbox/upcoming streams', () async {
      final db = createAutoClosingDb();
      final repo = TaskRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      final inbox1 = repo.watchAll(TaskQuery.inbox());
      final inbox2 = repo.watchAll(TaskQuery.inbox());
      expect(identical(inbox1, inbox2), isTrue);

      final upcomingQuery = TaskQuery(
        filter: const QueryFilter<TaskPredicate>(
          shared: [
            TaskBoolPredicate(
              field: TaskBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
            TaskDatePredicate(
              field: TaskDateField.deadlineDate,
              operator: DateOperator.isNotNull,
            ),
          ],
        ),
      );
      final upcoming1 = repo.watchAll(upcomingQuery);
      final upcoming2 = repo.watchAll(upcomingQuery);
      expect(identical(upcoming1, upcoming2), isTrue);
    });

    testSafe('createReturningId returns id and normalizes reminders', () async {
      final db = createAutoClosingDb();
      final repo = TaskRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      final id = await repo.createReturningId(
        name: 'Task',
        reminderKind: TaskReminderKind.absolute,
        reminderAtUtc: DateTime.utc(2026, 2, 15, 9),
      );
      final row = await db.select(db.taskTable).getSingle();

      expect(id, equals(row.id));
      expect(row.reminderKind, equals('absolute'));
      expect(row.reminderAtUtc, equals(DateTime.utc(2026, 2, 15, 9)));
      expect(row.reminderMinutesBeforeDue, isNull);
    });

    testSafe('create clamps before-due reminder minutes', () async {
      final db = createAutoClosingDb();
      final repo = TaskRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      await repo.create(
        name: 'Task',
        reminderKind: TaskReminderKind.beforeDue,
        reminderMinutesBeforeDue: 20000,
      );

      final row = await db.select(db.taskTable).getSingle();
      expect(row.reminderKind, equals('before_due'));
      expect(row.reminderAtUtc, isNull);
      expect(row.reminderMinutesBeforeDue, equals(10080));
    });

    testSafe(
      'create validates project primary requirements and conflicts',
      () async {
        final db = createAutoClosingDb();
        final repo = TaskRepository(
          driftDb: db,
          occurrenceExpander: _FakeOccurrenceExpander(),
          occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
          idGenerator: IdGenerator.withUserId('user-1'),
        );

        await db
            .into(db.projectTable)
            .insert(
              ProjectTableCompanion.insert(
                id: const drift.Value('p-no-primary'),
                name: 'No primary',
                completed: false,
              ),
            );
        await db
            .into(db.projectTable)
            .insert(
              ProjectTableCompanion.insert(
                id: const drift.Value('p-with-primary'),
                name: 'With primary',
                completed: false,
                primaryValueId: const drift.Value('v1'),
              ),
            );

        await expectLater(
          () => repo.create(
            name: 'Needs primary',
            projectId: 'p-no-primary',
            valueIds: const ['v2'],
          ),
          throwsA(isA<InputValidationFailure>()),
        );

        await expectLater(
          () => repo.create(
            name: 'Conflicts with primary',
            projectId: 'p-with-primary',
            valueIds: const ['v1'],
          ),
          throwsA(isA<InputValidationFailure>()),
        );
      },
    );

    testSafe('getAll applies sort criteria', () async {
      final db = createAutoClosingDb();
      final repo = TaskRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      await db
          .into(db.taskTable)
          .insert(
            TaskTableCompanion.insert(
              id: const drift.Value('t1'),
              name: 'B',
              completed: const drift.Value(false),
            ),
          );
      await db
          .into(db.taskTable)
          .insert(
            TaskTableCompanion.insert(
              id: const drift.Value('t2'),
              name: 'A',
              completed: const drift.Value(false),
            ),
          );

      final query = TaskQuery(
        sortCriteria: const [SortCriterion(field: SortField.name)],
      );
      final tasks = await repo.getAll(query);
      expect(tasks.map((t) => t.id).toList(), equals(['t2', 't1']));
    });

    testSafe('getByIds preserves order and omits missing', () async {
      final db = createAutoClosingDb();
      final repo = TaskRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      await db
          .into(db.taskTable)
          .insert(
            TaskTableCompanion.insert(
              id: const drift.Value('t1'),
              name: 'One',
              completed: const drift.Value(false),
            ),
          );
      await db
          .into(db.taskTable)
          .insert(
            TaskTableCompanion.insert(
              id: const drift.Value('t2'),
              name: 'Two',
              completed: const drift.Value(false),
            ),
          );

      final tasks = await repo.getByIds(['t2', 'missing', 't1']);
      expect(tasks.map((t) => t.id).toList(), equals(['t2', 't1']));
    });

    testSafe('watchById returns null for missing task', () async {
      final db = createAutoClosingDb();
      final repo = TaskRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      final task = await repo.watchById('missing').first;
      expect(task, isNull);
    });

    testSafe('watchByIds returns empty for empty ids', () async {
      final db = createAutoClosingDb();
      final repo = TaskRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      final tasks = await repo.watchByIds(const <String>[]).first;
      expect(tasks, isEmpty);
    });

    testSafe(
      'watchByIds preserves requested order for non-empty ids',
      () async {
        final db = createAutoClosingDb();
        final repo = TaskRepository(
          driftDb: db,
          occurrenceExpander: _FakeOccurrenceExpander(),
          occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
          idGenerator: IdGenerator.withUserId('user-1'),
        );

        await db
            .into(db.taskTable)
            .insert(
              TaskTableCompanion.insert(
                id: const drift.Value('t1'),
                name: 'One',
                completed: const drift.Value(false),
              ),
            );
        await db
            .into(db.taskTable)
            .insert(
              TaskTableCompanion.insert(
                id: const drift.Value('t2'),
                name: 'Two',
                completed: const drift.Value(false),
              ),
            );

        final tasks = await repo.watchByIds(['t2', 'missing', 't1']).first;
        expect(tasks.map((t) => t.id).toList(), equals(['t2', 't1']));
      },
    );

    testSafe('watchAll uses shared cache for generic stable query', () async {
      final db = createAutoClosingDb();
      final repo = TaskRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      final query = TaskQuery(
        filter: const QueryFilter<TaskPredicate>(
          shared: [
            TaskBoolPredicate(
              field: TaskBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
          ],
        ),
      );

      final s1 = repo.watchAll(query);
      final s2 = repo.watchAll(query);
      expect(identical(s1, s2), isTrue);
    });

    testSafe(
      'watchAll bypasses shared cache when date filter is present',
      () async {
        final db = createAutoClosingDb();
        final repo = TaskRepository(
          driftDb: db,
          occurrenceExpander: _FakeOccurrenceExpander(),
          occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
          idGenerator: IdGenerator.withUserId('user-1'),
        );

        final query = TaskQuery(
          filter: QueryFilter<TaskPredicate>(
            shared: [
              TaskDatePredicate(
                field: TaskDateField.deadlineDate,
                operator: DateOperator.onOrAfter,
                date: DateTime.utc(2026, 1, 1),
              ),
            ],
          ),
        );

        final s1 = repo.watchAll(query);
        final s2 = repo.watchAll(query);
        expect(identical(s1, s2), isFalse);
      },
    );

    testSafe('occurrence query flags are rejected', () async {
      final db = createAutoClosingDb();
      final repo = TaskRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      final query = TaskQuery(
        occurrenceExpansion: OccurrenceExpansion(
          rangeStart: DateTime.utc(2026, 1, 1),
          rangeEnd: DateTime.utc(2026, 1, 2),
        ),
      );

      expect(() => repo.watchAll(query), throwsA(isA<UnsupportedError>()));
      expect(() => repo.watchAllCount(query), throwsA(isA<UnsupportedError>()));
      expect(() => repo.getAll(query), throwsA(isA<UnsupportedError>()));
    });

    testSafe('recognizes inbox/upcoming queries', () async {
      final db = createAutoClosingDb();
      final repo = TaskRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      final upcomingQuery = TaskQuery(
        filter: const QueryFilter<TaskPredicate>(
          shared: [
            TaskBoolPredicate(
              field: TaskBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
            TaskDatePredicate(
              field: TaskDateField.deadlineDate,
              operator: DateOperator.isNotNull,
            ),
          ],
        ),
      );

      expect(repo.isInboxQuery(TaskQuery.inbox()), isTrue);
      expect(repo.isUpcomingQuery(upcomingQuery), isTrue);
    });

    testSafe('removeDatePredicates strips date filters', () async {
      final db = createAutoClosingDb();
      final repo = TaskRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      final filter = QueryFilter<TaskPredicate>(
        shared: [
          const TaskBoolPredicate(
            field: TaskBoolField.completed,
            operator: BoolOperator.isFalse,
          ),
          TaskDatePredicate(
            field: TaskDateField.deadlineDate,
            operator: DateOperator.onOrBefore,
            date: DateTime.utc(2025, 1, 1),
          ),
        ],
      );

      final stripped = repo.removeDatePredicates(filter);
      expect(stripped.shared.length, equals(1));
      expect(stripped.shared.first, isA<TaskBoolPredicate>());
    });

    testSafe('update clears overrides when project is removed', () async {
      final db = createAutoClosingDb();
      final repo = TaskRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      await db
          .into(db.taskTable)
          .insert(
            TaskTableCompanion.insert(
              id: const drift.Value('t1'),
              name: 'Task',
              completed: const drift.Value(false),
              projectId: const drift.Value('p1'),
              overridePrimaryValueId: const drift.Value('v2'),
              overrideSecondaryValueId: const drift.Value('v3'),
            ),
          );

      await repo.update(
        id: 't1',
        name: 'Task',
        completed: false,
        projectId: '  ',
      );

      final row = await (db.select(
        db.taskTable,
      )..where((t) => t.id.equals('t1'))).getSingle();
      expect(row.projectId, isNull);
      expect(row.overridePrimaryValueId, isNull);
      expect(row.overrideSecondaryValueId, isNull);
    });

    testSafe('create and update normalize checklist items', () async {
      final db = createAutoClosingDb();
      final repo = TaskRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      await repo.create(
        name: 'Task',
        checklistTitles: List<String>.generate(25, (i) => ' item-$i '),
      );
      final taskId = (await db.select(db.taskTable).getSingle()).id;

      var items =
          await (db.select(db.taskChecklistItemsTable)
                ..where((t) => t.taskId.equals(taskId))
                ..orderBy([(t) => drift.OrderingTerm(expression: t.sortIndex)]))
              .get();
      expect(items.length, 20);
      expect(items.first.title, 'item-0');
      expect(items.last.title, 'item-19');

      await repo.update(
        id: taskId,
        name: 'Task',
        completed: false,
        checklistTitles: const [' ', 'x', ' y '],
      );

      items =
          await (db.select(db.taskChecklistItemsTable)
                ..where((t) => t.taskId.equals(taskId))
                ..orderBy([(t) => drift.OrderingTerm(expression: t.sortIndex)]))
              .get();
      expect(items.map((e) => e.title).toList(), equals(['x', 'y']));
    });

    testSafe('bulk reschedule methods throw when any id is missing', () async {
      final db = createAutoClosingDb();
      final repo = TaskRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      await repo.create(name: 'Task');
      final existingId = (await db.select(db.taskTable).getSingle()).id;

      await expectLater(
        () => repo.bulkRescheduleDeadlines(
          taskIds: [existingId, 'missing'],
          deadlineDate: DateTime.utc(2026, 2, 11),
        ),
        throwsA(isA<NotFoundFailure>()),
      );
      await expectLater(
        () => repo.bulkRescheduleStarts(
          taskIds: [existingId, 'missing'],
          startDate: DateTime.utc(2026, 2, 11),
        ),
        throwsA(isA<NotFoundFailure>()),
      );
    });

    testSafe(
      'watch completion history and recurrence exceptions map rows',
      () async {
        final db = createAutoClosingDb();
        final repo = TaskRepository(
          driftDb: db,
          occurrenceExpander: _FakeOccurrenceExpander(),
          occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
          idGenerator: IdGenerator.withUserId('user-1'),
        );

        final day = DateTime.utc(2026, 1, 1);
        await db
            .into(db.taskCompletionHistoryTable)
            .insert(
              TaskCompletionHistoryTableCompanion.insert(
                id: 'c1',
                taskId: 't1',
                occurrenceDate: drift.Value(day),
                completedAt: drift.Value(day),
                originalOccurrenceDate: const drift.Value.absent(),
              ),
            );
        await db
            .into(db.taskRecurrenceExceptionsTable)
            .insert(
              TaskRecurrenceExceptionsTableCompanion.insert(
                id: 'e1',
                taskId: 't1',
                originalDate: day,
                exceptionType: ExceptionType.reschedule,
                newDate: drift.Value(day.add(const Duration(days: 1))),
                newDeadline: const drift.Value.absent(),
              ),
            );

        final completions = await repo.watchCompletionHistory().first;
        final exceptions = await repo.watchRecurrenceExceptions().first;
        expect(completions.single.entityId, 't1');
        expect(
          exceptions.single.exceptionType,
          RecurrenceExceptionType.reschedule,
        );
      },
    );

    testSafe(
      'setMyDaySnoozedUntil records events and computes snooze stats',
      () async {
        final db = createAutoClosingDb();
        final now = DateTime.utc(2026, 1, 1, 8);
        final repo = TaskRepository(
          driftDb: db,
          occurrenceExpander: _FakeOccurrenceExpander(),
          occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
          idGenerator: IdGenerator.withUserId('user-1'),
          clock: FixedClock(now),
        );

        await repo.create(name: 'Task');
        final taskId = (await db.select(db.taskTable).getSingle()).id;

        await repo.setMyDaySnoozedUntil(
          id: taskId,
          untilUtc: now.add(const Duration(hours: 25)),
        );
        await repo.setMyDaySnoozedUntil(id: taskId, untilUtc: null);

        final events = await db.select(db.taskSnoozeEventsTable).get();
        expect(events, hasLength(1));

        final stats = await repo.getSnoozeStats(
          sinceUtc: now.subtract(const Duration(hours: 1)),
          untilUtc: now.add(const Duration(days: 2)),
        );
        expect(stats[taskId]?.snoozeCount, equals(1));
        expect(stats[taskId]?.totalSnoozeDays, equals(2));
      },
    );

    testSafe('getOccurrences delegates to expander', () async {
      final db = createAutoClosingDb();
      final expander = _FakeOccurrenceExpander();
      final repo = TaskRepository(
        driftDb: db,
        occurrenceExpander: expander,
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      await db
          .into(db.taskTable)
          .insert(
            TaskTableCompanion.insert(
              id: const drift.Value('t1'),
              name: 'Task',
              completed: const drift.Value(false),
            ),
          );

      final rangeStart = DateTime.utc(2025, 1, 1);
      final rangeEnd = DateTime.utc(2025, 1, 2);

      final results = await repo.getOccurrences(
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      );

      expect(results.length, equals(1));
      expect(expander.lastTaskRangeStart, equals(rangeStart));
      expect(expander.lastTaskRangeEnd, equals(rangeEnd));
    });

    testSafe('watchOccurrences caches streams by range', () async {
      final db = createAutoClosingDb();
      final expander = _FakeOccurrenceExpander();
      final repo = TaskRepository(
        driftDb: db,
        occurrenceExpander: expander,
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      final rangeStart = DateTime.utc(2025, 1, 1);
      final rangeEnd = DateTime.utc(2025, 1, 2);

      final s1 = repo.watchOccurrences(
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      );
      final s2 = repo.watchOccurrences(
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      );

      expect(identical(s1, s2), isTrue);
    });

    testSafe('occurrence write helpers are delegated', () async {
      final db = createAutoClosingDb();
      final writeHelper = _FakeOccurrenceWriteHelper();
      final repo = TaskRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: writeHelper,
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      final day = DateTime.utc(2026, 1, 2);
      await repo.completeOccurrence(taskId: 't1', occurrenceDate: day);
      await repo.uncompleteOccurrence(taskId: 't1', occurrenceDate: day);
      await repo.skipOccurrence(taskId: 't1', originalDate: day);
      await repo.rescheduleOccurrence(
        taskId: 't1',
        originalDate: day,
        newDate: day.add(const Duration(days: 1)),
      );
      await repo.removeException(taskId: 't1', originalDate: day);
      await repo.stopSeries('t1');
      await repo.completeSeries('t1');
      await repo.convertToOneTime('t1');

      expect(
        writeHelper.calls,
        equals([
          'completeTaskOccurrence',
          'uncompleteTaskOccurrence',
          'skipTaskOccurrence',
          'rescheduleTaskOccurrence',
          'removeTaskException',
          'stopTaskSeries',
          'completeTaskSeries',
          'convertTaskToOneTime',
        ]),
      );
    });
  });
}

class _FakeOccurrenceExpander implements OccurrenceStreamExpanderContract {
  DateTime? lastTaskRangeStart;
  DateTime? lastTaskRangeEnd;
  DateTime? lastProjectRangeStart;
  DateTime? lastProjectRangeEnd;

  @override
  Stream<List<Task>> expandTaskOccurrences({
    required Stream<List<Task>> tasksStream,
    required Stream<List<CompletionHistoryData>> completionsStream,
    required Stream<List<RecurrenceExceptionData>> exceptionsStream,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    bool Function(Task p1)? postExpansionFilter,
  }) {
    lastTaskRangeStart = rangeStart;
    lastTaskRangeEnd = rangeEnd;
    return tasksStream;
  }

  @override
  List<Task> expandTaskOccurrencesSync({
    required List<Task> tasks,
    required List<CompletionHistoryData> completions,
    required List<RecurrenceExceptionData> exceptions,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    bool Function(Task p1)? postExpansionFilter,
  }) {
    lastTaskRangeStart = rangeStart;
    lastTaskRangeEnd = rangeEnd;
    return tasks;
  }

  @override
  Stream<List<Project>> expandProjectOccurrences({
    required Stream<List<Project>> projectsStream,
    required Stream<List<CompletionHistoryData>> completionsStream,
    required Stream<List<RecurrenceExceptionData>> exceptionsStream,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    bool Function(Project p1)? postExpansionFilter,
  }) {
    lastProjectRangeStart = rangeStart;
    lastProjectRangeEnd = rangeEnd;
    return projectsStream;
  }

  @override
  List<Project> expandProjectOccurrencesSync({
    required List<Project> projects,
    required List<CompletionHistoryData> completions,
    required List<RecurrenceExceptionData> exceptions,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    bool Function(Project p1)? postExpansionFilter,
  }) {
    lastProjectRangeStart = rangeStart;
    lastProjectRangeEnd = rangeEnd;
    return projects;
  }
}

class _FakeOccurrenceWriteHelper implements OccurrenceWriteHelperContract {
  final List<String> calls = [];

  void _record(String name) => calls.add(name);

  @override
  Future<void> completeTaskOccurrence({
    required String taskId,
    DateTime? occurrenceDate,
    DateTime? originalOccurrenceDate,
    String? notes,
    OperationContext? context,
  }) async {
    _record('completeTaskOccurrence');
  }

  @override
  Future<void> uncompleteTaskOccurrence({
    required String taskId,
    DateTime? occurrenceDate,
    OperationContext? context,
  }) async {
    _record('uncompleteTaskOccurrence');
  }

  @override
  Future<void> skipTaskOccurrence({
    required String taskId,
    required DateTime originalDate,
    OperationContext? context,
  }) async {
    _record('skipTaskOccurrence');
  }

  @override
  Future<void> rescheduleTaskOccurrence({
    required String taskId,
    required DateTime originalDate,
    required DateTime newDate,
    DateTime? newDeadline,
    OperationContext? context,
  }) async {
    _record('rescheduleTaskOccurrence');
  }

  @override
  Future<void> removeTaskException({
    required String taskId,
    required DateTime originalDate,
    OperationContext? context,
  }) async {
    _record('removeTaskException');
  }

  @override
  Future<void> stopTaskSeries(
    String taskId, {
    OperationContext? context,
  }) async {
    _record('stopTaskSeries');
  }

  @override
  Future<void> completeTaskSeries(
    String taskId, {
    OperationContext? context,
  }) async {
    _record('completeTaskSeries');
  }

  @override
  Future<void> convertTaskToOneTime(
    String taskId, {
    OperationContext? context,
  }) async {
    _record('convertTaskToOneTime');
  }

  @override
  Future<void> completeProjectOccurrence({
    required String projectId,
    DateTime? occurrenceDate,
    DateTime? originalOccurrenceDate,
    String? notes,
    OperationContext? context,
  }) async {
    _record('completeProjectOccurrence');
  }

  @override
  Future<void> uncompleteProjectOccurrence({
    required String projectId,
    DateTime? occurrenceDate,
    OperationContext? context,
  }) async {
    _record('uncompleteProjectOccurrence');
  }

  @override
  Future<void> skipProjectOccurrence({
    required String projectId,
    required DateTime originalDate,
    OperationContext? context,
  }) async {
    _record('skipProjectOccurrence');
  }

  @override
  Future<void> rescheduleProjectOccurrence({
    required String projectId,
    required DateTime originalDate,
    required DateTime newDate,
    DateTime? newDeadline,
    OperationContext? context,
  }) async {
    _record('rescheduleProjectOccurrence');
  }

  @override
  Future<void> removeProjectException({
    required String projectId,
    required DateTime originalDate,
    OperationContext? context,
  }) async {
    _record('removeProjectException');
  }

  @override
  Future<void> stopProjectSeries(
    String projectId, {
    OperationContext? context,
  }) async {
    _record('stopProjectSeries');
  }

  @override
  Future<void> completeProjectSeries(
    String projectId, {
    OperationContext? context,
  }) async {
    _record('completeProjectSeries');
  }

  @override
  Future<void> convertProjectToOneTime(
    String projectId, {
    OperationContext? context,
  }) async {
    _record('convertProjectToOneTime');
  }
}
