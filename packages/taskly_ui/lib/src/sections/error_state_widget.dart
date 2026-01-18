import 'package:flutter/material.dart';

/// A reusable error state widget that displays an error icon, message,
/// and optional retry action.
class ErrorStateWidget extends StatelessWidget {
  /// Creates an error state widget.
  const ErrorStateWidget({
    required this.message,
    this.onRetry,
    this.retryLabel,
    this.icon = Icons.error_outline,
    this.iconSize = 64,
    super.key,
  });

  /// Creates an error state for network errors.
  const ErrorStateWidget.network({
    required String message,
    VoidCallback? onRetry,
    String? retryLabel,
    Key? key,
  }) : this(
         message: message,
         onRetry: onRetry,
         retryLabel: retryLabel,
         icon: Icons.cloud_off_outlined,
         key: key,
       );

  /// Creates an error state for empty search results.
  const ErrorStateWidget.notFound({
    required String message,
    Key? key,
  }) : this(
         message: message,
         icon: Icons.search_off_outlined,
         key: key,
       );

  /// Creates an error state for permission errors.
  const ErrorStateWidget.permission({
    required String message,
    VoidCallback? onRetry,
    Key? key,
  }) : this(
         message: message,
         onRetry: onRetry,
         icon: Icons.lock_outline,
         key: key,
       );

  /// The error message to display.
  final String message;

  /// Callback when the retry button is pressed.
  final VoidCallback? onRetry;

  /// Label for the retry button.
  final String? retryLabel;

  /// The icon to display.
  final IconData icon;

  /// The size of the icon.
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    assert(
      onRetry == null || retryLabel != null,
      'When onRetry is provided, retryLabel must be provided (taskly_ui does not '
      'hardcode user-facing strings).',
    );

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconSize + 32,
              height: iconSize + 32,
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: onRetry,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.refresh, size: 18),
                    const SizedBox(width: 8),
                    Text(retryLabel!),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
