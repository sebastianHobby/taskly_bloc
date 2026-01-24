import 'package:flutter/material.dart';

import 'package:taskly_ui/src/forms/taskly_form_preset.dart';

class TasklyFormSheet extends StatelessWidget {
  const TasklyFormSheet({
    required this.child,
    required this.preset,
    this.title,
    this.padding = const EdgeInsets.all(24),
    super.key,
  });

  final String? title;
  final Widget child;
  final TasklyFormPreset preset;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
          ],
          child,
        ],
      ),
    );
  }
}
