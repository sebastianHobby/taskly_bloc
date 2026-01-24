import 'package:taskly_domain/src/core/editing/command_result.dart';
import 'package:taskly_domain/src/core/editing/task/task_commands.dart';
import 'package:taskly_domain/src/core/editing/validation_error.dart';
import 'package:taskly_domain/src/core/editing/validators/task_validators.dart';
import 'package:taskly_domain/src/forms/field_key.dart';
import 'package:taskly_domain/src/interfaces/task_repository_contract.dart';
import 'package:taskly_domain/src/telemetry/operation_context.dart';

final class TaskCommandHandler {
  TaskCommandHandler({required TaskRepositoryContract taskRepository})
    : _taskRepository = taskRepository;

  final TaskRepositoryContract _taskRepository;

  Future<CommandResult> handleCreate(
    CreateTaskCommand command, {
    OperationContext? context,
  }) async {
    final failure = _validate(command);
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
      context: context,
    );

    return const CommandResult.success();
  }

  Future<CommandResult> handleUpdate(
    UpdateTaskCommand command, {
    OperationContext? context,
  }) async {
    final failure = _validate(command);
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
      context: context,
    );

    return const CommandResult.success();
  }

  ValidationFailure? _validate(dynamic command) {
    final name = (command as dynamic).name as String;
    final description = (command as dynamic).description as String?;
    final startDate = (command as dynamic).startDate as DateTime?;
    final deadlineDate = (command as dynamic).deadlineDate as DateTime?;
    final repeat = (command as dynamic).repeatIcalRrule as String?;
    final valueIds = (command as dynamic).valueIds as List<String>?;

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
    final valueErrors = TaskValidators.valueIds(valueIds);
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
