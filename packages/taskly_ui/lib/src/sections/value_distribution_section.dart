import 'package:flutter/material.dart';

import 'package:taskly_ui/src/feed/taskly_feed_spec.dart';

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

    final effectiveEntries =
        entries.where((entry) => entry.count > 0).toList(growable: false);

    if (effectiveEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderRow(title: title, totalLabel: totalLabel),
              const SizedBox(height: 12),
              _SegmentBar(entries: effectiveEntries),
              const SizedBox(height: 12),
              _EntryGrid(entries: effectiveEntries),
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            totalLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 10,
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

class _EntryGrid extends StatelessWidget {
  const _EntryGrid({required this.entries});

  final List<TasklyValueDistributionEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.6,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(entry.value.icon, size: 18, color: entry.value.color),
                const SizedBox(width: 4),
                Text(
                  entry.count.toString(),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              entry.value.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }
}
