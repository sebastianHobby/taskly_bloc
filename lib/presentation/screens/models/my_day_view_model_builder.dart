import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/my_day.dart' as my_day;
import 'package:taskly_domain/services.dart';

import 'package:taskly_bloc/presentation/screens/models/my_day_models.dart';

final class MyDayViewModelBuilder {
  const MyDayViewModelBuilder();

  MyDayViewModel fromAllocation({
    required AllocationResult allocation,
    required List<Value> values,
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
      values: values,
      qualifyingByTaskId: qualifyingByTaskId,
    );
  }

  MyDayViewModel fromDailyPicks({
    required my_day.MyDayDayPicks dayPicks,
    required List<Task> tasks,
    required List<Value> values,
  }) {
    final tasksById = {for (final task in tasks) task.id: task};

    final orderedPickIds = dayPicks.picks.toList(growable: false)
      ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

    final selectedIds = orderedPickIds
        .map((p) => p.taskId)
        .toList(growable: false);

    final orderedTasks = selectedIds
        .map((id) => tasksById[id])
        .whereType<Task>()
        .where((task) => !_isCompleted(task))
        .toList(growable: false);

    final pinnedTasks = tasks
        .where((task) => !_isCompleted(task) && task.isPinned)
        .toList(growable: false);
    final pinnedIds = pinnedTasks.map((task) => task.id).toSet();

    final completedPicks = selectedIds
        .map((id) => tasksById[id])
        .whereType<Task>()
        .where(_isCompleted)
        .toList(growable: false);

    Iterable<String> idsForBucket(my_day.MyDayPickBucket bucket) {
      return orderedPickIds
          .where((p) => p.bucket == bucket)
          .map((p) => p.taskId);
    }

    final acceptedDueIds = idsForBucket(
      my_day.MyDayPickBucket.due,
    ).toList(growable: false);
    final acceptedStartsIds = idsForBucket(
      my_day.MyDayPickBucket.starts,
    ).toList(growable: false);
    final acceptedFocusIds = idsForBucket(
      my_day.MyDayPickBucket.focus,
    ).toList(growable: false);

    final acceptedDueTasks = _resolveAcceptedTasks(
      acceptedDueIds,
      tasksById,
    ).where((task) => !pinnedIds.contains(task.id)).toList(growable: false);
    final acceptedStartsTasks = _resolveAcceptedTasks(
      acceptedStartsIds,
      tasksById,
    ).where((task) => !pinnedIds.contains(task.id)).toList(growable: false);
    final acceptedFocusTasks = _resolveAcceptedTasks(
      acceptedFocusIds,
      tasksById,
    ).where((task) => !pinnedIds.contains(task.id)).toList(growable: false);

    final todaySelectedTaskIds = selectedIds.toSet();

    final qualifyingByTaskId = <String, String?>{};
    for (final pick in dayPicks.picks) {
      qualifyingByTaskId[pick.taskId] = pick.qualifyingValueId;
    }
    for (final task in orderedTasks) {
      qualifyingByTaskId.putIfAbsent(
        task.id,
        () => task.effectivePrimaryValueId,
      );
    }

    return _buildViewModel(
      tasks: [...pinnedTasks, ...orderedTasks],
      values: values,
      qualifyingByTaskId: qualifyingByTaskId,
      pinnedTasks: pinnedTasks,
      acceptedDue: acceptedDueTasks,
      acceptedStarts: acceptedStartsTasks,
      acceptedFocus: acceptedFocusTasks,
      completedPicks: completedPicks,
      selectedTotalCount: selectedIds.length,
      todaySelectedTaskIds: todaySelectedTaskIds,
    );
  }

  MyDayViewModel _buildViewModel({
    required List<Task> tasks,
    required List<Value> values,
    required Map<String, String?> qualifyingByTaskId,
    List<Task> pinnedTasks = const <Task>[],
    List<Task> acceptedDue = const <Task>[],
    List<Task> acceptedStarts = const <Task>[],
    List<Task> acceptedFocus = const <Task>[],
    List<Task> completedPicks = const <Task>[],
    int selectedTotalCount = 0,
    Set<String> todaySelectedTaskIds = const <String>{},
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
      acceptedDue: acceptedDue,
      acceptedStarts: acceptedStarts,
      acceptedFocus: acceptedFocus,
      completedPicks: completedPicks,
      selectedTotalCount: selectedTotalCount,
      todaySelectedTaskIds: todaySelectedTaskIds,
    );
  }

  List<Task> _resolveAcceptedTasks(
    Iterable<String> ids,
    Map<String, Task> tasksById,
  ) {
    return ids
        .map((id) => tasksById[id])
        .whereType<Task>()
        .where((task) => !_isCompleted(task))
        .toList(growable: false);
  }

  bool _isCompleted(Task task) {
    return task.occurrence?.isCompleted ?? task.completed;
  }
}
