import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

/// Curated palettes for Value colors.
///
/// Keep these lists stable to help users build a consistent mental model.
const List<Color> _valueColorPaletteCalmStudio = <Color>[
  Color(0xFF4F5B7A), // Slate Indigo
  Color(0xFF4E6B8A), // Mist Blue
  Color(0xFF4F7A7A), // Soft Teal
  Color(0xFF5E7C6A), // Sage
  Color(0xFF6C8063), // Moss
  Color(0xFF9C8B6E), // Warm Sand
  Color(0xFFA07C7A), // Dusty Rose
  Color(0xFF7D6F8A), // Lavender Grey
  Color(0xFF7B8492), // Storm Grey
];

const List<Color> _valueColorPaletteWellbeingNeutral = <Color>[
  Color(0xFF5B657A), // Blue Grey
  Color(0xFF6C7E85), // Quiet Teal
  Color(0xFF6E7B63), // Olive Sage
  Color(0xFF7C6E5E), // Clay
  Color(0xFF8C7B6E), // Warm Taupe
  Color(0xFFB08E6C), // Soft Amber
  Color(0xFFA07A6A), // Terracotta
  Color(0xFF7A6D86), // Muted Violet
  Color(0xFF858E8D), // Pebble
];

const List<Color> _valueColorPaletteMinimalPremium = <Color>[
  Color(0xFF576277), // Ink Slate
  Color(0xFF5D7186), // Steel Blue
  Color(0xFF5C7A78), // Eucalyptus
  Color(0xFF657A6A), // Pine
  Color(0xFF7B6F63), // Cocoa
  Color(0xFF9C8A73), // Parchment
  Color(0xFF9B7B82), // Mauve Grey
  Color(0xFF7F768C), // Hushed Violet
  Color(0xFF7F8893), // Fog
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

    return FormBuilderField<Color>(
      name: name,
      validator: validator,
      builder: (field) {
        final value = field.value ?? cs.primary;

        Future<void> pick() async {
          final picked = await _ValueColorPickerSheet.show(
            context,
            title: title,
            current: value,
          );

          if (picked != null) field.didChange(picked);
        }

        final height = compact ? 44.0 : 52.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showLabel)
              Padding(
                padding: EdgeInsets.only(bottom: tokens.spaceSm),
                child: Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            InkWell(
              onTap: pick,
              borderRadius: BorderRadius.circular(tokens.radiusMd),
              child: Container(
                height: height,
                padding: EdgeInsets.symmetric(horizontal: tokens.spaceMd),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(tokens.radiusMd),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: value,
                        shape: BoxShape.circle,
                        border: Border.all(color: cs.outlineVariant),
                      ),
                    ),
                    SizedBox(width: tokens.spaceMd),
                    Expanded(
                      child: Text(
                        '#${value.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.palette_outlined, color: cs.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            if (field.errorText != null) ...[
              SizedBox(height: tokens.spaceMd2),
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

class _ValueColorPickerSheet extends StatelessWidget {
  const _ValueColorPickerSheet({
    required this.title,
    required this.current,
  });

  final String title;
  final Color current;

  static Future<Color?> show(
    BuildContext context, {
    required String title,
    required Color current,
  }) {
    return showModalBottomSheet<Color>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _ValueColorPickerSheet(
        title: title,
        current: current,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final media = MediaQuery.of(context);
    final tokens = TasklyTokens.of(context);

    final crossAxisCount = media.size.width < 420 ? 6 : 8;

    return SizedBox(
      height: media.size.height * 0.62,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              tokens.spaceLg,
              tokens.spaceSm,
              tokens.spaceSm,
              tokens.spaceSm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(tokens.radiusMd),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Padding(
                padding: EdgeInsets.all(tokens.spaceMd),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: current,
                        shape: BoxShape.circle,
                        border: Border.all(color: cs.outlineVariant),
                      ),
                    ),
                    SizedBox(width: tokens.spaceMd),
                    Expanded(
                      child: Text(
                        _hexLabel(current),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: tokens.spaceMd2),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                tokens.spaceLg,
                0,
                tokens.spaceLg,
                tokens.spaceLg,
              ),
              children: [
                _PaletteSection(
                  title: 'Calm Studio',
                  colors: _valueColorPaletteCalmStudio,
                  current: current,
                  crossAxisCount: crossAxisCount,
                ),
                SizedBox(height: tokens.spaceLg),
                _PaletteSection(
                  title: 'Wellbeing Neutral',
                  colors: _valueColorPaletteWellbeingNeutral,
                  current: current,
                  crossAxisCount: crossAxisCount,
                ),
                SizedBox(height: tokens.spaceLg),
                _PaletteSection(
                  title: 'Minimal Premium',
                  colors: _valueColorPaletteMinimalPremium,
                  current: current,
                  crossAxisCount: crossAxisCount,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _hexLabel(Color color) {
    return '#${color.value.toRadixString(16).toUpperCase().padLeft(8, '0')}';
  }
}

class _ColorDotTile extends StatelessWidget {
  const _ColorDotTile({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = TasklyTokens.of(context);
    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(tokens.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(tokens.radiusMd),
            border: Border.all(
              color: selected ? cs.primary : cs.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaletteSection extends StatelessWidget {
  const _PaletteSection({
    required this.title,
    required this.colors,
    required this.current,
    required this.crossAxisCount,
  });

  final String title;
  final List<Color> colors;
  final Color current;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tokens = TasklyTokens.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: tokens.spaceSm2),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: tokens.spaceSm2,
            crossAxisSpacing: tokens.spaceSm2,
          ),
          itemCount: colors.length,
          itemBuilder: (context, index) {
            final color = colors[index];
            final selected = color.value == current.value;

            return _ColorDotTile(
              color: color,
              selected: selected,
              onTap: () => Navigator.of(context).pop(color),
            );
          },
        ),
      ],
    );
  }
}
