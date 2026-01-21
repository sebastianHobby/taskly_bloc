import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/my_day.dart' as my_day;
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/settings.dart' as settings;
import 'package:taskly_domain/time.dart';

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
    required DateTime dayKeyUtc,
    required List<Task> tasks,
    required List<Value> values,
    required settings.GlobalSettings globalSettings,
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

    final acceptedDueTasks = _resolveAcceptedTasks(acceptedDueIds, tasksById);
    final acceptedStartsTasks = _resolveAcceptedTasks(
      acceptedStartsIds,
      tasksById,
    );
    final acceptedFocusTasks = _resolveAcceptedTasks(
      acceptedFocusIds,
      tasksById,
    );

    final todaySelectedTaskIds = selectedIds.toSet();

    final today = dateOnly(dayKeyUtc);
    final dueLimit = _dueLimit(today, globalSettings.myDayDueWindowDays);

    final planned = _buildPlanned(
      tasks,
      today,
      globalSettings.myDayDueWindowDays,
    );
    final candidateDueIds = <String>[];
    final candidateStartsIds = <String>[];
    for (final task in planned) {
      if (_isDueWithinWindow(task, dueLimit)) {
        candidateDueIds.add(task.id);
        continue;
      }
      if (_isAvailableToStart(task, today)) {
        candidateStartsIds.add(task.id);
      }
    }

    final missingDueIds = candidateDueIds
        .where((id) => !todaySelectedTaskIds.contains(id))
        .toList(growable: false);
    final missingStartsIds = candidateStartsIds
        .where((id) => !todaySelectedTaskIds.contains(id))
        .toList(growable: false);

    final missingDueTasks = missingDueIds
        .map((id) => tasksById[id])
        .whereType<Task>()
        .where((t) => !_isCompleted(t))
        .toList(growable: false);
    final missingStartsTasks = missingStartsIds
        .map((id) => tasksById[id])
        .whereType<Task>()
        .where((t) => !_isCompleted(t))
        .toList(growable: false);

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
      tasks: orderedTasks,
      values: values,
      qualifyingByTaskId: qualifyingByTaskId,
      acceptedDue: acceptedDueTasks,
      acceptedStarts: acceptedStartsTasks,
      acceptedFocus: acceptedFocusTasks,
      dueAcceptedTotalCount: acceptedDueIds.length,
      startsAcceptedTotalCount: acceptedStartsIds.length,
      focusAcceptedTotalCount: acceptedFocusIds.length,
      selectedTotalCount: selectedIds.length,
      missingDueCount: missingDueIds.length,
      missingStartsCount: missingStartsIds.length,
      missingDueTasks: missingDueTasks,
      missingStartsTasks: missingStartsTasks,
      todaySelectedTaskIds: todaySelectedTaskIds,
    );
  }

  List<Task> _buildPlanned(
    List<Task> tasks,
    DateTime today,
    int dueWindowDays,
  ) {
    final dueSoonLimit = today.add(
      Duration(days: dueWindowDays.clamp(1, 30) - 1),
    );

    bool isPlanned(Task task) {
      if (_isCompleted(task)) return false;
      final start = dateOnlyOrNull(task.occurrence?.date ?? task.startDate);
      final deadline = dateOnlyOrNull(
        task.occurrence?.deadline ?? task.deadlineDate,
      );
      final startEligible = start != null && !start.isAfter(today);
      final dueSoon = deadline != null && !deadline.isAfter(dueSoonLimit);
      return startEligible || dueSoon;
    }

    return tasks.where(isPlanned).toList(growable: false);
  }

  DateTime? _deadlineDateOnly(Task task) {
    final raw = task.occurrence?.deadline ?? task.deadlineDate;
    return dateOnlyOrNull(raw);
  }

  DateTime? _startDateOnly(Task task) {
    final raw = task.occurrence?.date ?? task.startDate;
    return dateOnlyOrNull(raw);
  }

  bool _isAvailableToStart(Task task, DateTime today) {
    final start = _startDateOnly(task);
    return start != null && !start.isAfter(today);
  }

  bool _isDueWithinWindow(Task task, DateTime dueLimit) {
    final deadline = _deadlineDateOnly(task);
    return deadline != null && !deadline.isAfter(dueLimit);
  }

  DateTime _dueLimit(DateTime today, int dueWindowDays) {
    final days = dueWindowDays.clamp(1, 30);
    return today.add(Duration(days: days - 1));
  }

  MyDayViewModel _buildViewModel({
    required List<Task> tasks,
    required List<Value> values,
    required Map<String, String?> qualifyingByTaskId,
    List<Task> acceptedDue = const <Task>[],
    List<Task> acceptedStarts = const <Task>[],
    List<Task> acceptedFocus = const <Task>[],
    int dueAcceptedTotalCount = 0,
    int startsAcceptedTotalCount = 0,
    int focusAcceptedTotalCount = 0,
    int selectedTotalCount = 0,
    int missingDueCount = 0,
    int missingStartsCount = 0,
    List<Task> missingDueTasks = const <Task>[],
    List<Task> missingStartsTasks = const <Task>[],
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
      acceptedDue: acceptedDue,
      acceptedStarts: acceptedStarts,
      acceptedFocus: acceptedFocus,
      dueAcceptedTotalCount: dueAcceptedTotalCount,
      startsAcceptedTotalCount: startsAcceptedTotalCount,
      focusAcceptedTotalCount: focusAcceptedTotalCount,
      selectedTotalCount: selectedTotalCount,
      missingDueCount: missingDueCount,
      missingStartsCount: missingStartsCount,
      missingDueTasks: missingDueTasks,
      missingStartsTasks: missingStartsTasks,
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
