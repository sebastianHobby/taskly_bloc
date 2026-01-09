import 'package:flutter/material.dart';

/// A small badge indicating an item is part of today's focus allocation.
class FocusIndicator extends StatelessWidget {
  const FocusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Icon(
        Icons.center_focus_strong,
        size: 14,
        color: colorScheme.secondary,
      ),
    );
  }
}

/// A small badge indicating an item is pinned.
class PinnedIndicator extends StatelessWidget {
  const PinnedIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
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
        size: 14,
        color: colorScheme.primary,
      ),
    );
  }
}
