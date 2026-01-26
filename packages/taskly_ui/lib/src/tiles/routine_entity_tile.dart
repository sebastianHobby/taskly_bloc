import 'package:flutter/material.dart';

import 'package:taskly_ui/src/feed/taskly_feed_spec.dart';
import 'package:taskly_ui/src/primitives/taskly_badge.dart';
import 'package:taskly_ui/src/primitives/value_chip_widget.dart';
import 'package:taskly_ui/src/tiles/entity_tile_theme.dart';

class RoutineEntityTile extends StatelessWidget {
  const RoutineEntityTile({
    required this.model,
    required this.actions,
    super.key,
  });

  final TasklyRoutineRowData model;
  final TasklyRoutineRowActions actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = TasklyEntityTileTheme.of(context);

    final labels = model.labels;
    final primaryLabel = labels?.primaryActionLabel?.trim();
    final showPrimary =
        actions.onPrimaryAction != null &&
        primaryLabel != null &&
        primaryLabel.isNotEmpty;
    final badges = model.badges;
    final hasBadges = badges.isNotEmpty;

    final notTodayLabel = labels?.notTodayLabel?.trim();
    final laterThisWeekLabel = labels?.laterThisWeekLabel?.trim();
    final skipPeriodLabel = labels?.skipPeriodLabel?.trim();
    final pauseLabel = labels?.pauseLabel?.trim();
    final editLabel = labels?.editLabel?.trim();

    final menuEntries = <_RoutineMenuEntry>[
      if (actions.onNotToday != null && _hasLabel(notTodayLabel))
        _RoutineMenuEntry(
          label: notTodayLabel!,
          onTap: actions.onNotToday!,
        ),
      if (actions.onLaterThisWeek != null && _hasLabel(laterThisWeekLabel))
        _RoutineMenuEntry(
          label: laterThisWeekLabel!,
          onTap: actions.onLaterThisWeek!,
        ),
      if (actions.onSkipPeriod != null && _hasLabel(skipPeriodLabel))
        _RoutineMenuEntry(
          label: skipPeriodLabel!,
          onTap: actions.onSkipPeriod!,
        ),
      if (actions.onPause != null && _hasLabel(pauseLabel))
        _RoutineMenuEntry(
          label: pauseLabel!,
          onTap: actions.onPause!,
        ),
      if (actions.onEdit != null && _hasLabel(editLabel))
        _RoutineMenuEntry(
          label: editLabel!,
          onTap: actions.onEdit!,
        ),
    ];
    final showMenu = menuEntries.isNotEmpty;

    final statusColor = _statusColor(model.statusTone, scheme);
    final statusStyle = _statusStyle(model.statusTone);
    final statusLabel = model.statusLabel.trim();

    final metaLabel = [
      model.targetLabel,
      model.remainingLabel,
      model.windowLabel,
    ].map((text) => text.trim()).where((text) => text.isNotEmpty).join(' · ');

    final titleStyle = tokens.taskTitle.copyWith(
      fontWeight: FontWeight.w700,
      color: model.completed ? scheme.onSurfaceVariant : scheme.onSurface,
      decoration: model.completed
          ? TextDecoration.lineThrough
          : TextDecoration.none,
    );

    final surfaceTint = model.selected
        ? scheme.primaryContainer.withValues(alpha: 0.18)
        : Colors.transparent;

    final tileSurface = Color.alphaBlend(
      surfaceTint,
      tokens.cardSurfaceColor,
    );

    final tile = DecoratedBox(
      decoration: BoxDecoration(
        color: tileSurface,
        borderRadius: BorderRadius.circular(tokens.taskRadius),
        border: Border.all(color: tokens.cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: tokens.cardShadowColor,
            blurRadius: tokens.cardShadowBlur,
            offset: tokens.cardShadowOffset,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tokens.taskRadius),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: actions.onTap,
            child: Padding(
              padding: tokens.taskPadding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (model.completed) ...[
                              Icon(
                                Icons.check_circle_rounded,
                                size: 16,
                                color: scheme.primary,
                              ),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Text(
                                model.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: titleStyle,
                              ),
                            ),
                            if (statusLabel.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              TasklyBadge(
                                label: statusLabel,
                                color: statusColor,
                                style: statusStyle,
                              ),
                            ],
                          ],
                        ),
                        if (model.valueChip != null) ...[
                          const SizedBox(height: 8),
                          ValueChip(
                            data: model.valueChip!,
                            iconOnly: false,
                            maxLabelWidth: 140,
                          ),
                        ],
                        if (metaLabel.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            metaLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (hasBadges) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final badge in badges)
                                TasklyBadge(
                                  label: badge.label,
                                  icon: badge.icon,
                                  color: badge.color,
                                  style: badge.tone == TasklyBadgeTone.solid
                                      ? TasklyBadgeStyle.solid
                                      : badge.tone == TasklyBadgeTone.outline
                                      ? TasklyBadgeStyle.outline
                                      : TasklyBadgeStyle.softOutline,
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (showPrimary || showMenu) ...[
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (showPrimary)
                          FilledButton(
                            onPressed: actions.onPrimaryAction,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              minimumSize: const Size(0, 36),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              textStyle: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: Text(primaryLabel),
                          ),
                        if (showMenu) ...[
                          if (showPrimary) const SizedBox(height: 4),
                          _RoutineMenuButton(
                            entries: menuEntries,
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final baseOpacity = model.completed ? 0.75 : 1.0;
    return Opacity(
      key: Key('routine-${model.id}'),
      opacity: baseOpacity,
      child: tile,
    );
  }
}

bool _hasLabel(String? label) {
  final trimmed = label?.trim();
  return trimmed != null && trimmed.isNotEmpty;
}

Color _statusColor(TasklyRoutineStatusTone tone, ColorScheme scheme) {
  return switch (tone) {
    TasklyRoutineStatusTone.onPace => scheme.primary,
    TasklyRoutineStatusTone.tightWeek => scheme.tertiary,
    TasklyRoutineStatusTone.catchUp => scheme.error,
    TasklyRoutineStatusTone.restWeek => scheme.onSurfaceVariant,
  };
}

TasklyBadgeStyle _statusStyle(TasklyRoutineStatusTone tone) {
  return switch (tone) {
    TasklyRoutineStatusTone.onPace => TasklyBadgeStyle.softOutline,
    TasklyRoutineStatusTone.tightWeek => TasklyBadgeStyle.softOutline,
    TasklyRoutineStatusTone.catchUp => TasklyBadgeStyle.solid,
    TasklyRoutineStatusTone.restWeek => TasklyBadgeStyle.outline,
  };
}

final class _RoutineMenuEntry {
  const _RoutineMenuEntry({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;
}

class _RoutineMenuButton extends StatelessWidget {
  const _RoutineMenuButton({required this.entries});

  final List<_RoutineMenuEntry> entries;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_RoutineMenuEntry>(
      icon: const Icon(Icons.more_horiz_rounded, size: 20),
      onSelected: (entry) => entry.onTap(),
      itemBuilder: (context) {
        return [
          for (final entry in entries)
            PopupMenuItem<_RoutineMenuEntry>(
              value: entry,
              child: Text(entry.label),
            ),
        ];
      },
    );
  }
}
