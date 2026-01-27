import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_ui/taskly_ui_forms.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

/// Curated palette for Value colors (8 hues).
///
/// Light and dark variants intentionally shift in luminance to keep tags
/// legible across themes while preserving hue identity.
const List<Color> _valueColorPaletteTasklyProLight = <Color>[
  Color(0xFF3B82F6),
  Color(0xFF10B981),
  Color(0xFF8B5CF6),
  Color(0xFFF59E0B),
  Color(0xFFEC4899),
  Color(0xFF06B6D4),
  Color(0xFF14B8A6),
  Color(0xFFEF4444),
];

const List<Color> _valueColorPaletteTasklyProDark = <Color>[
  Color(0xFF3B82F6),
  Color(0xFF10B981),
  Color(0xFF8B5CF6),
  Color(0xFFF59E0B),
  Color(0xFFEC4899),
  Color(0xFF06B6D4),
  Color(0xFF14B8A6),
  Color(0xFFEF4444),
];

class FormBuilderColorPicker extends StatelessWidget {
  const FormBuilderColorPicker({
    required this.name,
    this.title = 'Color',
    this.showLabel = true,
    this.compact = false,
    this.validator,
    super.key,
  });

  final String name;
  final String title;
  final bool showLabel;
  final bool compact;
  final FormFieldValidator<Color>? validator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tokens = TasklyTokens.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final palette = isDark
        ? _valueColorPaletteTasklyProDark
        : _valueColorPaletteTasklyProLight;

    return FormBuilderField<Color>(
      name: name,
      validator: validator,
      builder: (field) {
        final value = field.value ?? cs.primary;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showLabel)
              Padding(
                padding: EdgeInsets.only(
                  bottom: compact ? tokens.spaceXs2 : tokens.spaceSm,
                ),
                child: Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            TasklyFormColorPalettePicker(
              colors: palette,
              selectedColor: value,
              onSelected: (color) => field.didChange(color),
            ),
            if (field.errorText != null) ...[
              SizedBox(height: tokens.spaceSm),
              Text(
                field.errorText!,
                style: theme.textTheme.bodySmall?.copyWith(color: cs.error),
              ),
            ],
          ],
        );
      },
    );
  }
}
