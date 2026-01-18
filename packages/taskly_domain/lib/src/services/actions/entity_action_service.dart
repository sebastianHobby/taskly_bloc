import 'package:taskly_core/logging.dart';
import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/telemetry.dart';

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
    required OccurrenceCommandService occurrenceCommandService,
  }) : _taskRepository = taskRepository,
       _projectRepository = projectRepository,
       _valueRepository = valueRepository,
       _allocationOrchestrator = allocationOrchestrator,
       _occurrenceCommandService = occurrenceCommandService;

  final TaskRepositoryContract _taskRepository;
  final ProjectRepositoryContract _projectRepository;
  final ValueRepositoryContract _valueRepository;
  final AllocationOrchestrator _allocationOrchestrator;
  final OccurrenceCommandService _occurrenceCommandService;

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
    OperationContext? context,
  }) async {
    AppLog.routine('domain.entity_actions', 'completeTask: $taskId');
    await _occurrenceCommandService.completeTask(
      taskId: taskId,
      occurrenceDate: occurrenceDate,
      originalOccurrenceDate: originalOccurrenceDate,
      context: context,
    );
  }

  /// Uncomplete a task (as an occurrence).
  Future<void> uncompleteTask(
    String taskId, {
    DateTime? occurrenceDate,
    OperationContext? context,
  }) async {
    AppLog.routine('domain.entity_actions', 'uncompleteTask: $taskId');
    await _occurrenceCommandService.uncompleteTask(
      taskId: taskId,
      occurrenceDate: occurrenceDate,
      context: context,
    );
  }

  /// Complete a task series (end recurrence).
  Future<void> completeTaskSeries(
    String taskId, {
    OperationContext? context,
  }) async {
    AppLog.routine('domain.entity_actions', 'completeTaskSeries: $taskId');
    await _occurrenceCommandService.completeTaskSeries(
      taskId: taskId,
      context: context,
    );
  }

  /// Delete a task.
  Future<void> deleteTask(String taskId, {OperationContext? context}) async {
    AppLog.routine('domain.entity_actions', 'deleteTask: $taskId');
    await _taskRepository.delete(taskId, context: context);
  }

  /// Pin a task for allocation.
  Future<void> pinTask(String taskId, {OperationContext? context}) async {
    AppLog.routine('domain.entity_actions', 'pinTask: $taskId');
    await _allocationOrchestrator.pinTask(taskId, context: context);
  }

  /// Unpin a task from allocation.
  Future<void> unpinTask(String taskId, {OperationContext? context}) async {
    AppLog.routine('domain.entity_actions', 'unpinTask: $taskId');
    await _allocationOrchestrator.unpinTask(taskId, context: context);
  }

  /// Move a task to a different project.
  Future<void> moveTask(
    String taskId,
    String? targetProjectId, {
    OperationContext? context,
  }) async {
    AppLog.routine(
      'domain.entity_actions',
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
        context: context,
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
    OperationContext? context,
  }) async {
    AppLog.routine('domain.entity_actions', 'completeProject: $projectId');
    await _occurrenceCommandService.completeProject(
      projectId: projectId,
      occurrenceDate: occurrenceDate,
      originalOccurrenceDate: originalOccurrenceDate,
      context: context,
    );
  }

  /// Uncomplete a project (as an occurrence).
  Future<void> uncompleteProject(
    String projectId, {
    DateTime? occurrenceDate,
    OperationContext? context,
  }) async {
    AppLog.routine('domain.entity_actions', 'uncompleteProject: $projectId');
    await _occurrenceCommandService.uncompleteProject(
      projectId: projectId,
      occurrenceDate: occurrenceDate,
      context: context,
    );
  }

  /// Complete a project series (end recurrence).
  Future<void> completeProjectSeries(
    String projectId, {
    OperationContext? context,
  }) async {
    AppLog.routine(
      'domain.entity_actions',
      'completeProjectSeries: $projectId',
    );
    await _occurrenceCommandService.completeProjectSeries(
      projectId: projectId,
      context: context,
    );
  }

  /// Delete a project.
  Future<void> deleteProject(
    String projectId, {
    OperationContext? context,
  }) async {
    AppLog.routine('domain.entity_actions', 'deleteProject: $projectId');
    await _projectRepository.delete(projectId, context: context);
  }

  /// Pin a project for allocation.
  Future<void> pinProject(String projectId, {OperationContext? context}) async {
    AppLog.routine('domain.entity_actions', 'pinProject: $projectId');
    await _allocationOrchestrator.pinProject(projectId, context: context);
  }

  /// Unpin a project from allocation.
  Future<void> unpinProject(
    String projectId, {
    OperationContext? context,
  }) async {
    AppLog.routine('domain.entity_actions', 'unpinProject: $projectId');
    await _allocationOrchestrator.unpinProject(projectId, context: context);
  }

  // ===========================================================================
  // VALUE ACTIONS
  // ===========================================================================

  /// Delete a value.
  Future<void> deleteValue(String valueId, {OperationContext? context}) async {
    AppLog.routine('domain.entity_actions', 'deleteValue: $valueId');
    await _valueRepository.delete(valueId, context: context);
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
    OperationContext? context,
  }) async {
    AppLog.routine(
      'domain.entity_actions',
      'performAction: $action on $entityType/$entityId',
    );

    switch (entityType) {
      case EntityType.task:
        await _performTaskAction(entityId, action, params, context: context);
      case EntityType.project:
        await _performProjectAction(entityId, action, context: context);
      case EntityType.value:
        await _performValueAction(entityId, action, context: context);
    }
  }

  Future<void> _performTaskAction(
    String taskId,
    EntityActionType action,
    Map<String, dynamic>? params, {
    OperationContext? context,
  }) async {
    switch (action) {
      case EntityActionType.complete:
        await completeTask(taskId, context: context);
      case EntityActionType.uncomplete:
        await uncompleteTask(taskId, context: context);
      case EntityActionType.delete:
        await deleteTask(taskId, context: context);
      case EntityActionType.pin:
        await pinTask(taskId, context: context);
      case EntityActionType.unpin:
        await unpinTask(taskId, context: context);
      case EntityActionType.move:
        final targetProjectId = params?['targetProjectId'] as String?;
        await moveTask(taskId, targetProjectId, context: context);
    }
  }

  Future<void> _performProjectAction(
    String projectId,
    EntityActionType action, {
    OperationContext? context,
  }) async {
    switch (action) {
      case EntityActionType.complete:
        await completeProject(projectId, context: context);
      case EntityActionType.uncomplete:
        await uncompleteProject(projectId, context: context);
      case EntityActionType.delete:
        await deleteProject(projectId, context: context);
      case EntityActionType.pin:
        await pinProject(projectId, context: context);
      case EntityActionType.unpin:
        await unpinProject(projectId, context: context);
      case EntityActionType.move:
        throw UnsupportedError('Action $action not supported for projects');
    }
  }

  Future<void> _performValueAction(
    String valueId,
    EntityActionType action, {
    OperationContext? context,
  }) async {
    switch (action) {
      case EntityActionType.delete:
        await deleteValue(valueId, context: context);
      case EntityActionType.complete:
      case EntityActionType.uncomplete:
      case EntityActionType.pin:
      case EntityActionType.unpin:
      case EntityActionType.move:
        throw UnsupportedError('Action $action not supported for values');
    }
  }
}
