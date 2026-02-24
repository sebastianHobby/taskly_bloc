import 'package:flutter/material.dart';

import 'package:taskly_ui/src/feed/taskly_feed_spec.dart';
import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';
import 'package:taskly_ui/src/models/value_chip_data.dart';
import 'package:taskly_ui/src/primitives/taskly_badge.dart';

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
    final isPlanActionStyle = style is TasklyRoutineRowStylePlanAction;
    final isBulkSelectionStyle = style is TasklyRoutineRowStyleBulkSelection;
    final showSelectionRail = isBulkSelectionStyle;
    final showSelectionToggle =
        !isPlanPickStyle &&
        !isPlanActionStyle &&
        !showSelectionRail &&
        actions.onToggleSelected != null;
    final showPrimary =
        !isPlanPickStyle &&
        !isPlanActionStyle &&
        !showSelectionRail &&
        !showSelectionToggle &&
        primaryLabelText.isNotEmpty &&
        (actions.onPrimaryAction != null || model.completed);
    final showPicker = isPlanPickStyle && actions.onToggleSelected != null;
    final planActionLabel = switch (style) {
      TasklyRoutineRowStylePlanAction(:final actionLabel) => actionLabel.trim(),
      _ => '',
    };
    final showPlanActionButton =
        isPlanActionStyle &&
        planActionLabel.isNotEmpty &&
        actions.onToggleSelected != null;
    final badges = model.badges;

    final showScheduleRow = model.scheduleRow != null;
    final hasDotRow = model.dotRow != null;
    final actionLineText = model.actionLineText?.trim() ?? '';

    final hasBadges = badges.isNotEmpty;
    final ValueChipData? leadingValueChip = model.leadingIcon;

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

    final tile = DecoratedBox(
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
                      onPressed: actions.onToggleSelected,
                    ),
                    SizedBox(width: tokens.spaceSm),
                  ],
                  if (leadingValueChip != null) ...[
                    _LeadingIcon(data: leadingValueChip),
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
                        if (showScheduleRow && model.scheduleRow != null) ...[
                          SizedBox(height: tokens.spaceSm2),
                          _RoutineScheduleRow(
                            data: model.scheduleRow!,
                          ),
                        ] else if (hasDotRow && model.dotRow != null) ...[
                          SizedBox(height: tokens.spaceSm2),
                          _RoutineDotRow(data: model.dotRow!),
                        ] else if (actionLineText.isNotEmpty) ...[
                          SizedBox(height: tokens.spaceSm2),
                          Text(
                            actionLineText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
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
                  ] else if (showPlanActionButton) ...[
                    SizedBox(width: tokens.spaceSm),
                    _PrimaryActionButton(
                      label: planActionLabel,
                      completed: false,
                      onPressed: actions.onToggleSelected,
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

    return Opacity(
      key: Key('routine-${model.id}'),
      opacity: (model.completed ? 0.7 : 1.0).clamp(0.0, 1.0),
      child: tile,
    );
  }
}

class _SelectionRailButton extends StatelessWidget {
  const _SelectionRailButton({
    required this.selected,
    required this.onPressed,
  });

  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = TasklyTokens.of(context);
    final iconSize = tokens.spaceLg2;
    final padding = tokens.spaceSm2;

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
    final bg = isDone ? scheme.surfaceContainerHighest : Colors.transparent;
    final fg = isDone ? scheme.onSurfaceVariant : scheme.onSurfaceVariant;
    final borderColor = isDone
        ? scheme.outlineVariant.withValues(alpha: 0.6)
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
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.fade,
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

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({
    required this.data,
  });

  final ValueChipData data;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final size = tokens.minTapTargetSize;
    final bg = data.color.withValues(alpha: 0.16);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        data.icon,
        size: tokens.spaceXl,
        color: data.color,
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

class _RoutineDotRow extends StatelessWidget {
  const _RoutineDotRow({required this.data});

  final TasklyRoutineDotRowData data;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final dots = <Widget>[];
    final count = data.targetCount.clamp(0, 12);
    final completed = data.completedCount.clamp(0, count);

    for (var i = 0; i < count; i++) {
      final isFilled = i < completed;
      dots.add(
        Container(
          width: tokens.spaceXs2,
          height: tokens.spaceXs2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled
                ? scheme.primary
                : scheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
      );
    }

    return Row(
      children: [
        Wrap(
          spacing: tokens.spaceXxs2,
          runSpacing: tokens.spaceXxs2,
          children: dots,
        ),
        SizedBox(width: tokens.spaceSm2),
        Expanded(
          child: Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
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
        state == TasklyRoutineScheduleDayState.skippedScheduled ||
        state == TasklyRoutineScheduleDayState.missedScheduled;

    final baseBackground = isToday
        ? accent.withValues(alpha: 0.08)
        : Colors.transparent;

    var background = baseBackground;
    var borderColor = isScheduledState
        ? outline.withValues(alpha: 0.8)
        : outline.withValues(alpha: 0.5);
    var foreground = isScheduledState
        ? onSurface
        : onSurfaceVariant.withValues(alpha: 0.6);
    IconData? markerIcon;
    Color? markerBackground;
    Color? markerForeground;

    switch (state) {
      case TasklyRoutineScheduleDayState.loggedScheduled:
        borderColor = accent.withValues(alpha: 0.7);
        background = accent.withValues(alpha: 0.16);
        foreground = accent;
        markerIcon = Icons.check_rounded;
        markerBackground = accent;
        markerForeground = Colors.white;
      case TasklyRoutineScheduleDayState.loggedUnscheduled:
        borderColor = accent.withValues(alpha: 0.6);
        background = accent.withValues(alpha: 0.1);
        foreground = accent;
        markerIcon = Icons.check_rounded;
        markerBackground = accent;
        markerForeground = Colors.white;
      case TasklyRoutineScheduleDayState.skippedScheduled:
        borderColor = outline.withValues(alpha: 0.9);
        background = onSurfaceVariant.withValues(alpha: 0.1);
        foreground = onSurfaceVariant;
        markerIcon = Icons.skip_next_rounded;
        markerBackground = onSurfaceVariant;
        markerForeground = Colors.white;
      case TasklyRoutineScheduleDayState.missedScheduled:
        borderColor = error.withValues(alpha: 0.4);
        background = errorContainer.withValues(alpha: 0.2);
        foreground = error.withValues(alpha: 0.8);
        markerIcon = Icons.priority_high_rounded;
        markerBackground = error;
        markerForeground = Colors.white;
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
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            day.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: isScheduledState ? FontWeight.w700 : FontWeight.w500,
              height: 1,
            ),
          ),
          if (markerIcon != null &&
              markerBackground != null &&
              markerForeground != null)
            Positioned(
              top: 1,
              right: 1,
              child: Container(
                width: tokens.spaceXs2,
                height: tokens.spaceXs2,
                decoration: BoxDecoration(
                  color: markerBackground,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  markerIcon,
                  size: tokens.spaceXxs2 + 1,
                  color: markerForeground,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
