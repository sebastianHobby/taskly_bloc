import 'package:flutter/material.dart';
import 'package:taskly_ui/src/foundations/theme/taskly_semantic_themes.dart';
import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';

ButtonStyle tasklyChromeIconButtonStyle(BuildContext context) {
  final tokens = TasklyTokens.of(context);
  final chromeTheme = TasklyAppChromeTheme.of(context);
  return IconButton.styleFrom(
    backgroundColor: chromeTheme.iconButtonBackground,
    foregroundColor: chromeTheme.iconButtonForeground,
    shape: const CircleBorder(),
    minimumSize: Size.square(tokens.iconButtonMinSize),
    padding: tokens.iconButtonPadding,
  );
}

class TasklyChromeIconButton extends StatelessWidget {
  const TasklyChromeIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon),
      onPressed: onPressed,
      style: tasklyChromeIconButtonStyle(context),
    );
  }
}
