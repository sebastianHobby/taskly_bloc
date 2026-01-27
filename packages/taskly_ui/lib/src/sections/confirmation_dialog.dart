import 'package:flutter/material.dart';
import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';

/// A generic confirmation dialog with optional destructive styling.
class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({
    required this.title,
    required this.confirmLabel,
    required this.cancelLabel,
    this.content,
    this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.isDestructive = false,
    super.key,
  });

  final String title;
  final String confirmLabel;
  final String cancelLabel;
  final Widget? content;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final bool isDestructive;

  /// Shows the dialog and returns true when the user confirms.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String confirmLabel,
    required String cancelLabel,
    Widget? content,
    IconData? icon,
    Color? iconColor,
    Color? iconBackgroundColor,
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        content: content,
        icon: icon,
        iconColor: iconColor,
        iconBackgroundColor: iconBackgroundColor,
        isDestructive: isDestructive,
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = TasklyTokens.of(context);

    final dialogIcon = icon == null
        ? null
        : Container(
            padding: EdgeInsets.all(tokens.spaceLg),
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor ?? colorScheme.primary,
              size: 32,
            ),
          );

    return AlertDialog(
      icon: dialogIcon,
      title: Text(
        title,
        textAlign: TextAlign.center,
      ),
      content: content,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            cancelLabel,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: isDestructive
              ? FilledButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                )
              : null,
          child: Text(confirmLabel),
        ),
      ],
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actionsPadding: EdgeInsets.fromLTRB(
        tokens.spaceXl,
        0,
        tokens.spaceXl,
        tokens.spaceXl,
      ),
    );
  }
}
