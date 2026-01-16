import 'package:taskly_bloc/core/logging/talker_service.dart';
import 'package:taskly_bloc/domain/analytics/model/entity_type.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/value_repository_contract.dart';
import 'package:taskly_bloc/domain/allocation/engine/allocation_orchestrator.dart';

/// Actions that can be performed on entities.
enum EntityActionType {
  complete,
  uncomplete,
  delete,
  pin,
  unpin,
  move,
}

/// Service for performing actions on entities (tasks, projects, etc.).
///
/// This service is used by the unified screen model to handle entity
/// mutations without coupling to any specific bloc or screen.
class EntityActionService {
  EntityActionService({
    required TaskRepositoryContract taskRepository,
    required ProjectRepositoryContract projectRepository,
    required ValueRepositoryContract valueRepository,
    required AllocationOrchestrator allocationOrchestrator,
  }) : _taskRepository = taskRepository,
       _projectRepository = projectRepository,
       _valueRepository = valueRepository,
       _allocationOrchestrator = allocationOrchestrator;

  final TaskRepositoryContract _taskRepository;
  final ProjectRepositoryContract _projectRepository;
  final ValueRepositoryContract _valueRepository;
  final AllocationOrchestrator _allocationOrchestrator;

  // ===========================================================================
  // TASK ACTIONS
  // ===========================================================================

  /// Complete a task (as an occurrence).
  ///
  /// For non-repeating tasks, pass [occurrenceDate] as null.
  Future<void> completeTask(
    String taskId, {
    DateTime? occurrenceDate,
    DateTime? originalOccurrenceDate,
  }) async {
    talker.serviceLog('EntityActionService', 'completeTask: $taskId');
    await _taskRepository.completeOccurrence(
      taskId: taskId,
      occurrenceDate: occurrenceDate,
      originalOccurrenceDate: originalOccurrenceDate,
    );
  }

  /// Uncomplete a task (as an occurrence).
  Future<void> uncompleteTask(
    String taskId, {
    DateTime? occurrenceDate,
  }) async {
    talker.serviceLog('EntityActionService', 'uncompleteTask: $taskId');
    await _taskRepository.uncompleteOccurrence(
      taskId: taskId,
      occurrenceDate: occurrenceDate,
    );
  }

  /// Delete a task.
  Future<void> deleteTask(String taskId) async {
    talker.serviceLog('EntityActionService', 'deleteTask: $taskId');
    await _taskRepository.delete(taskId);
  }

  /// Pin a task for allocation.
  Future<void> pinTask(String taskId) async {
    talker.serviceLog('EntityActionService', 'pinTask: $taskId');
    await _allocationOrchestrator.pinTask(taskId);
  }

  /// Unpin a task from allocation.
  Future<void> unpinTask(String taskId) async {
    talker.serviceLog('EntityActionService', 'unpinTask: $taskId');
    await _allocationOrchestrator.unpinTask(taskId);
  }

  /// Move a task to a different project.
  Future<void> moveTask(String taskId, String? targetProjectId) async {
    talker.serviceLog(
      'EntityActionService',
      'moveTask: $taskId -> $targetProjectId',
    );
    final task = await _taskRepository.getById(taskId);
    if (task != null) {
      await _taskRepository.update(
        id: task.id,
        name: task.name,
        description: task.description,
        completed: task.completed,
        projectId: targetProjectId,
        startDate: task.startDate,
        deadlineDate: task.deadlineDate,
        priority: task.priority,
        repeatIcalRrule: task.repeatIcalRrule,
        repeatFromCompletion: task.repeatFromCompletion,
      );
    }
  }

  // ===========================================================================
  // PROJECT ACTIONS
  // ===========================================================================

  /// Complete a project (as an occurrence).
  Future<void> completeProject(
    String projectId, {
    DateTime? occurrenceDate,
    DateTime? originalOccurrenceDate,
  }) async {
    talker.serviceLog('EntityActionService', 'completeProject: $projectId');
    await _projectRepository.completeOccurrence(
      projectId: projectId,
      occurrenceDate: occurrenceDate,
      originalOccurrenceDate: originalOccurrenceDate,
    );
  }

  /// Uncomplete a project (as an occurrence).
  Future<void> uncompleteProject(
    String projectId, {
    DateTime? occurrenceDate,
  }) async {
    talker.serviceLog('EntityActionService', 'uncompleteProject: $projectId');
    await _projectRepository.uncompleteOccurrence(
      projectId: projectId,
      occurrenceDate: occurrenceDate,
    );
  }

  /// Delete a project.
  Future<void> deleteProject(String projectId) async {
    talker.serviceLog('EntityActionService', 'deleteProject: $projectId');
    await _projectRepository.delete(projectId);
  }

  /// Pin a project for allocation.
  Future<void> pinProject(String projectId) async {
    talker.serviceLog('EntityActionService', 'pinProject: $projectId');
    await _allocationOrchestrator.pinProject(projectId);
  }

  /// Unpin a project from allocation.
  Future<void> unpinProject(String projectId) async {
    talker.serviceLog('EntityActionService', 'unpinProject: $projectId');
    await _allocationOrchestrator.unpinProject(projectId);
  }

  // ===========================================================================
  // VALUE ACTIONS
  // ===========================================================================

  /// Delete a value.
  Future<void> deleteValue(String valueId) async {
    talker.serviceLog('EntityActionService', 'deleteValue: $valueId');
    await _valueRepository.delete(valueId);
  }

  // ===========================================================================
  // GENERIC DISPATCH
  // ===========================================================================

  /// Perform an action on an entity by type.
  ///
  /// This is a convenience method for widgets that need to dispatch
  /// actions without knowing the entity type at compile time.
  Future<void> performAction({
    required String entityId,
    required EntityType entityType,
    required EntityActionType action,
    Map<String, dynamic>? params,
  }) async {
    talker.serviceLog(
      'EntityActionService',
      'performAction: $action on $entityType/$entityId',
    );

    switch (entityType) {
      case EntityType.task:
        await _performTaskAction(entityId, action, params);
      case EntityType.project:
        await _performProjectAction(entityId, action);
      case EntityType.value:
        await _performValueAction(entityId, action);
    }
  }

  Future<void> _performTaskAction(
    String taskId,
    EntityActionType action,
    Map<String, dynamic>? params,
  ) async {
    switch (action) {
      case EntityActionType.complete:
        await completeTask(taskId);
      case EntityActionType.uncomplete:
        await uncompleteTask(taskId);
      case EntityActionType.delete:
        await deleteTask(taskId);
      case EntityActionType.pin:
        await pinTask(taskId);
      case EntityActionType.unpin:
        await unpinTask(taskId);
      case EntityActionType.move:
        final targetProjectId = params?['targetProjectId'] as String?;
        await moveTask(taskId, targetProjectId);
    }
  }

  Future<void> _performProjectAction(
    String projectId,
    EntityActionType action,
  ) async {
    switch (action) {
      case EntityActionType.complete:
        await completeProject(projectId);
      case EntityActionType.uncomplete:
        await uncompleteProject(projectId);
      case EntityActionType.delete:
        await deleteProject(projectId);
      case EntityActionType.pin:
        await pinProject(projectId);
      case EntityActionType.unpin:
        await unpinProject(projectId);
      case EntityActionType.move:
        throw UnsupportedError('Action $action not supported for projects');
    }
  }

  Future<void> _performValueAction(
    String valueId,
    EntityActionType action,
  ) async {
    switch (action) {
      case EntityActionType.delete:
        await deleteValue(valueId);
      case EntityActionType.complete:
      case EntityActionType.uncomplete:
      case EntityActionType.pin:
      case EntityActionType.unpin:
      case EntityActionType.move:
        throw UnsupportedError('Action $action not supported for values');
    }
  }
}
