@Tags(['unit'])
library;

import '../../../helpers/test_imports.dart';

import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/preferences.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/settings.dart';
import 'package:taskly_domain/src/projects/model/project_anchor_state.dart';
import 'package:taskly_domain/src/services/suggestions/task_suggestion_service.dart';
import 'package:taskly_domain/src/services/time/home_day_key_service.dart';
import 'package:taskly_domain/src/time/clock.dart';
import 'package:taskly_domain/src/values/model/value_weekly_rating.dart';
import 'package:taskly_domain/telemetry.dart';

void main() {
  testSafe(
    'getSnapshot uses target-count allocation when target is provided',
    () async {
      final now = DateTime.utc(2026, 2, 22, 9);
      final value = _value('v1');
      final taskA = _task(id: 't1', value: value);
      final taskB = _task(
        id: 't2',
        value: value,
        snoozedUntilUtc: now.add(const Duration(hours: 2)),
      );

      final orchestrator = _StubAllocationOrchestrator(
        batchResult: _allocation([taskA, taskB], valueId: 'v1'),
        targetResult: _allocation([taskA, taskB], valueId: 'v1'),
      );
      final taskRepo = _TaskRepoFake();
      final ratingsRepo = _RatingsRepoFake();
      final service = TaskSuggestionService(
        allocationOrchestrator: orchestrator,
        taskRepository: taskRepo,
        valueRatingsRepository: ratingsRepo,
        dayKeyService: _dayKeyService(),
        clock: _FixedClock(now),
      );

      final context = OperationContext(
        correlationId: 'c1',
        feature: 'my_day',
        intent: 'load_suggestions',
        operation: 'suggestions.snapshot',
      );
      final snapshot = await service.getSnapshot(
        batchCount: 2,
        suggestedTargetCount: 3,
        tasksOverride: <Task>[taskA, taskB],
        context: context,
        nowUtc: now,
      );

      expect(orchestrator.targetCalls, 1);
      expect(orchestrator.batchCalls, 0);
      expect(orchestrator.lastTarget, 3);
      expect(orchestrator.lastContext, context);
      expect(snapshot.snoozed.map((t) => t.id), <String>['t2']);
      expect(snapshot.suggested.map((s) => s.task.id), <String>['t1']);
      expect(snapshot.suggested.single.rank, 1);
    },
  );

  testSafe('getSnapshot uses batch allocation when target is absent', () async {
    final now = DateTime.utc(2026, 2, 22, 9);
    final value = _value('v1');
    final tasks = <Task>[
      for (var i = 0; i < 10; i++) _task(id: 't$i', value: value),
    ];

    final orchestrator = _StubAllocationOrchestrator(
      batchResult: _allocation(tasks, valueId: 'v1'),
      targetResult: _allocation(const <Task>[], valueId: 'v1'),
    );
    final taskRepo = _TaskRepoFake();
    final ratingsRepo = _RatingsRepoFake(
      ratings: <ValueWeeklyRating>[
        for (var i = 0; i < 4; i++)
          ValueWeeklyRating(
            id: 'r_recent_$i',
            valueId: 'v1',
            weekStartUtc: DateTime.utc(2026, 2, 2).subtract(
              Duration(days: i * 7),
            ),
            rating: 4,
            createdAtUtc: now,
            updatedAtUtc: now,
          ),
      ],
    );
    final service = TaskSuggestionService(
      allocationOrchestrator: orchestrator,
      taskRepository: taskRepo,
      valueRatingsRepository: ratingsRepo,
      dayKeyService: _dayKeyService(),
      clock: _FixedClock(now),
    );

    final snapshot = await service.getSnapshot(
      batchCount: 2,
      tasksOverride: tasks,
      nowUtc: now,
    );

    expect(orchestrator.batchCalls, 1);
    expect(orchestrator.targetCalls, 0);
    expect(orchestrator.lastBatchCount, 2);
    expect(ratingsRepo.lastWeeks, 8);
    // For low average values: visible=2, poolExtra=6 => capped at 8.
    expect(snapshot.suggested.length, 8);
    expect(snapshot.suggested.first.rank, 1);
    expect(snapshot.suggested.last.rank, 8);
  });

  testSafe(
    'getSnapshot falls back to task repository when override is omitted',
    () async {
      final now = DateTime.utc(2026, 2, 22, 9);
      final value = _value('v1');
      final task = _task(id: 'repo-task', value: value);
      final orchestrator = _StubAllocationOrchestrator(
        batchResult: _allocation(<Task>[task], valueId: 'v1'),
        targetResult: _allocation(<Task>[task], valueId: 'v1'),
      );
      final taskRepo = _TaskRepoFake(tasks: <Task>[task]);
      final ratingsRepo = _RatingsRepoFake();
      final service = TaskSuggestionService(
        allocationOrchestrator: orchestrator,
        taskRepository: taskRepo,
        valueRatingsRepository: ratingsRepo,
        dayKeyService: _dayKeyService(),
        clock: _FixedClock(now),
      );

      final snapshot = await service.getSnapshot(batchCount: 1, nowUtc: now);

      expect(taskRepo.getAllCalls, 1);
      expect(taskRepo.lastQuery, isA<TaskQuery>());
      expect(snapshot.suggested.single.task.id, 'repo-task');
    },
  );

  testSafe(
    'getSnapshot excludes due and planned tasks from suggested shelf',
    () async {
      final now = DateTime.utc(2026, 2, 22, 9);
      final dayKey = DateTime.utc(2026, 2, 22);
      final value = _value('v1');
      final dueTask = _task(
        id: 'task-due',
        value: value,
        deadlineDate: dayKey,
      );
      final plannedTask = _task(
        id: 'task-planned',
        value: value,
        startDate: dayKey,
      );
      final suggestedTask = _task(id: 'task-suggested', value: value);

      final orchestrator = _StubAllocationOrchestrator(
        batchResult: _allocation(
          [dueTask, plannedTask, suggestedTask],
          valueId: value.id,
        ),
        targetResult: _allocation(
          [dueTask, plannedTask, suggestedTask],
          valueId: value.id,
        ),
      );
      final service = TaskSuggestionService(
        allocationOrchestrator: orchestrator,
        taskRepository: _TaskRepoFake(),
        valueRatingsRepository: _RatingsRepoFake(),
        dayKeyService: _dayKeyService(),
        clock: _FixedClock(now),
      );

      final snapshot = await service.getSnapshot(
        batchCount: 1,
        tasksOverride: [dueTask, plannedTask, suggestedTask],
        nowUtc: now,
      );

      expect(snapshot.suggested.map((entry) => entry.task.id), [
        suggestedTask.id,
      ]);
    },
  );
}

HomeDayKeyService _dayKeyService() {
  return HomeDayKeyService(settingsRepository: _SettingsRepoNoop());
}

AllocationResult _allocation(List<Task> tasks, {required String valueId}) {
  return AllocationResult(
    allocatedTasks: <AllocatedTask>[
      for (final task in tasks)
        AllocatedTask(
          task: task,
          qualifyingValueId: valueId,
          allocationScore: 0.9,
          reasonCodes: const <AllocationReasonCode>[
            AllocationReasonCode.valueAlignment,
          ],
        ),
    ],
    reasoning: const AllocationReasoning(
      strategyUsed: 'test',
      categoryAllocations: <String, int>{},
      categoryWeights: <String, double>{},
    ),
    excludedTasks: const <ExcludedTask>[],
    requiresRatings: false,
    requiresValueSetup: false,
  );
}

Value _value(String id) {
  final now = DateTime.utc(2026, 1, 1);
  return Value(id: id, createdAt: now, updatedAt: now, name: 'Value $id');
}

Task _task({
  required String id,
  required Value value,
  DateTime? snoozedUntilUtc,
  DateTime? deadlineDate,
  DateTime? startDate,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Task(
    id: id,
    createdAt: now,
    updatedAt: now,
    name: 'Task $id',
    completed: false,
    myDaySnoozedUntilUtc: snoozedUntilUtc,
    deadlineDate: deadlineDate,
    startDate: startDate,
    project: Project(
      id: 'p_$id',
      createdAt: now,
      updatedAt: now,
      name: 'Project',
      completed: false,
      values: <Value>[value],
      primaryValueId: value.id,
    ),
  );
}

final class _StubAllocationOrchestrator extends AllocationOrchestrator {
  _StubAllocationOrchestrator({
    required this.batchResult,
    required this.targetResult,
  }) : super(
         taskRepository: _TaskRepoNoop(),
         valueRepository: _ValueRepoNoop(),
         valueRatingsRepository: _RatingsRepoNoop(),
         settingsRepository: _SettingsRepoNoop(),
         projectRepository: _ProjectRepoNoop(),
         projectAnchorStateRepository: _ProjectAnchorRepoNoop(),
         dayKeyService: HomeDayKeyService(
           settingsRepository: _SettingsRepoNoop(),
         ),
       );

  final AllocationResult batchResult;
  final AllocationResult targetResult;

  int batchCalls = 0;
  int targetCalls = 0;
  int? lastBatchCount;
  int? lastTarget;
  OperationContext? lastContext;

  @override
  Future<AllocationResult> getSuggestedSnapshot({
    required int batchCount,
    DateTime? nowUtc,
    Map<String, int> routineSelectionsByValue = const {},
    OperationContext? context,
  }) async {
    batchCalls++;
    lastBatchCount = batchCount;
    lastContext = context;
    return batchResult;
  }

  @override
  Future<AllocationResult> getSuggestedSnapshotForTargetCount({
    required int suggestedTaskTarget,
    DateTime? nowUtc,
    Map<String, int> routineSelectionsByValue = const {},
    OperationContext? context,
  }) async {
    targetCalls++;
    lastTarget = suggestedTaskTarget;
    lastContext = context;
    return targetResult;
  }
}

final class _TaskRepoFake implements TaskRepositoryContract {
  _TaskRepoFake({this.tasks = const <Task>[]});

  final List<Task> tasks;
  int getAllCalls = 0;
  TaskQuery? lastQuery;

  @override
  Future<List<Task>> getAll([TaskQuery? query]) async {
    getAllCalls++;
    lastQuery = query;
    return tasks;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _RatingsRepoFake implements ValueRatingsRepositoryContract {
  _RatingsRepoFake({this.ratings = const <ValueWeeklyRating>[]});

  final List<ValueWeeklyRating> ratings;
  int? lastWeeks;

  @override
  Future<List<ValueWeeklyRating>> getAll({int weeks = 4}) async {
    lastWeeks = weeks;
    return ratings;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _TaskRepoNoop implements TaskRepositoryContract {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _ValueRepoNoop implements ValueRepositoryContract {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _RatingsRepoNoop implements ValueRatingsRepositoryContract {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _SettingsRepoNoop implements SettingsRepositoryContract {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _ProjectRepoNoop implements ProjectRepositoryContract {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _ProjectAnchorRepoNoop
    implements ProjectAnchorStateRepositoryContract {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FixedClock implements Clock {
  const _FixedClock(this.now);

  final DateTime now;

  @override
  DateTime nowLocal() => now.toLocal();

  @override
  DateTime nowUtc() => now;
}
