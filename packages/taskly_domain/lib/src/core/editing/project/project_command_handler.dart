import 'package:taskly_domain/src/core/editing/command_result.dart';
import 'package:taskly_domain/src/core/editing/project/project_commands.dart';
import 'package:taskly_domain/src/core/editing/validation_error.dart';
import 'package:taskly_domain/src/core/editing/validators/project_validators.dart';
import 'package:taskly_domain/src/forms/field_key.dart';
import 'package:taskly_domain/src/interfaces/project_repository_contract.dart';
import 'package:taskly_domain/src/telemetry/operation_context.dart';

final class ProjectCommandHandler {
  ProjectCommandHandler({required ProjectRepositoryContract projectRepository})
    : _projectRepository = projectRepository;

  final ProjectRepositoryContract _projectRepository;

  Future<CommandResult> handleCreate(
    CreateProjectCommand command, {
    OperationContext? context,
  }) async {
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
      context: context,
    );

    return const CommandResult.success();
  }

  Future<CommandResult> handleUpdate(
    UpdateProjectCommand command, {
    OperationContext? context,
  }) async {
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
      context: context,
    );

    return const CommandResult.success();
  }

  ValidationFailure? _validate(dynamic command) {
    final name = (command as dynamic).name as String;
    final startDate = (command as dynamic).startDate as DateTime?;
    final deadlineDate = (command as dynamic).deadlineDate as DateTime?;
    final repeat = (command as dynamic).repeatIcalRrule as String?;
    final valueIds = (command as dynamic).valueIds as List<String>;

    final fieldErrors = <FieldKey, List<ValidationError>>{};
    fieldErrors[ProjectFieldKeys.name] = ProjectValidators.name(name);
    final description = (command as dynamic).description as String?;
    final descriptionErrors = ProjectValidators.description(description);
    if (descriptionErrors.isNotEmpty) {
      fieldErrors[ProjectFieldKeys.description] = descriptionErrors;
    }
    final repeatErrors = ProjectValidators.repeatRule(repeat);
    if (repeatErrors.isNotEmpty) {
      fieldErrors[ProjectFieldKeys.repeatIcalRrule] = repeatErrors;
    }
    final valueErrors = ProjectValidators.valueIds(valueIds);
    if (valueErrors.isNotEmpty) {
      fieldErrors[ProjectFieldKeys.valueIds] = valueErrors;
    }
    fieldErrors.addAll(ProjectValidators.dateOrder(startDate, deadlineDate));
    fieldErrors.addAll(
      ProjectValidators.recurrenceShape(
        repeatIcalRrule: repeat,
        startDate: startDate,
      ),
    );

    final pruned = Map<FieldKey, List<ValidationError>>.fromEntries(
      fieldErrors.entries.where((entry) => entry.value.isNotEmpty),
    );
    if (pruned.isEmpty) return null;
    return ValidationFailure(fieldErrors: pruned);
  }
}
