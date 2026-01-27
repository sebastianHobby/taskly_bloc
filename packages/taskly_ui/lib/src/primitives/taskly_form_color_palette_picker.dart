import 'package:flutter/material.dart';
import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';

/// Inline color palette picker used by forms.
///
/// Pure UI: data in / events out.
class TasklyFormColorPalettePicker extends StatelessWidget {
  const TasklyFormColorPalettePicker({
    required this.colors,
    required this.onSelected,
    this.selectedColor,
    this.crossAxisCount,
    super.key,
  });

  final List<Color> colors;
  final Color? selectedColor;
  final ValueChanged<Color> onSelected;
  final int? crossAxisCount;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = TasklyTokens.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final columns = crossAxisCount ?? (width < 360 ? 4 : 4);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceSm),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: tokens.spaceSm2,
            crossAxisSpacing: tokens.spaceSm2,
          ),
          itemCount: colors.length,
          itemBuilder: (context, index) {
            final color = colors[index];
            final selected =
                selectedColor != null && color.value == selectedColor!.value;
            return _ColorSwatchTile(
              color: color,
              selected: selected,
              onTap: () => onSelected(color),
            );
          },
        ),
      ),
    );
  }
}

class _ColorSwatchTile extends StatelessWidget {
  const _ColorSwatchTile({
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
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(
                  color: selected ? cs.primary : cs.outlineVariant,
                  width: selected ? 2 : 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
