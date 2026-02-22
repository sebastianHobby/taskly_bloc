@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:taskly_domain/src/allocation/engine/allocation_strategy.dart';
import 'package:taskly_domain/src/allocation/engine/suggested_picks_engine.dart';
import 'package:taskly_domain/src/allocation/model/allocation_result.dart';
import 'package:taskly_domain/src/core/model/project.dart';
import 'package:taskly_domain/src/core/model/task.dart';
import 'package:taskly_domain/src/core/model/value.dart';
import 'package:taskly_domain/core/model/value_priority.dart';

Task _task({
  required String id,
  required DateTime now,
  String? valueId,
  bool completed = false,
}) {
  final value = valueId == null ? null : _value(id: valueId, now: now);
  final project = value == null
      ? null
      : Project(
          id: 'p-$id',
          createdAt: now,
          updatedAt: now,
          name: 'Project $id',
          completed: false,
          values: [value],
          primaryValueId: value.id,
        );
  return Task(
    id: id,
    createdAt: now,
    updatedAt: now,
    name: 'Task $id',
    completed: completed,
    projectId: project?.id,
    project: project,
    values: const <Value>[],
  );
}

Value _value({required String id, required DateTime now}) {
  return Value(
    id: id,
    createdAt: now,
    updatedAt: now,
    name: 'Value $id',
    color: '#000000',
    priority: ValuePriority.medium,
  );
}

void main() {
  group('SuggestedPicksEngine', () {
    testSafe('returns empty allocation when disabled', () async {
      final engine = SuggestedPicksEngine();
      final now = DateTime(2025, 1, 15, 12);
      final result = engine.allocate(
        AllocationParameters(
          nowUtc: now,
          todayDayKeyUtc: DateTime(2025, 1, 15),
          tasks: const [],
          projects: const [],
          projectAnchorStates: const [],
          categories: const {},
          anchorCount: 0,
          tasksPerAnchorMin: 0,
          tasksPerAnchorMax: 0,
          freeSlots: 0,
          rotationPressureDays: 7,
          readinessFilter: false,
          maxTasks: 0,
          taskUrgencyThresholdDays: 3,
          routineSelectionsByValue: const {},
        ),
      );

      expect(result.allocatedTasks, isEmpty);
      expect(result.excludedTasks, isEmpty);
      expect(result.reasoning.explanation, contains('No allocation'));
    });

    testSafe(
      'allocates proportionally by category and excludes valueless',
      () async {
        final now = DateTime(2025, 1, 15, 12);
        final tasks = [
          _task(id: 't1', now: now, valueId: 'v1'),
          _task(id: 't2', now: now, valueId: 'v1'),
          _task(id: 't3', now: now, valueId: 'v2'),
          _task(id: 't4', now: now),
        ];

        final engine = SuggestedPicksEngine();
        final result = engine.allocate(
          AllocationParameters(
            nowUtc: now,
            todayDayKeyUtc: DateTime(2025, 1, 15),
            tasks: tasks,
            projects: tasks
                .map((t) => t.project)
                .whereType<Project>()
                .toList(growable: false),
            projectAnchorStates: const [],
            categories: const {'v1': 2.0, 'v2': 1.0},
            anchorCount: 2,
            tasksPerAnchorMin: 0,
            tasksPerAnchorMax: 2,
            freeSlots: 0,
            rotationPressureDays: 7,
            readinessFilter: false,
            maxTasks: 2,
            taskUrgencyThresholdDays: 3,
            routineSelectionsByValue: const {},
          ),
        );

        expect(result.allocatedTasks, hasLength(2));
        expect(
          result.excludedTasks.where(
            (e) => e.exclusionType == ExclusionType.noCategory,
          ),
          isNotEmpty,
        );
      },
    );

    testSafe('respects anchor and max-task limits', () async {
      final now = DateTime(2025, 1, 15, 12);
      final tasks = [
        _task(id: 't1', now: now, valueId: 'v1'),
        _task(id: 't2', now: now, valueId: 'v1'),
        _task(id: 't3', now: now, valueId: 'v2'),
      ];

      final engine = SuggestedPicksEngine();
      final result = engine.allocate(
        AllocationParameters(
          nowUtc: now,
          todayDayKeyUtc: DateTime(2025, 1, 15),
          tasks: tasks,
          projects: tasks
              .map((t) => t.project)
              .whereType<Project>()
              .toList(growable: false),
          projectAnchorStates: const [],
          categories: const {'v1': 1.0, 'v2': 1.0},
          anchorCount: 2,
          tasksPerAnchorMin: 0,
          tasksPerAnchorMax: 1,
          freeSlots: 0,
          rotationPressureDays: 7,
          readinessFilter: false,
          maxTasks: 2,
          taskUrgencyThresholdDays: 3,
          routineSelectionsByValue: const {},
        ),
      );

      expect(result.allocatedTasks.length, lessThanOrEqualTo(2));
      expect(result.anchorProjectIds.length, lessThanOrEqualTo(2));
    });
  });
}
