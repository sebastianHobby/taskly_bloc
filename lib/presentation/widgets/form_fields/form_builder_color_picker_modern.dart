import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

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
    this.showLabel = true,
    this.compact = false,
    this.showMaterialName = false,
    this.enableOpacity = false,
    super.key,
  });

  final String name;
  final String? label;
  final String? hint;
  final Color initialValue;
  final String? Function(Color?)? validator;
  final bool enabled;
  final bool isRequired;

  /// Whether to show the label above the chip.
  final bool showLabel;

  /// If true, removes padding for inline use.
  final bool compact;

  /// Whether to show the material color name.
  final bool showMaterialName;

  /// Whether to enable opacity/alpha channel.
  final bool enableOpacity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: compact
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: FormBuilderField<Color>(
        name: name,
        initialValue: initialValue,
        validator: validator,
        enabled: enabled,
        builder: (FormFieldState<Color> field) {
          final currentColor = field.value ?? initialValue;

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
                label: Text(ColorTools.nameThatColor(currentColor)),
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

  Future<void> _showColorPickerDialog(
    BuildContext context,
    FormFieldState<Color> field,
  ) async {
    final pickedColor = await showColorPickerDialog(
      context,
      field.value ?? initialValue,
      title: Text(label ?? 'Select color'),
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
