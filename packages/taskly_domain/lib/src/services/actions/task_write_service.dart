import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/telemetry.dart';

/// Write facade for task mutations.
///
/// Centralizes validation and side-effects for task edits and actions.
final class TaskWriteService {
  TaskWriteService({
    required TaskRepositoryContract taskRepository,
    required ProjectRepositoryContract projectRepository,
    required OccurrenceCommandService occurrenceCommandService,
  }) : _taskRepository = taskRepository,
       _occurrenceCommandService = occurrenceCommandService,
       _commandHandler = TaskCommandHandler(
         taskRepository: taskRepository,
         projectRepository: projectRepository,
       );

  final TaskRepositoryContract _taskRepository;
  final OccurrenceCommandService _occurrenceCommandService;
  final TaskCommandHandler _commandHandler;

  Future<CommandResult> create(
    CreateTaskCommand command, {
    OperationContext? context,
  }) {
    return _commandHandler.handleCreate(command, context: context);
  }

  Future<CommandResult> update(
    UpdateTaskCommand command, {
    OperationContext? context,
  }) {
    return _commandHandler.handleUpdate(command, context: context);
  }

  Future<void> delete(String taskId, {OperationContext? context}) {
    return _taskRepository.delete(taskId, context: context);
  }

  Future<void> complete(
    String taskId, {
    DateTime? occurrenceDate,
    DateTime? originalOccurrenceDate,
    OperationContext? context,
  }) {
    return _occurrenceCommandService.completeTask(
      taskId: taskId,
      occurrenceDate: occurrenceDate,
      originalOccurrenceDate: originalOccurrenceDate,
      context: context,
    );
  }

  Future<void> uncomplete(
    String taskId, {
    DateTime? occurrenceDate,
    OperationContext? context,
  }) {
    return _occurrenceCommandService.uncompleteTask(
      taskId: taskId,
      occurrenceDate: occurrenceDate,
      context: context,
    );
  }

  Future<void> completeSeries(String taskId, {OperationContext? context}) {
    return _occurrenceCommandService.completeTaskSeries(
      taskId: taskId,
      context: context,
    );
  }

  Future<void> move(
    String taskId,
    String? targetProjectId, {
    OperationContext? context,
  }) async {
    final task = await _taskRepository.getById(taskId);
    if (task == null) return;

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

  Future<int> bulkRescheduleDeadlines(
    Iterable<String> taskIds,
    DateTime newDeadlineDate, {
    OperationContext? context,
  }) {
    return _taskRepository.bulkRescheduleDeadlines(
      taskIds: taskIds,
      deadlineDate: newDeadlineDate,
      context: context,
    );
  }

  Future<int> bulkRescheduleStarts(
    Iterable<String> taskIds,
    DateTime newStartDate, {
    OperationContext? context,
  }) {
    return _taskRepository.bulkRescheduleStarts(
      taskIds: taskIds,
      startDate: newStartDate,
      context: context,
    );
  }

  Future<void> setMyDaySnoozedUntil(
    String taskId, {
    required DateTime? untilUtc,
    OperationContext? context,
  }) {
    return _taskRepository.setMyDaySnoozedUntil(
      id: taskId,
      untilUtc: untilUtc,
      context: context,
    );
  }
}
