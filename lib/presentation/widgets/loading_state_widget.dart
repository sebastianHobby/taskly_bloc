import 'package:flutter/material.dart';

/// A reusable loading state widget that displays a progress indicator
/// with an optional message.
class LoadingStateWidget extends StatelessWidget {
  /// Creates a loading state widget.
  const LoadingStateWidget({
    this.message,
    this.size = 48,
    super.key,
  });

  /// Creates a compact loading indicator for inline use.
  const LoadingStateWidget.compact({super.key}) : message = null, size = 24;

  /// Creates a loading indicator for list items.
  const LoadingStateWidget.listItem({super.key}) : message = null, size = 32;

  /// Optional message to display below the indicator.
  final String? message;

  /// The size of the progress indicator.
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: size > 32 ? 4 : 3,
              color: colorScheme.primary,
              backgroundColor: colorScheme.surfaceContainerHighest,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
