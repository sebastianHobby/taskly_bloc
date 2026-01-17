import '../../../helpers/test_imports.dart';


import 'package:taskly_domain/taskly_domain.dart';
void main() {
  group('NeglectBasedAllocator', () {
    Value value(String id) => TestData.value(id: id, name: id);

    testSafe('returns empty result when totalWeight is 0', () async {
      final allocator = NeglectBasedAllocator();

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

    testSafe(
      'excludes completed tasks and tasks with no matching category',
      () async {
        final allocator = NeglectBasedAllocator();

        final completed = TestData.task(
          name: 'completed',
          completed: true,
          values: [value('v1')],
        );

        final noCategory = TestData.task(
          name: 'no-category',
          completed: false,
          values: const <Value>[],
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

    testSafe(
      'respects maxTasks limit and excludes remaining as lowPriority',
      () async {
        final allocator = NeglectBasedAllocator();

        final tasks = [
          TestData.task(name: 't1', values: [value('v1')]),
          TestData.task(name: 't2', values: [value('v1')]),
          TestData.task(name: 't3', values: [value('v1')]),
        ];

        final result = allocator.allocate(
          AllocationParameters(
            tasks: tasks,
            categories: const {'v1': 1},
            maxTasks: 2,
            completionsByValue: const {'v1': 0},
          ),
        );

        expect(result.allocatedTasks, hasLength(2));
        expect(
          result.excludedTasks.where(
            (e) => e.exclusionType == ExclusionType.lowPriority,
          ),
          hasLength(1),
        );
      },
    );

    testSafe(
      'overdue urgent tasks rank above non-urgent tasks (all else equal)',
      () async {
        final allocator = NeglectBasedAllocator();

        final now = DateTime.now();

        final overdue = TestData.task(
          name: 'overdue',
          values: [value('v1')],
          deadlineDate: now.subtract(const Duration(days: 2)),
        );

        final later = TestData.task(
          name: 'later',
          values: [value('v1')],
          deadlineDate: now.add(const Duration(days: 30)),
        );

        final result = allocator.allocate(
          AllocationParameters(
            tasks: [later, overdue],
            categories: const {'v1': 1},
            maxTasks: 1,
            urgencyBoostMultiplier: 2,
            overdueEmergencyMultiplier: 2,
          ),
        );

        expect(result.allocatedTasks.single.task.name, 'overdue');
      },
    );
  });
}
