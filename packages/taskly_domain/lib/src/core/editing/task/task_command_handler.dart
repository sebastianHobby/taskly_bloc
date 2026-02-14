import 'package:taskly_domain/src/core/editing/command_result.dart';
import 'package:taskly_domain/src/core/editing/task/task_commands.dart';
import 'package:taskly_domain/src/core/editing/validation_error.dart';
import 'package:taskly_domain/src/core/editing/validators/task_validators.dart';
import 'package:taskly_domain/src/forms/field_key.dart';
import 'package:taskly_domain/src/interfaces/project_repository_contract.dart';
import 'package:taskly_domain/src/interfaces/task_repository_contract.dart';
import 'package:taskly_domain/src/telemetry/operation_context.dart';

final class TaskCommandHandler {
  TaskCommandHandler({
    required TaskRepositoryContract taskRepository,
    required ProjectRepositoryContract projectRepository,
  }) : _taskRepository = taskRepository,
       _projectRepository = projectRepository;

  final TaskRepositoryContract _taskRepository;
  final ProjectRepositoryContract _projectRepository;

  Future<CommandResult> handleCreate(
    CreateTaskCommand command, {
    OperationContext? context,
  }) async {
    final failure = await _validate(command);
    if (failure != null) return CommandResult.validationFailure(failure);

    await _taskRepository.create(
      name: command.name.trim(),
      description: command.description,
      completed: command.completed,
      startDate: command.startDate,
      deadlineDate: command.deadlineDate,
      projectId: command.projectId,
      priority: command.priority,
      repeatIcalRrule: command.repeatIcalRrule,
      repeatFromCompletion: command.repeatFromCompletion,
      seriesEnded: command.seriesEnded,
      valueIds: command.valueIds,
      checklistTitles: command.checklistTitles,
      context: context,
    );

    return const CommandResult.success();
  }

  Future<CommandResult> handleCreateWithId(
    CreateTaskCommand command, {
    OperationContext? context,
  }) async {
    final failure = await _validate(command);
    if (failure != null) return CommandResult.validationFailure(failure);

    final taskId = await _taskRepository.createReturningId(
      name: command.name.trim(),
      description: command.description,
      completed: command.completed,
      startDate: command.startDate,
      deadlineDate: command.deadlineDate,
      projectId: command.projectId,
      priority: command.priority,
      repeatIcalRrule: command.repeatIcalRrule,
      repeatFromCompletion: command.repeatFromCompletion,
      seriesEnded: command.seriesEnded,
      valueIds: command.valueIds,
      checklistTitles: command.checklistTitles,
      context: context,
    );

    return CommandSuccess(entityId: taskId);
  }

  Future<CommandResult> handleUpdate(
    UpdateTaskCommand command, {
    OperationContext? context,
  }) async {
    final failure = await _validate(command);
    if (failure != null) return CommandResult.validationFailure(failure);

    await _taskRepository.update(
      id: command.id,
      name: command.name.trim(),
      description: command.description,
      completed: command.completed,
      startDate: command.startDate,
      deadlineDate: command.deadlineDate,
      projectId: command.projectId,
      priority: command.priority,
      repeatIcalRrule: command.repeatIcalRrule,
      repeatFromCompletion: command.repeatFromCompletion,
      seriesEnded: command.seriesEnded,
      valueIds: command.valueIds,
      checklistTitles: command.checklistTitles,
      context: context,
    );

    return const CommandResult.success();
  }

  Future<ValidationFailure?> _validate(dynamic command) async {
    final name = (command as dynamic).name as String;
    final description = (command as dynamic).description as String?;
    final startDate = (command as dynamic).startDate as DateTime?;
    final deadlineDate = (command as dynamic).deadlineDate as DateTime?;
    final repeat = (command as dynamic).repeatIcalRrule as String?;
    final projectId = (command as dynamic).projectId as String?;
    final valueIds = (command as dynamic).valueIds as List<String>?;
    final normalizedProjectId = projectId?.trim();
    final project = normalizedProjectId == null || normalizedProjectId.isEmpty
        ? null
        : await _projectRepository.getById(normalizedProjectId);
    final projectPrimaryValueId = project?.primaryValueId;

    final fieldErrors = <FieldKey, List<ValidationError>>{};
    fieldErrors[TaskFieldKeys.name] = TaskValidators.name(name);
    final descriptionErrors = TaskValidators.description(description);
    if (descriptionErrors.isNotEmpty) {
      fieldErrors[TaskFieldKeys.description] = descriptionErrors;
    }
    final repeatErrors = TaskValidators.repeatRule(repeat);
    if (repeatErrors.isNotEmpty) {
      fieldErrors[TaskFieldKeys.repeatIcalRrule] = repeatErrors;
    }
    final valueErrors = TaskValidators.valueIds(
      valueIds,
      projectId: projectId,
      projectPrimaryValueId: projectPrimaryValueId,
    );
    if (valueErrors.isNotEmpty) {
      fieldErrors[TaskFieldKeys.valueIds] = valueErrors;
    }
    fieldErrors.addAll(TaskValidators.dateOrder(startDate, deadlineDate));

    final pruned = Map<FieldKey, List<ValidationError>>.fromEntries(
      fieldErrors.entries.where((entry) => entry.value.isNotEmpty),
    );
    if (pruned.isEmpty) return null;
    return ValidationFailure(fieldErrors: pruned);
  }
}
