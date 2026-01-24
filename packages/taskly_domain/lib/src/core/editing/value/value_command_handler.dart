import 'package:taskly_domain/src/core/editing/command_result.dart';
import 'package:taskly_domain/src/core/editing/value/value_commands.dart';
import 'package:taskly_domain/src/core/editing/validation_error.dart';
import 'package:taskly_domain/src/core/editing/validators/value_validators.dart';
import 'package:taskly_domain/src/forms/field_key.dart';
import 'package:taskly_domain/src/interfaces/value_repository_contract.dart';
import 'package:taskly_domain/src/telemetry/operation_context.dart';

final class ValueCommandHandler {
  ValueCommandHandler({required ValueRepositoryContract valueRepository})
    : _valueRepository = valueRepository;

  final ValueRepositoryContract _valueRepository;

  Future<CommandResult> handleCreate(
    CreateValueCommand command, {
    OperationContext? context,
  }) async {
    final failure = _validate(command.name, command.color, command.iconName);
    if (failure != null) return CommandResult.validationFailure(failure);

    await _valueRepository.create(
      name: command.name.trim(),
      color: command.color,
      priority: command.priority,
      iconName: command.iconName,
      context: context,
    );

    return const CommandResult.success();
  }

  Future<CommandResult> handleUpdate(
    UpdateValueCommand command, {
    OperationContext? context,
  }) async {
    final failure = _validate(command.name, command.color, command.iconName);
    if (failure != null) return CommandResult.validationFailure(failure);

    await _valueRepository.update(
      id: command.id,
      name: command.name.trim(),
      color: command.color,
      priority: command.priority,
      iconName: command.iconName,
      context: context,
    );

    return const CommandResult.success();
  }

  ValidationFailure? _validate(String name, String color, String? iconName) {
    final fieldErrors = <FieldKey, List<ValidationError>>{};

    fieldErrors[ValueFieldKeys.name] = ValueValidators.name(name);

    final colorErrors = ValueValidators.color(color);
    if (colorErrors.isNotEmpty) {
      fieldErrors[ValueFieldKeys.colour] = colorErrors;
    }

    final iconErrors = ValueValidators.iconName(iconName);
    if (iconErrors.isNotEmpty) {
      fieldErrors[ValueFieldKeys.iconName] = iconErrors;
    }

    final pruned = Map<FieldKey, List<ValidationError>>.fromEntries(
      fieldErrors.entries.where((entry) => entry.value.isNotEmpty),
    );
    if (pruned.isEmpty) return null;
    return ValidationFailure(fieldErrors: pruned);
  }
}
