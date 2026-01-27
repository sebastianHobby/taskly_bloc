import 'package:flutter/material.dart';

import 'package:taskly_ui/src/feed/taskly_feed_spec.dart';
import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';
import 'package:taskly_ui/src/primitives/taskly_badge.dart';
import 'package:taskly_ui/src/primitives/value_chip_widget.dart';

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
    final tokens = TasklyTokens.of(context);

    final labels = model.labels;
    final primaryLabel = labels?.primaryActionLabel?.trim();
    final showPrimary =
        actions.onPrimaryAction != null &&
        primaryLabel != null &&
        primaryLabel.isNotEmpty;
    final badges = model.badges;
    final hasBadges = badges.isNotEmpty;

    final pauseLabel = labels?.pauseLabel?.trim();
    final editLabel = labels?.editLabel?.trim();

    final menuEntries = <_RoutineMenuEntry>[
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
    final showStatus = statusLabel.isNotEmpty;

    final metaLabel = [
      model.remainingLabel,
      model.windowLabel,
      model.targetLabel,
    ].map((text) => text.trim()).where((text) => text.isNotEmpty).join(' \u00b7 ');
    final showMeta = metaLabel.isNotEmpty;

    final baseOpacity = model.completed ? 0.7 : 1.0;
    final opacity = baseOpacity.clamp(0.0, 1.0);

    final isSelected = model.selected || model.completed;
    final selectedTint = scheme.primaryContainer.withValues(alpha: 0.16);
    final tileSurface = isSelected
        ? Color.alphaBlend(selectedTint, scheme.surface)
        : scheme.surface;

    final titleStyle = theme.textTheme.titleSmall?.copyWith(
      color: scheme.onSurface,
      decoration: model.completed ? TextDecoration.lineThrough : null,
      decorationColor: scheme.onSurface.withValues(alpha: 0.55),
      fontWeight: FontWeight.w700,
    );

    final metaStyle = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );

    final tile = DecoratedBox(
      decoration: BoxDecoration(
        color: tileSurface,
        borderRadius: BorderRadius.circular(tokens.taskRadius),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.05),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          model.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: titleStyle,
                        ),
                      ),
                      if (showStatus) ...[
                        SizedBox(width: tokens.spaceXs2),
                        TasklyBadge(
                          label: statusLabel,
                          color: statusColor,
                          style: statusStyle,
                        ),
                      ],
                      if (showMenu) ...[
                        SizedBox(width: tokens.spaceXs2),
                        _RoutineMenuButton(entries: menuEntries),
                      ],
                    ],
                  ),
                  if (model.valueChip != null || showMeta) ...[
                    SizedBox(height: tokens.spaceXs2),
                    Wrap(
                      spacing: tokens.spaceXs2,
                      runSpacing: tokens.spaceXs2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (model.valueChip != null)
                          ValueChip(
                            data: model.valueChip!,
                            maxLabelWidth: 140,
                          ),
                        if (showMeta) Text(metaLabel, style: metaStyle),
                      ],
                    ),
                  ],
                  if (hasBadges) ...[
                    SizedBox(height: tokens.spaceXs2),
                    Wrap(
                      spacing: tokens.spaceXs2,
                      runSpacing: tokens.spaceXs2,
                      children: [
                        for (final badge in badges)
                          TasklyBadge(
                            label: badge.label,
                            icon: badge.icon,
                            color: badge.color,
                            style: _badgeStyle(badge.tone),
                          ),
                      ],
                    ),
                  ],
                  if (showPrimary) ...[
                    SizedBox(height: tokens.spaceSm),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _PrimaryActionButton(
                        label: primaryLabel ?? '',
                        selected: isSelected,
                        onPressed: actions.onPrimaryAction,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Opacity(
      key: Key('routine-${model.id}'),
      opacity: opacity,
      child: tile,
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    if (selected) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.check_rounded, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spaceMd,
            vertical: tokens.spaceXs2,
          ),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceMd,
          vertical: tokens.spaceXs2,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label),
    );
  }
}

class _RoutineMenuEntry {
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
    final tokens = TasklyTokens.of(context);
    return PopupMenuButton<_RoutineMenuEntry>(
      onSelected: (entry) => entry.onTap(),
      tooltip: 'Routine actions',
      itemBuilder: (context) => entries
          .map(
            (entry) => PopupMenuItem<_RoutineMenuEntry>(
              value: entry,
              child: Text(entry.label),
            ),
          )
          .toList(growable: false),
      icon: const Icon(Icons.more_vert_rounded),
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(minWidth: tokens.minTapTargetSize),
    );
  }
}

bool _hasLabel(String? value) {
  return value != null && value.trim().isNotEmpty;
}

Color _statusColor(TasklyRoutineStatusTone tone, ColorScheme scheme) {
  return switch (tone) {
    TasklyRoutineStatusTone.onPace => scheme.tertiary,
    TasklyRoutineStatusTone.tightWeek => scheme.secondary,
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

TasklyBadgeStyle _badgeStyle(TasklyBadgeTone tone) {
  return switch (tone) {
    TasklyBadgeTone.solid => TasklyBadgeStyle.solid,
    TasklyBadgeTone.outline => TasklyBadgeStyle.outline,
    TasklyBadgeTone.soft => TasklyBadgeStyle.softOutline,
  };
}
