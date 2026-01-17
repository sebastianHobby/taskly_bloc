import '../../../helpers/test_imports.dart';


import 'package:taskly_domain/taskly_domain.dart';
void main() {
  group('UrgencyWeightedAllocator', () {
    Value value(String id) => TestData.value(id: id, name: id);

    testSafe('returns empty result when totalWeight is 0', () async {
      final allocator = UrgencyWeightedAllocator();

      final result = allocator.allocate(
        AllocationParameters(
          tasks: [
            TestData.task(values: [value('v1')]),
          ],
          categories: const {'v1': 0},
          maxTasks: 3,
        ),
      );

      expect(result.allocatedTasks, isEmpty);
      expect(result.excludedTasks, isEmpty);
      expect(result.reasoning.strategyUsed, allocator.strategyName);
      expect(result.reasoning.explanation, contains('No categories'));
    });

    testSafe('allocates highest urgency when influence is 1.0', () async {
      final allocator = UrgencyWeightedAllocator();

      final now = DateTime.now();

      final urgent = TestData.task(
        name: 'urgent',
        values: [value('v1')],
        deadlineDate: now.add(const Duration(days: 1)),
      );

      final later = TestData.task(
        name: 'later',
        values: [value('v1')],
        deadlineDate: now.add(const Duration(days: 30)),
      );

      final result = allocator.allocate(
        AllocationParameters(
          tasks: [later, urgent],
          categories: const {'v1': 1},
          maxTasks: 1,
          urgencyInfluence: 1,
        ),
      );

      expect(result.allocatedTasks.single.task.name, 'urgent');
      expect(
        result.excludedTasks.single.exclusionType,
        ExclusionType.lowPriority,
      );
    });

    testSafe(
      'excludes completed tasks and tasks with no matching category',
      () async {
        final allocator = UrgencyWeightedAllocator();

        final completed = TestData.task(
          name: 'completed',
          completed: true,
          values: [value('v1')],
        );

        final noCategory = TestData.task(
          name: 'no-category',
          completed: false,
          values: const <Value>[],
          deadlineDate: DateTime.now().add(const Duration(days: 1)),
        );

        final ok = TestData.task(
          name: 'ok',
          completed: false,
          values: [value('v1')],
        );

        final result = allocator.allocate(
          AllocationParameters(
            tasks: [completed, noCategory, ok],
            categories: const {'v1': 1},
            maxTasks: 10,
            urgencyInfluence: 0.5,
          ),
        );

        expect(result.allocatedTasks.map((t) => t.task.name), ['ok']);
        expect(result.excludedTasks, hasLength(2));
        expect(
          result.excludedTasks.map((e) => e.exclusionType).toSet(),
          {ExclusionType.completed, ExclusionType.noCategory},
        );
      },
    );
  });
}
