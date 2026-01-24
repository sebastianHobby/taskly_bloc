import 'package:flutter/widgets.dart';

import 'package:taskly_domain/core.dart';
import 'package:taskly_bloc/presentation/shared/validation/validation_error_message.dart';

String? Function(T?) toFormBuilderValidator<T>(
  List<ValidationError> Function(T?) validator,
  BuildContext context,
) {
  return (value) {
    final errors = validator(value);
    if (errors.isEmpty) return null;
    final message = errors
        .map((e) => validationErrorMessage(context, e))
        .where((m) => m.trim().isNotEmpty)
        .join('\n');
    return message.isEmpty ? null : message;
  };
}
