import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

/// A compact number input field for FormBuilder.
///
/// Provides a consistent number input experience with:
/// - Integer or decimal support
/// - Min/max validation
/// - Compact or standard sizing
/// - Optional unit suffix
class FormBuilderNumberField extends StatelessWidget {
  const FormBuilderNumberField({
    required this.name,
    this.label,
    this.initialValue,
    this.min,
    this.max,
    this.allowDecimal = false,
    this.compact = false,
    this.unit,
    this.onChanged,
    this.enabled = true,
    this.validator,
    super.key,
  });

  /// Form field name
  final String name;

  /// Optional label text
  final String? label;

  /// Initial numeric value
  final num? initialValue;

  /// Minimum allowed value
  final num? min;

  /// Maximum allowed value
  final num? max;

  /// Whether to allow decimal input
  final bool allowDecimal;

  /// Use compact sizing (for inline/trailing use)
  final bool compact;

  /// Optional unit suffix (e.g., "days", "%")
  final String? unit;

  /// Called when value changes
  final void Function(num?)? onChanged;

  /// Whether the field is enabled
  final bool enabled;

  /// Custom validator
  final String? Function(num?)? validator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FormBuilderField<num>(
      name: name,
      initialValue: initialValue,
      enabled: enabled,
      validator: (value) {
        if (validator != null) {
          final customError = validator!(value);
          if (customError != null) return customError;
        }
        if (value != null) {
          if (min != null && value < min!) {
            return 'Must be at least $min';
          }
          if (max != null && value > max!) {
            return 'Must be at most $max';
          }
        }
        return null;
      },
      builder: (field) {
        final textController = TextEditingController(
          text: field.value?.toString() ?? '',
        );

        return SizedBox(
          width: compact ? 80 : null,
          child: TextField(
            controller: textController,
            enabled: enabled,
            keyboardType: TextInputType.numberWithOptions(
              decimal: allowDecimal,
              signed: min != null && min! < 0,
            ),
            inputFormatters: [
              if (allowDecimal)
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
              else
                FilteringTextInputFormatter.digitsOnly,
            ],
            textAlign: compact ? TextAlign.center : TextAlign.start,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              labelText: compact ? null : label,
              hintText: compact ? label : null,
              suffixText: unit,
              filled: true,
              fillColor: colorScheme.surfaceContainerLow,
              isDense: compact,
              contentPadding: compact
                  ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                  : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(compact ? 8 : 12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(compact ? 8 : 12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(compact ? 8 : 12),
                borderSide: BorderSide(
                  color: colorScheme.primary,
                  width: 1.5,
                ),
              ),
              errorText: field.errorText,
            ),
            onChanged: (text) {
              final parsed = allowDecimal
                  ? double.tryParse(text)
                  : int.tryParse(text);
              field.didChange(parsed);
              onChanged?.call(parsed);
            },
          ),
        );
      },
    );
  }
}

/// A ListTile with an integrated number input in the trailing position.
///
/// Convenience wrapper for settings-style number inputs.
class NumberInputTile extends StatelessWidget {
  const NumberInputTile({
    required this.name,
    required this.title,
    this.subtitle,
    this.initialValue,
    this.min,
    this.max,
    this.allowDecimal = false,
    this.unit,
    this.onChanged,
    this.enabled = true,
    this.leading,
    super.key,
  });

  final String name;
  final String title;
  final String? subtitle;
  final num? initialValue;
  final num? min;
  final num? max;
  final bool allowDecimal;
  final String? unit;
  final void Function(num?)? onChanged;
  final bool enabled;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      enabled: enabled,
      trailing: FormBuilderNumberField(
        name: name,
        initialValue: initialValue,
        min: min,
        max: max,
        allowDecimal: allowDecimal,
        compact: true,
        unit: unit,
        onChanged: onChanged,
        enabled: enabled,
      ),
    );
  }
}
