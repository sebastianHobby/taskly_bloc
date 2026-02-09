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
    final isCompactStyle = style is TasklyRoutineRowStyleCompact;
    final isBulkSelectionStyle =
        style is TasklyRoutineRowStyleBulkSelection ||
        style is TasklyRoutineRowStyleBulkSelectionCompact;
    final isBulkSelectionCompact =
        style is TasklyRoutineRowStyleBulkSelectionCompact;
    final useCompactLayout =
        isPlanPickStyle || isCompactStyle || isBulkSelectionCompact;
    final showSelectionRail = isBulkSelectionStyle;
    final showSelectionToggle =
        !isPlanPickStyle &&
        !showSelectionRail &&
        actions.onToggleSelected != null;
    final showPrimary =
        !isPlanPickStyle &&
        !showSelectionRail &&
        !showSelectionToggle &&
        primaryLabelText.isNotEmpty &&
        (actions.onPrimaryAction != null || model.completed);
    final showPicker = isPlanPickStyle && actions.onToggleSelected != null;
    final badges = model.badges;

    final showProgress = model.progress != null;
    final showScheduleRow = model.scheduleRow != null;
    final isScheduledRow = showScheduleRow;

    final valueChip = model.valueChip;
    final metaLabel =
        [
              if (!showProgress) model.remainingLabel,
              model.windowLabel,
              model.targetLabel,
            ]
            .map((text) => text.trim())
            .where((text) => text.isNotEmpty)
            .join(' \u00b7 ');
    final showMeta = !isScheduledRow && metaLabel.isNotEmpty;

    final progress = isScheduledRow ? null : model.progress;
    final compactMetaLabel = metaLabel;

    final hasBadges = !isScheduledRow && badges.isNotEmpty;
    final ValueChipData? leadingValueChip = isScheduledRow ? valueChip : null;

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

    final VoidCallback? onTap = isPlanPickStyle
        ? actions.onTap ?? actions.onToggleSelected
        : actions.onTap;

    final tile = useCompactLayout
        ? _CompactRoutineTile(
            model: model,
            actions: actions,
            titleStyle: titleStyle,
            tileSurface: tileSurface,
            showScheduleRow: showScheduleRow,
            metaLabel: compactMetaLabel,
            progress: progress,
            showPrimary: showPrimary,
            primaryLabelText: primaryLabelText,
            showPicker: showPicker,
            showSelection: showSelectionToggle,
            showSelectionRail: showSelectionRail,
            selectionCompact: isBulkSelectionCompact,
            selectionEnabled: actions.onToggleSelected != null,
            selectionAddLabel: selectionAddLabel,
            selectionAddedLabel: selectionAddedLabel,
            leadingValueChip: leadingValueChip,
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
                        if (showSelectionRail) ...[
                          _SelectionRailButton(
                            selected: model.selected,
                            compact: isBulkSelectionCompact,
                            onPressed: actions.onToggleSelected,
                          ),
                          SizedBox(width: tokens.spaceSm),
                        ],
                        if (leadingValueChip != null) ...[
                          Icon(
                            leadingValueChip.icon,
                            size: tokens.spaceLg2,
                            color: leadingValueChip.color,
                          ),
                          SizedBox(width: tokens.spaceSm),
                        ],
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
                              if (!isScheduledRow &&
                                  (valueChip != null || showMeta)) ...[
                                SizedBox(height: tokens.spaceXs2),
                                _RoutineMetaRow(
                                  valueChip: valueChip,
                                  metaLabel: metaLabel,
                                  showMeta: showMeta,
                                  progress: progress,
                                ),
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
                        ] else if (showSelectionToggle) ...[
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

    return tile;
  }
}

class _CompactRoutineTile extends StatelessWidget {
  const _CompactRoutineTile({
    required this.model,
    required this.actions,
    required this.titleStyle,
    required this.tileSurface,
    required this.showScheduleRow,
    required this.metaLabel,
    required this.progress,
    required this.showPrimary,
    required this.primaryLabelText,
    required this.showPicker,
    required this.showSelection,
    required this.showSelectionRail,
    required this.selectionCompact,
    required this.selectionEnabled,
    required this.selectionAddLabel,
    required this.selectionAddedLabel,
    required this.leadingValueChip,
  });

  final TasklyRoutineRowData model;
  final TasklyRoutineRowActions actions;
  final TextStyle? titleStyle;
  final Color tileSurface;
  final bool showScheduleRow;
  final String metaLabel;
  final TasklyRoutineProgressData? progress;
  final bool showPrimary;
  final String primaryLabelText;
  final bool showPicker;
  final bool showSelection;
  final bool showSelectionRail;
  final bool selectionCompact;
  final bool selectionEnabled;
  final String selectionAddLabel;
  final String selectionAddedLabel;
  final ValueChipData? leadingValueChip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = TasklyTokens.of(context);
    final valueChip = model.valueChip;
    final leadingValueChip = this.leadingValueChip;
    final trimmedMetaLabel = metaLabel.trim();
    final hasMetaLabel = trimmedMetaLabel.isNotEmpty;
    final hasProgress = progress != null;
    final isScheduledRow = showScheduleRow && model.scheduleRow != null;

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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (showSelectionRail) ...[
                    _SelectionRailButton(
                      selected: model.selected,
                      compact: selectionCompact,
                      onPressed: selectionEnabled
                          ? actions.onToggleSelected
                          : null,
                    ),
                    SizedBox(width: tokens.spaceSm),
                  ],
                  if (leadingValueChip != null)
                    Icon(
                      leadingValueChip.icon,
                      size: tokens.spaceLg2,
                      color: leadingValueChip.color,
                    )
                  else
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
                            if (!isScheduledRow && valueChip != null) ...[
                              SizedBox(width: tokens.spaceXs2),
                              _ValueIconOnly(data: valueChip),
                            ],
                            if (!isScheduledRow && hasProgress) ...[
                              SizedBox(width: tokens.spaceXs2),
                              _ProgressChip(data: progress!),
                            ],
                            if (!isScheduledRow && hasMetaLabel) ...[
                              SizedBox(width: tokens.spaceSm2),
                              Text(
                                trimmedMetaLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (showScheduleRow && model.scheduleRow != null) ...[
                          SizedBox(height: tokens.spaceXs2),
                          _RoutineScheduleRow(data: model.scheduleRow!),
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
      opacity: (model.completed ? 0.7 : 1.0).clamp(0.0, 1.0),
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

class _SelectionRailButton extends StatelessWidget {
  const _SelectionRailButton({
    required this.selected,
    required this.compact,
    required this.onPressed,
  });

  final bool selected;
  final bool compact;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = TasklyTokens.of(context);
    final iconSize = compact ? tokens.spaceMd2 : tokens.spaceLg2;
    final padding = compact ? tokens.spaceXs2 : tokens.spaceSm2;

    return IconButton(
      tooltip: selected ? 'Deselect' : 'Select',
      onPressed: onPressed,
      icon: Icon(
        selected
            ? Icons.check_circle_rounded
            : Icons.radio_button_unchecked_rounded,
        size: iconSize,
        color: selected ? scheme.primary : scheme.onSurfaceVariant,
      ),
      style: IconButton.styleFrom(
        minimumSize: Size.square(tokens.minTapTargetSize),
        padding: EdgeInsets.all(padding),
      ),
    );
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

class _RoutineMetaRow extends StatelessWidget {
  const _RoutineMetaRow({
    required this.valueChip,
    required this.metaLabel,
    required this.showMeta,
    required this.progress,
  });

  final ValueChipData? valueChip;
  final String metaLabel;
  final bool showMeta;
  final TasklyRoutineProgressData? progress;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final children = <Widget>[];

    if (valueChip != null) {
      children.add(
        _ValueInlineLabel(
          data: valueChip!,
          textColor: scheme.onSurfaceVariant,
        ),
      );
    }
    if (progress != null) {
      if (children.isNotEmpty) {
        children.add(_ValueMetaDot(tokens: tokens));
      }
      children.add(_ProgressChip(data: progress!));
    }
    if (showMeta) {
      if (children.isNotEmpty) {
        children.add(_ValueMetaDot(tokens: tokens));
      }
      children.add(
        Text(
          metaLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Wrap(
      spacing: tokens.spaceXs2,
      runSpacing: tokens.spaceXs2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}

class _ProgressChip extends StatelessWidget {
  const _ProgressChip({required this.data});

  final TasklyRoutineProgressData data;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final label = '${data.completedCount}/${data.targetCount}';
    final background = scheme.primaryContainer.withValues(alpha: 0.7);
    final foreground = scheme.primary;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceXs2,
        vertical: tokens.spaceXxs2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(tokens.radiusPill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
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
