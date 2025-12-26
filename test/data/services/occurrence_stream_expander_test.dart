import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/services/occurrence_stream_expander.dart';
import 'package:taskly_bloc/domain/contracts/occurrence_stream_expander_contract.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/models/task.dart';

void main() {
  group('OccurrenceStreamExpander', () {
    late OccurrenceStreamExpander expander;

    setUp(() {
      expander = const OccurrenceStreamExpander();
    });

    group('expandTaskOccurrencesSync - non-repeating', () {
      test('expands single non-repeating task in range', () {
        final task = Task(
          id: 'task-1',
          name: 'Test Task',
          completed: false,
          startDate: DateTime(2025, 1, 15),
          deadlineDate: DateTime(2025, 1, 20),
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        );

        final result = expander.expandTaskOccurrencesSync(
          tasks: [task],
          completions: [],
          exceptions: [],
          rangeStart: DateTime(2025),
          rangeEnd: DateTime(2025, 1, 31),
        );

        expect(result, hasLength(1));
        expect(result.first.id, 'task-1');
        expect(result.first.occurrence, isNotNull);
        expect(result.first.occurrence!.date, DateTime(2025, 1, 15));
      });

      test('excludes non-repeating task before range', () {
        final task = Task(
          id: 'task-1',
          name: 'Test Task',
          completed: false,
          startDate: DateTime(2024, 12, 15),
          createdAt: DateTime(2024, 12),
          updatedAt: DateTime(2024, 12),
        );

        final result = expander.expandTaskOccurrencesSync(
          tasks: [task],
          completions: [],
          exceptions: [],
          rangeStart: DateTime(2025),
          rangeEnd: DateTime(2025, 1, 31),
        );

        expect(result, isEmpty);
      });

      test('excludes non-repeating task after range', () {
        final task = Task(
          id: 'task-1',
          name: 'Test Task',
          completed: false,
          startDate: DateTime(2025, 2, 15),
          createdAt: DateTime(2025, 2),
          updatedAt: DateTime(2025, 2),
        );

        final result = expander.expandTaskOccurrencesSync(
          tasks: [task],
          completions: [],
          exceptions: [],
          rangeStart: DateTime(2025),
          rangeEnd: DateTime(2025, 1, 31),
        );

        expect(result, isEmpty);
      });

      test('includes completion data for non-repeating task', () {
        final task = Task(
          id: 'task-1',
          name: 'Test Task',
          completed: false,
          startDate: DateTime(2025, 1, 15),
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        );

        final completion = CompletionHistoryData(
          id: 'comp-1',
          entityId: 'task-1',
          completedAt: DateTime(2025, 1, 15, 10),
          notes: 'Done!',
        );

        final result = expander.expandTaskOccurrencesSync(
          tasks: [task],
          completions: [completion],
          exceptions: [],
          rangeStart: DateTime(2025),
          rangeEnd: DateTime(2025, 1, 31),
        );

        expect(result, hasLength(1));
        expect(result.first.occurrence!.completionId, 'comp-1');
        expect(result.first.occurrence!.completedAt, isNotNull);
        expect(result.first.occurrence!.completionNotes, 'Done!');
      });

      test('handles task without startDate (uses createdAt)', () {
        final task = Task(
          id: 'task-1',
          name: 'Test Task',
          completed: false,
          createdAt: DateTime(2025, 1, 15),
          updatedAt: DateTime(2025, 1, 15),
        );

        final result = expander.expandTaskOccurrencesSync(
          tasks: [task],
          completions: [],
          exceptions: [],
          rangeStart: DateTime(2025),
          rangeEnd: DateTime(2025, 1, 31),
        );

        expect(result, hasLength(1));
        expect(result.first.occurrence!.date, DateTime(2025, 1, 15));
      });
    });

    group('expandTaskOccurrencesSync - repeating', () {
      test('expands daily repeating task', () {
        final task = Task(
          id: 'task-1',
          name: 'Daily Task',
          completed: false,
          startDate: DateTime(2025),
          repeatIcalRrule: 'FREQ=DAILY',
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        );

        final result = expander.expandTaskOccurrencesSync(
          tasks: [task],
          completions: [],
          exceptions: [],
          rangeStart: DateTime(2025),
          rangeEnd: DateTime(2025, 1, 7),
        );

        expect(result, hasLength(7));
        expect(result[0].occurrence!.date, DateTime(2025));
        expect(result[6].occurrence!.date, DateTime(2025, 1, 7));
      });

      test('expands weekly repeating task', () {
        final task = Task(
          id: 'task-1',
          name: 'Weekly Task',
          completed: false,
          startDate: DateTime(2025),
          repeatIcalRrule: 'FREQ=WEEKLY',
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        );

        final result = expander.expandTaskOccurrencesSync(
          tasks: [task],
          completions: [],
          exceptions: [],
          rangeStart: DateTime(2025),
          rangeEnd: DateTime(2025, 1, 31),
        );

        expect(result, hasLength(5)); // 1, 8, 15, 22, 29
      });

      test('handles invalid RRULE as non-repeating', () {
        final task = Task(
          id: 'task-1',
          name: 'Invalid RRULE Task',
          completed: false,
          startDate: DateTime(2025, 1, 15),
          repeatIcalRrule: 'INVALID_RRULE',
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        );

        final result = expander.expandTaskOccurrencesSync(
          tasks: [task],
          completions: [],
          exceptions: [],
          rangeStart: DateTime(2025),
          rangeEnd: DateTime(2025, 1, 31),
        );

        expect(result, hasLength(1));
      });

      test('applies deadline offset to repeating occurrences', () {
        final task = Task(
          id: 'task-1',
          name: 'Task with Deadline',
          completed: false,
          startDate: DateTime(2025),
          deadlineDate: DateTime(2025, 1, 3), // 2 days after start
          repeatIcalRrule: 'FREQ=WEEKLY',
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        );

        final result = expander.expandTaskOccurrencesSync(
          tasks: [task],
          completions: [],
          exceptions: [],
          rangeStart: DateTime(2025),
          rangeEnd: DateTime(2025, 1, 31),
        );

        // Each occurrence should have deadline 2 days after start
        for (final occurrence in result) {
          final daysDiff = occurrence.occurrence!.deadline!
              .difference(occurrence.occurrence!.date)
              .inDays;
          expect(daysDiff, 2);
        }
      });

      test('respects seriesEnded flag', () {
        final task = Task(
          id: 'task-1',
          name: 'Ended Series',
          completed: false,
          startDate: DateTime(2025),
          repeatIcalRrule: 'FREQ=DAILY',
          seriesEnded: true,
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        );

        final result = expander.expandTaskOccurrencesSync(
          tasks: [task],
          completions: [],
          exceptions: [],
          rangeStart: DateTime(2025),
          rangeEnd: DateTime(2030, 12, 31),
        );

        // Should only return occurrences before now
        final now = DateTime.now();
        for (final occurrence in result) {
          expect(occurrence.occurrence!.date.isBefore(now), isTrue);
        }
      });

      test('skips occurrences with skip exceptions', () {
        final task = Task(
          id: 'task-1',
          name: 'Task with Skip',
          completed: false,
          startDate: DateTime(2025),
          repeatIcalRrule: 'FREQ=DAILY',
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        );

        final exception = RecurrenceExceptionData(
          id: 'exc-1',
          entityId: 'task-1',
          originalDate: DateTime(2025, 1, 3),
          exceptionType: RecurrenceExceptionType.skip,
        );

        final result = expander.expandTaskOccurrencesSync(
          tasks: [task],
          completions: [],
          exceptions: [exception],
          rangeStart: DateTime(2025),
          rangeEnd: DateTime(2025, 1, 5),
        );

        // Should have 4 occurrences (1, 2, 4, 5 - skipping 3)
        expect(result, hasLength(4));
        final dates = result.map((t) => t.occurrence!.date.day).toList();
        expect(dates, [1, 2, 4, 5]);
      });

      test('reschedules occurrences with reschedule exceptions', () {
        final task = Task(
          id: 'task-1',
          name: 'Task with Reschedule',
          completed: false,
          startDate: DateTime(2025),
          repeatIcalRrule: 'FREQ=DAILY',
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        );

        final exception = RecurrenceExceptionData(
          id: 'exc-1',
          entityId: 'task-1',
          originalDate: DateTime(2025, 1, 3),
          exceptionType: RecurrenceExceptionType.reschedule,
          newDate: DateTime(2025, 1, 10),
        );

        final result = expander.expandTaskOccurrencesSync(
          tasks: [task],
          completions: [],
          exceptions: [exception],
          rangeStart: DateTime(2025),
          rangeEnd: DateTime(2025, 1, 15),
        );

        // Find the rescheduled occurrence
        final rescheduled = result.firstWhere(
          (t) => t.occurrence!.originalDate == DateTime(2025, 1, 3),
        );

        expect(rescheduled.occurrence!.date, DateTime(2025, 1, 10));
        expect(rescheduled.occurrence!.isRescheduled, isTrue);
      });

      test('includes completion data for repeating occurrences', () {
        final task = Task(
          id: 'task-1',
          name: 'Repeating with Completion',
          completed: false,
          startDate: DateTime(2025),
          repeatIcalRrule: 'FREQ=DAILY',
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        );

        final completion = CompletionHistoryData(
          id: 'comp-1',
          entityId: 'task-1',
          occurrenceDate: DateTime(2025, 1, 3),
          originalOccurrenceDate: DateTime(2025, 1, 3),
          completedAt: DateTime(2025, 1, 3, 10),
        );

        final result = expander.expandTaskOccurrencesSync(
          tasks: [task],
          completions: [completion],
          exceptions: [],
          rangeStart: DateTime(2025),
          rangeEnd: DateTime(2025, 1, 5),
        );

        final completedOccurrence = result.firstWhere(
          (t) => t.occurrence!.date == DateTime(2025, 1, 3),
        );

        expect(completedOccurrence.occurrence!.completionId, 'comp-1');
        expect(completedOccurrence.occurrence!.completedAt, isNotNull);
      });

      test('handles repeatFromCompletion flag', () {
        final task = Task(
          id: 'task-1',
          name: 'Rolling Task',
          completed: false,
          startDate: DateTime(2025),
          repeatIcalRrule: 'FREQ=DAILY',
          repeatFromCompletion: true,
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        );

        final completion = CompletionHistoryData(
          id: 'comp-1',
          entityId: 'task-1',
          occurrenceDate: DateTime(2025),
          originalOccurrenceDate: DateTime(2025),
          completedAt: DateTime(2025, 1, 5), // Completed on 5th
        );

        final result = expander.expandTaskOccurrencesSync(
          tasks: [task],
          completions: [completion],
          exceptions: [],
          rangeStart: DateTime(2025),
          rangeEnd: DateTime(2025, 1, 31),
        );

        // Should anchor from completion date (Jan 5)
        expect(result.isNotEmpty, isTrue);
        expect(
          result.any((t) => t.occurrence!.date == DateTime(2025, 1, 5)),
          isTrue,
        );
      });
    });

    group('expandProjectOccurrencesSync', () {
      test('expands non-repeating project in range', () {
        final project = Project(
          id: 'proj-1',
          name: 'Test Project',
          completed: false,
          startDate: DateTime(2025, 1, 15),
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        );

        final result = expander.expandProjectOccurrencesSync(
          projects: [project],
          completions: [],
          exceptions: [],
          rangeStart: DateTime(2025),
          rangeEnd: DateTime(2025, 1, 31),
        );

        expect(result, hasLength(1));
        expect(result.first.occurrence, isNotNull);
      });

      test('expands repeating project', () {
        final project = Project(
          id: 'proj-1',
          name: 'Repeating Project',
          completed: false,
          startDate: DateTime(2025),
          repeatIcalRrule: 'FREQ=WEEKLY',
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        );

        final result = expander.expandProjectOccurrencesSync(
          projects: [project],
          completions: [],
          exceptions: [],
          rangeStart: DateTime(2025),
          rangeEnd: DateTime(2025, 1, 31),
        );

        expect(result.length, greaterThan(1));
      });

      test('sorts projects by occurrence date', () {
        final project1 = Project(
          id: 'proj-1',
          name: 'Later Project',
          completed: false,
          startDate: DateTime(2025, 1, 20),
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        );

        final project2 = Project(
          id: 'proj-2',
          name: 'Earlier Project',
          completed: false,
          startDate: DateTime(2025, 1, 10),
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        );

        final result = expander.expandProjectOccurrencesSync(
          projects: [project1, project2],
          completions: [],
          exceptions: [],
          rangeStart: DateTime(2025),
          rangeEnd: DateTime(2025, 1, 31),
        );

        expect(result, hasLength(2));
        expect(result[0].id, 'proj-2');
        expect(result[1].id, 'proj-1');
      });
    });

    group('postExpansionFilter', () {
      test('applies filter to expanded tasks', () {
        final task1 = Task(
          id: 'task-1',
          name: 'Task A',
          completed: false,
          startDate: DateTime(2025),
          repeatIcalRrule: 'FREQ=DAILY',
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        );

        final result = expander.expandTaskOccurrencesSync(
          tasks: [task1],
          completions: [],
          exceptions: [],
          rangeStart: DateTime(2025),
          rangeEnd: DateTime(2025, 1, 10),
          postExpansionFilter: (task) =>
              task.occurrence!.date.day.isEven, // Only even days
        );

        expect(result.length, 5); // Days 2, 4, 6, 8, 10
        for (final task in result) {
          expect(task.occurrence!.date.day.isEven, isTrue);
        }
      });

      test('returns all tasks when filter is null', () {
        final task = Task(
          id: 'task-1',
          name: 'Task A',
          completed: false,
          startDate: DateTime(2025),
          repeatIcalRrule: 'FREQ=DAILY',
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        );

        final result = expander.expandTaskOccurrencesSync(
          tasks: [task],
          completions: [],
          exceptions: [],
          rangeStart: DateTime(2025),
          rangeEnd: DateTime(2025, 1, 5),
        );

        expect(result, hasLength(5));
      });
    });

    group('sorting', () {
      test('sorts tasks by occurrence date', () {
        final task1 = Task(
          id: 'task-1',
          name: 'Task 1',
          completed: false,
          startDate: DateTime(2025, 1, 20),
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        );

        final task2 = Task(
          id: 'task-2',
          name: 'Task 2',
          completed: false,
          startDate: DateTime(2025, 1, 10),
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        );

        final task3 = Task(
          id: 'task-3',
          name: 'Task 3',
          completed: false,
          startDate: DateTime(2025, 1, 15),
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        );

        final result = expander.expandTaskOccurrencesSync(
          tasks: [task1, task2, task3],
          completions: [],
          exceptions: [],
          rangeStart: DateTime(2025),
          rangeEnd: DateTime(2025, 1, 31),
        );

        expect(result[0].id, 'task-2');
        expect(result[1].id, 'task-3');
        expect(result[2].id, 'task-1');
      });
    });

    group('edge cases', () {
      test('handles empty task list', () {
        final result = expander.expandTaskOccurrencesSync(
          tasks: [],
          completions: [],
          exceptions: [],
          rangeStart: DateTime(2025),
          rangeEnd: DateTime(2025, 1, 31),
        );

        expect(result, isEmpty);
      });

      test('handles empty project list', () {
        final result = expander.expandProjectOccurrencesSync(
          projects: [],
          completions: [],
          exceptions: [],
          rangeStart: DateTime(2025),
          rangeEnd: DateTime(2025, 1, 31),
        );

        expect(result, isEmpty);
      });

      test('handles task with no RRULE string', () {
        final task = Task(
          id: 'task-1',
          name: 'Task',
          completed: false,
          startDate: DateTime(2025, 1, 15),
          repeatIcalRrule: '',
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        );

        final result = expander.expandTaskOccurrencesSync(
          tasks: [task],
          completions: [],
          exceptions: [],
          rangeStart: DateTime(2025),
          rangeEnd: DateTime(2025, 1, 31),
        );

        expect(result, hasLength(1));
      });

      test('handles multiple exceptions for same task', () {
        final task = Task(
          id: 'task-1',
          name: 'Task',
          completed: false,
          startDate: DateTime(2025),
          repeatIcalRrule: 'FREQ=DAILY',
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        );

        final exceptions = [
          RecurrenceExceptionData(
            id: 'exc-1',
            entityId: 'task-1',
            originalDate: DateTime(2025, 1, 3),
            exceptionType: RecurrenceExceptionType.skip,
          ),
          RecurrenceExceptionData(
            id: 'exc-2',
            entityId: 'task-1',
            originalDate: DateTime(2025, 1, 5),
            exceptionType: RecurrenceExceptionType.skip,
          ),
        ];

        final result = expander.expandTaskOccurrencesSync(
          tasks: [task],
          completions: [],
          exceptions: exceptions,
          rangeStart: DateTime(2025),
          rangeEnd: DateTime(2025, 1, 7),
        );

        // Should have 5 occurrences (1, 2, 4, 6, 7)
        expect(result, hasLength(5));
      });

      test('handles completions for non-existent tasks', () {
        final task = Task(
          id: 'task-1',
          name: 'Task',
          completed: false,
          startDate: DateTime(2025, 1, 15),
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        );

        final completion = CompletionHistoryData(
          id: 'comp-1',
          entityId: 'task-999', // Different task
          completedAt: DateTime(2025, 1, 15),
        );

        final result = expander.expandTaskOccurrencesSync(
          tasks: [task],
          completions: [completion],
          exceptions: [],
          rangeStart: DateTime(2025),
          rangeEnd: DateTime(2025, 1, 31),
        );

        expect(result, hasLength(1));
        expect(result.first.occurrence!.completionId, isNull);
      });

      test('preserves task labels through expansion', () {
        final task = Task(
          id: 'task-1',
          name: 'Task with Labels',
          completed: false,
          startDate: DateTime(2025, 1, 15),
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
          labels: [
            Label(
              id: 'label-1',
              name: 'Important',
              createdAt: DateTime(2025),
              updatedAt: DateTime(2025),
            ),
          ],
        );

        final result = expander.expandTaskOccurrencesSync(
          tasks: [task],
          completions: [],
          exceptions: [],
          rangeStart: DateTime(2025),
          rangeEnd: DateTime(2025, 1, 31),
        );

        expect(result.first.labels, hasLength(1));
        expect(result.first.labels.first.name, 'Important');
      });
    });
  });
}
