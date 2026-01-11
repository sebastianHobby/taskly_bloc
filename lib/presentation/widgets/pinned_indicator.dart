import 'package:flutter/material.dart';
import 'package:taskly_bloc/l10n/l10n.dart';

/// A compact visual indicator that an entity is pinned.
class PinnedIndicator extends StatelessWidget {
  const PinnedIndicator({
    this.size = 14,
    super.key,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Tooltip(
      message: context.l10n.pinnedTasksSection,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
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
