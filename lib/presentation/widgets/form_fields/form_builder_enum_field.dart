import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

/// A radio group field for enum values in FormBuilder.
///
/// Provides a type-safe way to select from enum values with:
/// - Automatic RadioListTile generation
/// - Title and description display
/// - Custom label/description callbacks
class FormBuilderEnumRadioGroup<T extends Enum> extends StatelessWidget {
  const FormBuilderEnumRadioGroup({
    required this.name,
    required this.values,
    required this.labelBuilder,
    this.initialValue,
    this.descriptionBuilder,
    this.onChanged,
    this.enabled = true,
    this.validator,
    this.dense = false,
    super.key,
  });

  /// Form field name
  final String name;

  /// List of enum values to display
  final List<T> values;

  /// Builds the label text for each enum value
  final String Function(T value) labelBuilder;

  /// Initial selected value
  final T? initialValue;

  /// Builds the description text for each enum value (optional)
  final String Function(T value)? descriptionBuilder;

  /// Called when selection changes
  final void Function(T?)? onChanged;

  /// Whether the field is enabled
  final bool enabled;

  /// Custom validator
  final String? Function(T?)? validator;

  /// Whether to use dense styling
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<T>(
      name: name,
      initialValue: initialValue,
      enabled: enabled,
      validator: validator,
      builder: (field) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: values.map((value) {
            return RadioListTile<T>(
              title: Text(labelBuilder(value)),
              subtitle: descriptionBuilder != null
                  ? Text(descriptionBuilder!(value))
                  : null,
              value: value,
              groupValue: field.value,
              dense: dense,
              onChanged: enabled
                  ? (newValue) {
                      field.didChange(newValue);
                      onChanged?.call(newValue);
                    }
                  : null,
            );
          }).toList(),
        );
      },
    );
  }
}

/// A segmented button field for enum values in FormBuilder.
///
/// Compact alternative to radio group for small enum sets.
class FormBuilderSegmentedField<T extends Enum> extends StatelessWidget {
  const FormBuilderSegmentedField({
    required this.name,
    required this.values,
    required this.labelBuilder,
    this.initialValue,
    this.iconBuilder,
    this.onChanged,
    this.enabled = true,
    this.showSelectedIcon = false,
    this.multiSelectionEnabled = false,
    super.key,
  });

  /// Form field name
  final String name;

  /// List of enum values to display
  final List<T> values;

  /// Builds the label widget for each enum value
  final Widget Function(T value) labelBuilder;

  /// Initial selected value
  final T? initialValue;

  /// Builds an optional icon for each enum value
  final Widget Function(T value)? iconBuilder;

  /// Called when selection changes
  final void Function(T?)? onChanged;

  /// Whether the field is enabled
  final bool enabled;

  /// Whether to show a checkmark on selected segment
  final bool showSelectedIcon;

  /// Whether multiple segments can be selected
  final bool multiSelectionEnabled;

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<T>(
      name: name,
      initialValue: initialValue,
      enabled: enabled,
      builder: (field) {
        return SegmentedButton<T>(
          segments: values.map((value) {
            return ButtonSegment<T>(
              value: value,
              label: labelBuilder(value),
              icon: iconBuilder?.call(value),
            );
          }).toList(),
          selected: field.value != null ? {field.value!} : {},
          onSelectionChanged: enabled
              ? (selection) {
                  final newValue = selection.firstOrNull;
                  field.didChange(newValue);
                  onChanged?.call(newValue);
                }
              : null,
          showSelectedIcon: showSelectedIcon,
          multiSelectionEnabled: multiSelectionEnabled,
        );
      },
    );
  }
}
