import 'package:flutter/material.dart';

class TasklyFormSectionLabel extends StatelessWidget {
  const TasklyFormSectionLabel({
    required this.text,
    super.key,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
    );

    return Text(
      text.toUpperCase(),
      style: labelStyle,
    );
  }
}
