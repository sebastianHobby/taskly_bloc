import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';

/// A visual indicator showing that a task is marked as a "Next Action".
///
/// This appears as a small pin icon badge. When tapped, shows an info dialog
/// explaining what Next Action means with option to unpin.
class NextActionIndicator extends StatelessWidget {
  const NextActionIndicator({
    required this.onUnpin,
    this.showInfoOnTap = true,
    this.size = NextActionIndicatorSize.small,
    super.key,
  });

  /// Callback when user chooses to unpin/remove next action status
  final VoidCallback? onUnpin;

  /// Whether tapping shows an info dialog (vs just the badge)
  final bool showInfoOnTap;

  /// Size variant of the indicator
  final NextActionIndicatorSize size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final iconSize = switch (size) {
      NextActionIndicatorSize.small => 14.0,
      NextActionIndicatorSize.medium => 18.0,
      NextActionIndicatorSize.large => 22.0,
    };

    final padding = switch (size) {
      NextActionIndicatorSize.small => const EdgeInsets.all(4),
      NextActionIndicatorSize.medium => const EdgeInsets.all(6),
      NextActionIndicatorSize.large => const EdgeInsets.all(8),
    };

    return Tooltip(
      message: context.l10n.nextActionsTitle,
      child: InkWell(
        onTap: showInfoOnTap ? () => _showInfoDialog(context) : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Icon(
            Icons.push_pin,
            size: iconSize,
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Future<void> _showInfoDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _NextActionInfoDialog(
        canUnpin: onUnpin != null,
      ),
    );

    if ((result ?? false) && onUnpin != null) {
      onUnpin!();
    }
  }
}

/// Size variants for the Next Action indicator
enum NextActionIndicatorSize { small, medium, large }

/// Dialog explaining what Next Action means with option to unpin
class _NextActionInfoDialog extends StatelessWidget {
  const _NextActionInfoDialog({
    required this.canUnpin,
  });

  final bool canUnpin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;

    return AlertDialog(
      icon: Icon(
        Icons.push_pin,
        color: colorScheme.primary,
        size: 32,
      ),
      title: Text(l10n.nextActionsTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This task is marked as a Next Action.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.star_outline,
            text: 'Next Actions appear in your daily focus list',
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.priority_high,
            text: 'They override the automatic allocation algorithm',
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.sort,
            text: 'Sorted by deadline (most urgent first)',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancelLabel),
        ),
        if (canUnpin)
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.push_pin_outlined),
            label: const Text('Remove Next Action'),
          ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
