import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

/// A slider field for FormBuilder with value display.
///
/// Features:
/// - Configurable min/max/divisions
/// - Value label display
/// - Unit suffix support
/// - Wrapped in ListTile for settings-style use
class FormBuilderSliderField extends StatelessWidget {
  const FormBuilderSliderField({
    required this.name,
    required this.min,
    required this.max,
    this.initialValue,
    this.divisions,
    this.label,
    this.unit,
    this.formatValue,
    this.onChanged,
    this.enabled = true,
    super.key,
  });

  /// Form field name
  final String name;

  /// Minimum slider value
  final double min;

  /// Maximum slider value
  final double max;

  /// Initial value
  final double? initialValue;

  /// Number of discrete divisions
  final int? divisions;

  /// Label text
  final String? label;

  /// Unit suffix for display
  final String? unit;

  /// Custom value formatter
  final String Function(double value)? formatValue;

  /// Called when value changes
  final void Function(double?)? onChanged;

  /// Whether the field is enabled
  final bool enabled;

  String _defaultFormatValue(double value) {
    if (unit == '%') {
      return '${(value * 100).round()}%';
    }
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FormBuilderField<double>(
      name: name,
      initialValue: initialValue ?? min,
      enabled: enabled,
      builder: (field) {
        final value = field.value ?? min;
        final displayValue =
            formatValue?.call(value) ??
            _defaultFormatValue(value) + (unit ?? '');

        return ListTile(
          title: label != null ? Text(label!) : null,
          subtitle: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            label: displayValue,
            onChanged: enabled
                ? (newValue) {
                    field.didChange(newValue);
                    onChanged?.call(newValue);
                  }
                : null,
          ),
          trailing: Text(
            displayValue,
            style: theme.textTheme.titleMedium,
          ),
        );
      },
    );
  }
}

/// A switch field for FormBuilder wrapped in a ListTile.
///
/// Convenience wrapper for settings-style boolean toggles.
class FormBuilderSwitchTile extends StatelessWidget {
  const FormBuilderSwitchTile({
    required this.name,
    required this.title,
    this.subtitle,
    this.initialValue = false,
    this.onChanged,
    this.enabled = true,
    this.secondary,
    this.dense = false,
    super.key,
  });

  /// Form field name
  final String name;

  /// Title text
  final String title;

  /// Optional subtitle text
  final String? subtitle;

  /// Initial value
  final bool initialValue;

  /// Called when value changes
  final void Function(bool?)? onChanged;

  /// Whether the field is enabled
  final bool enabled;

  /// Leading widget (icon)
  final Widget? secondary;

  /// Whether to use dense styling
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<bool>(
      name: name,
      initialValue: initialValue,
      enabled: enabled,
      builder: (field) {
        return SwitchListTile(
          title: Text(title),
          subtitle: subtitle != null ? Text(subtitle!) : null,
          value: field.value ?? false,
          onChanged: enabled
              ? (value) {
                  field.didChange(value);
                  onChanged?.call(value);
                }
              : null,
          secondary: secondary,
          dense: dense,
        );
      },
    );
  }
}
