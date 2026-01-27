import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';

import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';

/// Reusable color picker field using flex_color_picker.
///
/// Displays the current color as a button with the color swatch.
/// Tapping opens a Material 3 style color picker dialog.
class ColorPickerField extends StatelessWidget {
  const ColorPickerField({
    required this.color,
    required this.onColorChanged,
    this.label,
    this.dialogTitle,
    this.colorNameBuilder,
    this.enabled = true,
    this.showMaterialName = false,
    this.enableOpacity = false,
    super.key,
  });

  final Color color;
  final ValueChanged<Color> onColorChanged;
  final String? label;

  /// Optional dialog title widget.
  ///
  /// Shared UI must not hardcode user-facing strings; if you want a title,
  /// pass a localized widget from the app.
  final Widget? dialogTitle;

  /// Optional label for the current color.
  ///
  /// If not provided, a non-localized hex code is shown.
  final String Function(Color color)? colorNameBuilder;
  final bool enabled;
  final bool showMaterialName;
  final bool enableOpacity;

  @override
  Widget build(BuildContext context) {
    final displayName =
        colorNameBuilder?.call(color) ?? _defaultColorLabel(color);
    final tokens = TasklyTokens.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          SizedBox(height: tokens.spaceSm),
        ],
        InkWell(
          onTap: enabled ? () => _showColorPicker(context) : null,
          borderRadius: BorderRadius.circular(tokens.radiusSm),
          child: Container(
            height: tokens.minTapTargetSize + tokens.spaceSm,
            padding: EdgeInsets.symmetric(horizontal: tokens.spaceMd),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
              ),
              borderRadius: BorderRadius.circular(tokens.radiusSm),
            ),
            child: Row(
              children: [
                Container(
                  width: tokens.spaceXxl,
                  height: tokens.spaceXxl,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(tokens.radiusXs),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
                SizedBox(width: tokens.spaceMd),
                Text(
                  displayName,
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
      title: dialogTitle,
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

  String _defaultColorLabel(Color color) {
    final hex = color.value.toRadixString(16).toUpperCase().padLeft(8, '0');
    return '#$hex';
  }
}
