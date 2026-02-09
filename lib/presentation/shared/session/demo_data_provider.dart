import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/my_day.dart' as my_day;
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/settings.dart' as settings;
import 'package:taskly_domain/time.dart';

import 'package:taskly_bloc/presentation/screens/models/my_day_models.dart';
import 'package:taskly_bloc/presentation/screens/bloc/plan_my_day_bloc.dart';

final class DemoDataProvider {
  DemoDataProvider({
    RoutineScheduleService scheduleService = const RoutineScheduleService(),
  }) : _scheduleService = scheduleService;

  final RoutineScheduleService _scheduleService;

  static final DateTime demoDayKeyUtc = DateTime.utc(2026, 1, 29);

  static const String demoProjectJapaneseId =
      '11111111-1111-1111-1111-111111111111';
  static const String demoProjectWebsiteId =
      '22222222-2222-2222-2222-222222222222';
  static const String demoProjectGymId = '33333333-3333-3333-3333-333333333333';
  static const String demoProjectDinnerId =
      '44444444-4444-4444-4444-444444444444';

  static const String demoTaskEditId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  static const String demoProjectDetailId = demoProjectJapaneseId;
  static const String demoRoutineGymId = '14141414-1414-1414-1414-141414141414';
  static const String demoRoutinePhotoShareId =
      '15151515-1515-1515-1515-151515151515';
  static const String demoRoutineVocabId =
      '16161616-1616-1616-1616-161616161616';
  static const String demoRoutineGuitarId =
      '17171717-1717-1717-1717-171717171717';

  late final List<Value> _values = [
    Value(
      id: '55555555-5555-5555-5555-555555555555',
      createdAt: demoDayKeyUtc,
      updatedAt: demoDayKeyUtc,
      name: 'Learning',
      color: '#6750A4',
      iconName: 'menu_book',
      priority: ValuePriority.high,
    ),
    Value(
      id: '66666666-6666-6666-6666-666666666666',
      createdAt: demoDayKeyUtc,
      updatedAt: demoDayKeyUtc,
      name: 'Health',
      color: '#2E7D32',
      iconName: 'health_and_safety',
      priority: ValuePriority.medium,
    ),
    Value(
      id: '77777777-7777-7777-7777-777777777777',
      createdAt: demoDayKeyUtc,
      updatedAt: demoDayKeyUtc,
      name: 'Social',
      color: '#C2185B',
      iconName: 'groups',
      priority: ValuePriority.low,
    ),
  ];

  late final Map<String, Value> _valuesById = {
    for (final value in _values) value.id: value,
  };

  late final List<Project> _projects = [
    Project(
      id: demoProjectJapaneseId,
      createdAt: demoDayKeyUtc,
      updatedAt: demoDayKeyUtc,
      name: 'Japanese Basics',
      completed: false,
      taskCount: 3,
      completedTaskCount: 1,
      deadlineDate: DateTime.utc(2026, 2, 5),
      priority: 1,
      values: [_valuesById['55555555-5555-5555-5555-555555555555']!],
      primaryValueId: '55555555-5555-5555-5555-555555555555',
    ),
    Project(
      id: demoProjectWebsiteId,
      createdAt: demoDayKeyUtc,
      updatedAt: demoDayKeyUtc,
      name: 'Website Refresh',
      completed: false,
      taskCount: 2,
      completedTaskCount: 0,
      deadlineDate: DateTime.utc(2026, 2, 10),
      priority: 2,
      values: [_valuesById['55555555-5555-5555-5555-555555555555']!],
      primaryValueId: '55555555-5555-5555-5555-555555555555',
    ),
    Project(
      id: demoProjectGymId,
      createdAt: demoDayKeyUtc,
      updatedAt: demoDayKeyUtc,
      name: 'Gym Routine',
      completed: false,
      taskCount: 2,
      completedTaskCount: 0,
      priority: 2,
      values: [_valuesById['66666666-6666-6666-6666-666666666666']!],
      primaryValueId: '66666666-6666-6666-6666-666666666666',
    ),
    Project(
      id: demoProjectDinnerId,
      createdAt: demoDayKeyUtc,
      updatedAt: demoDayKeyUtc,
      name: 'Dinner Party Menu',
      completed: false,
      taskCount: 3,
      completedTaskCount: 0,
      deadlineDate: DateTime.utc(2026, 2, 2),
      priority: 3,
      values: [_valuesById['77777777-7777-7777-7777-777777777777']!],
      primaryValueId: '77777777-7777-7777-7777-777777777777',
    ),
  ];

  late final Map<String, Project> _projectsById = {
    for (final project in _projects) project.id: project,
  };

  late final List<Task> _tasks = [
    Task(
      id: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
      createdAt: demoDayKeyUtc,
      updatedAt: demoDayKeyUtc,
      name: 'Complete Lesson 3',
      completed: false,
      deadlineDate: DateTime.utc(2026, 2, 1),
      priority: 1,
      projectId: demoProjectJapaneseId,
      project: _projectsById[demoProjectJapaneseId],
      values: _projectsById[demoProjectJapaneseId]!.values,
    ),
    Task(
      id: 'cccccccc-cccc-cccc-cccc-cccccccccccc',
      createdAt: demoDayKeyUtc,
      updatedAt: demoDayKeyUtc,
      name: 'Review Hiragana',
      completed: false,
      deadlineDate: DateTime.utc(2026, 2, 3),
      priority: 2,
      projectId: demoProjectJapaneseId,
      project: _projectsById[demoProjectJapaneseId],
      values: _projectsById[demoProjectJapaneseId]!.values,
    ),
    Task(
      id: demoTaskEditId,
      createdAt: demoDayKeyUtc,
      updatedAt: demoDayKeyUtc,
      name: 'Create country flashcards',
      completed: false,
      deadlineDate: DateTime.utc(2026, 2, 7),
      priority: 2,
      projectId: demoProjectJapaneseId,
      project: _projectsById[demoProjectJapaneseId],
      values: _projectsById[demoProjectJapaneseId]!.values,
    ),
    Task(
      id: 'dddddddd-dddd-dddd-dddd-dddddddddddd',
      createdAt: demoDayKeyUtc,
      updatedAt: demoDayKeyUtc,
      name: 'Homepage layout pass',
      completed: false,
      deadlineDate: DateTime.utc(2026, 2, 10),
      priority: 2,
      projectId: demoProjectWebsiteId,
      project: _projectsById[demoProjectWebsiteId],
      values: _projectsById[demoProjectWebsiteId]!.values,
    ),
    Task(
      id: 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
      createdAt: demoDayKeyUtc,
      updatedAt: demoDayKeyUtc,
      name: 'Draft hero copy',
      completed: false,
      deadlineDate: DateTime.utc(2026, 2, 8),
      priority: 1,
      projectId: demoProjectWebsiteId,
      project: _projectsById[demoProjectWebsiteId],
      values: _projectsById[demoProjectWebsiteId]!.values,
    ),
    Task(
      id: 'ffffffff-ffff-ffff-ffff-ffffffffffff',
      createdAt: demoDayKeyUtc,
      updatedAt: demoDayKeyUtc,
      name: 'Draft grocery list',
      completed: false,
      deadlineDate: DateTime.utc(2026, 2, 2),
      priority: 2,
      projectId: demoProjectDinnerId,
      project: _projectsById[demoProjectDinnerId],
      values: _projectsById[demoProjectDinnerId]!.values,
    ),
    Task(
      id: '99999999-9999-9999-9999-999999999999',
      createdAt: demoDayKeyUtc,
      updatedAt: demoDayKeyUtc,
      name: 'Finalize guest list',
      completed: false,
      deadlineDate: DateTime.utc(2026, 2, 1),
      priority: 3,
      projectId: demoProjectDinnerId,
      project: _projectsById[demoProjectDinnerId],
      values: _projectsById[demoProjectDinnerId]!.values,
    ),
    Task(
      id: '12121212-1212-1212-1212-121212121212',
      createdAt: demoDayKeyUtc,
      updatedAt: demoDayKeyUtc,
      name: 'Renew gym membership',
      completed: false,
      projectId: null,
    ),
    Task(
      id: '13131313-1313-1313-1313-131313131313',
      createdAt: demoDayKeyUtc,
      updatedAt: demoDayKeyUtc,
      name: 'Schedule photo walk',
      completed: false,
      startDate: DateTime.utc(2026, 2, 1),
      projectId: null,
    ),
  ];

  late final Map<String, Task> _tasksById = {
    for (final task in _tasks) task.id: task,
  };

  late final List<Routine> _routines = [
    Routine(
      id: demoRoutineGymId,
      createdAt: demoDayKeyUtc,
      updatedAt: demoDayKeyUtc,
      name: 'Gym session',
      valueId: '66666666-6666-6666-6666-666666666666',
      routineType: RoutineType.weeklyFixed,
      targetCount: 2,
      scheduleDays: const [DateTime.tuesday, DateTime.thursday],
      value: _valuesById['66666666-6666-6666-6666-666666666666'],
    ),
    Routine(
      id: demoRoutinePhotoShareId,
      createdAt: demoDayKeyUtc,
      updatedAt: demoDayKeyUtc,
      name: 'Weekly photo share',
      valueId: '77777777-7777-7777-7777-777777777777',
      routineType: RoutineType.weeklyFixed,
      targetCount: 1,
      scheduleDays: const [DateTime.saturday],
      value: _valuesById['77777777-7777-7777-7777-777777777777'],
    ),
    Routine(
      id: demoRoutineVocabId,
      createdAt: demoDayKeyUtc,
      updatedAt: demoDayKeyUtc,
      name: '15-min vocab drill',
      valueId: '55555555-5555-5555-5555-555555555555',
      routineType: RoutineType.weeklyFlexible,
      targetCount: 3,
      value: _valuesById['55555555-5555-5555-5555-555555555555'],
    ),
    Routine(
      id: demoRoutineGuitarId,
      createdAt: demoDayKeyUtc,
      updatedAt: demoDayKeyUtc,
      name: '20-min guitar practice',
      valueId: '55555555-5555-5555-5555-555555555555',
      routineType: RoutineType.weeklyFlexible,
      targetCount: 3,
      value: _valuesById['55555555-5555-5555-5555-555555555555'],
    ),
  ];

  late final List<RoutineCompletion> _routineCompletions = [
    RoutineCompletion(
      id: '18181818-1818-1818-1818-181818181818',
      routineId: demoRoutineVocabId,
      completedAtUtc: demoDayKeyUtc.subtract(const Duration(days: 2)),
      createdAtUtc: demoDayKeyUtc.subtract(const Duration(days: 2)),
    ),
  ];

  List<Value> get values => List<Value>.unmodifiable(_values);

  List<Project> get projects => List<Project>.unmodifiable(_projects);

  List<Task> get tasks => List<Task>.unmodifiable(_tasks);

  List<Routine> get routines => List<Routine>.unmodifiable(_routines);

  List<RoutineCompletion> get routineCompletions =>
      List<RoutineCompletion>.unmodifiable(_routineCompletions);

  List<RoutineSkip> get routineSkips => const <RoutineSkip>[];

  int get inboxTaskCount =>
      _tasks.where((task) => task.projectId == null).length;

  Project? projectById(String id) => _projectsById[id];

  Task? taskById(String id) => _tasksById[id];

  List<Task> tasksForProject(String projectId) {
    return _tasks
        .where((task) => task.projectId == projectId)
        .toList(growable: false);
  }

  MyDayViewModel buildMyDayViewModel() {
    final dayKey = demoDayKeyUtc;
    final picks = <my_day.MyDayPick>[
      my_day.MyDayPick.task(
        taskId: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
        bucket: my_day.MyDayPickBucket.valueSuggestions,
        sortIndex: 0,
        pickedAtUtc: demoDayKeyUtc,
        qualifyingValueId: '55555555-5555-5555-5555-555555555555',
      ),
      my_day.MyDayPick.task(
        taskId: 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
        bucket: my_day.MyDayPickBucket.due,
        sortIndex: 1,
        pickedAtUtc: demoDayKeyUtc,
        qualifyingValueId: '55555555-5555-5555-5555-555555555555',
      ),
      my_day.MyDayPick.routine(
        routineId: demoRoutineGymId,
        bucket: my_day.MyDayPickBucket.routine,
        sortIndex: 2,
        pickedAtUtc: demoDayKeyUtc,
        qualifyingValueId: '66666666-6666-6666-6666-666666666666',
      ),
      my_day.MyDayPick.task(
        taskId: demoTaskEditId,
        bucket: my_day.MyDayPickBucket.valueSuggestions,
        sortIndex: 3,
        pickedAtUtc: demoDayKeyUtc,
        qualifyingValueId: '55555555-5555-5555-5555-555555555555',
      ),
    ];

    final dayPicks = my_day.MyDayDayPicks(
      dayKeyUtc: dayKey,
      ritualCompletedAtUtc: demoDayKeyUtc,
      picks: picks,
    );

    final ritualStatus = my_day.MyDayRitualStatus.fromDayPicks(dayPicks);
    final tasks = _tasks;
    final routines = _routines;

    final routineSnapshots = {
      for (final routine in routines)
        routine.id: _scheduleService.buildSnapshot(
          routine: routine,
          dayKeyUtc: dayKey,
          completions: _routineCompletions,
          skips: routineSkips,
        ),
    };

    final routineItems = <MyDayPlannedItem>[];
    final taskItems = <MyDayPlannedItem>[];

    for (final pick in picks) {
      if (pick.targetType == my_day.MyDayPickTargetType.routine) {
        final routine = routines.firstWhere(
          (r) => r.id == pick.targetId,
        );
        final snapshot = routineSnapshots[routine.id];
        if (snapshot == null) continue;
        routineItems.add(
          MyDayPlannedItem.routine(
            routine: routine,
            routineSnapshot: snapshot,
            completionsInPeriod: _completionsForPeriod(
              routine: routine,
              snapshot: snapshot,
            ),
            bucket: pick.bucket,
            sortIndex: pick.sortIndex,
            qualifyingValueId: pick.qualifyingValueId,
            completed: false,
          ),
        );
      } else {
        final task = _tasksById[pick.targetId];
        if (task == null) continue;
        taskItems.add(
          MyDayPlannedItem.task(
            task: task,
            bucket: pick.bucket,
            sortIndex: pick.sortIndex,
            qualifyingValueId: pick.qualifyingValueId,
          ),
        );
      }
    }

    final plannedItems = [...routineItems, ...taskItems]
      ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

    final selectedTaskIds = dayPicks.selectedTaskIds;
    final selectedRoutineIds = dayPicks.selectedRoutineIds;

    final completedPicks = <Task>[];

    final summary = MyDaySummary(
      doneCount: 0,
      totalCount: plannedItems.length,
    );

    final valueById = _valuesById;
    final qualifyingByTaskId = {
      for (final pick in picks)
        if (pick.targetType == my_day.MyDayPickTargetType.task)
          pick.targetId: pick.qualifyingValueId,
    };

    final mix = MyDayMixVm.from(
      tasks: taskItems.map((e) => e.task!).toList(growable: false),
      qualifyingByTaskId: qualifyingByTaskId,
      valueById: valueById,
    );

    return MyDayViewModel(
      tasks: tasks,
      plannedItems: plannedItems,
      ritualStatus: ritualStatus,
      summary: summary,
      mix: mix,
      completedPicks: completedPicks,
      selectedTotalCount: plannedItems.length,
      todaySelectedTaskIds: selectedTaskIds,
      todaySelectedRoutineIds: selectedRoutineIds,
    );
  }

  PlanMyDayReady buildPlanMyDayReady() {
    final dayKeyUtc = demoDayKeyUtc;
    final suggestedTasks = [
      _tasksById['bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb']!,
      _tasksById[demoTaskEditId]!,
      _tasksById['eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee']!,
    ];
    final dueTodayTasks = [
      _tasksById['eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee']!,
      _tasksById['ffffffff-ffff-ffff-ffff-ffffffffffff']!,
    ];
    final plannedTasks = [
      _tasksById['13131313-1313-1313-1313-131313131313']!,
    ];

    final scheduledRoutines = _routines
        .where((r) => r.routineType == RoutineType.weeklyFixed)
        .map((routine) => _buildRoutineItem(routine, dayKeyUtc))
        .toList(growable: false);
    final flexibleRoutines = _routines
        .where((r) => r.routineType == RoutineType.weeklyFlexible)
        .map((routine) => _buildRoutineItem(routine, dayKeyUtc))
        .toList(growable: false);

    final selectedTaskIds = {
      'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
      'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
      'ffffffff-ffff-ffff-ffff-ffffffffffff',
      '13131313-1313-1313-1313-131313131313',
    };
    final selectedRoutineIds = {
      demoRoutineGymId,
      demoRoutineVocabId,
    };

    final groups = _buildValueSuggestionGroups(
      suggestedTasks,
      selectedTaskIds: selectedTaskIds,
    );

    return PlanMyDayReady(
      needsPlan: true,
      dayKeyUtc: dayKeyUtc,
      globalSettings: const settings.GlobalSettings(),
      suggestionSignal: SuggestionSignal.behaviorBased,
      dailyLimit: 8,
      requiresValueSetup: false,
      requiresRatings: false,
      dueTodayTasks: dueTodayTasks,
      plannedTasks: plannedTasks,
      suggested: suggestedTasks,
      scheduledRoutines: scheduledRoutines,
      flexibleRoutines: flexibleRoutines,
      allRoutines: [...scheduledRoutines, ...flexibleRoutines],
      selectedTaskIds: selectedTaskIds,
      selectedRoutineIds: selectedRoutineIds,
      allTasks: tasks,
      routineSelectionsByValue: _routineSelectionsByValue(selectedRoutineIds),
      valueSuggestionGroups: groups,
      valueSort: PlanMyDayValueSort.attentionFirst,
      spotlightTaskId: suggestedTasks.first.id,
      overCapacity: false,
      toastRequestId: 0,
    );
  }

  ScheduledOccurrencesResult buildScheduledOccurrences({
    required DateTime rangeStartDay,
    required DateTime rangeEndDay,
  }) {
    final today = demoDayKeyUtc;
    final overdueTask = _tasksById['99999999-9999-9999-9999-999999999999']!;
    final dueTodayTask = _tasksById['bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb']!;
    final dueTomorrowTask = _tasksById['ffffffff-ffff-ffff-ffff-ffffffffffff']!;
    final laterTask = _tasksById['eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee']!;

    final overdue = [
      ScheduledOccurrence.forTask(
        ref: ScheduledOccurrenceRef(
          entityType: EntityType.task,
          entityId: overdueTask.id,
          localDay: today.subtract(const Duration(days: 1)),
          tag: ScheduledDateTag.due,
        ),
        name: overdueTask.name,
        task: overdueTask,
      ),
    ];

    final occurrences = [
      ScheduledOccurrence.forTask(
        ref: ScheduledOccurrenceRef(
          entityType: EntityType.task,
          entityId: dueTodayTask.id,
          localDay: today,
          tag: ScheduledDateTag.due,
        ),
        name: dueTodayTask.name,
        task: dueTodayTask,
      ),
      ScheduledOccurrence.forTask(
        ref: ScheduledOccurrenceRef(
          entityType: EntityType.task,
          entityId: dueTomorrowTask.id,
          localDay: today.add(const Duration(days: 1)),
          tag: ScheduledDateTag.due,
        ),
        name: dueTomorrowTask.name,
        task: dueTomorrowTask,
      ),
      ScheduledOccurrence.forTask(
        ref: ScheduledOccurrenceRef(
          entityType: EntityType.task,
          entityId: laterTask.id,
          localDay: today.add(const Duration(days: 7)),
          tag: ScheduledDateTag.due,
        ),
        name: laterTask.name,
        task: laterTask,
      ),
    ];

    final filtered = occurrences
        .where((o) {
          return !o.localDay.isBefore(rangeStartDay) &&
              !o.localDay.isAfter(rangeEndDay);
        })
        .toList(growable: false);

    return ScheduledOccurrencesResult(
      rangeStartDay: rangeStartDay,
      rangeEndDay: rangeEndDay,
      overdue: overdue,
      occurrences: filtered,
    );
  }

  PlanMyDayRoutineItem _buildRoutineItem(
    Routine routine,
    DateTime dayKeyUtc,
  ) {
    final snapshot = _scheduleService.buildSnapshot(
      routine: routine,
      dayKeyUtc: dayKeyUtc,
      completions: _routineCompletions,
      skips: routineSkips,
    );
    final isScheduled = routine.routineType == RoutineType.weeklyFixed;
    return PlanMyDayRoutineItem(
      routine: routine,
      snapshot: snapshot,
      selected:
          routine.id == demoRoutineGymId || routine.id == demoRoutineVocabId,
      completedToday: false,
      isCatchUpDay: false,
      isScheduled: isScheduled,
      isEligibleToday: true,
      lastScheduledDayUtc: null,
      completionsInPeriod: _completionsForPeriod(
        routine: routine,
        snapshot: snapshot,
      ),
    );
  }

  List<RoutineCompletion> _completionsForPeriod({
    required Routine routine,
    required RoutineCadenceSnapshot snapshot,
  }) {
    final periodStart = dateOnly(snapshot.periodStartUtc);
    final periodEnd = dateOnly(snapshot.periodEndUtc);
    return _routineCompletions
        .where((completion) => completion.routineId == routine.id)
        .where((completion) {
          final day = dateOnly(completion.completedAtUtc);
          return !day.isBefore(periodStart) && !day.isAfter(periodEnd);
        })
        .toList(growable: false);
  }

  Map<String, int> _routineSelectionsByValue(Set<String> routineIds) {
    final counts = <String, int>{};
    for (final routine in _routines) {
      if (!routineIds.contains(routine.id)) continue;
      counts[routine.valueId] = (counts[routine.valueId] ?? 0) + 1;
    }
    return counts;
  }

  List<PlanMyDayValueSuggestionGroup> _buildValueSuggestionGroups(
    List<Task> tasks, {
    required Set<String> selectedTaskIds,
  }) {
    final byValue = <String, List<Task>>{};
    for (final task in tasks) {
      final valueId = task.effectivePrimaryValueId;
      if (valueId == null) continue;
      byValue.putIfAbsent(valueId, () => []).add(task);
    }

    final groups = <PlanMyDayValueSuggestionGroup>[];
    for (final entry in byValue.entries) {
      final value = _valuesById[entry.key];
      if (value == null) continue;
      groups.add(
        PlanMyDayValueSuggestionGroup(
          valueId: value.id,
          value: value,
          tasks: entry.value,
          attentionNeeded: value.priority == ValuePriority.high,
          neglectScore: value.priority == ValuePriority.high ? 0.4 : 0.1,
          visibleCount: _minVisibleCount(
            entry.value.length,
            value.priority,
            attentionNeeded: value.priority == ValuePriority.high,
          ),
          expanded: true,
          isSpotlight: value.id == _values.first.id,
        ),
      );
    }

    return groups;
  }

  int _minVisibleCount(
    int taskCount,
    ValuePriority priority, {
    required bool attentionNeeded,
  }) {
    final defaultVisible = switch (priority) {
      ValuePriority.high => attentionNeeded ? 4 : 3,
      ValuePriority.medium => attentionNeeded ? 3 : 2,
      ValuePriority.low => attentionNeeded ? 2 : 1,
    };
    return taskCount < defaultVisible ? taskCount : defaultVisible;
  }
}
