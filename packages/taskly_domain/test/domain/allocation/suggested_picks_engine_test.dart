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
  DateTime? deadlineDate,
  int? priority,
  DateTime? createdAt,
  DateTime? updatedAt,
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
    createdAt: createdAt ?? now,
    updatedAt: updatedAt ?? now,
    name: 'Task $id',
    completed: completed,
    deadlineDate: deadlineDate,
    priority: priority,
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
    testSafe('exposes strategy metadata', () async {
      final engine = SuggestedPicksEngine();
      expect(engine.strategyName, 'ProjectFirstAnchors');
      expect(engine.description, contains('anchor'));
    });

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

    testSafe('returns empty when all category weights are zero', () async {
      final now = DateTime(2025, 1, 15, 12);
      final tasks = [
        _task(id: 't1', now: now, valueId: 'v1'),
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
          categories: const {'v1': 0},
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

      expect(result.allocatedTasks, isEmpty);
      expect(
        result.reasoning.explanation,
        'No categories with weights defined',
      );
    });

    testSafe(
      'returns anchor-count-zero result when anchor count is zero',
      () async {
        final now = DateTime(2025, 1, 15, 12);
        final tasks = [
          _task(id: 't1', now: now, valueId: 'v1'),
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
            categories: const {'v1': 1},
            anchorCount: 0,
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

        expect(result.allocatedTasks, isEmpty);
        expect(result.reasoning.explanation, 'Anchor count is zero');
      },
    );

    testSafe(
      'readiness filter excludes values with no eligible tasks',
      () async {
        final now = DateTime(2025, 1, 15, 12);
        final value1 = _value(id: 'v1', now: now);
        final value2 = _value(id: 'v2', now: now);
        final project1 = Project(
          id: 'p1',
          createdAt: now,
          updatedAt: now,
          name: 'Project 1',
          completed: false,
          values: [value1],
          primaryValueId: value1.id,
        );
        final project2 = Project(
          id: 'p2',
          createdAt: now,
          updatedAt: now,
          name: 'Project 2',
          completed: false,
          values: [value2],
          primaryValueId: value2.id,
        );
        final tasks = [
          Task(
            id: 't1',
            createdAt: now,
            updatedAt: now,
            name: 'Task 1',
            completed: false,
            projectId: project1.id,
            project: project1,
          ),
        ];

        final engine = SuggestedPicksEngine();
        final result = engine.allocate(
          AllocationParameters(
            nowUtc: now,
            todayDayKeyUtc: DateTime(2025, 1, 15),
            tasks: tasks,
            projects: [project1, project2],
            projectAnchorStates: const [],
            categories: const {'v1': 1.0, 'v2': 1.0},
            anchorCount: 2,
            tasksPerAnchorMin: 0,
            tasksPerAnchorMax: 2,
            freeSlots: 0,
            rotationPressureDays: 7,
            readinessFilter: true,
            maxTasks: 2,
            taskUrgencyThresholdDays: 3,
            routineSelectionsByValue: const {},
          ),
        );

        expect(result.allocatedTasks, hasLength(1));
        expect(result.allocatedTasks.single.qualifyingValueId, 'v1');
      },
    );

    testSafe('includes urgency and priority reason codes', () async {
      final now = DateTime(2025, 1, 15, 12);
      final value = _value(id: 'v1', now: now);
      final project = Project(
        id: 'p1',
        createdAt: now,
        updatedAt: now,
        name: 'Project 1',
        completed: false,
        values: [value],
        primaryValueId: value.id,
      );
      final tasks = [
        Task(
          id: 'urgent',
          createdAt: now,
          updatedAt: now,
          name: 'Task urgent',
          completed: false,
          projectId: project.id,
          project: project,
          deadlineDate: DateTime(2025, 1, 16),
          priority: 1,
        ),
        Task(
          id: 'priority-only',
          createdAt: DateTime(2024, 12, 1),
          updatedAt: DateTime(2024, 12, 1),
          name: 'Task priority-only',
          completed: false,
          projectId: project.id,
          project: project,
          priority: 1,
        ),
      ];

      final engine = SuggestedPicksEngine();
      final result = engine.allocate(
        AllocationParameters(
          nowUtc: now,
          todayDayKeyUtc: DateTime(2025, 1, 15),
          tasks: tasks,
          projects: [project],
          projectAnchorStates: const [],
          categories: const {'v1': 1.0},
          anchorCount: 1,
          tasksPerAnchorMin: 0,
          tasksPerAnchorMax: 2,
          freeSlots: 0,
          rotationPressureDays: 7,
          readinessFilter: false,
          maxTasks: 2,
          taskUrgencyThresholdDays: 2,
          routineSelectionsByValue: const {},
        ),
      );

      expect(result.allocatedTasks, hasLength(2));
      final urgentTask = result.allocatedTasks.firstWhere(
        (entry) => entry.task.id == 'urgent',
      );
      final priorityTask = result.allocatedTasks.firstWhere(
        (entry) => entry.task.id == 'priority-only',
      );
      expect(urgentTask.reasonCodes, contains(AllocationReasonCode.urgency));
      expect(priorityTask.reasonCodes, contains(AllocationReasonCode.priority));
    });

    testSafe('free slots pick remaining tasks across projects', () async {
      final now = DateTime(2025, 1, 15, 12);
      final tasks = [
        _task(id: 'a1', now: now, valueId: 'v1', priority: 2),
        _task(id: 'a2', now: now, valueId: 'v1', priority: 3),
        _task(id: 'b1', now: now, valueId: 'v2', priority: 1),
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
          anchorCount: 1,
          tasksPerAnchorMin: 0,
          tasksPerAnchorMax: 1,
          freeSlots: 2,
          rotationPressureDays: 7,
          readinessFilter: false,
          maxTasks: 3,
          taskUrgencyThresholdDays: 3,
          routineSelectionsByValue: const {},
        ),
      );

      expect(result.allocatedTasks, hasLength(3));
      expect(
        result.allocatedTasks.map((entry) => entry.task.id),
        containsAll(<String>['a1', 'a2', 'b1']),
      );
      expect(result.excludedTasks, isEmpty);
    });

    testSafe(
      'returns no eligible values when only zero-weight value has projects',
      () async {
        final now = DateTime(2025, 1, 15, 12);
        final tasks = [
          _task(id: 't1', now: now, valueId: 'v1'),
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
            categories: const {'v1': 0, 'v2': 1},
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

        expect(result.allocatedTasks, isEmpty);
        expect(
          result.reasoning.explanation,
          'No eligible values for allocation',
        );
      },
    );

    testSafe('routine selections reduce quotas but never below zero', () async {
      final now = DateTime(2025, 1, 15, 12);
      final tasks = [
        _task(id: 'v1-a', now: now, valueId: 'v1'),
        _task(id: 'v2-a', now: now, valueId: 'v2'),
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
          categories: const {'v1': 1, 'v2': 1},
          anchorCount: 2,
          tasksPerAnchorMin: 0,
          tasksPerAnchorMax: 1,
          freeSlots: 0,
          rotationPressureDays: 7,
          readinessFilter: false,
          maxTasks: 2,
          taskUrgencyThresholdDays: 3,
          routineSelectionsByValue: const {
            'v1': 99,
            'v2': 1,
            'missing': 3,
          },
        ),
      );

      expect(result.reasoning.categoryAllocations['v1'], 0);
      expect(result.reasoning.categoryAllocations['v2'], 0);
      expect(result.allocatedTasks, hasLength(2));
    });

    testSafe(
      'group eligibility captures completed/unavailable/unrated exclusions',
      () async {
        final now = DateTime(2025, 1, 15, 12);
        final ratedValue = _value(id: 'v-rated', now: now);

        final completedProject = Project(
          id: 'p-completed',
          createdAt: now,
          updatedAt: now,
          name: 'Completed project',
          completed: true,
          values: [ratedValue],
          primaryValueId: ratedValue.id,
        );
        final unratedProject = Project(
          id: 'p-unrated',
          createdAt: now,
          updatedAt: now,
          name: 'Unrated project',
          completed: false,
        );
        final ratedProject = Project(
          id: 'p-rated',
          createdAt: now,
          updatedAt: now,
          name: 'Rated project',
          completed: false,
          values: [ratedValue],
          primaryValueId: ratedValue.id,
        );

        final tasks = <Task>[
          Task(
            id: 't-completed',
            createdAt: now,
            updatedAt: now,
            name: 'Completed task',
            completed: true,
            projectId: ratedProject.id,
            project: ratedProject,
          ),
          Task(
            id: 't-no-project',
            createdAt: now,
            updatedAt: now,
            name: 'No project',
            completed: false,
          ),
          Task(
            id: 't-unavailable-project',
            createdAt: now,
            updatedAt: now,
            name: 'Unavailable project',
            completed: false,
            projectId: completedProject.id,
            project: completedProject,
          ),
          Task(
            id: 't-unrated-project',
            createdAt: now,
            updatedAt: now,
            name: 'Unrated project',
            completed: false,
            projectId: unratedProject.id,
            project: unratedProject,
          ),
        ];

        final engine = SuggestedPicksEngine();
        final result = engine.allocate(
          AllocationParameters(
            nowUtc: now,
            todayDayKeyUtc: DateTime(2025, 1, 15),
            tasks: tasks,
            projects: [completedProject, unratedProject, ratedProject],
            projectAnchorStates: const [],
            categories: const {'v-rated': 1},
            anchorCount: 1,
            tasksPerAnchorMin: 0,
            tasksPerAnchorMax: 1,
            freeSlots: 0,
            rotationPressureDays: 7,
            readinessFilter: false,
            maxTasks: 1,
            taskUrgencyThresholdDays: 3,
            routineSelectionsByValue: const {},
          ),
        );

        expect(result.allocatedTasks, isEmpty);
        expect(result.excludedTasks, hasLength(4));
        expect(
          result.excludedTasks.map((e) => e.reason),
          containsAll(<String>[
            'Task is completed',
            'Task has no project',
            'Project is unavailable',
            'Project has no rated value',
          ]),
        );
      },
    );

    testSafe(
      'fallback anchor fill uses remaining projects when quotas cannot fill target',
      () async {
        final now = DateTime(2025, 1, 15, 12);
        final v1 = _value(id: 'v1', now: now);
        final v2 = _value(id: 'v2', now: now);

        final p1 = Project(
          id: 'p1',
          createdAt: now,
          updatedAt: now,
          name: 'A',
          completed: false,
          values: [v1],
          primaryValueId: v1.id,
        );
        final p2 = Project(
          id: 'p2',
          createdAt: now,
          updatedAt: now,
          name: 'B',
          completed: false,
          values: [v2],
          primaryValueId: v2.id,
        );

        final tasks = <Task>[
          Task(
            id: 't1',
            createdAt: now,
            updatedAt: now,
            name: 'T1',
            completed: false,
            projectId: p1.id,
            project: p1,
          ),
          Task(
            id: 't2',
            createdAt: now,
            updatedAt: now,
            name: 'T2',
            completed: false,
            projectId: p2.id,
            project: p2,
          ),
        ];

        final engine = SuggestedPicksEngine();
        final result = engine.allocate(
          AllocationParameters(
            nowUtc: now,
            todayDayKeyUtc: DateTime(2025, 1, 15),
            tasks: tasks,
            projects: [p1, p2],
            projectAnchorStates: const [],
            categories: const {'v1': 1, 'v2': 0},
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

        expect(result.anchorProjectIds, hasLength(2));
        expect(result.anchorProjectIds, containsAll(<String>['p1', 'p2']));
      },
    );
  });
}
