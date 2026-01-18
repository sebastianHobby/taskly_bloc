import 'package:flutter/material.dart';
import 'package:taskly_ui/taskly_ui.dart';

/// Shows a sign out confirmation dialog.
///
/// Prefer calling [ConfirmationDialog.show] directly in new code.
@Deprecated('Use ConfirmationDialog.show from taskly_ui instead.')
Future<bool> showSignOutConfirmationDialog({
  required BuildContext context,
}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  return ConfirmationDialog.show(
    context,
    title: 'Sign Out?',
    confirmLabel: 'Sign Out',
    cancelLabel: 'Cancel',
    content: Text(
      "You'll need to sign in again to access your tasks and projects.",
      textAlign: TextAlign.center,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    ),
    icon: Icons.logout_rounded,
    iconColor: colorScheme.primary,
    iconBackgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
  );
}
