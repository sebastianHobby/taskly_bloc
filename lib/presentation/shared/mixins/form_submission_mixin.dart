import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_domain/domain/core/editing/validation_error.dart';
import 'package:taskly_bloc/presentation/shared/validation/validation_error_message.dart';

/// Mixin for handling common form submission patterns in detail views.
///
/// Provides helpers for form validation and value extraction to reduce
/// duplication across task, project, and label forms.
mixin FormSubmissionMixin {
  /// Validates the form and returns the form values if valid.
  /// Returns null if form is invalid or form state is null.
  Map<String, dynamic>? validateAndGetFormValues(
    GlobalKey<FormBuilderState> formKey,
  ) {
    final formState = formKey.currentState;
    if (formState == null) return null;
    if (!formState.saveAndValidate()) return null;
    return formState.value;
  }

  /// Helper to safely extract a string value from form values.
  String extractStringValue(
    Map<String, dynamic> formValues,
    String key, {
    String defaultValue = '',
  }) {
    return (formValues[key] as String?) ?? defaultValue;
  }

  /// Helper to safely extract a nullable string value from form values.
  /// Returns null for empty strings.
  String? extractNullableStringValue(
    Map<String, dynamic> formValues,
    String key,
  ) {
    final value = (formValues[key] as String?)?.trim();
    return (value == null || value.isEmpty) ? null : value;
  }

  /// Helper to safely extract a boolean value from form values.
  bool extractBoolValue(
    Map<String, dynamic> formValues,
    String key, {
    bool defaultValue = false,
  }) {
    return (formValues[key] as bool?) ?? defaultValue;
  }

  /// Helper to safely extract a DateTime value from form values.
  DateTime? extractDateTimeValue(
    Map<String, dynamic> formValues,
    String key,
  ) {
    return formValues[key] as DateTime?;
  }

  /// Helper to safely extract a list of strings from form values.
  List<String> extractStringListValue(
    Map<String, dynamic> formValues,
    String key,
  ) {
    return (formValues[key] as List<dynamic>?)?.cast<String>() ?? <String>[];
  }

  /// Applies domain validation errors onto the current FormBuilder state.
  ///
  /// This uses [FieldKey.id] as the FormBuilder field name.
  void applyValidationFailureToForm(
    GlobalKey<FormBuilderState> formKey,
    ValidationFailure failure,
    BuildContext context,
  ) {
    final formState = formKey.currentState;
    if (formState == null) return;

    for (final entry in failure.fieldErrors.entries) {
      final fieldName = entry.key.id;
      final field = formState.fields[fieldName];
      if (field == null) continue;

      final message = entry.value
          .map((e) => validationErrorMessage(context, e))
          .where((m) => m.trim().isNotEmpty)
          .join('\n');

      if (message.isNotEmpty) {
        field.invalidate(message);
      }
    }
  }
}
