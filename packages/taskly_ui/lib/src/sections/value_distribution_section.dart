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
    final sortedEntries = effectiveEntries.toList(growable: false)
      ..sort((a, b) => b.count.compareTo(a.count));

    if (sortedEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderRow(title: title, totalLabel: totalLabel),
              const SizedBox(height: 12),
              _SegmentBar(entries: sortedEntries),
              const SizedBox(height: 12),
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
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

class _EntryLegend extends StatelessWidget {
  const _EntryLegend({required this.entries});

  final List<TasklyValueDistributionEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: OutlinedButton(
        onPressed: () => _showAllValues(context),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          minimumSize: const Size(0, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
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
