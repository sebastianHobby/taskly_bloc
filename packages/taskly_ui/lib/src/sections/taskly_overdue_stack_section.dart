import 'package:flutter/material.dart';

import 'package:taskly_ui/src/sections/taskly_timeline_day_section.dart';

@immutable
final class TasklyOverdueStackModel {
  const TasklyOverdueStackModel({
    required this.title,
    required this.countLabel,
    required this.isCollapsed,
    required this.onToggleCollapsed,
    required this.cards,
    this.actionLabel,
    this.actionTooltip,
    this.onActionPressed,
  });

  final String title;
  final String countLabel;

  final bool isCollapsed;
  final VoidCallback? onToggleCollapsed;

  /// When collapsed, only the first 3 are shown.
  final List<TasklyTimelineCardModel> cards;

  final String? actionLabel;
  final String? actionTooltip;
  final VoidCallback? onActionPressed;
}

class TasklyOverdueStackSection extends StatelessWidget {
  const TasklyOverdueStackSection({
    required this.model,
    super.key,
  });

  final TasklyOverdueStackModel model;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final actionLabel = model.actionLabel;
    final hasAction = actionLabel != null && model.onActionPressed != null;

    final visibleCards = model.isCollapsed
        ? model.cards.take(3).toList(growable: false)
        : model.cards;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Material(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: model.onToggleCollapsed,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        model.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (hasAction)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Tooltip(
                          message: model.actionTooltip ?? actionLabel,
                          child: TextButton.icon(
                            onPressed: model.onActionPressed,
                            icon: const Icon(Icons.event, size: 18),
                            label: Text(actionLabel),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              visualDensity: VisualDensity.compact,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        model.countLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      model.isCollapsed
                          ? Icons.expand_more_rounded
                          : Icons.expand_less_rounded,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                    ),
                  ],
                ),
              ),
            ),
            if (!model.isCollapsed || model.cards.isNotEmpty) ...[
              if (visibleCards.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Text(
                    'Nothing overdue',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Column(
                    children: [
                      for (final c in visibleCards)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _OverdueCard(card: c),
                        ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OverdueCard extends StatelessWidget {
  const _OverdueCard({required this.card});

  final TasklyTimelineCardModel card;

  @override
  Widget build(BuildContext context) {
    // Reuse the same visual as timeline cards by composing TasklyTimelineDaySection's
    // internal card layout would be ideal, but it's private.
    // For now, render using a small inline card with the same model.
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surface,
      elevation: 0,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: card.onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              if (card.onToggleCompletion != null) ...[
                Checkbox(
                  value: card.completed,
                  onChanged: card.onToggleCompletion,
                  shape: const CircleBorder(),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  card.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    decoration: card.completed
                        ? TextDecoration.lineThrough
                        : null,
                    color: card.completed
                        ? scheme.onSurface.withValues(alpha: 0.55)
                        : scheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: scheme.errorContainer.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'DUE',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: scheme.onErrorContainer,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
