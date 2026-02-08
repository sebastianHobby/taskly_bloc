import 'package:taskly_domain/src/core/editing/validation_failure.dart';

/// Result of executing a domain command.
sealed class CommandResult {
  const CommandResult();

  const factory CommandResult.success() = CommandSuccess;
  const factory CommandResult.validationFailure(ValidationFailure failure) =
      CommandValidationFailure;
}

final class CommandSuccess extends CommandResult {
  const CommandSuccess({this.entityId});

  final String? entityId;
}

final class CommandValidationFailure extends CommandResult {
  const CommandValidationFailure(this.failure);

  final ValidationFailure failure;
}
