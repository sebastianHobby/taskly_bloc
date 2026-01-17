import 'package:taskly_domain/src/core/editing/command_result.dart';
import 'package:taskly_domain/src/core/editing/validation_error.dart';
import 'package:taskly_domain/src/core/editing/value/value_commands.dart';
import 'package:taskly_domain/src/forms/field_key.dart';
import 'package:taskly_domain/src/interfaces/value_repository_contract.dart';

final class ValueCommandHandler {
  ValueCommandHandler({required ValueRepositoryContract valueRepository})
    : _valueRepository = valueRepository;

  final ValueRepositoryContract _valueRepository;

  Future<CommandResult> handleCreate(CreateValueCommand command) async {
    final failure = _validate(command.name, command.color, command.iconName);
    if (failure != null) return CommandResult.validationFailure(failure);

    await _valueRepository.create(
      name: command.name.trim(),
      color: command.color,
      priority: command.priority,
      iconName: command.iconName,
    );

    return const CommandResult.success();
  }

  Future<CommandResult> handleUpdate(UpdateValueCommand command) async {
    final failure = _validate(command.name, command.color, command.iconName);
    if (failure != null) return CommandResult.validationFailure(failure);

    await _valueRepository.update(
      id: command.id,
      name: command.name.trim(),
      color: command.color,
      priority: command.priority,
      iconName: command.iconName,
    );

    return const CommandResult.success();
  }

  ValidationFailure? _validate(String name, String color, String? iconName) {
    final trimmedName = name.trim();
    final fieldErrors = <FieldKey, List<ValidationError>>{};

    if (trimmedName.isEmpty) {
      fieldErrors[ValueFieldKeys.name] = const <ValidationError>[
        ValidationError(code: 'required', messageKey: 'Name is required'),
      ];
    } else if (trimmedName.length > 120) {
      fieldErrors[ValueFieldKeys.name] = const <ValidationError>[
        ValidationError(
          code: 'max_length',
          messageKey: 'Name must be 120 characters or fewer',
        ),
      ];
    }

    if (color.trim().isEmpty) {
      fieldErrors[ValueFieldKeys.colour] = const <ValidationError>[
        ValidationError(code: 'required', messageKey: 'Color is required'),
      ];
    }

    if (iconName != null && iconName.trim().isEmpty) {
      fieldErrors[ValueFieldKeys.iconName] = const <ValidationError>[
        ValidationError(code: 'required', messageKey: 'Emoji is required'),
      ];
    }

    if (fieldErrors.isEmpty) return null;
    return ValidationFailure(fieldErrors: fieldErrors);
  }
}
