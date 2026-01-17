import '../command_result.dart';
import '../validation_error.dart';
import 'task_commands.dart';
import '../../../forms/field_key.dart';
import '../../../interfaces/task_repository_contract.dart';

final class TaskCommandHandler {
  TaskCommandHandler({required TaskRepositoryContract taskRepository})
    : _taskRepository = taskRepository;

  final TaskRepositoryContract _taskRepository;

  Future<CommandResult> handleCreate(CreateTaskCommand command) async {
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
    );

    return const CommandResult.success();
  }

  Future<CommandResult> handleUpdate(UpdateTaskCommand command) async {
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
    );

    return const CommandResult.success();
  }

  ValidationFailure? _validate(dynamic command) {
    final name = (command as dynamic).name as String;
    final description = (command as dynamic).description as String?;
    final startDate = (command as dynamic).startDate as DateTime?;
    final deadlineDate = (command as dynamic).deadlineDate as DateTime?;
    final repeat = (command as dynamic).repeatIcalRrule as String?;

    final trimmedName = name.trim();
    final fieldErrors = <FieldKey, List<ValidationError>>{};

    if (trimmedName.isEmpty) {
      fieldErrors[TaskFieldKeys.name] = const <ValidationError>[
        ValidationError(code: 'required', messageKey: 'taskFormNameRequired'),
      ];
    } else if (trimmedName.length > 120) {
      fieldErrors[TaskFieldKeys.name] = const <ValidationError>[
        ValidationError(code: 'max_length', messageKey: 'taskFormNameTooLong'),
      ];
    }

    if (description != null && description.length > 200) {
      fieldErrors[TaskFieldKeys.description] = const <ValidationError>[
        ValidationError(
          code: 'max_length',
          messageKey: 'taskFormDescriptionTooLong',
        ),
      ];
    }

    if (repeat != null && repeat.length > 500) {
      fieldErrors[TaskFieldKeys.repeatIcalRrule] = const <ValidationError>[
        ValidationError(
          code: 'max_length',
          messageKey: 'taskFormRepeatRuleTooLong',
        ),
      ];
    }

    if (startDate != null && deadlineDate != null) {
      if (deadlineDate.isBefore(startDate)) {
        fieldErrors[TaskFieldKeys.deadlineDate] = const <ValidationError>[
          ValidationError(
            code: 'deadline_before_start',
            messageKey: 'taskFormDeadlineAfterStartError',
          ),
        ];
      }
    }

    if (fieldErrors.isEmpty) return null;
    return ValidationFailure(fieldErrors: fieldErrors);
  }
}
