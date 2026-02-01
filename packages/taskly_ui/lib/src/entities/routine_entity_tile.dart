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
    this.style = const TasklyRoutineRowStyle.standard(),
    super.key,
  });

  final TasklyRoutineRowData model;
  final TasklyRoutineRowActions actions;
  final TasklyRoutineRowStyle style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = TasklyTokens.of(context);

    final labels = model.labels;
    final primaryLabelText = labels?.primaryActionLabel?.trim() ?? '';
    final selectionAddLabelRaw = labels?.selectionTooltipLabel?.trim();
    final selectionAddLabel =
        (selectionAddLabelRaw != null && selectionAddLabelRaw.isNotEmpty)
        ? selectionAddLabelRaw
        : 'Add';
    final selectionAddedLabelRaw = labels?.selectionTooltipSelectedLabel
        ?.trim();
    final selectionAddedLabel =
        (selectionAddedLabelRaw != null && selectionAddedLabelRaw.isNotEmpty)
        ? selectionAddedLabelRaw
        : 'Added';
    final isPlanPickStyle = style is TasklyRoutineRowStylePlanPick;
    final showPrimary =
        !isPlanPickStyle &&
        primaryLabelText.isNotEmpty &&
        (actions.onPrimaryAction != null || model.completed);
    final showSelection = actions.onToggleSelected != null;
    final showPicker = isPlanPickStyle && actions.onToggleSelected != null;
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

    final VoidCallback? onTap = isPlanPickStyle
        ? actions.onTap ?? actions.onToggleSelected
        : actions.onTap;

    final tile = isPlanPickStyle
        ? _PlanPickTile(
            model: model,
            actions: actions,
            opacity: opacity,
            titleStyle: titleStyle,
            metaStyle: metaStyle,
            tileSurface: tileSurface,
            showProgress: showProgress,
            showScheduleRow: showScheduleRow,
            showMeta: showMeta,
            metaLabel: metaLabel,
            showPrimary: showPrimary,
            showPicker: showPicker,
            showSelection: showSelection,
            selectionAddLabel: selectionAddLabel,
            selectionAddedLabel: selectionAddedLabel,
          )
        : DecoratedBox(
            decoration: BoxDecoration(
              color: tileSurface,
              borderRadius: BorderRadius.circular(tokens.taskRadius),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.7),
              ),
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
                  onTap: onTap,
                  onLongPress: actions.onLongPress,
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
                              if (showScheduleRow &&
                                  model.scheduleRow != null) ...[
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
                        if (showPicker) ...[
                          SizedBox(width: tokens.spaceSm),
                          _PickerActionButton(
                            selected: model.selected,
                            onPressed: actions.onToggleSelected,
                            tooltip: model.selected
                                ? selectionAddedLabel
                                : selectionAddLabel,
                          ),
                        ] else if (showSelection) ...[
                          SizedBox(width: tokens.spaceSm),
                          _SelectionToggleButton(
                            selected: model.selected,
                            onPressed: actions.onToggleSelected,
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

class _PlanPickTile extends StatelessWidget {
  const _PlanPickTile({
    required this.model,
    required this.actions,
    required this.opacity,
    required this.titleStyle,
    required this.metaStyle,
    required this.tileSurface,
    required this.showProgress,
    required this.showScheduleRow,
    required this.showMeta,
    required this.metaLabel,
    required this.showPrimary,
    required this.showPicker,
    required this.showSelection,
    required this.selectionAddLabel,
    required this.selectionAddedLabel,
  });

  final TasklyRoutineRowData model;
  final TasklyRoutineRowActions actions;
  final double opacity;
  final TextStyle? titleStyle;
  final TextStyle? metaStyle;
  final Color tileSurface;
  final bool showProgress;
  final bool showScheduleRow;
  final bool showMeta;
  final String metaLabel;
  final bool showPrimary;
  final bool showPicker;
  final bool showSelection;
  final String selectionAddLabel;
  final String selectionAddedLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = TasklyTokens.of(context);
    final valueChip = model.valueChip;
    final targetLabel = model.targetLabel.trim();
    final hasTargetLabel = targetLabel.isNotEmpty;

    final VoidCallback? onTap = actions.onTap ?? actions.onToggleSelected;

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
            onTap: onTap,
            onLongPress: actions.onLongPress,
            child: Padding(
              padding: tokens.taskPadding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.repeat_outlined,
                    size: tokens.spaceLg2,
                    color: scheme.onSurfaceVariant,
                  ),
                  SizedBox(width: tokens.spaceSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                model.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: titleStyle,
                              ),
                            ),
                            if (valueChip != null) ...[
                              SizedBox(width: tokens.spaceXs2),
                              _ValueIconOnly(data: valueChip),
                            ],
                            if (hasTargetLabel) ...[
                              SizedBox(width: tokens.spaceSm2),
                              Text(
                                targetLabel,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: tokens.spaceXs2),
                        if (showProgress && model.progress != null)
                          _RoutineProgressRow(data: model.progress!)
                        else if (showScheduleRow && model.scheduleRow != null)
                          _RoutineScheduleRow(data: model.scheduleRow!)
                        else if (showMeta)
                          Text(metaLabel, style: metaStyle),
                      ],
                    ),
                  ),
                  if (showPrimary) ...[
                    SizedBox(width: tokens.spaceSm),
                    _PrimaryActionButton(
                      label: model.completed ? 'Logged' : 'Do today',
                      completed: model.completed,
                      onPressed: actions.onPrimaryAction,
                    ),
                  ],
                  if (showPicker) ...[
                    SizedBox(width: tokens.spaceSm),
                    _PickerActionButton(
                      selected: model.selected,
                      onPressed: actions.onToggleSelected,
                      tooltip: model.selected
                          ? selectionAddedLabel
                          : selectionAddLabel,
                    ),
                  ] else if (showSelection) ...[
                    SizedBox(width: tokens.spaceSm),
                    _SelectionToggleButton(
                      selected: model.selected,
                      onPressed: actions.onToggleSelected,
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

class _ValueIconOnly extends StatelessWidget {
  const _ValueIconOnly({required this.data});

  final ValueChipData data;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    return Icon(data.icon, size: tokens.spaceMd2, color: data.color);
  }
}

class _SelectionToggleButton extends StatelessWidget {
  const _SelectionToggleButton({
    required this.selected,
    required this.onPressed,
  });

  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = TasklyTokens.of(context);
    return IconButton(
      tooltip: selected ? 'Deselect' : 'Select',
      onPressed: onPressed,
      icon: Icon(
        selected
            ? Icons.check_circle_rounded
            : Icons.radio_button_unchecked_rounded,
        color: selected ? scheme.primary : scheme.onSurfaceVariant,
      ),
      style: IconButton.styleFrom(
        minimumSize: Size.square(tokens.minTapTargetSize),
        padding: EdgeInsets.all(tokens.spaceSm2),
      ),
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

class _PickerActionButton extends StatelessWidget {
  const _PickerActionButton({
    required this.selected,
    required this.onPressed,
    required this.tooltip,
  });

  final bool selected;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = TasklyTokens.of(context);
    final bg = selected ? scheme.primaryContainer : scheme.primary;
    final fg = selected ? scheme.primary : scheme.onPrimary;

    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(selected ? Icons.check_rounded : Icons.add_rounded),
      style: IconButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        minimumSize: Size.square(tokens.minTapTargetSize),
        padding: EdgeInsets.all(tokens.spaceXs2),
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
    final caption = data.caption?.trim() ?? '';

    final bar = SizedBox(
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
    );

    final metaText = Text.rich(
      TextSpan(
        children: [
          TextSpan(text: progressLabel),
          if (windowLabel.isNotEmpty) TextSpan(text: ' \u00b7 $windowLabel'),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: textTheme.labelSmall?.copyWith(
        color: scheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );

    if (caption.isEmpty) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          bar,
          SizedBox(width: tokens.spaceSm),
          Expanded(child: metaText),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        bar,
        SizedBox(height: tokens.spaceXs2),
        Text(
          caption,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
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
                  error: scheme.error,
                  errorContainer: scheme.errorContainer,
                ),
            ],
          ),
        ),
      ],
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
    required this.error,
    required this.errorContainer,
  });

  final TasklyRoutineScheduleDay day;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outline;
  final Color accent;
  final Color error;
  final Color errorContainer;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final size = tokens.spaceLg2;
    final isToday = day.isToday;
    final state = day.state;

    final isScheduledState =
        state == TasklyRoutineScheduleDayState.scheduled ||
        state == TasklyRoutineScheduleDayState.loggedScheduled ||
        state == TasklyRoutineScheduleDayState.missedScheduled;

    final showIcon =
        state == TasklyRoutineScheduleDayState.loggedScheduled ||
        state == TasklyRoutineScheduleDayState.loggedUnscheduled ||
        state == TasklyRoutineScheduleDayState.missedScheduled;

    final baseBackground = isToday
        ? accent.withValues(alpha: 0.12)
        : Colors.transparent;

    var background = baseBackground;
    var borderColor = isScheduledState
        ? outline.withValues(alpha: 0.8)
        : outline.withValues(alpha: 0.5);
    var foreground = isScheduledState
        ? onSurface
        : onSurfaceVariant.withValues(alpha: 0.6);
    IconData? icon;

    switch (state) {
      case TasklyRoutineScheduleDayState.loggedScheduled:
        borderColor = accent.withValues(alpha: 0.7);
        background = accent.withValues(alpha: 0.16);
        foreground = accent;
        icon = Icons.check_rounded;
      case TasklyRoutineScheduleDayState.loggedUnscheduled:
        borderColor = accent.withValues(alpha: 0.8);
        foreground = accent;
        icon = Icons.check_rounded;
      case TasklyRoutineScheduleDayState.missedScheduled:
        borderColor = error.withValues(alpha: 0.7);
        background = errorContainer.withValues(alpha: 0.35);
        foreground = error;
        icon = Icons.remove_rounded;
      case TasklyRoutineScheduleDayState.scheduled:
      case TasklyRoutineScheduleDayState.none:
        break;
    }

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(tokens.radiusPill),
        border: Border.all(color: borderColor),
      ),
      child: showIcon
          ? Icon(icon, size: tokens.spaceMd, color: foreground)
          : Text(
              day.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: foreground,
                fontWeight: isScheduledState
                    ? FontWeight.w700
                    : FontWeight.w500,
                height: 1,
              ),
            ),
    );
  }
}
