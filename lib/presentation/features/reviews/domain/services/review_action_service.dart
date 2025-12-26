import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';
import 'package:taskly_bloc/presentation/features/analytics/domain/models/entity_type.dart';
import 'package:taskly_bloc/presentation/features/reviews/domain/models/review_action.dart';
import 'package:taskly_bloc/presentation/features/reviews/domain/models/review_action_type.dart';

/// Service that executes review actions on entities
class ReviewActionService {
  ReviewActionService(this._taskRepository);
  final TaskRepositoryContract _taskRepository;

  /// Execute an action on a task
  Future<void> executeTaskAction(Task task, ReviewAction action) async {
    switch (action.type) {
      case ReviewActionType.update:
        if (action.updateData != null) {
          final updatedTask = _applyTaskUpdates(task, action.updateData!);
          await _taskRepository.update(
            id: updatedTask.id,
            name: updatedTask.name,
            completed: updatedTask.completed,
            description: updatedTask.description,
            startDate: updatedTask.startDate,
            deadlineDate: updatedTask.deadlineDate,
            projectId: updatedTask.projectId,
            repeatIcalRrule: updatedTask.repeatIcalRrule,
            repeatFromCompletion: updatedTask.repeatFromCompletion,
            labelIds: updatedTask.labels.map((l) => l.id).toList(),
          );
        }
      case ReviewActionType.complete:
        await _taskRepository.update(
          id: task.id,
          name: task.name,
          completed: true,
          description: task.description,
          startDate: task.startDate,
          deadlineDate: task.deadlineDate,
          projectId: task.projectId,
          repeatIcalRrule: task.repeatIcalRrule,
          repeatFromCompletion: task.repeatFromCompletion,
          labelIds: task.labels.map((l) => l.id).toList(),
        );
      case ReviewActionType.archive:
        // TODO: Implement archive when supported
        break;
      case ReviewActionType.delete:
        await _taskRepository.delete(task.id);
      case ReviewActionType.skip:
        // No action needed
        break;
    }
  }

  /// Execute an action on a project
  Future<void> executeProjectAction(
    Project project,
    ReviewAction action,
  ) async {
    // TODO: Implement when ProjectRepository is available
    switch (action.type) {
      case ReviewActionType.update:
        // Update project with action.updateData
        break;
      case ReviewActionType.complete:
        // Mark project as completed
        break;
      case ReviewActionType.archive:
        // Archive project
        break;
      case ReviewActionType.delete:
        // Delete project
        break;
      case ReviewActionType.skip:
        // No action needed
        break;
    }
  }

  /// Apply updates to a task from action data
  Task _applyTaskUpdates(Task task, Map<String, dynamic> updates) {
    return task.copyWith(
      name: updates['name'] as String? ?? task.name,
      description: updates['description'] as String?,
      deadlineDate: updates['deadlineDate'] != null
          ? DateTime.parse(updates['deadlineDate'] as String)
          : task.deadlineDate,
      projectId: updates['projectId'] as String?,
    );
  }

  /// Get recommended actions for an entity based on analytics
  Future<List<ReviewAction>> getRecommendedActions({
    required EntityType entityType,
    required String entityId,
  }) async {
    // This could use AnalyticsService to provide intelligent recommendations
    // For now, return empty list
    return [];
  }
}
