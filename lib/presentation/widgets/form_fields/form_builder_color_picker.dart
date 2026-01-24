import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

/// Curated palette for Value colors.
///
/// Keep this list stable to help users build a consistent mental model.
const List<Color> _valueColorPalette = <Color>[
  Color(0xFF4F46E5), // Indigo
  Color(0xFF0EA5E9), // Sky
  Color(0xFF14B8A6), // Teal
  Color(0xFF10B981), // Emerald
  Color(0xFFF59E0B), // Amber
  Color(0xFFEF4444), // Red
  Color(0xFFE11D48), // Rose
  Color(0xFF8B5CF6), // Violet
  Color(0xFF64748B), // Slate
  Color(0xFF22C55E), // Green
  Color(0xFF1E88E5), // Blue
  Color(0xFFFB8C00), // Orange
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
                padding: const EdgeInsets.only(bottom: 8),
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
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: height,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
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
                    const SizedBox(width: 12),
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
              const SizedBox(height: 6),
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

    final crossAxisCount = media.size.width < 420 ? 6 : 8;

    return SizedBox(
      height: media.size.height * 0.62,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
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
                    const SizedBox(width: 12),
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

          const SizedBox(height: 14),

          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: _valueColorPalette.length,
              itemBuilder: (context, index) {
                final color = _valueColorPalette[index];
                final selected = color.value == current.value;

                return _ColorDotTile(
                  color: color,
                  selected: selected,
                  onTap: () => Navigator.of(context).pop(color),
                );
              },
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
    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
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
