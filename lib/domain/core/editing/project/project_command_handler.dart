import 'package:taskly_bloc/domain/core/editing/command_result.dart';
import 'package:taskly_bloc/domain/core/editing/validation_error.dart';
import 'package:taskly_bloc/domain/core/editing/project/project_commands.dart';
import 'package:taskly_bloc/domain/forms/field_key.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';

final class ProjectCommandHandler {
  ProjectCommandHandler({required ProjectRepositoryContract projectRepository})
    : _projectRepository = projectRepository;

  final ProjectRepositoryContract _projectRepository;

  Future<CommandResult> handleCreate(CreateProjectCommand command) async {
    final failure = _validate(command);
    if (failure != null) return CommandResult.validationFailure(failure);

    await _projectRepository.create(
      name: command.name.trim(),
      description: command.description,
      completed: command.completed,
      startDate: command.startDate,
      deadlineDate: command.deadlineDate,
      priority: command.priority,
      repeatIcalRrule: command.repeatIcalRrule,
      repeatFromCompletion: command.repeatFromCompletion,
      seriesEnded: command.seriesEnded,
      valueIds: command.valueIds,
    );

    return const CommandResult.success();
  }

  Future<CommandResult> handleUpdate(UpdateProjectCommand command) async {
    final failure = _validate(command);
    if (failure != null) return CommandResult.validationFailure(failure);

    await _projectRepository.update(
      id: command.id,
      name: command.name.trim(),
      description: command.description,
      completed: command.completed,
      startDate: command.startDate,
      deadlineDate: command.deadlineDate,
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
    final startDate = (command as dynamic).startDate as DateTime?;
    final deadlineDate = (command as dynamic).deadlineDate as DateTime?;
    final repeat = (command as dynamic).repeatIcalRrule as String?;

    final trimmedName = name.trim();
    final fieldErrors = <FieldKey, List<ValidationError>>{};

    if (trimmedName.isEmpty) {
      fieldErrors[ProjectFieldKeys.name] = const <ValidationError>[
        ValidationError(
          code: 'required',
          messageKey: 'projectFormTitleRequired',
        ),
      ];
    } else if (trimmedName.length > 120) {
      fieldErrors[ProjectFieldKeys.name] = const <ValidationError>[
        ValidationError(
          code: 'max_length',
          messageKey: 'projectFormTitleTooLong',
        ),
      ];
    }

    final description = (command as dynamic).description as String?;
    if (description != null && description.length > 200) {
      fieldErrors[ProjectFieldKeys.description] = const <ValidationError>[
        ValidationError(
          code: 'max_length',
          messageKey: 'projectFormDescriptionTooLong',
        ),
      ];
    }

    if (repeat != null && repeat.length > 500) {
      fieldErrors[ProjectFieldKeys.repeatIcalRrule] = const <ValidationError>[
        ValidationError(
          code: 'max_length',
          messageKey: 'projectFormRepeatRuleTooLong',
        ),
      ];
    }

    if (startDate != null && deadlineDate != null) {
      if (deadlineDate.isBefore(startDate)) {
        fieldErrors[ProjectFieldKeys.deadlineDate] = const <ValidationError>[
          ValidationError(
            code: 'deadline_before_start',
            messageKey: 'projectFormDeadlineAfterStartError',
          ),
        ];
      }
    }

    if (fieldErrors.isEmpty) return null;
    return ValidationFailure(fieldErrors: fieldErrors);
  }
}
