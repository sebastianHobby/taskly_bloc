import 'package:flutter/material.dart';

import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';

/// A compact visual indicator that an entity is pinned.
class PinnedIndicator extends StatelessWidget {
  const PinnedIndicator({
    this.size = 14,
    this.tooltip,
    super.key,
  });

  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = TasklyTokens.of(context);

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: EdgeInsets.all(tokens.spaceXs),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(tokens.radiusSm),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Icon(
          Icons.push_pin,
          size: size,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}
