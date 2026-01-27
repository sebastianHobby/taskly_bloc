import 'package:flutter/material.dart';

import 'package:taskly_ui/src/forms/taskly_form_preset.dart';
import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';

class TasklyFormSheet extends StatelessWidget {
  const TasklyFormSheet({
    required this.child,
    required this.preset,
    this.title,
    this.padding,
    super.key,
  });

  final String? title;
  final Widget child;
  final TasklyFormPreset preset;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = TasklyTokens.of(context);
    return Padding(
      padding: padding ?? EdgeInsets.all(tokens.spaceXl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: theme.textTheme.headlineSmall,
            ),
            SizedBox(height: tokens.spaceXl),
          ],
          child,
        ],
      ),
    );
  }
}
