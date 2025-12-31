import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/services/occurrence_write_helper.dart';

import '../../helpers/test_db.dart';

void main() {
  group('OccurrenceWriteHelper', () {
    late AppDatabase db;
    late OccurrenceWriteHelper helper;

    setUp(() async {
      db = await createTestDatabase();
      helper = OccurrenceWriteHelper(driftDb: db);

      final now = DateTime.now();

      await db
          .into(db.projectTable)
          .insert(
            ProjectTableCompanion.insert(
              id: const Value('proj-1'),
              name: 'Test Project',
              completed: false,
              createdAt: Value(now),
              updatedAt: Value(now),
              seriesEnded: const Value(false),
              repeatFromCompletion: const Value(false),
            ),
          );

      await db
          .into(db.taskTable)
          .insert(
            TaskTableCompanion.insert(
              id: const Value('task-1'),
              name: 'Test Task',
              projectId: const Value('proj-1'),
            ),
          );
    });

    tearDown(() async {
      await db.close();
    });

    group('completeTaskOccurrence', () {
      test('creates completion record for non-repeating task', () async {
        await helper.completeTaskOccurrence(
          taskId: 'task-1',
          notes: 'Test completion',
        );

        final completions = await db
            .select(db.taskCompletionHistoryTable)
            .get();

        expect(completions, hasLength(1));
        expect(completions.first.taskId, 'task-1');
        expect(completions.first.occurrenceDate, isNull);
        expect(completions.first.notes, 'Test completion');
      });

      test('creates completion record for repeating task', () async {
        final occDate = DateTime(2025, 1, 15);

        await helper.completeTaskOccurrence(
          taskId: 'task-1',
          occurrenceDate: occDate,
          originalOccurrenceDate: occDate,
        );

        final completions = await db
            .select(db.taskCompletionHistoryTable)
            .get();

        expect(completions, hasLength(1));
        expect(completions.first.taskId, 'task-1');
        expect(completions.first.occurrenceDate, DateTime.utc(2025, 1, 15));
      });

      test('sets completedAt to current time', () async {
        final before = DateTime.now();
        await Future<void>.delayed(const Duration(milliseconds: 10));

        await helper.completeTaskOccurrence(
          taskId: 'task-1',
        );

        await Future<void>.delayed(const Duration(milliseconds: 10));
        final after = DateTime.now();

        final completions = await db
            .select(db.taskCompletionHistoryTable)
            .get();

        expect(completions.first.completedAt.isAfter(before), isTrue);
        expect(completions.first.completedAt.isBefore(after), isTrue);
      });

      test(
        'handles rescheduled occurrence with different original date',
        () async {
          await helper.completeTaskOccurrence(
            taskId: 'task-1',
            occurrenceDate: DateTime(2025, 1, 20),
            originalOccurrenceDate: DateTime(2025, 1, 15),
          );

          final completions = await db
              .select(db.taskCompletionHistoryTable)
              .get();

          expect(completions.first.occurrenceDate, DateTime.utc(2025, 1, 20));
          expect(
            completions.first.originalOccurrenceDate,
            DateTime.utc(2025, 1, 15),
          );
        },
      );

      test(
        'can complete same task multiple times with different dates',
        () async {
          await helper.completeTaskOccurrence(
            taskId: 'task-1',
            occurrenceDate: DateTime(2025),
            originalOccurrenceDate: DateTime(2025),
          );

          await helper.completeTaskOccurrence(
            taskId: 'task-1',
            occurrenceDate: DateTime(2025, 1, 2),
            originalOccurrenceDate: DateTime(2025, 1, 2),
          );

          final completions = await db
              .select(db.taskCompletionHistoryTable)
              .get();

          expect(completions, hasLength(2));
        },
      );
    });

    group('uncompleteTaskOccurrence', () {
      test('removes completion for non-repeating task', () async {
        await helper.completeTaskOccurrence(
          taskId: 'task-1',
        );

        await helper.uncompleteTaskOccurrence(
          taskId: 'task-1',
        );

        final completions = await db
            .select(db.taskCompletionHistoryTable)
            .get();

        expect(completions, isEmpty);
      });

      test('removes completion for specific occurrence', () async {
        await helper.completeTaskOccurrence(
          taskId: 'task-1',
          occurrenceDate: DateTime(2025, 1, 15),
          originalOccurrenceDate: DateTime(2025, 1, 15),
        );

        await helper.uncompleteTaskOccurrence(
          taskId: 'task-1',
          occurrenceDate: DateTime(2025, 1, 15),
        );

        final completions = await db
            .select(db.taskCompletionHistoryTable)
            .get();

        expect(completions, isEmpty);
      });

      test('only removes matching occurrence', () async {
        await helper.completeTaskOccurrence(
          taskId: 'task-1',
          occurrenceDate: DateTime(2025, 1, 15),
          originalOccurrenceDate: DateTime(2025, 1, 15),
        );

        await helper.completeTaskOccurrence(
          taskId: 'task-1',
          occurrenceDate: DateTime(2025, 1, 16),
          originalOccurrenceDate: DateTime(2025, 1, 16),
        );

        await helper.uncompleteTaskOccurrence(
          taskId: 'task-1',
          occurrenceDate: DateTime(2025, 1, 15),
        );

        final completions = await db
            .select(db.taskCompletionHistoryTable)
            .get();

        expect(completions, hasLength(1));
        expect(completions.first.occurrenceDate, DateTime.utc(2025, 1, 16));
      });

      test('does not throw when completion does not exist', () async {
        await expectLater(
          helper.uncompleteTaskOccurrence(
            taskId: 'task-999',
          ),
          completes,
        );
      });

      test('normalizes occurrence date', () async {
        await helper.completeTaskOccurrence(
          taskId: 'task-1',
          occurrenceDate: DateTime(2025, 1, 15, 14, 30, 45),
          originalOccurrenceDate: DateTime(2025, 1, 15),
        );

        await helper.uncompleteTaskOccurrence(
          taskId: 'task-1',
          occurrenceDate: DateTime(2025, 1, 15, 10),
        );

        final completions = await db
            .select(db.taskCompletionHistoryTable)
            .get();

        expect(completions, isEmpty);
      });
    });

    group('skipTaskOccurrence', () {
      test('creates skip exception record', () async {
        await helper.skipTaskOccurrence(
          taskId: 'task-1',
          originalDate: DateTime(2025, 1, 15),
        );

        final exceptions = await db
            .select(db.taskRecurrenceExceptionsTable)
            .get();

        expect(exceptions, hasLength(1));
        expect(exceptions.first.taskId, 'task-1');
        expect(exceptions.first.exceptionType, ExceptionType.skip);
        expect(exceptions.first.originalDate, DateTime.utc(2025, 1, 15));
      });

      test('normalizes original date', () async {
        await helper.skipTaskOccurrence(
          taskId: 'task-1',
          originalDate: DateTime(2025, 1, 15, 14, 30, 45),
        );

        final exceptions = await db
            .select(db.taskRecurrenceExceptionsTable)
            .get();

        expect(exceptions.first.originalDate, DateTime.utc(2025, 1, 15));
      });

      test('sets createdAt and updatedAt', () async {
        await helper.skipTaskOccurrence(
          taskId: 'task-1',
          originalDate: DateTime(2025, 1, 15),
        );

        final exceptions = await db
            .select(db.taskRecurrenceExceptionsTable)
            .get();

        expect(exceptions.first.createdAt, isNotNull);
        expect(exceptions.first.updatedAt, isNotNull);
      });
    });

    group('rescheduleTaskOccurrence', () {
      test('creates reschedule exception record', () async {
        await helper.rescheduleTaskOccurrence(
          taskId: 'task-1',
          originalDate: DateTime(2025, 1, 15),
          newDate: DateTime(2025, 1, 20),
        );

        final exceptions = await db
            .select(db.taskRecurrenceExceptionsTable)
            .get();

        expect(exceptions, hasLength(1));
        expect(exceptions.first.exceptionType, ExceptionType.reschedule);
        expect(exceptions.first.originalDate, DateTime.utc(2025, 1, 15));
        expect(exceptions.first.newDate, DateTime.utc(2025, 1, 20));
      });

      test('includes new deadline when provided', () async {
        await helper.rescheduleTaskOccurrence(
          taskId: 'task-1',
          originalDate: DateTime(2025, 1, 15),
          newDate: DateTime(2025, 1, 20),
          newDeadline: DateTime(2025, 1, 25),
        );

        final exceptions = await db
            .select(db.taskRecurrenceExceptionsTable)
            .get();

        expect(exceptions.first.newDeadline, DateTime.utc(2025, 1, 25));
      });

      test('normalizes dates', () async {
        await helper.rescheduleTaskOccurrence(
          taskId: 'task-1',
          originalDate: DateTime(2025, 1, 15, 10),
          newDate: DateTime(2025, 1, 20, 14, 30),
        );

        final exceptions = await db
            .select(db.taskRecurrenceExceptionsTable)
            .get();

        expect(exceptions.first.originalDate, DateTime.utc(2025, 1, 15));
        expect(exceptions.first.newDate, DateTime.utc(2025, 1, 20));
      });
    });

    group('completeProjectOccurrence', () {
      test('creates completion record for project', () async {
        await helper.completeProjectOccurrence(
          projectId: 'proj-1',
          occurrenceDate: DateTime(2025, 1, 15),
        );

        final completions = await db
            .select(db.projectCompletionHistoryTable)
            .get();

        expect(completions, hasLength(1));
        expect(completions.first.projectId, 'proj-1');
      });

      test('includes notes when provided', () async {
        await helper.completeProjectOccurrence(
          projectId: 'proj-1',
          occurrenceDate: DateTime(2025, 1, 15),
          notes: 'Project completed!',
        );

        final completions = await db
            .select(db.projectCompletionHistoryTable)
            .get();

        expect(completions.first.notes, 'Project completed!');
      });
    });

    group('uncompleteProjectOccurrence', () {
      test('removes project completion', () async {
        await helper.completeProjectOccurrence(
          projectId: 'proj-1',
          occurrenceDate: DateTime(2025, 1, 15),
        );

        await helper.uncompleteProjectOccurrence(
          projectId: 'proj-1',
          occurrenceDate: DateTime(2025, 1, 15),
        );

        final completions = await db
            .select(db.projectCompletionHistoryTable)
            .get();

        expect(completions, isEmpty);
      });
    });

    group('skipProjectOccurrence', () {
      test('creates skip exception for project', () async {
        await helper.skipProjectOccurrence(
          projectId: 'proj-1',
          originalDate: DateTime(2025, 1, 15),
        );

        final exceptions = await db
            .select(db.projectRecurrenceExceptionsTable)
            .get();

        expect(exceptions, hasLength(1));
        expect(exceptions.first.projectId, 'proj-1');
        expect(exceptions.first.exceptionType, ExceptionType.skip);
      });
    });

    group('rescheduleProjectOccurrence', () {
      test('creates reschedule exception for project', () async {
        await helper.rescheduleProjectOccurrence(
          projectId: 'proj-1',
          originalDate: DateTime(2025, 1, 15),
          newDate: DateTime(2025, 1, 20),
        );

        final exceptions = await db
            .select(db.projectRecurrenceExceptionsTable)
            .get();

        expect(exceptions, hasLength(1));
        expect(exceptions.first.exceptionType, ExceptionType.reschedule);
      });
    });

    group('edge cases', () {
      test(
        'handles concurrent completions for different occurrences',
        () async {
          await Future.wait([
            helper.completeTaskOccurrence(
              taskId: 'task-1',
              occurrenceDate: DateTime(2025),
              originalOccurrenceDate: DateTime(2025),
            ),
            helper.completeTaskOccurrence(
              taskId: 'task-1',
              occurrenceDate: DateTime(2025, 1, 2),
              originalOccurrenceDate: DateTime(2025, 1, 2),
            ),
            helper.completeTaskOccurrence(
              taskId: 'task-1',
              occurrenceDate: DateTime(2025, 1, 3),
              originalOccurrenceDate: DateTime(2025, 1, 3),
            ),
          ]);

          final completions = await db
              .select(db.taskCompletionHistoryTable)
              .get();

          expect(completions, hasLength(3));
        },
      );

      test('handles very long note strings', () async {
        final longNote = 'A' * 10000;

        await helper.completeTaskOccurrence(
          taskId: 'task-1',
          notes: longNote,
        );

        final completions = await db
            .select(db.taskCompletionHistoryTable)
            .get();

        expect(completions.first.notes, longNote);
      });

      test('handles dates far in the future', () async {
        await helper.completeTaskOccurrence(
          taskId: 'task-1',
          occurrenceDate: DateTime(2099, 12, 31),
          originalOccurrenceDate: DateTime(2099, 12, 31),
        );

        final completions = await db
            .select(db.taskCompletionHistoryTable)
            .get();

        expect(completions.first.occurrenceDate, DateTime.utc(2099, 12, 31));
      });

      test('handles dates far in the past', () async {
        await helper.completeTaskOccurrence(
          taskId: 'task-1',
          occurrenceDate: DateTime(2000),
          originalOccurrenceDate: DateTime(2000),
        );

        final completions = await db
            .select(db.taskCompletionHistoryTable)
            .get();

        expect(completions.first.occurrenceDate, DateTime.utc(2000));
      });

      test('generates unique IDs for each operation', () async {
        await helper.completeTaskOccurrence(
          taskId: 'task-1',
          occurrenceDate: DateTime(2025),
          originalOccurrenceDate: DateTime(2025),
        );

        await helper.completeTaskOccurrence(
          taskId: 'task-1',
          occurrenceDate: DateTime(2025, 1, 2),
          originalOccurrenceDate: DateTime(2025, 1, 2),
        );

        final completions = await db
            .select(db.taskCompletionHistoryTable)
            .get();

        expect(completions[0].id, isNot(equals(completions[1].id)));
      });
    });
  });
}
