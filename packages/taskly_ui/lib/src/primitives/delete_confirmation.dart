import 'package:flutter/material.dart';

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
