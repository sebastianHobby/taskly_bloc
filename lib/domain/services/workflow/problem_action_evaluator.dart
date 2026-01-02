import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/models/workflow/problem_action.dart';

/// Service for evaluating and executing problem actions.
///
/// Takes a [ProblemAction] and applies it to an entity (task, project, etc.)
/// via the appropriate repository.
class ProblemActionEvaluator {
  ProblemActionEvaluator({
    required TaskRepositoryContract taskRepository,
  }) : _taskRepository = taskRepository;

  final TaskRepositoryContract _taskRepository;

  /// Execute a problem action on a task.
  ///
  /// Returns true if the action was executed successfully.
  /// Some actions like [PickDate] and [PickValue] return false as they
  /// require UI interaction and are handled by the caller.
  Future<bool> executeOnTask({
    required Task task,
    required ProblemAction action,
    DateTime? selectedDate,
    String? selectedValueId,
  }) async {
    return action.when(
      // Date actions
      rescheduleToday: () => _rescheduleTask(task, DateTime.now()),
      rescheduleTomorrow: () =>
          _rescheduleTask(task, DateTime.now().add(const Duration(days: 1))),
      rescheduleInDays: (days) =>
          _rescheduleTask(task, DateTime.now().add(Duration(days: days))),
      pickDate: () async {
        // UI handles date picking, selectedDate should be provided
        if (selectedDate != null) {
          return _rescheduleTask(task, selectedDate);
        }
        return false; // Caller should show date picker
      },
      clearDeadline: () => _clearTaskDeadline(task),

      // Value actions
      assignValue: (valueId, _) => _assignValueToTask(task, valueId),
      pickValue: () async {
        // UI handles value picking, selectedValueId should be provided
        if (selectedValueId != null) {
          return _assignValueToTask(task, selectedValueId);
        }
        return false; // Caller should show value picker
      },

      // Priority actions
      lowerPriority: () => _lowerTaskPriority(task),
      removePriority: () => _removeTaskPriority(task),
    );
  }

  /// Reschedule a task to a new deadline date.
  Future<bool> _rescheduleTask(Task task, DateTime newDate) async {
    // Normalize to date only (no time component)
    final normalizedDate = DateTime(newDate.year, newDate.month, newDate.day);

    await _taskRepository.update(
      id: task.id,
      name: task.name,
      completed: task.completed,
      description: task.description,
      startDate: task.startDate,
      deadlineDate: normalizedDate,
      projectId: task.projectId,
      repeatIcalRrule: task.repeatIcalRrule,
      repeatFromCompletion: task.repeatFromCompletion,
      labelIds: task.labels.map((l) => l.id).toList(),
    );
    return true;
  }

  /// Clear a task's deadline.
  Future<bool> _clearTaskDeadline(Task task) async {
    await _taskRepository.update(
      id: task.id,
      name: task.name,
      completed: task.completed,
      description: task.description,
      startDate: task.startDate,
      projectId: task.projectId,
      repeatIcalRrule: task.repeatIcalRrule,
      repeatFromCompletion: task.repeatFromCompletion,
      labelIds: task.labels.map((l) => l.id).toList(),
    );
    return true;
  }

  /// Assign a value (label) to a task.
  Future<bool> _assignValueToTask(Task task, String valueId) async {
    // Add the value ID to the task's label list if not already present
    final currentLabelIds = task.labels.map((l) => l.id).toList();
    final updatedLabelIds = List<String>.from(currentLabelIds);
    if (!updatedLabelIds.contains(valueId)) {
      updatedLabelIds.add(valueId);
    }

    await _taskRepository.update(
      id: task.id,
      name: task.name,
      completed: task.completed,
      description: task.description,
      startDate: task.startDate,
      deadlineDate: task.deadlineDate,
      projectId: task.projectId,
      repeatIcalRrule: task.repeatIcalRrule,
      repeatFromCompletion: task.repeatFromCompletion,
      labelIds: updatedLabelIds,
    );
    return true;
  }

  /// Lower a task's priority by one level.
  /// P1 → P2, P2 → P3, P3 → P4, P4 or null stays as is.
  Future<bool> _lowerTaskPriority(Task task) async {
    final currentPriority = task.priority;
    int? newPriority;

    if (currentPriority != null && currentPriority < 4) {
      newPriority = currentPriority + 1;
    } else {
      // Already at lowest or no priority, nothing to do
      return false;
    }

    await _updateTaskPriority(task, newPriority);
    return true;
  }

  /// Remove a task's priority entirely.
  Future<bool> _removeTaskPriority(Task task) async {
    if (task.priority == null) {
      return false; // Already no priority
    }

    await _updateTaskPriority(task, null);
    return true;
  }

  /// Update task priority.
  ///
  /// Note: The current repository.update() method doesn't support priority.
  /// This will need to be added to the TaskRepositoryContract.
  /// For now, this is a placeholder that demonstrates the intended behavior.
  Future<void> _updateTaskPriority(Task task, int? priority) async {
    // TODO: Add priority parameter to TaskRepositoryContract.update()
    // For now, using the existing update method which doesn't include priority
    // This will need to be updated when the repository contract is extended.
    await _taskRepository.update(
      id: task.id,
      name: task.name,
      completed: task.completed,
      description: task.description,
      startDate: task.startDate,
      deadlineDate: task.deadlineDate,
      projectId: task.projectId,
      repeatIcalRrule: task.repeatIcalRrule,
      repeatFromCompletion: task.repeatFromCompletion,
      labelIds: task.labels.map((l) => l.id).toList(),
    );

    // Priority update will be implemented in a later phase when
    // TaskRepositoryContract is updated to support priority field.
    // TODO: Implement priority update when repository supports it
  }

  /// Check if an action requires UI interaction.
  ///
  /// Returns true for actions like PickDate and PickValue that need
  /// the UI to show a picker before execution.
  bool requiresUiInteraction(ProblemAction action) {
    return action.maybeWhen(
      pickDate: () => true,
      pickValue: () => true,
      orElse: () => false,
    );
  }
}
