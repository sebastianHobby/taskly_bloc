@Tags(['unit'])
library;

import '../../../helpers/test_imports.dart';

import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/core.dart';

void main() {
  Value value(String id) {
    return Value(
      id: id,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      name: 'V$id',
    );
  }

  Task task({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    bool completed = false,
    DateTime? deadlineDate,
    String? projectId,
    List<Value> values = const <Value>[],
    DateTime? completedAt,
  }) {
    return Task(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt,
      name: 'Task $id',
      completed: completed,
      deadlineDate: deadlineDate,
      projectId: projectId,
      values: values,
      occurrence: completedAt == null
          ? null
          : OccurrenceData(
              date: createdAt,
              isRescheduled: false,
              completionId: 'c$id',
              completedAt: completedAt,
            ),
    );
  }

  testSafe('TaskStatsCalculator calculates core stats', () async {
    final calculator = TaskStatsCalculator(staleThresholdDays: 14);

    final nowUtc = DateTime.utc(2026, 1, 31);
    final todayDayKeyUtc = DateTime.utc(2026, 1, 31);

    final tasks = <Task>[
      task(
        id: 't1',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 2),
        completed: true,
        completedAt: DateTime.utc(2026, 1, 3),
      ),
      task(
        id: 't2',
        createdAt: DateTime.utc(2026, 1, 10),
        updatedAt: DateTime.utc(2026, 1, 10),
        completed: true,
        completedAt: DateTime.utc(2026, 1, 11),
      ),
      task(
        id: 't3',
        createdAt: DateTime.utc(2026, 1, 15),
        updatedAt: DateTime.utc(2026, 1, 20),
        completed: false,
        deadlineDate: DateTime.utc(2026, 1, 31),
      ),
      task(
        id: 't4',
        createdAt: DateTime.utc(2026, 1, 5),
        updatedAt: DateTime.utc(2026, 1, 30),
        completed: false,
        deadlineDate: DateTime.utc(2026, 1, 20),
      ),
      // Stale: not completed, last activity older than threshold.
      task(
        id: 't5',
        createdAt: DateTime.utc(2025, 12, 1),
        updatedAt: DateTime.utc(2025, 12, 15),
        completed: false,
      ),
    ];

    expect(
      calculator
          .calculate(
            tasks: tasks,
            statType: TaskStatType.totalCount,
            nowUtc: nowUtc,
            todayDayKeyUtc: todayDayKeyUtc,
          )
          .value,
      5,
    );

    expect(
      calculator
          .calculate(
            tasks: tasks,
            statType: TaskStatType.completedCount,
            nowUtc: nowUtc,
            todayDayKeyUtc: todayDayKeyUtc,
          )
          .value,
      2,
    );

    final completionRate = calculator.calculate(
      tasks: tasks,
      statType: TaskStatType.completionRate,
      nowUtc: nowUtc,
      todayDayKeyUtc: todayDayKeyUtc,
    );
    expect(completionRate.formattedValue, '40%');

    final stale = calculator.calculate(
      tasks: tasks,
      statType: TaskStatType.staleCount,
      nowUtc: nowUtc,
      todayDayKeyUtc: todayDayKeyUtc,
    );
    expect(stale.value, 1);
    expect(stale.description, contains('14+ days'));

    final overdue = calculator.calculate(
      tasks: tasks,
      statType: TaskStatType.overdueCount,
      nowUtc: nowUtc,
      todayDayKeyUtc: todayDayKeyUtc,
    );
    expect(overdue.value, 1); // t4 deadline before today

    final avgDays = calculator.calculate(
      tasks: tasks,
      statType: TaskStatType.avgDaysToComplete,
      nowUtc: nowUtc,
      todayDayKeyUtc: todayDayKeyUtc,
    );
    expect(avgDays.formattedValue, '1.5 days');
  });

  testSafe(
    'TaskStatsCalculator range filtering includes created or completed in range',
    () async {
      final calculator = TaskStatsCalculator();

      final range = DateRange(
        start: DateTime.utc(2026, 1, 1),
        end: DateTime.utc(2026, 1, 10),
      );

      final tasks = <Task>[
        // Created in range.
        task(
          id: 'in_created',
          createdAt: DateTime.utc(2026, 1, 2),
          updatedAt: DateTime.utc(2026, 1, 2),
        ),
        // Created out of range, but completed in range.
        task(
          id: 'in_completed',
          createdAt: DateTime.utc(2025, 12, 1),
          updatedAt: DateTime.utc(2026, 1, 3),
          completed: true,
          completedAt: DateTime.utc(2026, 1, 3),
        ),
        // Neither created nor completed in range.
        task(
          id: 'out',
          createdAt: DateTime.utc(2025, 12, 1),
          updatedAt: DateTime.utc(2025, 12, 1),
        ),
      ];

      final result = calculator.calculate(
        tasks: tasks,
        statType: TaskStatType.totalCount,
        nowUtc: DateTime.utc(2026, 1, 31),
        todayDayKeyUtc: DateTime.utc(2026, 1, 31),
        range: range,
      );

      expect(result.value, 2);
    },
  );

  testSafe(
    'TaskStatsCalculator completedThisWeek and velocity branches',
    () async {
      final calculator = TaskStatsCalculator();

      // Friday, so weekStart is Monday of this week.
      final todayDayKeyUtc = DateTime.utc(2026, 1, 30);

      final weekStart = todayDayKeyUtc.subtract(
        Duration(days: todayDayKeyUtc.weekday - 1),
      );

      final tasks = <Task>[
        task(
          id: 'w1',
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 1),
          completed: true,
          completedAt: weekStart.add(const Duration(hours: 12)),
        ),
        task(
          id: 'w2',
          createdAt: DateTime.utc(2026, 1, 2),
          updatedAt: DateTime.utc(2026, 1, 2),
          completed: true,
          completedAt: weekStart.add(const Duration(hours: 13)),
        ),
        task(
          id: 'w3',
          createdAt: DateTime.utc(2026, 1, 3),
          updatedAt: DateTime.utc(2026, 1, 3),
          completed: true,
          completedAt: weekStart.add(const Duration(hours: 14)),
        ),
        // Completed outside this week.
        task(
          id: 'old',
          createdAt: DateTime.utc(2025, 12, 1),
          updatedAt: DateTime.utc(2025, 12, 1),
          completed: true,
          completedAt: weekStart.subtract(const Duration(days: 1)),
        ),
      ];

      final completedThisWeek = calculator.calculate(
        tasks: tasks,
        statType: TaskStatType.completedThisWeek,
        nowUtc: DateTime.utc(2026, 1, 30),
        todayDayKeyUtc: todayDayKeyUtc,
      );

      expect(completedThisWeek.value, 3);

      final velocityNoRange = calculator.calculate(
        tasks: tasks,
        statType: TaskStatType.velocity,
        nowUtc: DateTime.utc(2026, 1, 30),
        todayDayKeyUtc: todayDayKeyUtc,
        range: null,
      );
      expect(velocityNoRange.formattedValue, '0 tasks/week');

      final zeroDayRange = DateRange(start: weekStart, end: weekStart);
      final velocityZeroWeeks = calculator.calculate(
        tasks: tasks,
        statType: TaskStatType.velocity,
        nowUtc: DateTime.utc(2026, 1, 30),
        todayDayKeyUtc: todayDayKeyUtc,
        range: zeroDayRange,
      );
      expect(velocityZeroWeeks.formattedValue, '3 tasks/week');

      final twoWeekRange = DateRange(
        start: weekStart,
        end: weekStart.add(const Duration(days: 14)),
      );
      final velocityTwoWeeks = calculator.calculate(
        tasks: tasks,
        statType: TaskStatType.velocity,
        nowUtc: DateTime.utc(2026, 1, 30),
        todayDayKeyUtc: todayDayKeyUtc,
        range: twoWeekRange,
      );
      expect(velocityTwoWeeks.formattedValue, '1.5 tasks/week');
    },
  );

  testSafe(
    'TaskStatsCalculator getTaskDaysForEntity returns unique sorted day keys',
    () async {
      final calculator = TaskStatsCalculator();

      final range = DateRange(
        start: DateTime.utc(2026, 1, 1),
        end: DateTime.utc(2026, 1, 31),
      );

      final tasks = <Task>[
        task(
          id: 't1',
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 1),
          completed: true,
          completedAt: DateTime.utc(2026, 1, 10, 8),
          projectId: 'p1',
          values: [value('v1')],
        ),
        // Same completion day (different time) should dedupe.
        task(
          id: 't2',
          createdAt: DateTime.utc(2026, 1, 2),
          updatedAt: DateTime.utc(2026, 1, 2),
          completed: true,
          completedAt: DateTime.utc(2026, 1, 10, 18),
          projectId: 'p1',
          values: [value('v1')],
        ),
        // Different completion day.
        task(
          id: 't3',
          createdAt: DateTime.utc(2026, 1, 3),
          updatedAt: DateTime.utc(2026, 1, 3),
          completed: true,
          completedAt: DateTime.utc(2026, 1, 11, 12),
          projectId: 'p2',
          values: [value('v2')],
        ),
        // Not completed -> ignored.
        task(
          id: 't4',
          createdAt: DateTime.utc(2026, 1, 4),
          updatedAt: DateTime.utc(2026, 1, 4),
          completed: false,
          projectId: 'p1',
          values: [value('v1')],
        ),
      ];

      final byProject = calculator.getTaskDaysForEntity(
        tasks: tasks,
        entityId: 'p1',
        entityType: EntityType.project,
        range: range,
      );

      expect(byProject['days'], [DateTime(2026, 1, 10)]);

      final byValue = calculator.getTaskDaysForEntity(
        tasks: tasks,
        entityId: 'v1',
        entityType: EntityType.value,
        range: range,
      );

      expect(byValue['days'], [DateTime(2026, 1, 10)]);

      final byTask = calculator.getTaskDaysForEntity(
        tasks: tasks,
        entityId: 't3',
        entityType: EntityType.task,
        range: range,
      );

      expect(byTask['days'], [DateTime(2026, 1, 11)]);
    },
  );
}
