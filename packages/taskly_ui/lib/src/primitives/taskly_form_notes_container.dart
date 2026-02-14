import 'package:flutter/material.dart';

import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';

class TasklyFormNotesContainer extends StatelessWidget {
  const TasklyFormNotesContainer({
    required this.child,
    this.height,
    super.key,
  });

  final Widget child;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;

    final body = Container(
      height: height,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: child,
    );

    return body;
  }
}
