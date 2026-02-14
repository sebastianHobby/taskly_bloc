import 'package:flutter/material.dart';

import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';

class TasklyFormSelectorRow extends StatelessWidget {
  const TasklyFormSelectorRow({
    required this.label,
    required this.child,
    this.spacing,
    super.key,
  });

  final String label;
  final Widget child;
  final double? spacing;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: spacing ?? tokens.spaceSm),
        child,
      ],
    );
  }
}
