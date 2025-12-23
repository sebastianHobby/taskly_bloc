import 'package:flutter/material.dart';

/// Shows a modern delete confirmation dialog.
///
/// Returns `true` if the user confirms the deletion, `false` otherwise.
Future<bool> showDeleteConfirmationDialog({
  required BuildContext context,
  required String title,
  required String itemName,
  String? description,
  bool isDestructive = true,
}) async {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: colorScheme.error,
          size: 32,
        ),
      ),
      title: Text(
        title,
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              children: [
                const TextSpan(text: 'Are you sure you want to delete '),
                TextSpan(
                  text: '"$itemName"',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const TextSpan(text: '?'),
              ],
            ),
          ),
          if (description != null) ...[
            const SizedBox(height: 12),
            Text(
              description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
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
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
          ),
          child: const Text('Delete'),
        ),
      ],
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
    ),
  );

  return result ?? false;
}

/// Shows a snackbar after a deletion.
///
/// Returns a [ScaffoldFeatureController] that can be used to dismiss the
/// snackbar programmatically.
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showDeleteSnackBar({
  required BuildContext context,
  required String message,
  Duration duration = const Duration(seconds: 3),
}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  return ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            Icons.delete_outline_rounded,
            color: colorScheme.onInverseSurface,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message),
          ),
        ],
      ),
      duration: duration,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}
