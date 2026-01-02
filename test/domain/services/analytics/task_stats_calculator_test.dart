import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/analytics/date_range.dart';
import 'package:taskly_bloc/domain/models/analytics/entity_type.dart';
import 'package:taskly_bloc/domain/models/analytics/stat_result.dart';
import 'package:taskly_bloc/domain/models/analytics/task_stat_type.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/models/occurrence_data.dart';
import 'package:taskly_bloc/domain/services/analytics/task_stats_calculator.dart';

import '../../../fixtures/test_data.dart';

void main() {
  late TaskStatsCalculator calculator;

  setUp(() {
    calculator = TaskStatsCalculator();
  });

  group('TaskStatsCalculator', () {
    group('totalCount', () {
      test('returns count of all tasks', () {
        final tasks = [
          TestData.task(id: '1'),
          TestData.task(id: '2'),
          TestData.task(id: '3'),
        ];

        final result = calculator.calculate(
          tasks: tasks,
          statType: TaskStatType.totalCount,
        );

        expect(result.value, 3);
        expect(result.formattedValue, '3');
        expect(result.label, 'Total Tasks');
      });

      test('returns 0 for empty list', () {
        final result = calculator.calculate(
          tasks: [],
          statType: TaskStatType.totalCount,
        );

        expect(result.value, 0);
      });
    });

    group('completedCount', () {
      test('returns count of completed tasks', () {
        final tasks = [
          TestData.task(id: '1', completed: true),
          TestData.task(id: '2'),
          TestData.task(id: '3', completed: true),
        ];

        final result = calculator.calculate(
          tasks: tasks,
          statType: TaskStatType.completedCount,
        );

        expect(result.value, 2);
        expect(result.severity, StatSeverity.positive);
      });

      test('returns 0 when no tasks completed', () {
        final tasks = [
          TestData.task(id: '1'),
          TestData.task(id: '2'),
        ];

        final result = calculator.calculate(
          tasks: tasks,
          statType: TaskStatType.completedCount,
        );

        expect(result.value, 0);
      });
    });

    group('completionRate', () {
      test('calculates percentage of completed tasks', () {
        final tasks = [
          TestData.task(id: '1', completed: true),
          TestData.task(id: '2', completed: true),
          TestData.task(id: '3'),
          TestData.task(id: '4'),
        ];

        final result = calculator.calculate(
          tasks: tasks,
          statType: TaskStatType.completionRate,
        );

        expect(result.value, 50.0);
        expect(result.formattedValue, '50%');
      });

      test('returns 0% for empty list', () {
        final result = calculator.calculate(
          tasks: [],
          statType: TaskStatType.completionRate,
        );

        expect(result.value, 0);
        expect(result.formattedValue, '0%');
      });

      test('has positive severity when rate >= 70%', () {
        final tasks = [
          TestData.task(id: '1', completed: true),
          TestData.task(id: '2', completed: true),
          TestData.task(id: '3', completed: true),
          TestData.task(id: '4'),
        ];

        final result = calculator.calculate(
          tasks: tasks,
          statType: TaskStatType.completionRate,
        );

        expect(result.value, 75.0);
        expect(result.severity, StatSeverity.positive);
      });

      test('has normal severity when rate < 70%', () {
        final tasks = [
          TestData.task(id: '1', completed: true),
          TestData.task(id: '2'),
          TestData.task(id: '3'),
        ];

        final result = calculator.calculate(
          tasks: tasks,
          statType: TaskStatType.completionRate,
        );

        expect(result.value, closeTo(33.3, 0.1));
        expect(result.severity, StatSeverity.normal);
      });
    });

    group('staleCount', () {
      test('counts tasks with no activity for 14+ days', () {
        final now = DateTime.now();
        final staleDate = now.subtract(const Duration(days: 20));
        final recentDate = now.subtract(const Duration(days: 5));

        final tasks = [
          TestData.task(
            id: '1',
            updatedAt: staleDate,
          ),
          TestData.task(
            id: '2',
            updatedAt: recentDate,
          ),
          TestData.task(
            id: '3',
            updatedAt: staleDate,
          ),
        ];

        final result = calculator.calculate(
          tasks: tasks,
          statType: TaskStatType.staleCount,
        );

        expect(result.value, 2);
        expect(result.severity, StatSeverity.warning);
      });

      test('does not count completed tasks as stale', () {
        final staleDate = DateTime.now().subtract(const Duration(days: 20));

        final tasks = [
          TestData.task(
            id: '1',
            completed: true,
            updatedAt: staleDate,
          ),
        ];

        final result = calculator.calculate(
          tasks: tasks,
          statType: TaskStatType.staleCount,
        );

        expect(result.value, 0);
        expect(result.severity, StatSeverity.normal);
      });
    });

    group('overdueCount', () {
      test('counts tasks past their deadline', () {
        final now = DateTime.now();
        final pastDeadline = now.subtract(const Duration(days: 5));
        final futureDeadline = now.add(const Duration(days: 5));

        final tasks = [
          TestData.task(
            id: '1',
            deadlineDate: pastDeadline,
          ),
          TestData.task(
            id: '2',
            deadlineDate: futureDeadline,
          ),
          TestData.task(
            id: '3',
            deadlineDate: pastDeadline,
          ),
        ];

        final result = calculator.calculate(
          tasks: tasks,
          statType: TaskStatType.overdueCount,
        );

        expect(result.value, 2);
        expect(result.severity, StatSeverity.warning);
      });

      test('does not count completed tasks as overdue', () {
        final pastDeadline = DateTime.now().subtract(const Duration(days: 5));

        final tasks = [
          TestData.task(
            id: '1',
            completed: true,
            deadlineDate: pastDeadline,
          ),
        ];

        final result = calculator.calculate(
          tasks: tasks,
          statType: TaskStatType.overdueCount,
        );

        expect(result.value, 0);
      });

      test('does not count tasks without deadline', () {
        final tasks = [
          TestData.task(id: '1'),
        ];

        final result = calculator.calculate(
          tasks: tasks,
          statType: TaskStatType.overdueCount,
        );

        expect(result.value, 0);
      });
    });

    group('avgDaysToComplete', () {
      test('calculates average days between creation and completion', () {
        final now = DateTime.now();
        final createdAt1 = now.subtract(const Duration(days: 10));
        final createdAt2 = now.subtract(const Duration(days: 6));
        final completedAt1 = now.subtract(const Duration(days: 5));
        final completedAt2 = now.subtract(const Duration(days: 2));

        final tasks = [
          TestData.task(
            id: '1',
            completed: true,
            createdAt: createdAt1,
            occurrence: OccurrenceData(
              date: createdAt1,
              isRescheduled: false,
              completedAt: completedAt1,
            ),
          ),
          TestData.task(
            id: '2',
            completed: true,
            createdAt: createdAt2,
            occurrence: OccurrenceData(
              date: createdAt2,
              isRescheduled: false,
              completedAt: completedAt2,
            ),
          ),
        ];

        final result = calculator.calculate(
          tasks: tasks,
          statType: TaskStatType.avgDaysToComplete,
        );

        // Task 1: 10 - 5 = 5 days, Task 2: 6 - 2 = 4 days
        // Average: (5 + 4) / 2 = 4.5 days
        expect(result.value, closeTo(4.5, 0.5));
      });

      test('returns N/A when no completed tasks', () {
        final tasks = [
          TestData.task(id: '1'),
        ];

        final result = calculator.calculate(
          tasks: tasks,
          statType: TaskStatType.avgDaysToComplete,
        );

        expect(result.formattedValue, 'N/A');
      });
    });

    group('completedThisWeek', () {
      test('returns count of tasks completed this week', () {
        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final tasks = [
          TestData.task(
            id: '1',
            completed: true,
            occurrence: OccurrenceData(
              date: weekStart,
              isRescheduled: false,
              completedAt: weekStart.add(const Duration(days: 1)),
            ),
          ),
          TestData.task(
            id: '2',
            completed: true,
            occurrence: OccurrenceData(
              date: weekStart.subtract(const Duration(days: 10)),
              isRescheduled: false,
              completedAt: weekStart.subtract(const Duration(days: 5)),
            ),
          ),
        ];

        final result = calculator.calculate(
          tasks: tasks,
          statType: TaskStatType.completedThisWeek,
        );

        expect(result.label, 'Completed This Week');
        expect(result.value, 1);
        expect(result.severity, StatSeverity.positive);
      });

      test('returns 0 when no tasks completed this week', () {
        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final tasks = [
          TestData.task(
            id: '1',
            completed: true,
            occurrence: OccurrenceData(
              date: weekStart.subtract(const Duration(days: 10)),
              isRescheduled: false,
              completedAt: weekStart.subtract(const Duration(days: 10)),
            ),
          ),
        ];

        final result = calculator.calculate(
          tasks: tasks,
          statType: TaskStatType.completedThisWeek,
        );

        expect(result.value, 0);
      });

      test('excludes incomplete tasks', () {
        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final tasks = [
          TestData.task(
            id: '1',
            completed: false,
            occurrence: OccurrenceData(
              date: weekStart.add(const Duration(days: 1)),
              isRescheduled: false,
            ),
          ),
        ];

        final result = calculator.calculate(
          tasks: tasks,
          statType: TaskStatType.completedThisWeek,
        );

        expect(result.value, 0);
      });

      test('excludes completed tasks without completedAt', () {
        final tasks = [
          TestData.task(
            id: '1',
            completed: true,
            occurrence: null,
          ),
        ];

        final result = calculator.calculate(
          tasks: tasks,
          statType: TaskStatType.completedThisWeek,
        );

        expect(result.value, 0);
      });
    });

    group('velocity', () {
      test('returns 0 for no completed tasks', () {
        final result = calculator.calculate(
          tasks: [],
          statType: TaskStatType.velocity,
        );

        expect(result.label, 'Velocity');
        expect(result.value, 0);
        expect(result.formattedValue, '0 tasks/week');
      });

      test('returns 0 when no range provided', () {
        final tasks = [
          TestData.task(id: '1', completed: true),
        ];

        final result = calculator.calculate(
          tasks: tasks,
          statType: TaskStatType.velocity,
          range: null,
        );

        expect(result.value, 0);
      });

      test('returns task count when range days equals zero', () {
        final now = DateTime.now();
        final tasks = [
          TestData.task(id: '1', completed: true, createdAt: now),
          TestData.task(id: '2', completed: true, createdAt: now),
        ];

        // Range with 0 days difference triggers weeks == 0 branch
        final range = DateRange(
          start: now,
          end: now,
        );

        final result = calculator.calculate(
          tasks: tasks,
          statType: TaskStatType.velocity,
          range: range,
        );

        expect(result.value, 2);
        expect(result.formattedValue, '2 tasks/week');
      });

      test('calculates velocity for multi-week range', () {
        final now = DateTime.now();
        final tasks = List.generate(
          14,
          (i) => TestData.task(
            id: 'task-$i',
            completed: true,
            createdAt: now.subtract(Duration(days: i)),
          ),
        );

        final range = DateRange(
          start: now.subtract(const Duration(days: 14)),
          end: now,
        );

        final result = calculator.calculate(
          tasks: tasks,
          statType: TaskStatType.velocity,
          range: range,
        );

        // 14 tasks / 2 weeks = 7 tasks/week
        expect(result.value, 7);
        expect(result.formattedValue, '7.0 tasks/week');
      });

      test('excludes incomplete tasks from velocity', () {
        final now = DateTime.now();
        final tasks = [
          TestData.task(id: '1', completed: true, createdAt: now),
          TestData.task(id: '2', completed: false, createdAt: now),
        ];

        final range = DateRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );

        final result = calculator.calculate(
          tasks: tasks,
          statType: TaskStatType.velocity,
          range: range,
        );

        expect(result.value, 1);
      });
    });

    group('getTaskDaysForEntity', () {
      test('returns completion days for specific task', () {
        final now = DateTime.now();
        final targetDate = now.subtract(const Duration(days: 5));
        final tasks = [
          TestData.task(
            id: 'target-task',
            completed: true,
            occurrence: OccurrenceData(
              date: targetDate,
              isRescheduled: false,
              completedAt: targetDate,
            ),
          ),
          TestData.task(
            id: 'other-task',
            completed: true,
            occurrence: OccurrenceData(
              date: now,
              isRescheduled: false,
              completedAt: now,
            ),
          ),
        ];

        final range = DateRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );

        final result = calculator.getTaskDaysForEntity(
          tasks: tasks,
          entityId: 'target-task',
          entityType: EntityType.task,
          range: range,
        );

        expect(result['days'], isNotEmpty);
        expect(result['days']!.length, 1);
      });

      test('returns completion days for project', () {
        final now = DateTime.now();
        final tasks = [
          TestData.task(
            id: '1',
            projectId: 'my-project',
            completed: true,
            occurrence: OccurrenceData(
              date: now.subtract(const Duration(days: 1)),
              isRescheduled: false,
              completedAt: now.subtract(const Duration(days: 1)),
            ),
          ),
          TestData.task(
            id: '2',
            projectId: 'my-project',
            completed: true,
            occurrence: OccurrenceData(
              date: now.subtract(const Duration(days: 2)),
              isRescheduled: false,
              completedAt: now.subtract(const Duration(days: 2)),
            ),
          ),
          TestData.task(
            id: '3',
            projectId: 'other-project',
            completed: true,
            occurrence: OccurrenceData(
              date: now,
              isRescheduled: false,
              completedAt: now,
            ),
          ),
        ];

        final range = DateRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );

        final result = calculator.getTaskDaysForEntity(
          tasks: tasks,
          entityId: 'my-project',
          entityType: EntityType.project,
          range: range,
        );

        expect(result['days']!.length, 2);
      });

      test('returns completion days for label', () {
        final now = DateTime.now();
        final targetLabel = TestData.label(id: 'urgent-label');
        final tasks = [
          TestData.task(
            id: '1',
            labels: [targetLabel],
            completed: true,
            occurrence: OccurrenceData(
              date: now.subtract(const Duration(days: 1)),
              isRescheduled: false,
              completedAt: now.subtract(const Duration(days: 1)),
            ),
          ),
          TestData.task(
            id: '2',
            labels: [TestData.label(id: 'other-label')],
            completed: true,
            occurrence: OccurrenceData(
              date: now,
              isRescheduled: false,
              completedAt: now,
            ),
          ),
        ];

        final range = DateRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );

        final result = calculator.getTaskDaysForEntity(
          tasks: tasks,
          entityId: 'urgent-label',
          entityType: EntityType.label,
          range: range,
        );

        expect(result['days']!.length, 1);
      });

      test('returns completion days for value (same as label)', () {
        final now = DateTime.now();
        final valueLabel = TestData.label(
          id: 'high-value',
          type: LabelType.value,
        );
        final tasks = [
          TestData.task(
            id: '1',
            labels: [valueLabel],
            completed: true,
            occurrence: OccurrenceData(
              date: now.subtract(const Duration(days: 1)),
              isRescheduled: false,
              completedAt: now.subtract(const Duration(days: 1)),
            ),
          ),
        ];

        final range = DateRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );

        final result = calculator.getTaskDaysForEntity(
          tasks: tasks,
          entityId: 'high-value',
          entityType: EntityType.value,
          range: range,
        );

        expect(result['days']!.length, 1);
      });

      test('excludes incomplete tasks', () {
        final now = DateTime.now();
        final tasks = [
          TestData.task(
            id: 'incomplete',
            completed: false,
          ),
        ];

        final range = DateRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );

        final result = calculator.getTaskDaysForEntity(
          tasks: tasks,
          entityId: 'incomplete',
          entityType: EntityType.task,
          range: range,
        );

        expect(result['days'], isEmpty);
      });

      test('excludes tasks without completedAt', () {
        final now = DateTime.now();
        final tasks = [
          TestData.task(
            id: 'no-date',
            completed: true,
            occurrence: OccurrenceData(
              date: now,
              isRescheduled: false,
              completedAt: null,
            ),
          ),
        ];

        final range = DateRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );

        final result = calculator.getTaskDaysForEntity(
          tasks: tasks,
          entityId: 'no-date',
          entityType: EntityType.task,
          range: range,
        );

        expect(result['days'], isEmpty);
      });

      test('excludes tasks completed outside range', () {
        final now = DateTime.now();
        final tasks = [
          TestData.task(
            id: 'out-of-range',
            completed: true,
            occurrence: OccurrenceData(
              date: now.subtract(const Duration(days: 60)),
              isRescheduled: false,
              completedAt: now.subtract(const Duration(days: 60)),
            ),
          ),
        ];

        final range = DateRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );

        final result = calculator.getTaskDaysForEntity(
          tasks: tasks,
          entityId: 'out-of-range',
          entityType: EntityType.task,
          range: range,
        );

        expect(result['days'], isEmpty);
      });

      test('deduplicates completion days', () {
        final now = DateTime.now();
        final sameDay = DateTime(now.year, now.month, now.day - 1, 10);
        final sameDayLater = DateTime(now.year, now.month, now.day - 1, 15);

        final tasks = [
          TestData.task(
            id: 'task1',
            projectId: 'my-project',
            completed: true,
            occurrence: OccurrenceData(
              date: sameDay,
              isRescheduled: false,
              completedAt: sameDay,
            ),
          ),
          TestData.task(
            id: 'task2',
            projectId: 'my-project',
            completed: true,
            occurrence: OccurrenceData(
              date: sameDayLater,
              isRescheduled: false,
              completedAt: sameDayLater,
            ),
          ),
        ];

        final range = DateRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );

        final result = calculator.getTaskDaysForEntity(
          tasks: tasks,
          entityId: 'my-project',
          entityType: EntityType.project,
          range: range,
        );

        // Both tasks completed on the same day should result in 1 unique day
        expect(result['days']!.length, 1);
      });

      test('sorts completion days', () {
        final now = DateTime.now();
        final tasks = [
          TestData.task(
            id: '1',
            projectId: 'my-project',
            completed: true,
            occurrence: OccurrenceData(
              date: now.subtract(const Duration(days: 1)),
              isRescheduled: false,
              completedAt: now.subtract(const Duration(days: 1)),
            ),
          ),
          TestData.task(
            id: '2',
            projectId: 'my-project',
            completed: true,
            occurrence: OccurrenceData(
              date: now.subtract(const Duration(days: 5)),
              isRescheduled: false,
              completedAt: now.subtract(const Duration(days: 5)),
            ),
          ),
          TestData.task(
            id: '3',
            projectId: 'my-project',
            completed: true,
            occurrence: OccurrenceData(
              date: now.subtract(const Duration(days: 3)),
              isRescheduled: false,
              completedAt: now.subtract(const Duration(days: 3)),
            ),
          ),
        ];

        final range = DateRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );

        final result = calculator.getTaskDaysForEntity(
          tasks: tasks,
          entityId: 'my-project',
          entityType: EntityType.project,
          range: range,
        );

        final days = result['days']!;
        expect(days.length, 3);
        expect(days[0].isBefore(days[1]), isTrue);
        expect(days[1].isBefore(days[2]), isTrue);
      });
    });

    group('with date range', () {
      test('filters tasks by date range', () {
        final now = DateTime.now();
        final rangeStart = now.subtract(const Duration(days: 7));
        final rangeEnd = now;

        final inRangeCreatedAt = now.subtract(const Duration(days: 3));
        final outsideRangeCreatedAt = now.subtract(const Duration(days: 30));

        final tasks = [
          TestData.task(
            id: '1',
            createdAt: inRangeCreatedAt,
          ),
          TestData.task(
            id: '2',
            createdAt: outsideRangeCreatedAt,
          ),
        ];

        final result = calculator.calculate(
          tasks: tasks,
          statType: TaskStatType.totalCount,
          range: DateRange(start: rangeStart, end: rangeEnd),
        );

        expect(result.value, 1);
      });

      test('includes completed task in range by completedAt', () {
        final now = DateTime.now();
        final rangeStart = now.subtract(const Duration(days: 7));
        final rangeEnd = now;

        final tasks = [
          TestData.task(
            id: '1',
            completed: true,
            createdAt: now.subtract(const Duration(days: 30)),
            occurrence: OccurrenceData(
              date: now.subtract(const Duration(days: 30)),
              isRescheduled: false,
              completedAt: now.subtract(const Duration(days: 3)),
            ),
          ),
        ];

        final result = calculator.calculate(
          tasks: tasks,
          statType: TaskStatType.totalCount,
          range: DateRange(start: rangeStart, end: rangeEnd),
        );

        expect(result.value, 1);
      });
    });
  });
}
