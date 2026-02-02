import 'package:taskly_domain/src/allocation/model/allocation_config.dart';
import 'package:taskly_domain/src/core/model/task.dart';
import 'package:taskly_domain/src/services/values/effective_values.dart';

/// Shared urgency detection logic for tasks.
///
/// Urgency is determined by proximity to deadline:
/// - Tasks are urgent when deadline is within [taskThresholdDays]
class UrgencyDetector {
  const UrgencyDetector({
    required this.taskThresholdDays,
  });

  /// Creates an UrgencyDetector from AllocationConfig.
  factory UrgencyDetector.fromConfig(AllocationConfig config) {
    return UrgencyDetector(
      taskThresholdDays: config.strategySettings.taskUrgencyThresholdDays,
    );
  }

  /// Days before deadline at which a task becomes urgent.
  final int taskThresholdDays;

  /// Returns true if [task] is urgent based on its deadline.
  ///
  /// A task is urgent if:
  /// - It has a deadline, AND
  /// - The deadline is within [taskThresholdDays] days from now
  bool isTaskUrgent(Task task, {required DateTime todayDayKeyUtc}) {
    final deadline = task.deadlineDate;
    if (deadline == null) return false;

    final daysUntilDeadline = deadline.difference(todayDayKeyUtc).inDays;
    return daysUntilDeadline <= taskThresholdDays;
  }

  /// Filters [tasks] to return only urgent tasks.
  List<Task> findUrgentTasks(
    List<Task> tasks, {
    required DateTime todayDayKeyUtc,
  }) {
    return tasks
        .where((t) => isTaskUrgent(t, todayDayKeyUtc: todayDayKeyUtc))
        .toList();
  }

  /// Returns tasks that are urgent but have no value assigned.
  ///
  /// These are the tasks that trigger warnings in `warnOnly` mode
  /// or get included in `includeAll` mode.
  List<Task> findUrgentValuelessTasks(
    List<Task> tasks, {
    required DateTime todayDayKeyUtc,
  }) {
    return tasks.where((task) {
      final hasNoValue = task.isEffectivelyValueless;
      return hasNoValue && isTaskUrgent(task, todayDayKeyUtc: todayDayKeyUtc);
    }).toList();
  }
}
