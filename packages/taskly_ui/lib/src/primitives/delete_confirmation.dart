import 'package:flutter/material.dart';

import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';

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
  final tokens = TasklyTokens.of(context);

  return SnackBar(
    content: Row(
      children: [
        Icon(
          Icons.delete_outline_rounded,
          color: colorScheme.onInverseSurface,
          size: tokens.spaceLg3,
        ),
        SizedBox(width: tokens.spaceMd),
        Expanded(
          child: Text(message),
        ),
      ],
    ),
    duration: duration,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(tokens.radiusMd),
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
