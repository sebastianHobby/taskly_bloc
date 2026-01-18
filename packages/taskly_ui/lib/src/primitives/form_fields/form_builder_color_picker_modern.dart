import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flex_color_picker/flex_color_picker.dart';

/// A modern color picker field for FormBuilder using flex_color_picker.
///
/// Features:
/// - Material 3 design
/// - Full color selection with wheel, shades, and predefined palettes
/// - Visual color circle in action chip
/// - Integrates with FormBuilder validation
class FormBuilderColorPickerModern extends StatelessWidget {
  const FormBuilderColorPickerModern({
    required this.name,
    this.label,
    this.hint,
    this.initialValue = Colors.blue,
    this.validator,
    this.enabled = true,
    this.isRequired = false,
    this.requiredErrorText,
    this.showLabel = true,
    this.compact = false,
    this.showMaterialName = false,
    this.enableOpacity = false,
    this.dialogTitle,
    this.chipLabelBuilder,
    super.key,
  });

  final String name;
  final String? label;
  final String? hint;
  final Color initialValue;
  final String? Function(Color?)? validator;
  final bool enabled;
  final bool isRequired;

  /// Error text returned when [isRequired] is true and no color is selected.
  ///
  /// Shared UI must not hardcode user-facing strings; provide localized text
  /// from the app.
  final String? requiredErrorText;

  /// Whether to show the label above the chip.
  final bool showLabel;

  /// If true, removes padding for inline use.
  final bool compact;

  /// Whether to show the material color name.
  final bool showMaterialName;

  /// Whether to enable opacity/alpha channel.
  final bool enableOpacity;

  /// Optional dialog title.
  ///
  /// Shared UI must not hardcode user-facing strings; provide localized text
  /// from the app.
  final String? dialogTitle;

  /// Builds the label shown in the chip from the current color.
  ///
  /// If not provided, a language-neutral hex label is used.
  final String Function(Color color)? chipLabelBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    assert(
      !isRequired || requiredErrorText != null || validator != null,
      'When isRequired is true, provide requiredErrorText or validator (taskly_ui '
      'does not hardcode user-facing strings).',
    );

    return Padding(
      padding: compact
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: FormBuilderField<Color>(
        name: name,
        initialValue: initialValue,
        validator: (value) {
          if (validator != null) {
            final error = validator!(value);
            if (error != null) return error;
          }

          if (isRequired && value == null) {
            return requiredErrorText;
          }

          return null;
        },
        enabled: enabled,
        builder: (FormFieldState<Color> field) {
          final currentColor = field.value ?? initialValue;
          final resolvedChipLabel =
              chipLabelBuilder?.call(currentColor) ??
              _defaultHexLabel(currentColor, includeAlpha: enableOpacity);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showLabel && label != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    label!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              if (hint != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    hint!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ActionChip(
                avatar: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: currentColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.outline,
                      width: 1.5,
                    ),
                  ),
                ),
                label: Text(resolvedChipLabel),
                onPressed: enabled
                    ? () => _showColorPickerDialog(context, field)
                    : null,
                backgroundColor: colorScheme.surfaceContainerLow,
                side: BorderSide(
                  color: field.hasError
                      ? colorScheme.error
                      : colorScheme.outline.withValues(alpha: 0.5),
                ),
              ),
              if (field.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 12),
                  child: Text(
                    field.errorText ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _defaultHexLabel(Color color, {required bool includeAlpha}) {
    final value = includeAlpha ? color.value : (color.value & 0x00FFFFFF);
    final width = includeAlpha ? 8 : 6;
    final hex = value.toRadixString(16).toUpperCase().padLeft(width, '0');
    return '#$hex';
  }

  Future<void> _showColorPickerDialog(
    BuildContext context,
    FormFieldState<Color> field,
  ) async {
    final pickedColor = await showColorPickerDialog(
      context,
      field.value ?? initialValue,
      title: dialogTitle != null
          ? Text(dialogTitle!)
          : (label != null ? Text(label!) : const SizedBox.shrink()),
      pickersEnabled: const <ColorPickerType, bool>{
        ColorPickerType.primary: true,
        ColorPickerType.accent: true,
        ColorPickerType.wheel: true,
      },
      enableOpacity: enableOpacity,
      showMaterialName: showMaterialName,
      showColorName: true,
      showColorCode: true,
      colorCodeHasColor: true,
      copyPasteBehavior: const ColorPickerCopyPasteBehavior(
        copyButton: true,
        pasteButton: true,
        longPressMenu: true,
      ),
    );

    if (pickedColor != field.value) {
      field.didChange(pickedColor);
    }
  }
}
