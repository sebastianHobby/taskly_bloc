import 'package:taskly_bloc/domain/forms/field_key.dart';

/// A single domain validation error.
///
/// [messageKey] is a stable identifier that presentation can map to a localized
/// string (optionally using [args]).
final class ValidationError {
  const ValidationError({
    required this.code,
    required this.messageKey,
    this.args = const <String, Object?>{},
  });

  final String code;
  final String messageKey;
  final Map<String, Object?> args;
}

/// A validation failure that can contain both field-level and form-level errors.
final class ValidationFailure {
  const ValidationFailure({
    this.fieldErrors = const <FieldKey, List<ValidationError>>{},
    this.formErrors = const <ValidationError>[],
  });

  final Map<FieldKey, List<ValidationError>> fieldErrors;
  final List<ValidationError> formErrors;

  bool get hasErrors => fieldErrors.isNotEmpty || formErrors.isNotEmpty;
}
