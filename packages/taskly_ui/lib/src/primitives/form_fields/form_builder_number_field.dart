import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';

/// A compact number input field for FormBuilder.
///
/// Provides a consistent number input experience with:
/// - Integer or decimal support
/// - Optional min/max validation (with app-provided error messages)
/// - Compact or standard sizing
/// - Optional unit suffix
///
/// Note: This widget owns a [TextEditingController] to avoid recreating it in
/// build (cursor jumps / extra allocations).
class FormBuilderNumberField extends StatefulWidget {
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
    this.minErrorTextBuilder,
    this.maxErrorTextBuilder,
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

  /// Error text builder used when [min] is violated.
  ///
  /// Shared UI must not hardcode user-facing strings; provide a localized
  /// message from the app.
  final String Function(num min)? minErrorTextBuilder;

  /// Error text builder used when [max] is violated.
  ///
  /// Shared UI must not hardcode user-facing strings; provide a localized
  /// message from the app.
  final String Function(num max)? maxErrorTextBuilder;

  @override
  State<FormBuilderNumberField> createState() => _FormBuilderNumberFieldState();
}

class _FormBuilderNumberFieldState extends State<FormBuilderNumberField> {
  late final TextEditingController _controller;
  String? _lastTextSetByUser;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncControllerWithValue(num? value) {
    final nextText = value?.toString() ?? '';

    // Avoid overwriting in the same frame where the user typed.
    if (_lastTextSetByUser == nextText) {
      return;
    }

    if (_controller.text != nextText) {
      _controller.value = _controller.value.copyWith(
        text: nextText,
        selection: TextSelection.collapsed(offset: nextText.length),
        composing: TextRange.empty,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = TasklyTokens.of(context);

    assert(
      widget.min == null || widget.minErrorTextBuilder != null,
      'When min is provided, minErrorTextBuilder must be provided (taskly_ui '
      'does not hardcode user-facing strings).',
    );
    assert(
      widget.max == null || widget.maxErrorTextBuilder != null,
      'When max is provided, maxErrorTextBuilder must be provided (taskly_ui '
      'does not hardcode user-facing strings).',
    );

    return FormBuilderField<num>(
      name: widget.name,
      initialValue: widget.initialValue,
      enabled: widget.enabled,
      validator: (value) {
        if (widget.validator != null) {
          final customError = widget.validator!(value);
          if (customError != null) return customError;
        }
        if (value != null) {
          if (widget.min != null && value < widget.min!) {
            return widget.minErrorTextBuilder!(widget.min!);
          }
          if (widget.max != null && value > widget.max!) {
            return widget.maxErrorTextBuilder!(widget.max!);
          }
        }
        return null;
      },
      builder: (field) {
        _syncControllerWithValue(field.value);

        final allowSigned = widget.min != null && widget.min! < 0;
        final inputRegex = widget.allowDecimal
            ? RegExp(allowSigned ? r'[-\d.]' : r'[\d.]')
            : RegExp(allowSigned ? r'[-\d]' : r'\d');

        return SizedBox(
          width: widget.compact ? tokens.valueItemWidth + tokens.spaceSm : null,
          child: TextField(
            controller: _controller,
            enabled: widget.enabled,
            keyboardType: TextInputType.numberWithOptions(
              decimal: widget.allowDecimal,
              signed: allowSigned,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(inputRegex),
            ],
            textAlign: widget.compact ? TextAlign.center : TextAlign.start,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              labelText: widget.compact ? null : widget.label,
              hintText: widget.compact ? widget.label : null,
              suffixText: widget.unit,
              filled: true,
              fillColor: colorScheme.surfaceContainerLow,
              isDense: widget.compact,
              contentPadding: widget.compact
                  ? EdgeInsets.symmetric(
                      horizontal: tokens.spaceMd,
                      vertical: tokens.spaceSm,
                    )
                  : EdgeInsets.symmetric(
                      horizontal: tokens.spaceLg,
                      vertical: tokens.spaceMd,
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  widget.compact ? tokens.radiusSm : tokens.radiusMd,
                ),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  widget.compact ? tokens.radiusSm : tokens.radiusMd,
                ),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  widget.compact ? tokens.radiusSm : tokens.radiusMd,
                ),
                borderSide: BorderSide(
                  color: colorScheme.primary,
                  width: 1.5,
                ),
              ),
              errorText: field.errorText,
            ),
            onChanged: (text) {
              _lastTextSetByUser = text;
              final parsed = widget.allowDecimal
                  ? double.tryParse(text)
                  : int.tryParse(text);
              field.didChange(parsed);
              widget.onChanged?.call(parsed);
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
