import '../../helpers/test_imports.dart';
import '../../helpers/test_db.dart';

import 'package:drift/drift.dart' show Value;
import 'package:taskly_data/id.dart';
import 'package:taskly_data/db.dart';
import 'package:taskly_bloc/data/services/occurrence_write_helper.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  late AppDatabase db;
  late IdGenerator ids;
  late OccurrenceWriteHelper helper;

  setUp(() {
    db = createTestDb();
    ids = IdGenerator.withUserId('user-1');
    helper = OccurrenceWriteHelper(driftDb: db, idGenerator: ids);
  });

  tearDown(() async {
    await closeTestDb(db);
  });

  group('OccurrenceWriteHelper (tasks)', () {
    testSafe(
      'completeTaskOccurrence inserts completion and sets completed for non-repeating task',
      () async {
        const taskId = 'task-1';
        await db
            .into(db.taskTable)
            .insert(TaskTableCompanion.insert(id: Value(taskId), name: 'T1'));

        await helper.completeTaskOccurrence(taskId: taskId, notes: 'done');

        final task = await (db.select(
          db.taskTable,
        )..where((t) => t.id.equals(taskId))).getSingle();
        expect(task.completed, isTrue);

        final completions = await db
            .select(db.taskCompletionHistoryTable)
            .get();
        expect(completions, hasLength(1));
        expect(completions.single.taskId, taskId);
        expect(completions.single.occurrenceDate, isNull);
        expect(completions.single.notes, 'done');
      },
    );

    testSafe(
      'completeTaskOccurrence updates existing completion record when called twice',
      () async {
        const taskId = 'task-2';
        await db
            .into(db.taskTable)
            .insert(TaskTableCompanion.insert(id: Value(taskId), name: 'T2'));

        await helper.completeTaskOccurrence(taskId: taskId, notes: 'first');
        await helper.completeTaskOccurrence(taskId: taskId, notes: 'second');

        final completions = await db
            .select(db.taskCompletionHistoryTable)
            .get();
        expect(completions, hasLength(1));
        expect(completions.single.notes, 'second');
      },
    );

    testSafe(
      'completeTaskOccurrence normalizes occurrenceDate and uses deterministic id',
      () async {
        const taskId = 'task-2b';
        await db
            .into(db.taskTable)
            .insert(TaskTableCompanion.insert(id: Value(taskId), name: 'T2b'));

        final occurrence1 = DateTime.utc(2026, 1, 3, 23, 59);
        final occurrence2 = DateTime.utc(2026, 1, 3, 0, 1);

        await helper.completeTaskOccurrence(
          taskId: taskId,
          occurrenceDate: occurrence1,
          notes: 'first',
        );
        await helper.completeTaskOccurrence(
          taskId: taskId,
          occurrenceDate: occurrence2,
          notes: 'second',
        );

        final rows = await db.select(db.taskCompletionHistoryTable).get();
        expect(rows, hasLength(1));

        final expectedDate = DateTime.utc(2026, 1, 3);
        expect(rows.single.occurrenceDate, expectedDate);
        expect(
          rows.single.id,
          ids.taskCompletionId(taskId: taskId, occurrenceDate: expectedDate),
        );
        expect(rows.single.notes, 'second');
      },
    );

    testSafe(
      'completeTaskOccurrence does not set completed for repeating tasks',
      () async {
        const taskId = 'task-3';
        await db
            .into(db.taskTable)
            .insert(
              TaskTableCompanion.insert(
                id: Value(taskId),
                name: 'Repeating',
                repeatIcalRrule: const Value('FREQ=DAILY'),
              ),
            );

        await helper.completeTaskOccurrence(taskId: taskId, notes: 'occ');

        final task = await (db.select(
          db.taskTable,
        )..where((t) => t.id.equals(taskId))).getSingle();
        expect(task.completed, isFalse);

        final completions = await db
            .select(db.taskCompletionHistoryTable)
            .get();
        expect(completions, hasLength(1));
      },
    );

    testSafe(
      'uncompleteTaskOccurrence deletes completion and clears completed for non-repeating tasks',
      () async {
        const taskId = 'task-4';
        await db
            .into(db.taskTable)
            .insert(TaskTableCompanion.insert(id: Value(taskId), name: 'T4'));

        await helper.completeTaskOccurrence(taskId: taskId);
        await helper.uncompleteTaskOccurrence(taskId: taskId);

        final completions = await db
            .select(db.taskCompletionHistoryTable)
            .get();
        expect(completions, isEmpty);

        final task = await (db.select(
          db.taskTable,
        )..where((t) => t.id.equals(taskId))).getSingle();
        expect(task.completed, isFalse);
      },
    );

    testSafe(
      'uncompleteTaskOccurrence deletes only the targeted occurrenceDate',
      () async {
        const taskId = 'task-4b';
        await db
            .into(db.taskTable)
            .insert(
              TaskTableCompanion.insert(
                id: Value(taskId),
                name: 'T4b',
                repeatIcalRrule: const Value('FREQ=DAILY'),
              ),
            );

        final day1 = DateTime.utc(2026, 1, 1);
        final day2 = DateTime.utc(2026, 1, 2);

        await helper.completeTaskOccurrence(
          taskId: taskId,
          occurrenceDate: day1,
          notes: 'd1',
        );
        await helper.completeTaskOccurrence(
          taskId: taskId,
          occurrenceDate: day2,
          notes: 'd2',
        );

        await helper.uncompleteTaskOccurrence(
          taskId: taskId,
          occurrenceDate: day1,
        );

        final remaining = await db.select(db.taskCompletionHistoryTable).get();
        expect(remaining, hasLength(1));
        expect(remaining.single.occurrenceDate, day2);
      },
    );

    testSafe(
      'skip/reschedule/removeTaskException write expected rows',
      () async {
        const taskId = 'task-5';
        await db
            .into(db.taskTable)
            .insert(TaskTableCompanion.insert(id: Value(taskId), name: 'T5'));

        final original = DateTime.utc(2026, 1, 1);
        final newDate = DateTime.utc(2026, 1, 2);
        final newDeadline = DateTime.utc(2026, 1, 3);

        await helper.skipTaskOccurrence(taskId: taskId, originalDate: original);
        await helper.rescheduleTaskOccurrence(
          taskId: taskId,
          originalDate: DateTime.utc(2026, 1, 10),
          newDate: newDate,
          newDeadline: newDeadline,
        );

        final rows = await db.select(db.taskRecurrenceExceptionsTable).get();
        expect(rows, hasLength(2));

        final skip = rows.singleWhere(
          (r) => r.exceptionType == ExceptionType.skip,
        );
        expect(skip.taskId, taskId);
        expect(skip.newDate, isNull);
        expect(
          skip.id,
          ids.taskRecurrenceExceptionId(
            taskId: taskId,
            originalDate: DateTime.utc(2026, 1, 1),
          ),
        );

        await helper.removeTaskException(
          taskId: taskId,
          originalDate: original,
        );

        final afterRemove = await db
            .select(db.taskRecurrenceExceptionsTable)
            .get();
        expect(afterRemove, hasLength(1));
        expect(afterRemove.single.exceptionType, ExceptionType.reschedule);
      },
    );

    testSafe('stopTaskSeries sets seriesEnded', () async {
      const taskId = 'task-6';
      await db
          .into(db.taskTable)
          .insert(TaskTableCompanion.insert(id: Value(taskId), name: 'T6'));

      await helper.stopTaskSeries(taskId);

      final task = await (db.select(
        db.taskTable,
      )..where((t) => t.id.equals(taskId))).getSingle();
      expect(task.seriesEnded, isTrue);
    });

    testSafe(
      'completeTaskSeries deletes future exceptions but keeps past ones',
      () async {
        const taskId = 'task-7';
        await db
            .into(db.taskTable)
            .insert(TaskTableCompanion.insert(id: Value(taskId), name: 'T7'));

        final today = DateTime.now();
        final past = DateTime(today.year, today.month, today.day).subtract(
          const Duration(days: 2),
        );
        final future = DateTime(today.year, today.month, today.day).add(
          const Duration(days: 2),
        );

        await helper.skipTaskOccurrence(taskId: taskId, originalDate: past);
        await helper.skipTaskOccurrence(taskId: taskId, originalDate: future);

        await helper.completeTaskSeries(taskId);

        final exceptions = await db
            .select(db.taskRecurrenceExceptionsTable)
            .get();
        expect(exceptions, hasLength(1));
        expect(exceptions.single.originalDate, past);

        final task = await (db.select(
          db.taskTable,
        )..where((t) => t.id.equals(taskId))).getSingle();
        expect(task.seriesEnded, isTrue);
      },
    );

    testSafe(
      'convertTaskToOneTime completes series and clears recurrence fields',
      () async {
        const taskId = 'task-8';
        await db
            .into(db.taskTable)
            .insert(
              TaskTableCompanion.insert(
                id: Value(taskId),
                name: 'T8',
                repeatIcalRrule: const Value('FREQ=DAILY'),
                repeatFromCompletion: const Value(true),
              ),
            );

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final past = today.subtract(const Duration(days: 2));
        final future = today.add(const Duration(days: 2));

        await helper.skipTaskOccurrence(taskId: taskId, originalDate: past);
        await helper.skipTaskOccurrence(taskId: taskId, originalDate: future);

        await helper.convertTaskToOneTime(taskId);

        final task = await (db.select(
          db.taskTable,
        )..where((t) => t.id.equals(taskId))).getSingle();
        expect(task.seriesEnded, isTrue);
        expect(task.repeatIcalRrule, isNull);
        expect(task.repeatFromCompletion, isFalse);

        final exceptions = await db
            .select(db.taskRecurrenceExceptionsTable)
            .get();
        expect(exceptions, hasLength(1));
        expect(exceptions.single.originalDate, past);
      },
    );
  });

  group('OccurrenceWriteHelper (projects)', () {
    testSafe(
      'completeProjectOccurrence inserts completion and sets completed for non-repeating project',
      () async {
        const projectId = 'project-1';
        await db
            .into(db.projectTable)
            .insert(
              ProjectTableCompanion(
                id: Value(projectId),
                name: const Value('P1'),
                completed: const Value(false),
              ),
            );

        await helper.completeProjectOccurrence(
          projectId: projectId,
          notes: 'done',
        );

        final project = await (db.select(
          db.projectTable,
        )..where((p) => p.id.equals(projectId))).getSingle();
        expect(project.completed, isTrue);

        final completions = await db
            .select(db.projectCompletionHistoryTable)
            .get();
        expect(completions, hasLength(1));
        expect(completions.single.projectId, projectId);
        expect(completions.single.occurrenceDate, isNull);
        expect(completions.single.notes, 'done');
      },
    );

    testSafe(
      'uncompleteProjectOccurrence deletes completion and clears completed for non-repeating project',
      () async {
        const projectId = 'project-2';
        await db
            .into(db.projectTable)
            .insert(
              ProjectTableCompanion(
                id: Value(projectId),
                name: const Value('P2'),
                completed: const Value(false),
              ),
            );

        await helper.completeProjectOccurrence(projectId: projectId);
        await helper.uncompleteProjectOccurrence(projectId: projectId);

        final completions = await db
            .select(db.projectCompletionHistoryTable)
            .get();
        expect(completions, isEmpty);

        final project = await (db.select(
          db.projectTable,
        )..where((p) => p.id.equals(projectId))).getSingle();
        expect(project.completed, isFalse);
      },
    );

    testSafe(
      'convertProjectToOneTime completes series and clears recurrence fields',
      () async {
        const projectId = 'project-3';
        await db
            .into(db.projectTable)
            .insert(
              ProjectTableCompanion(
                id: Value(projectId),
                name: const Value('P3'),
                completed: const Value(false),
                repeatIcalRrule: const Value('FREQ=DAILY'),
                repeatFromCompletion: const Value(true),
              ),
            );

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final past = today.subtract(const Duration(days: 2));
        final future = today.add(const Duration(days: 2));

        await helper.skipProjectOccurrence(
          projectId: projectId,
          originalDate: past,
        );
        await helper.skipProjectOccurrence(
          projectId: projectId,
          originalDate: future,
        );

        await helper.convertProjectToOneTime(projectId);

        final project = await (db.select(
          db.projectTable,
        )..where((p) => p.id.equals(projectId))).getSingle();
        expect(project.seriesEnded, isTrue);
        expect(project.repeatIcalRrule, isNull);
        expect(project.repeatFromCompletion, isFalse);

        final exceptions = await db
            .select(db.projectRecurrenceExceptionsTable)
            .get();
        expect(exceptions, hasLength(1));
        expect(exceptions.single.originalDate, past);
      },
    );
  });
}
