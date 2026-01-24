@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';
import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/core.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('SuggestedPicksEngine', () {
    testSafe('returns empty allocation when disabled', () async {
      final engine = SuggestedPicksEngine();
      final result = engine.allocate(
        AllocationParameters(
          nowUtc: TestConstants.referenceDate,
          todayDayKeyUtc: DateTime(2025, 1, 15),
          tasks: const [],
          categories: const {},
          maxTasks: 0,
          taskUrgencyThresholdDays: 3,
          keepValuesInBalance: false,
          completionsByValue: const {},
        ),
      );

      expect(result.allocatedTasks, isEmpty);
      expect(result.excludedTasks, isEmpty);
      expect(result.reasoning.explanation, contains('No allocation'));
    });

    testSafe('allocates proportionally by category and excludes valueless', () async {
      final valueA = TestData.value(id: 'v1');
      final valueB = TestData.value(id: 'v2');

      final tasks = [
        TestData.task(id: 't1', values: [valueA]),
        TestData.task(id: 't2', values: [valueA]),
        TestData.task(id: 't3', values: [valueB]),
        TestData.task(id: 't4', values: const []),
      ];

      final engine = SuggestedPicksEngine();
      final result = engine.allocate(
        AllocationParameters(
          nowUtc: TestConstants.referenceDate,
          todayDayKeyUtc: DateTime(2025, 1, 15),
          tasks: tasks,
          categories: const {'v1': 2.0, 'v2': 1.0},
          maxTasks: 2,
          taskUrgencyThresholdDays: 3,
          keepValuesInBalance: false,
          completionsByValue: const {},
        ),
      );

      expect(result.allocatedTasks, hasLength(2));
      expect(
        result.excludedTasks.where((e) => e.exclusionType == ExclusionType.noCategory),
        isNotEmpty,
      );
    });

    testSafe('applies bounded quota repair when enabled', () async {
      final valueA = TestData.value(id: 'v1');
      final valueB = TestData.value(id: 'v2');

      final tasks = [
        TestData.task(id: 't1', values: [valueA]),
        TestData.task(id: 't2', values: [valueA]),
        TestData.task(id: 't3', values: [valueB]),
      ];

      final engine = SuggestedPicksEngine();
      final result = engine.allocate(
        AllocationParameters(
          nowUtc: TestConstants.referenceDate,
          todayDayKeyUtc: DateTime(2025, 1, 15),
          tasks: tasks,
          categories: const {'v1': 1.0, 'v2': 1.0},
          maxTasks: 2,
          taskUrgencyThresholdDays: 3,
          keepValuesInBalance: true,
          completionsByValue: const {'v1': 10, 'v2': 1},
        ),
      );

      expect(result.reasoning.explanation, contains('balanced'));
    });
  });
}
