import 'package:taskly_domain/src/core/editing/validation_error.dart';

final class ValueValidators {
  ValueValidators._();

  static const int maxNameLength = 30;

  static List<ValidationError> name(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) {
      return const [
        ValidationError(code: 'required', messageKey: 'valueFormNameRequired'),
      ];
    }
    if (trimmed.length > maxNameLength) {
      return [
        ValidationError(
          code: 'max_length',
          messageKey: 'valueFormNameTooLong',
          args: const {'max': maxNameLength},
        ),
      ];
    }
    return const [];
  }

  static List<ValidationError> color(String? value) {
    if (value == null || value.trim().isEmpty) {
      return const [
        ValidationError(code: 'required', messageKey: 'validationRequired'),
      ];
    }
    return const [];
  }

  static List<ValidationError> iconName(String? value) {
    if (value == null) return const [];
    if (value.trim().isEmpty) {
      return const [
        ValidationError(code: 'required', messageKey: 'validationRequired'),
      ];
    }
    return const [];
  }
}
