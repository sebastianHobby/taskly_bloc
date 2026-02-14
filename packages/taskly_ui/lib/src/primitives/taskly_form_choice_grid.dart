import 'package:flutter/material.dart';

import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';

class TasklyFormChoiceGrid extends StatelessWidget {
  const TasklyFormChoiceGrid({
    required this.values,
    required this.isSelected,
    required this.labelBuilder,
    required this.onTap,
    this.columns = 7,
    super.key,
  });

  final List<int> values;
  final bool Function(int value) isSelected;
  final String Function(int value) labelBuilder;
  final ValueChanged<int> onTap;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final size = tokens.minTapTargetSize;

    return Wrap(
      spacing: tokens.spaceXs2,
      runSpacing: tokens.spaceXs2,
      children: [
        for (final value in values)
          _ChoiceChip(
            label: labelBuilder(value),
            selected: isSelected(value),
            size: size,
            onTap: () => onTap(value),
          ),
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.size,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = selected ? scheme.onPrimary : scheme.onSurfaceVariant;
    final background = selected ? scheme.primary : scheme.surfaceContainerLow;

    return Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: foreground,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
