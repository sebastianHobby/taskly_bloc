import 'package:flutter/material.dart';

@immutable
class TasklyJournalDailySummaryItem {
  const TasklyJournalDailySummaryItem({
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final String value;
  final IconData? icon;
}

class TasklyJournalDailySummarySection extends StatelessWidget {
  const TasklyJournalDailySummarySection({
    required this.moodEmoji,
    required this.moodLabel,
    required this.entryCountLabel,
    required this.items,
    this.emptyItemsLabel = 'No daily trackers yet.',
    this.showItems = true,
    this.onEditDaily,
    this.onSeeAll,
    super.key,
  });

  final String moodEmoji;
  final String moodLabel;
  final String entryCountLabel;
  final List<TasklyJournalDailySummaryItem> items;
  final String emptyItemsLabel;
  final bool showItems;
  final VoidCallback? onEditDaily;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actionButtons = <Widget>[
      if (onSeeAll != null)
        TextButton(
          onPressed: onSeeAll,
          child: const Text('See all'),
        ),
      if (onEditDaily != null)
        TextButton(
          onPressed: onEditDaily,
          child: const Text('Edit daily'),
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  moodEmoji,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      moodLabel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entryCountLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (actionButtons.isNotEmpty)
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  alignment: WrapAlignment.end,
                  children: actionButtons,
                ),
            ],
          ),
          if (showItems) ...[
            const SizedBox(height: 12),
            if (items.isEmpty)
              Text(
                emptyItemsLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final item in items)
                    _SummaryChip(
                      label: item.label,
                      value: item.value,
                      icon: item.icon,
                    ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = theme.colorScheme.outlineVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            '$label: $value',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
