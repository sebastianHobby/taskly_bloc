import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';

/// A modern color picker field displayed as a chip with color circle.
///
/// Features:
/// - Material 3 chip design
/// - Predefined color palette
/// - Visual color circle in chip
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

  static const List<Color> _availableColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
    Colors.black,
  ];

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
        valueTransformer: (Color? color) {
          return color != null ? ColorUtils.toHexWithHash(color) : null;
        },
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
                label: Text(showLabel ? 'Color' : 'Color'),
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
    final selectedColor = await showDialog<Color>(
      context: context,
      builder: (context) => _ColorPickerDialog(
        currentColor: field.value ?? initialValue,
        availableColors: _availableColors,
      ),
    );

    if (selectedColor != null) {
      field.didChange(selectedColor);
    }
  }
}

class _ColorPickerDialog extends StatelessWidget {
  const _ColorPickerDialog({
    required this.currentColor,
    required this.availableColors,
  });

  final Color currentColor;
  final List<Color> availableColors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Select Color',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: availableColors.map((color) {
                final isSelected = color == currentColor;
                return GestureDetector(
                  onTap: () => Navigator.of(context).pop(color),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outline,
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            color: _getContrastColor(color),
                            size: 24,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
