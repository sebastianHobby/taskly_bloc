import 'package:flutter/material.dart';
import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';

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
    final tokens = TasklyTokens.of(context);
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
      padding: EdgeInsets.all(tokens.spaceMd2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: tokens.progressRingSize,
                height: tokens.progressRingSize,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(tokens.radiusMd2),
                ),
                alignment: Alignment.center,
                child: Text(
                  moodEmoji,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              SizedBox(width: tokens.spaceMd),
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
                    SizedBox(height: tokens.spaceXxs),
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
                  spacing: tokens.spaceXs,
                  runSpacing: tokens.spaceXs,
                  alignment: WrapAlignment.end,
                  children: actionButtons,
                ),
            ],
          ),
          if (showItems) ...[
            SizedBox(height: tokens.spaceMd),
            if (items.isEmpty)
              Text(
                emptyItemsLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              Wrap(
                spacing: tokens.spaceSm,
                runSpacing: tokens.spaceSm,
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
    final tokens = TasklyTokens.of(context);
    final border = theme.colorScheme.outlineVariant;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceSm2,
        vertical: tokens.spaceXs2,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(tokens.radiusPill),
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
            SizedBox(width: tokens.spaceXs),
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
