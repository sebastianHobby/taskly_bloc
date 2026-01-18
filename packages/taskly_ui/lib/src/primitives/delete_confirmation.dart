import 'package:flutter/material.dart';

/// Shows a snackbar after a deletion.
///
/// Returns a [ScaffoldFeatureController] that can be used to dismiss the
/// snackbar programmatically.
SnackBar buildDeleteSnackBar({
  required BuildContext context,
  required String message,
  Duration duration = const Duration(seconds: 3),
}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  return SnackBar(
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
  );
}

/// Shows a snackbar after a deletion.
///
/// Prefer using [buildDeleteSnackBar] and letting the app decide where/when to
/// show it.
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showDeleteSnackBar({
  required BuildContext context,
  required String message,
  Duration duration = const Duration(seconds: 3),
}) {
  return ScaffoldMessenger.of(context).showSnackBar(
    buildDeleteSnackBar(
      context: context,
      message: message,
      duration: duration,
    ),
  );
}
