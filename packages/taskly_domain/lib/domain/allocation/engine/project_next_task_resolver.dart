import '../../core/model/project.dart';
import '../model/allocation_config.dart';
import '../../core/model/task.dart';

/// Determines the recommended next task for a project.
///
/// Resolution priority:
/// 1. Tasks already in Focus (user explicitly prioritized)
/// 2. Urgent tasks (deadline within threshold)
/// 3. Tasks with values (value-aligned)
/// 4. Oldest incomplete task (FIFO fallback)
class ProjectNextTaskResolver {
  const ProjectNextTaskResolver();

  /// Returns the recommended next task for [project], or null if no tasks.
  ///
  /// [projectTasks] should be incomplete tasks belonging to [project].
  /// [focusTaskIds] are IDs of tasks currently in the Focus list.
  /// [config] provides urgency thresholds.
  Task? getNextTask({
    required Project project,
    required List<Task> projectTasks,
    required Set<String> focusTaskIds,
    required AllocationConfig config,
  }) {
    if (projectTasks.isEmpty) return null;

    // Priority 1: Task already in Focus
    final inFocus = projectTasks.where(
      (t) => focusTaskIds.contains(t.id),
    );
    if (inFocus.isNotEmpty) {
      return _selectBest(inFocus.toList(), config);
    }

    // Priority 2: Urgent tasks (deadline within threshold)
    final urgent = projectTasks.where((t) {
      if (t.deadlineDate == null) return false;
      final daysUntil = t.deadlineDate!.difference(DateTime.now()).inDays;
      return daysUntil <= config.strategySettings.taskUrgencyThresholdDays;
    });
    if (urgent.isNotEmpty) {
      return _selectMostUrgent(urgent.toList());
    }

    // Priority 3: Tasks with values
    final withValues = projectTasks.where(
      (t) => t.values.isNotEmpty,
    );
    if (withValues.isNotEmpty) {
      return _selectBest(withValues.toList(), config);
    }

    // Priority 4: Oldest task (FIFO)
    return _selectOldest(projectTasks);
  }

  /// Select the "best" task from a list (by deadline, then creation date).
  Task _selectBest(List<Task> tasks, AllocationConfig config) {
    final sorted = List<Task>.from(tasks);
    sorted.sort((a, b) {
      // Tasks with deadlines come first
      if (a.deadlineDate != null && b.deadlineDate == null) return -1;
      if (a.deadlineDate == null && b.deadlineDate != null) return 1;
      if (a.deadlineDate != null && b.deadlineDate != null) {
        return a.deadlineDate!.compareTo(b.deadlineDate!);
      }
      // Fall back to creation date
      return a.createdAt.compareTo(b.createdAt);
    });
    return sorted.first;
  }

  /// Select the task with the nearest deadline.
  Task _selectMostUrgent(List<Task> tasks) {
    final sorted = List<Task>.from(tasks);
    sorted.sort((a, b) => a.deadlineDate!.compareTo(b.deadlineDate!));
    return sorted.first;
  }

  /// Select the oldest task by creation date.
  Task _selectOldest(List<Task> tasks) {
    final sorted = List<Task>.from(tasks);
    sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return sorted.first;
  }
}
