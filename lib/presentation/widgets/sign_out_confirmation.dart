import 'package:flutter/material.dart';

/// Shows a sign out confirmation dialog.
///
/// Returns `true` if the user confirms the sign out, `false` otherwise.
Future<bool> showSignOutConfirmationDialog({
  required BuildContext context,
}) async {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.logout_rounded,
          color: colorScheme.primary,
          size: 32,
        ),
      ),
      title: const Text(
        'Sign Out?',
        textAlign: TextAlign.center,
      ),
      content: Text(
        "You'll need to sign in again to access your tasks and projects.",
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Sign Out'),
        ),
      ],
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
    ),
  );

  return result ?? false;
}
