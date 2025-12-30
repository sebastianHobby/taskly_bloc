import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';

/// Reusable color picker field using flex_color_picker.
///
/// Displays the current color as a button with the color swatch.
/// Tapping opens a Material 3 style color picker dialog.
class ColorPickerField extends StatelessWidget {
  const ColorPickerField({
    required this.color,
    required this.onColorChanged,
    this.label,
    this.enabled = true,
    this.showMaterialName = false,
    this.enableOpacity = false,
    super.key,
  });

  final Color color;
  final ValueChanged<Color> onColorChanged;
  final String? label;
  final bool enabled;
  final bool showMaterialName;
  final bool enableOpacity;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
        ],
        InkWell(
          onTap: enabled ? () => _showColorPicker(context) : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  ColorTools.nameThatColor(color),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showColorPicker(BuildContext context) async {
    final pickedColor = await showColorPickerDialog(
      context,
      color,
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

    if (pickedColor != color) {
      onColorChanged(pickedColor);
    }
  }
}
