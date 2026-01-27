import 'package:flutter/material.dart';

import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';

@immutable
class TasklyFormPrioritySegment {
  const TasklyFormPrioritySegment({
    required this.label,
    required this.value,
    this.selectedColor,
  });

  final String label;
  final int value;
  final Color? selectedColor;
}

class TasklyFormPrioritySegmented extends StatelessWidget {
  const TasklyFormPrioritySegmented({
    required this.segments,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final List<TasklyFormPrioritySegment> segments;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = TasklyTokens.of(context);

    return Container(
      padding: EdgeInsets.all(tokens.spaceXs),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
      ),
      child: Row(
        children: [
          for (final segment in segments)
            Expanded(
              child: _Segment(
                label: segment.label,
                selectedColor: segment.selectedColor,
                selected: value == segment.value,
                onTap: () => onChanged(
                  value == segment.value ? null : segment.value,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? selectedColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = TasklyTokens.of(context);
    final color = selected
        ? (selectedColor ?? scheme.primary)
        : scheme.onSurfaceVariant;

    return Material(
      color: selected ? scheme.surface : Colors.transparent,
      borderRadius: BorderRadius.circular(tokens.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.radiusSm),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: tokens.spaceSm),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
