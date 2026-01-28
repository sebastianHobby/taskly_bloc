import 'package:flutter/material.dart';

import 'package:taskly_ui/src/feed/taskly_feed_spec.dart';
import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';
import 'package:taskly_ui/src/models/value_chip_data.dart';
import 'package:taskly_ui/src/primitives/taskly_badge.dart';
import 'package:taskly_ui/src/primitives/value_tag.dart';

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
    final primaryLabelText = labels?.primaryActionLabel?.trim() ?? '';
    final showPrimary =
        primaryLabelText.isNotEmpty &&
        (actions.onPrimaryAction != null || model.completed);
    final badges = model.badges;
    final hasBadges = badges.isNotEmpty;

    final showProgress = model.progress != null;
    final showScheduleRow = model.scheduleRow != null;

    final valueChip = model.valueChip;
    final metaLabel =
        [
              model.remainingLabel,
              model.windowLabel,
              model.targetLabel,
            ]
            .map((text) => text.trim())
            .where((text) => text.isNotEmpty)
            .join(' \u00b7 ');
    final showMeta = metaLabel.isNotEmpty && !showProgress && !showScheduleRow;

    final baseOpacity = model.completed ? 0.7 : 1.0;
    final opacity = baseOpacity.clamp(0.0, 1.0);

    final isSelected =
        model.selected || (model.completed && model.highlightCompleted);
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          model.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: titleStyle,
                        ),
                        if (!showProgress &&
                            !showScheduleRow &&
                            (valueChip != null || showMeta)) ...[
                          SizedBox(height: tokens.spaceXs2),
                          Wrap(
                            spacing: tokens.spaceXs2,
                            runSpacing: tokens.spaceXs2,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (valueChip != null)
                                _ValueInlineLabel(
                                  data: valueChip,
                                  textColor: scheme.onSurfaceVariant,
                                ),
                              if (showMeta) ...[
                                if (valueChip != null)
                                  _ValueMetaDot(tokens: tokens),
                                Text(metaLabel, style: metaStyle),
                              ],
                            ],
                          ),
                        ],
                        if ((showProgress || showScheduleRow) &&
                            valueChip != null) ...[
                          SizedBox(height: tokens.spaceXs2),
                          _ValueInlineLabel(
                            data: valueChip,
                            textColor: scheme.onSurfaceVariant,
                          ),
                        ],
                        if (showProgress && model.progress != null) ...[
                          SizedBox(height: tokens.spaceSm2),
                          _RoutineProgressRow(data: model.progress!),
                        ],
                        if (showScheduleRow && model.scheduleRow != null) ...[
                          SizedBox(height: tokens.spaceSm2),
                          _RoutineScheduleRow(data: model.scheduleRow!),
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
                      ],
                    ),
                  ),
                  if (showPrimary) ...[
                    SizedBox(width: tokens.spaceSm),
                    _PrimaryActionButton(
                      label: primaryLabelText,
                      completed: model.completed,
                      onPressed: actions.onPrimaryAction,
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
    required this.completed,
    required this.onPressed,
  });

  final String label;
  final bool completed;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isDone = completed;
    final bg = isDone ? scheme.primaryContainer : Colors.transparent;
    final fg = isDone ? scheme.primary : scheme.onSurfaceVariant;
    final borderColor = isDone
        ? scheme.primaryContainer
        : scheme.outlineVariant.withValues(alpha: 0.8);

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        minimumSize: Size(tokens.minTapTargetSize + tokens.spaceLg, 40),
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceMd,
          vertical: tokens.spaceXs2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          side: BorderSide(color: borderColor),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

TasklyBadgeStyle _badgeStyle(TasklyBadgeTone tone) {
  return switch (tone) {
    TasklyBadgeTone.solid => TasklyBadgeStyle.solid,
    TasklyBadgeTone.outline => TasklyBadgeStyle.outline,
    TasklyBadgeTone.soft => TasklyBadgeStyle.softOutline,
  };
}

class _ValueInlineLabel extends StatelessWidget {
  const _ValueInlineLabel({
    required this.data,
    required this.textColor,
  });

  final ValueChipData data;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    const maxLabelChars = 20;
    final label = ValueTagLayout.formatLabel(
      data.label,
      maxChars: maxLabelChars,
    );
    if (label == null || label.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(data.icon, size: tokens.spaceMd2, color: data.color),
        SizedBox(width: tokens.spaceXxs2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: (Theme.of(context).textTheme.labelSmall ?? const TextStyle())
              .copyWith(color: textColor, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _ValueMetaDot extends StatelessWidget {
  const _ValueMetaDot({required this.tokens});

  final TasklyTokens tokens;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: tokens.spaceXxs2,
      height: tokens.spaceXxs2,
      decoration: BoxDecoration(
        color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _RoutineProgressRow extends StatelessWidget {
  const _RoutineProgressRow({required this.data});

  final TasklyRoutineProgressData data;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    const progressWidth = 72.0;
    final barHeight = tokens.spaceXs2;
    final progressColor = scheme.primary;
    final trackColor = scheme.surfaceVariant.withValues(alpha: 0.6);

    final progressLabel = '${data.completedCount}/${data.targetCount}';
    final windowLabel = data.windowLabel.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: progressWidth,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(tokens.radiusPill),
            child: SizedBox(
              height: barHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(color: trackColor),
                  ),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: data.progressRatio.clamp(0.0, 1.0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: progressColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: tokens.spaceSm),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: progressLabel),
                if (windowLabel.isNotEmpty)
                  TextSpan(text: ' \u00b7 $windowLabel'),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoutineScheduleRow extends StatelessWidget {
  const _RoutineScheduleRow({required this.data});

  final TasklyRoutineScheduleRowData data;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final iconSpacing = tokens.spaceXxs2;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (data.icons.isNotEmpty) ...[
          Wrap(
            spacing: iconSpacing,
            runSpacing: iconSpacing,
            children: [
              for (final icon in data.icons) _ScheduleStatusIcon(type: icon),
            ],
          ),
          SizedBox(width: tokens.spaceSm),
        ],
        Expanded(
          child: Wrap(
            spacing: tokens.spaceXxs2,
            runSpacing: tokens.spaceXxs2,
            children: [
              for (final day in data.days)
                _ScheduleDayPill(
                  day: day,
                  onSurface: scheme.onSurface,
                  onSurfaceVariant: scheme.onSurfaceVariant,
                  outline: scheme.outlineVariant,
                  accent: scheme.primary,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScheduleStatusIcon extends StatelessWidget {
  const _ScheduleStatusIcon({required this.type});

  final TasklyRoutineScheduleIcon type;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;

    final size = tokens.spaceLg2;
    final iconSize = tokens.spaceMd;
    final borderRadius = tokens.radiusPill;

    Color borderColor;
    Color foreground;
    Color background;
    IconData icon;

    switch (type) {
      case TasklyRoutineScheduleIcon.loggedScheduled:
        borderColor = scheme.primary.withValues(alpha: 0.6);
        foreground = scheme.onPrimary;
        background = scheme.primary;
        icon = Icons.check_rounded;
      case TasklyRoutineScheduleIcon.loggedUnscheduled:
        borderColor = scheme.primary.withValues(alpha: 0.8);
        foreground = scheme.primary;
        background = Colors.transparent;
        icon = Icons.check_rounded;
      case TasklyRoutineScheduleIcon.missedScheduled:
        borderColor = scheme.error.withValues(alpha: 0.6);
        foreground = scheme.error;
        background = scheme.errorContainer.withValues(alpha: 0.3);
        icon = Icons.remove_rounded;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: iconSize, color: foreground),
    );
  }
}

class _ScheduleDayPill extends StatelessWidget {
  const _ScheduleDayPill({
    required this.day,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
    required this.accent,
  });

  final TasklyRoutineScheduleDay day;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outline;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final size = tokens.spaceLg2;
    final isScheduled = day.isScheduled;
    final isToday = day.isToday;

    final borderColor = isScheduled
        ? outline.withValues(alpha: 0.8)
        : outline.withValues(alpha: 0.5);
    final textColor = isScheduled
        ? onSurface
        : onSurfaceVariant.withValues(alpha: 0.6);
    final background = isToday
        ? accent.withValues(alpha: 0.12)
        : Colors.transparent;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(tokens.radiusPill),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        day.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: isScheduled ? FontWeight.w700 : FontWeight.w500,
          height: 1,
        ),
      ),
    );
  }
}
