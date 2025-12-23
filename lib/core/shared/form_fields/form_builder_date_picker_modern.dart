import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/core/utils/date_only.dart';

/// A modern date picker field with consistent styling and Material 3 design.
///
/// Features:
/// - Consistent visual design
/// - Proper Material 3 styling
/// - Support for start and deadline date types
/// - Built-in validation and date formatting
class FormBuilderDatePickerModern extends StatelessWidget {
  const FormBuilderDatePickerModern({
    required this.name,
    this.label,
    this.hint,
    this.initialValue,
    this.validator,
    this.enabled = true,
    this.isRequired = false,
    this.firstDate,
    this.lastDate,
    this.dateType = DateFieldType.standard,
    super.key,
  });

  final String name;
  final String? label;
  final String? hint;
  final DateTime? initialValue;
  final String? Function(DateTime?)? validator;
  final bool enabled;
  final bool isRequired;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final DateFieldType dateType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: FormBuilderDateTimePicker(
        name: name,
        initialValue: initialValue,
        validator: validator,
        valueTransformer: (DateTime? value) {
          return value != null ? dateOnly(value) : null;
        },
        enabled: enabled,
        inputType: InputType.date,
        firstDate: firstDate,
        lastDate: lastDate,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: _getPrefixIcon(colorScheme),
          suffixIcon: _getSuffixIcon(),
          filled: true,
          fillColor: colorScheme.surfaceContainerLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: colorScheme.outline.withOpacity(0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: colorScheme.outline.withOpacity(0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: colorScheme.primary,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: colorScheme.error,
              width: 2,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: colorScheme.error,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _getPrefixIcon(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(left: 12, right: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _getIconBackgroundColor(colorScheme),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _getIconData(),
        size: 14,
        color: _getIconColor(colorScheme),
      ),
    );
  }

  Widget? _getSuffixIcon() {
    return const Icon(
      Icons.calendar_today,
      size: 14,
    );
  }

  IconData _getIconData() {
    return switch (dateType) {
      DateFieldType.startDate => Icons.calendar_today,
      DateFieldType.deadline => Icons.flag,
      DateFieldType.standard => Icons.event,
    };
  }

  Color _getIconBackgroundColor(ColorScheme colorScheme) {
    return switch (dateType) {
      DateFieldType.startDate => colorScheme.primaryContainer,
      DateFieldType.deadline => colorScheme.errorContainer,
      DateFieldType.standard => colorScheme.secondaryContainer,
    };
  }

  Color _getIconColor(ColorScheme colorScheme) {
    return switch (dateType) {
      DateFieldType.startDate => colorScheme.onPrimaryContainer,
      DateFieldType.deadline => colorScheme.onErrorContainer,
      DateFieldType.standard => colorScheme.onSecondaryContainer,
    };
  }
}

/// Different visual styles for date fields.
enum DateFieldType {
  /// Start date field with play icon
  startDate,

  /// Deadline date field with flag icon
  deadline,

  /// Standard date field with calendar icon
  standard,
}
