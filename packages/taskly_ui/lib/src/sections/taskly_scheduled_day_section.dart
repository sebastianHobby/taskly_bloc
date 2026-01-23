import 'package:flutter/material.dart';

@immutable
final class TasklyScheduledDayModel {
  const TasklyScheduledDayModel({
    required this.day,
    required this.title,
    required this.isToday,
    required this.children,
    this.countLabel,
    this.emptyLabel,
    this.onAddRequested,
  });

  /// Local date-only semantics.
  final DateTime day;

  /// App-owned header string (already localized/formatted).
  final String title;

  final bool isToday;

  /// Optional right-aligned count label (app-owned, e.g. "4 tasks").
  final String? countLabel;

  /// Canonical entity tiles for this day.
  final List<Widget> children;

  /// Optional label shown when there are no children for this day.
  final String? emptyLabel;

  /// Optional callback to add an item for this day.
  final VoidCallback? onAddRequested;
}

/// Stitch-aligned Scheduled day block:
/// - date header with optional Today pill and right-aligned count
/// - divider
/// - list of canonical entity tiles (or an empty row)
class TasklyScheduledDaySection extends StatelessWidget {
  const TasklyScheduledDaySection({required this.model, super.key});

  final TasklyScheduledDayModel model;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final countLabel = model.countLabel?.trim();
    final hasCount = countLabel != null && countLabel.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          model.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: scheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (model.isToday) ...[
                        const SizedBox(width: 10),
                        _TodayPill(),
                      ],
                    ],
                  ),
                ),
                if (hasCount)
                  Text(
                    countLabel,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.only(bottom: 12),
            color: scheme.outlineVariant.withValues(alpha: 0.55),
          ),
          if (model.children.isEmpty)
            _EmptyDayRow(
              label: model.emptyLabel ?? 'No tasks',
              onAddRequested: model.onAddRequested,
            )
          else
            ...model.children.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: c,
              ),
            ),
        ],
      ),
    );
  }
}

class _TodayPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'TODAY',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w900,
          color: scheme.onPrimaryContainer,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _EmptyDayRow extends StatelessWidget {
  const _EmptyDayRow({required this.label, required this.onAddRequested});

  final String label;
  final VoidCallback? onAddRequested;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onAddRequested != null)
              TextButton.icon(
                onPressed: onAddRequested,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add'),
              ),
          ],
        ),
      ),
    );
  }
}
