import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/my_day.dart' as my_day;
import 'package:taskly_domain/my_day.dart' show MyDayRitualStatus;
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/time.dart';

import 'package:taskly_bloc/presentation/screens/models/my_day_models.dart';

final class MyDayViewModelBuilder {
  const MyDayViewModelBuilder();

  MyDayViewModel fromAllocation({
    required AllocationResult allocation,
    required List<Value> values,
    required MyDayRitualStatus ritualStatus,
  }) {
    final tasks = allocation.allocatedTasks
        .map((entry) => entry.task)
        .toList(growable: false);

    final qualifyingByTaskId = {
      for (final entry in allocation.allocatedTasks)
        entry.task.id: entry.qualifyingValueId,
    };

    return _buildViewModel(
      tasks: tasks,
      plannedItems: const <MyDayPlannedItem>[],
      values: values,
      qualifyingByTaskId: qualifyingByTaskId,
      ritualStatus: ritualStatus,
    );
  }

  MyDayViewModel fromDailyPicks({
    required my_day.MyDayDayPicks dayPicks,
    required MyDayRitualStatus ritualStatus,
    required List<Task> tasks,
    required List<Value> values,
    required List<Routine> routines,
    required List<RoutineCompletion> routineCompletions,
    required List<RoutineSkip> routineSkips,
    RoutineScheduleService scheduleService = const RoutineScheduleService(),
  }) {
    final tasksById = {for (final task in tasks) task.id: task};
    final routinesById = {for (final routine in routines) routine.id: routine};

    final orderedPickIds = dayPicks.picks.toList(growable: false)
      ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

    final plannedItems = <MyDayPlannedItem>[];
    for (final pick in orderedPickIds) {
      final routineId = pick.routineId;
      if (routineId != null) {
        final routine = routinesById[routineId];
        if (routine == null) continue;
        final snapshot = scheduleService.buildSnapshot(
          routine: routine,
          dayKeyUtc: dayPicks.dayKeyUtc,
          completions: routineCompletions,
          skips: routineSkips,
        );
        final completionsInPeriod = _completionsForPeriod(
          routine: routine,
          snapshot: snapshot,
          completions: routineCompletions,
        );
        final completedToday = routineCompletions.any(
          (completion) =>
              completion.routineId == routineId &&
              dateOnly(
                completion.completedAtUtc,
              ).isAtSameMomentAs(dateOnly(dayPicks.dayKeyUtc)),
        );
        plannedItems.add(
          MyDayPlannedItem.routine(
            routine: routine,
            routineSnapshot: snapshot,
            completionsInPeriod: completionsInPeriod,
            bucket: pick.bucket,
            sortIndex: pick.sortIndex,
            qualifyingValueId: pick.qualifyingValueId ?? routine.valueId,
            completed: completedToday,
          ),
        );
        continue;
      }

      final taskId = pick.taskId;
      if (taskId == null) continue;
      final task = tasksById[taskId];
      if (task == null) continue;
      plannedItems.add(
        MyDayPlannedItem.task(
          task: task,
          bucket: pick.bucket,
          sortIndex: pick.sortIndex,
          qualifyingValueId:
              pick.qualifyingValueId ?? task.effectivePrimaryValueId,
        ),
      );
    }

    final selectedTaskIds = plannedItems
        .where((item) => item.type == MyDayPlannedItemType.task)
        .map((item) => item.id)
        .toSet();
    final selectedRoutineIds = plannedItems
        .where((item) => item.type == MyDayPlannedItemType.routine)
        .map((item) => item.id)
        .toSet();

    final orderedTasks = plannedItems
        .where(
          (item) =>
              item.type == MyDayPlannedItemType.task &&
              item.task != null &&
              !_isCompleted(item.task!),
        )
        .map((item) => item.task!)
        .toList(growable: false);

    final pinnedTasks = tasks
        .where((task) => !_isCompleted(task) && task.isPinned)
        .toList(growable: false);

    final completedPicks = plannedItems
        .where(
          (item) =>
              item.type == MyDayPlannedItemType.task &&
              item.task != null &&
              _isCompleted(item.task!),
        )
        .map((item) => item.task!)
        .toList(growable: false);

    final todaySelectedTaskIds = selectedTaskIds;

    final qualifyingByTaskId = <String, String?>{};
    for (final pick in dayPicks.picks) {
      final taskId = pick.taskId;
      if (taskId == null) continue;
      qualifyingByTaskId[taskId] = pick.qualifyingValueId;
    }
    for (final task in orderedTasks) {
      qualifyingByTaskId.putIfAbsent(
        task.id,
        () => task.effectivePrimaryValueId,
      );
    }

    return _buildViewModel(
      tasks: [...pinnedTasks, ...orderedTasks],
      plannedItems: plannedItems,
      values: values,
      qualifyingByTaskId: qualifyingByTaskId,
      ritualStatus: ritualStatus,
      pinnedTasks: pinnedTasks,
      completedPicks: completedPicks,
      selectedTotalCount: plannedItems.length,
      todaySelectedTaskIds: todaySelectedTaskIds,
      todaySelectedRoutineIds: selectedRoutineIds,
    );
  }

  List<RoutineCompletion> _completionsForPeriod({
    required Routine routine,
    required RoutineCadenceSnapshot snapshot,
    required List<RoutineCompletion> completions,
  }) {
    final periodStart = dateOnly(snapshot.periodStartUtc);
    final periodEnd = dateOnly(snapshot.periodEndUtc);
    final filtered = <RoutineCompletion>[];

    for (final completion in completions) {
      if (completion.routineId != routine.id) continue;
      final day = dateOnly(completion.completedAtUtc);
      if (day.isBefore(periodStart) || day.isAfter(periodEnd)) continue;
      filtered.add(completion);
    }

    return filtered;
  }

  MyDayViewModel _buildViewModel({
    required List<Task> tasks,
    required List<MyDayPlannedItem> plannedItems,
    required List<Value> values,
    required Map<String, String?> qualifyingByTaskId,
    required MyDayRitualStatus ritualStatus,
    List<Task> pinnedTasks = const <Task>[],
    List<Task> completedPicks = const <Task>[],
    int selectedTotalCount = 0,
    Set<String> todaySelectedTaskIds = const <String>{},
    Set<String> todaySelectedRoutineIds = const <String>{},
  }) {
    final valueById = {for (final value in values) value.id: value};

    for (final task in tasks) {
      for (final value in task.effectiveValues) {
        valueById.putIfAbsent(value.id, () => value);
      }
    }

    final doneCount = tasks.where(_isCompleted).length;
    final totalCount = tasks.length;

    return MyDayViewModel(
      tasks: tasks,
      plannedItems: plannedItems,
      ritualStatus: ritualStatus,
      summary: MyDaySummary(
        doneCount: doneCount,
        totalCount: totalCount,
      ),
      mix: MyDayMixVm.from(
        tasks: tasks,
        qualifyingByTaskId: qualifyingByTaskId,
        valueById: valueById,
      ),
      pinnedTasks: pinnedTasks,
      completedPicks: completedPicks,
      selectedTotalCount: selectedTotalCount,
      todaySelectedTaskIds: todaySelectedTaskIds,
      todaySelectedRoutineIds: todaySelectedRoutineIds,
    );
  }

  bool _isCompleted(Task task) {
    return task.occurrence?.isCompleted ?? task.completed;
  }
}
