@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/core.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('TaskStatsCalculator', () {
    testSafe('calculates basic counts and rates', () async {
      final calculator = TaskStatsCalculator();
      final now = TestConstants.referenceDate;
      final tasks = [
        TestData.task(completed: true),
        TestData.task(completed: false),
      ];

      final total = calculator.calculate(
        tasks: tasks,
        statType: TaskStatType.totalCount,
        nowUtc: now,
        todayDayKeyUtc: now,
      );
      final completed = calculator.calculate(
        tasks: tasks,
        statType: TaskStatType.completedCount,
        nowUtc: now,
        todayDayKeyUtc: now,
      );
      final rate = calculator.calculate(
        tasks: tasks,
        statType: TaskStatType.completionRate,
        nowUtc: now,
        todayDayKeyUtc: now,
      );

      expect(total.value, 2);
      expect(completed.value, 1);
      expect(rate.formattedValue, endsWith('%'));
    });

    testSafe('calculates stale and overdue counts', () async {
      final now = DateTime(2025, 2, 1);
      final staleTask = TestData.task(
        updatedAt: now.subtract(const Duration(days: 30)),
      );
      final overdueTask = TestData.task(
        deadlineDate: now.subtract(const Duration(days: 1)),
      );

      final calculator = TaskStatsCalculator();

      final stale = calculator.calculate(
        tasks: [staleTask, overdueTask],
        statType: TaskStatType.staleCount,
        nowUtc: now,
        todayDayKeyUtc: now,
      );
      final overdue = calculator.calculate(
        tasks: [staleTask, overdueTask],
        statType: TaskStatType.overdueCount,
        nowUtc: now,
        todayDayKeyUtc: now,
      );

      expect(stale.value, 1);
      expect(overdue.value, 1);
    });

    testSafe('calculates average days to complete and velocity', () async {
      final now = DateTime(2025, 1, 15);
      final completedTask = TestData.task(
        completed: true,
        createdAt: now.subtract(const Duration(days: 4)),
        occurrence: TestData.occurrenceData(completedAt: now),
      );

      final calculator = TaskStatsCalculator();
      final range = DateRange(
        start: now.subtract(const Duration(days: 7)),
        end: now,
      );

      final avg = calculator.calculate(
        tasks: [completedTask],
        statType: TaskStatType.avgDaysToComplete,
        nowUtc: now,
        todayDayKeyUtc: now,
      );
      final velocity = calculator.calculate(
        tasks: [completedTask],
        statType: TaskStatType.velocity,
        nowUtc: now,
        todayDayKeyUtc: now,
        range: range,
      );

      expect(avg.formattedValue, contains('days'));
      expect(velocity.formattedValue, contains('tasks/week'));
    });

    testSafe('returns completion days for entity', () async {
      final now = DateTime(2025, 1, 15);
      final range = DateRange(
        start: now.subtract(const Duration(days: 7)),
        end: now,
      );
      final completedTask = TestData.task(
        id: 't1',
        projectId: 'p1',
        values: [TestData.value(id: 'v1')],
        completed: true,
        occurrence: TestData.occurrenceData(completedAt: now),
      );

      final calculator = TaskStatsCalculator();
      final result = calculator.getTaskDaysForEntity(
        tasks: [completedTask],
        entityId: 'p1',
        entityType: EntityType.project,
        range: range,
      );

      expect(result['days'], isNotEmpty);
    });
  });
}
