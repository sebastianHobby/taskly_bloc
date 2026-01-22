import 'package:flutter/material.dart';

import 'package:taskly_ui/src/models/value_chip_data.dart';

enum TasklyTimelineStatus { due, planned }

@immutable
final class TasklyTimelineCardModel {
  const TasklyTimelineCardModel({
    required this.key,
    required this.title,
    required this.completed,
    required this.status,
    required this.onTap,
    this.primaryValue,
    this.onToggleCompletion,
    this.leadingAccentColor,
  });

  final String key;
  final String title;
  final bool completed;
  final TasklyTimelineStatus status;
  final VoidCallback onTap;

  final ValueChipData? primaryValue;

  /// When provided, a circular completion checkbox is shown.
  final ValueChanged<bool?>? onToggleCompletion;

  /// Optional left accent used for urgency emphasis.
  final Color? leadingAccentColor;
}

@immutable
final class TasklyTimelineDayModel {
  const TasklyTimelineDayModel({
    required this.day,
    required this.title,
    required this.isToday,
    required this.cards,
    this.emptyLabel,
    this.onAddRequested,
  });

  /// Local date-only semantics.
  final DateTime day;

  /// App-owned header string (already localized/formatted).
  final String title;

  final bool isToday;

  final List<TasklyTimelineCardModel> cards;

  /// Optional label shown when there are no cards for this day.
  final String? emptyLabel;

  /// Optional callback to add an item for this day.
  final VoidCallback? onAddRequested;
}

/// Renders a single timeline day block:
/// - left rail + day marker
/// - day title
/// - list of agenda-style entity cards (or an empty row)
class TasklyTimelineDaySection extends StatelessWidget {
  const TasklyTimelineDaySection({
    required this.model,
    super.key,
  });

  final TasklyTimelineDayModel model;

  static const double _gutterWidth = 64;
  static const double _lineX = 30;
  static const double _railWidth = 1.5;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Stack(
        children: [
          // Rail line.
          Positioned.fill(
            left: 0,
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: _lineX),
                child: Container(
                  width: _railWidth,
                  color: scheme.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: _gutterWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DayHeader(model: model),
                const SizedBox(height: 6),
                if (model.cards.isEmpty)
                  _EmptyDayRow(
                    label: model.emptyLabel ?? 'No tasks',
                    onAddRequested: model.onAddRequested,
                  )
                else
                  ...model.cards.map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AgendaCard(card: c),
                    ),
                  ),
              ],
            ),
          ),
          // Day marker.
          Positioned(
            left: _lineX - 18,
            top: 10,
            child: _DayMarker(isToday: model.isToday),
          ),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.model});

  final TasklyTimelineDayModel model;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        model.title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}

class _DayMarker extends StatelessWidget {
  const _DayMarker({required this.isToday});

  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final Color background = isToday
        ? scheme.primaryContainer
        : scheme.surfaceContainerHighest.withValues(alpha: 0.6);

    final Color foreground = isToday
        ? scheme.onPrimaryContainer
        : scheme.primary;

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        boxShadow: isToday
            ? [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.22),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Icon(
        Icons.calendar_month_rounded,
        size: 16,
        color: foreground,
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

class _AgendaCard extends StatelessWidget {
  const _AgendaCard({required this.card});

  final TasklyTimelineCardModel card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final leadingAccentColor = card.leadingAccentColor;

    return Material(
      color: scheme.surface,
      elevation: 0,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: card.onTap,
        child: Stack(
          children: [
            if (leadingAccentColor != null)
              Positioned.fill(
                left: 0,
                right: null,
                child: Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: leadingAccentColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (card.primaryValue != null) ...[
                        _ValueChip(data: card.primaryValue!),
                        const SizedBox(width: 8),
                      ],
                      _StatusPill(status: card.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (card.onToggleCompletion != null) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Transform.scale(
                            scale: 0.92,
                            child: Checkbox(
                              value: card.completed,
                              onChanged: card.onToggleCompletion,
                              shape: const CircleBorder(),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          card.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
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
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValueChip extends StatelessWidget {
  const _ValueChip({required this.data});

  final ValueChipData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.36,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: data.color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(data.icon, size: 15, color: data.color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                data.label.toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: data.color,
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final TasklyTimelineStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final label = status == TasklyTimelineStatus.due ? 'DUE' : 'PLANNED';

    final Color background;
    final Color foreground;

    if (status == TasklyTimelineStatus.due) {
      background = scheme.errorContainer.withValues(alpha: 0.9);
      foreground = scheme.onErrorContainer;
    } else {
      background = scheme.surfaceContainerHighest.withValues(alpha: 0.75);
      foreground = scheme.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: foreground,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
