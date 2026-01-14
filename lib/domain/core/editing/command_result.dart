import 'package:taskly_bloc/domain/core/editing/validation_failure.dart';

/// Result of executing a domain command.
sealed class CommandResult {
  const CommandResult();

  const factory CommandResult.success() = CommandSuccess;
  const factory CommandResult.validationFailure(ValidationFailure failure) =
      CommandValidationFailure;
}

final class CommandSuccess extends CommandResult {
  const CommandSuccess();
}

final class CommandValidationFailure extends CommandResult {
  const CommandValidationFailure(this.failure);

  final ValidationFailure failure;
}
