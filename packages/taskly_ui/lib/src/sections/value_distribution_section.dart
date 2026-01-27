import 'package:flutter/material.dart';

import 'package:taskly_ui/src/feed/taskly_feed_spec.dart';
import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';

class ValueDistributionSection extends StatelessWidget {
  const ValueDistributionSection({
    required this.title,
    required this.totalLabel,
    required this.entries,
    super.key,
  });

  final String title;
  final String totalLabel;
  final List<TasklyValueDistributionEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = TasklyTokens.of(context);

    final effectiveEntries = entries
        .where((entry) => entry.count > 0)
        .toList(growable: false);
    final sortedEntries = effectiveEntries.toList(growable: false)
      ..sort((a, b) => b.count.compareTo(a.count));

    if (sortedEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(0, tokens.spaceXs2, 0, tokens.spaceLg),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(tokens.radiusLg2),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.08),
              blurRadius: tokens.spaceMd,
              offset: Offset(0, tokens.spaceXs),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(tokens.spaceLg2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderRow(title: title, totalLabel: totalLabel),
              SizedBox(height: tokens.spaceMd),
              _SegmentBar(entries: sortedEntries),
              SizedBox(height: tokens.spaceMd),
              _EntryLegend(entries: sortedEntries),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.title,
    required this.totalLabel,
  });

  final String title;
  final String totalLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = TasklyTokens.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spaceSm,
            vertical: tokens.spaceXs,
          ),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(tokens.radiusPill),
          ),
          child: Text(
            totalLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _SegmentBar extends StatelessWidget {
  const _SegmentBar({
    required this.entries,
  });

  final List<TasklyValueDistributionEntry> entries;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = TasklyTokens.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(tokens.radiusPill),
      child: SizedBox(
        height: tokens.spaceSm2,
        child: Row(
          children: [
            for (final entry in entries)
              Expanded(
                flex: entry.count,
                child: Container(
                  color: entry.value.color.withValues(alpha: 0.9),
                ),
              ),
            if (entries.isEmpty)
              Expanded(
                child: Container(
                  color: scheme.surfaceContainerHighest,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EntryLegend extends StatelessWidget {
  const _EntryLegend({required this.entries});

  final List<TasklyValueDistributionEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = TasklyTokens.of(context);
    final textColor = scheme.onSurfaceVariant;

    final visible = entries.take(4).toList(growable: false);
    final remaining = entries.length - visible.length;

    return Row(
      children: [
        for (final entry in visible)
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      entry.value.icon,
                      size: tokens.spaceLg2,
                      color: entry.value.color,
                    ),
                    SizedBox(width: tokens.spaceXs),
                    Text(
                      entry.count.toString(),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: tokens.spaceXs),
                Text(
                  entry.value.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        if (remaining > 0)
          _MoreValuesPill(
            count: remaining,
            entries: entries,
          ),
      ],
    );
  }
}

class _MoreValuesPill extends StatelessWidget {
  const _MoreValuesPill({
    required this.count,
    required this.entries,
  });

  final int count;
  final List<TasklyValueDistributionEntry> entries;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = TasklyTokens.of(context);

    return Padding(
      padding: EdgeInsets.only(left: tokens.spaceSm),
      child: OutlinedButton(
        onPressed: () => _showAllValues(context),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spaceMd,
            vertical: tokens.spaceSm2,
          ),
          minimumSize: Size(0, tokens.minTapTargetSize),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.radiusPill),
          ),
        ),
        child: Text(
          '+$count',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
          ),
        ),
      ),
    );
  }

  void _showAllValues(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return ListView.separated(
          itemCount: entries.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
          itemBuilder: (context, index) {
            final entry = entries[index];
            return ListTile(
              leading: Icon(entry.value.icon, color: entry.value.color),
              title: Text(entry.value.label),
              trailing: Text(
                entry.count.toString(),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
