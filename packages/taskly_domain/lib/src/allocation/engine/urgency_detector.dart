import 'package:taskly_domain/src/core/model/project.dart';
import 'package:taskly_domain/src/allocation/model/allocation_config.dart';
import 'package:taskly_domain/src/core/model/task.dart';
import 'package:taskly_domain/src/services/values/effective_values.dart';

/// Shared urgency detection logic for tasks and projects.
///
/// Urgency is determined by proximity to deadline:
/// - Tasks are urgent when deadline is within [taskThresholdDays]
/// - Projects are urgent when deadline is within [projectThresholdDays]
class UrgencyDetector {
  const UrgencyDetector({
    required this.taskThresholdDays,
    required this.projectThresholdDays,
  });

  /// Creates an UrgencyDetector from AllocationConfig.
  factory UrgencyDetector.fromConfig(AllocationConfig config) {
    return UrgencyDetector(
      taskThresholdDays: config.strategySettings.taskUrgencyThresholdDays,
      projectThresholdDays: config.strategySettings.projectUrgencyThresholdDays,
    );
  }

  /// Days before deadline at which a task becomes urgent.
  final int taskThresholdDays;

  /// Days before deadline at which a project becomes urgent.
  final int projectThresholdDays;

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

  /// Returns true if [project] is urgent based on its deadline.
  ///
  /// A project is urgent if:
  /// - It has a deadline, AND
  /// - The deadline is within [projectThresholdDays] days from now
  bool isProjectUrgent(Project project, {required DateTime todayDayKeyUtc}) {
    final deadline = project.deadlineDate;
    if (deadline == null) return false;

    final daysUntilDeadline = deadline.difference(todayDayKeyUtc).inDays;
    return daysUntilDeadline <= projectThresholdDays;
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

  /// Filters [projects] to return only urgent projects.
  List<Project> findUrgentProjects(
    List<Project> projects, {
    required DateTime todayDayKeyUtc,
  }) {
    return projects
        .where((p) => isProjectUrgent(p, todayDayKeyUtc: todayDayKeyUtc))
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
