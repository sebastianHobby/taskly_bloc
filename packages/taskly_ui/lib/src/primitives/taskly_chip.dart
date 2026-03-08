import 'package:flutter/material.dart';

import 'package:taskly_ui/src/foundations/theme/taskly_semantic_themes.dart';
import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';

class TasklyChip extends StatelessWidget {
  const TasklyChip({
    required this.label,
    this.variant = TasklyChipVariant.metric,
    this.padding,
    super.key,
  });

  final String label;
  final TasklyChipVariant variant;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final chipTheme = TasklyChipTheme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: chipTheme.background(variant),
        borderRadius: BorderRadius.circular(tokens.radiusPill),
        border: Border.all(color: chipTheme.border(variant)),
      ),
      child: Padding(
        padding:
            padding ??
            EdgeInsets.symmetric(
              horizontal: tokens.spaceSm2,
              vertical: tokens.spaceXs2,
            ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: chipTheme.foreground(variant),
          ),
        ),
      ),
    );
  }
}
