import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:taskly_ui/src/feed/taskly_feed_spec.dart';
import 'package:taskly_ui/src/models/value_chip_data.dart';
import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';
import 'package:taskly_ui/src/primitives/meta_badges.dart';
import 'package:taskly_ui/src/primitives/taskly_badge.dart';
import 'package:taskly_ui/src/primitives/value_tag.dart';

/// Canonical Task tile (rows/cards) aligned to Stitch mockups.
///
/// This is a pure UI component: data in / events out.
class TaskEntityTile extends StatelessWidget {
  const TaskEntityTile({
    required this.model,
    required this.actions,
    this.style = const TasklyTaskRowStyle.standard(),
    super.key,
  });

  final TasklyTaskRowData model;

  final TasklyTaskRowStyle style;
  final TasklyTaskRowActions actions;

  bool get _isSelectionStyle =>
      style is TasklyTaskRowStylePlanPick ||
      style is TasklyTaskRowStyleBulkSelection;

  bool get _isBulkSelectionStyle => style is TasklyTaskRowStyleBulkSelection;

  bool get _isPlanPickStyle => style is TasklyTaskRowStylePlanPick;

  bool get _isPickerLikeStyle => _isPlanPickStyle;

  bool? get _selected => switch (style) {
    TasklyTaskRowStylePlanPick(:final selected) => selected,
    TasklyTaskRowStyleBulkSelection(:final selected) => selected,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = TasklyTokens.of(context);

    final effectiveCompact = MediaQuery.sizeOf(context).width < 420;
    final isMobileWidth = MediaQuery.sizeOf(context).width < 600;
    const planPickInset = 2.0;
    final basePadding = tokens.taskPadding;
    final effectivePadding = _isPlanPickStyle
        ? basePadding.copyWith(
            left: (basePadding.left - planPickInset).clamp(
              0.0,
              double.infinity,
            ),
            right: (basePadding.right - planPickInset).clamp(
              0.0,
              double.infinity,
            ),
          )
        : basePadding;

    final completionEnabled =
        !_isSelectionStyle && actions.onToggleCompletion != null;

    // Bulk selection UX: hide completion affordance and show selection control.
    // Keep left-side spacing so rows don't horizontally jump when entering/exiting
    // selection mode.
    final showCompletionControl = !_isBulkSelectionStyle && !_isPickerLikeStyle;

    final VoidCallback? onTap = switch (style) {
      TasklyTaskRowStylePlanPick() => actions.onToggleSelected ?? actions.onTap,
      TasklyTaskRowStyleBulkSelection() =>
        actions.onToggleSelected ?? actions.onTap,
      _ => actions.onTap,
    };

    final addTooltipLabel = (_selected ?? false)
        ? (model.labels?.selectionPillSelectedLabel ?? 'Added')
        : (model.labels?.selectionPillLabel ?? 'Add');

    final baseOpacity = model.deemphasized ? 0.6 : 1.0;
    final completedOpacity = model.completed ? 0.75 : 1.0;
    final opacity = (baseOpacity * completedOpacity).clamp(0.0, 1.0);

    final isPlanPickSelected = _isPlanPickStyle && (_selected ?? false);
    final selectedTint = scheme.primaryContainer.withValues(alpha: 0.16);
    final tileSurface = isPlanPickSelected
        ? Color.alphaBlend(selectedTint, scheme.surface)
        : scheme.surface;

    final titleStyle =
        (isMobileWidth
            ? theme.textTheme.titleMedium
            : theme.textTheme.titleSmall) ??
        const TextStyle();

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
            child: Stack(
              children: [
                Padding(
                  padding: effectivePadding.copyWith(
                    left: effectivePadding.left,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showCompletionControl) ...[
                        _CompletionControl(
                          completed: model.completed,
                          enabled: completionEnabled,
                          size: tokens.checkboxSize,
                          checkedFill: scheme.primary,
                          semanticLabel: model.checkboxSemanticLabel,
                          onToggle: completionEnabled
                              ? () {
                                  HapticFeedback.lightImpact();
                                  actions.onToggleCompletion?.call(
                                    !model.completed,
                                  );
                                }
                              : null,
                        ),
                        SizedBox(
                          width: effectiveCompact
                              ? tokens.spaceXs2
                              : tokens.spaceSm,
                        ),
                      ] else if (_isBulkSelectionStyle) ...[
                        SizedBox(width: tokens.spaceXl, height: tokens.spaceXl),
                        SizedBox(
                          width: effectiveCompact
                              ? tokens.spaceXs2
                              : tokens.spaceSm,
                        ),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    model.title,
                                    maxLines: effectiveCompact ? 1 : 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: titleStyle.copyWith(
                                      color: scheme.onSurface,
                                      decoration: model.completed
                                          ? TextDecoration.lineThrough
                                          : null,
                                      decorationColor: scheme.onSurface
                                          .withValues(alpha: 0.55),
                                    ),
                                  ),
                                ),
                                if (model.pinned) ...[
                                  SizedBox(width: tokens.spaceXs2),
                                  _PinnedTrailingIcon(
                                    label: model.labels?.pinnedSemanticLabel,
                                  ),
                                ],
                                if (_isBulkSelectionStyle) ...[
                                  SizedBox(width: tokens.spaceXs2),
                                  IconButton(
                                    tooltip: (_selected ?? false)
                                        ? 'Deselect'
                                        : 'Select',
                                    onPressed: actions.onToggleSelected,
                                    icon: Icon(
                                      (_selected ?? false)
                                          ? Icons.check_circle_rounded
                                          : Icons
                                                .radio_button_unchecked_rounded,
                                      color: (_selected ?? false)
                                          ? scheme.primary
                                          : scheme.onSurfaceVariant,
                                    ),
                                    style: IconButton.styleFrom(
                                      minimumSize: Size.square(
                                        tokens.minTapTargetSize,
                                      ),
                                      padding: EdgeInsets.all(tokens.spaceSm),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: tokens.spaceXs2),
                            _MetaRow(
                              model: model,
                              tokens: tokens,
                              compactPriorityPill: _isPlanPickStyle,
                            ),
                          ],
                        ),
                      ),
                      if (_isPickerLikeStyle) ...[
                        SizedBox(width: tokens.spaceSm),
                        _PickerActionButton(
                          selected: _selected ?? false,
                          enabled: actions.onToggleSelected != null,
                          onPressed: actions.onToggleSelected,
                          tooltip: addTooltipLabel,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final swipeEnabled = _isPlanPickStyle && actions.onSnoozeRequested != null;
    final swipeLabel = model.labels?.snoozeTooltip?.trim();
    final effectiveSwipeLabel = (swipeLabel != null && swipeLabel.isNotEmpty)
        ? swipeLabel
        : 'Snooze';

    final Widget swipeWrapped = swipeEnabled
        ? Dismissible(
            key: ValueKey('task-snooze-${model.id}'),
            direction: DismissDirection.endToStart,
            dismissThresholds: const {DismissDirection.endToStart: 0.35},
            confirmDismiss: (_) async {
              await HapticFeedback.mediumImpact();
              actions.onSnoozeRequested?.call();
              return false;
            },
            background: _buildSnoozeBackground(
              context,
              scheme,
              label: effectiveSwipeLabel,
              isStartToEnd: true,
            ),
            secondaryBackground: _buildSnoozeBackground(
              context,
              scheme,
              label: effectiveSwipeLabel,
              isStartToEnd: false,
            ),
            child: tile,
          )
        : tile;

    return Opacity(
      key: Key('task-${model.id}'),
      opacity: opacity,
      child: swipeWrapped,
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.model,
    required this.tokens,
    required this.compactPriorityPill,
  });

  final TasklyTaskRowData model;
  final TasklyTokens tokens;
  final bool compactPriorityPill;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final meta = model.meta;

    final primaryValue = model.leadingChip;
    final secondaryValue = model.secondaryChips.isNotEmpty
        ? model.secondaryChips.first
        : null;
    final hasValues = primaryValue != null || secondaryValue != null;
    final badges = model.badges;
    final hasBadges = badges.isNotEmpty;
    final hasMetaLine = _TaskMetaLine.hasMeta(meta);
    final metaLine = hasMetaLine
        ? _TaskMetaLine(
            meta: meta,
            tokens: tokens,
            compactPriorityPill: compactPriorityPill,
          )
        : null;

    final valueLine = hasValues
        ? _ValueTagLine(primary: primaryValue, secondary: secondaryValue)
        : null;

    if (!hasValues && !hasMetaLine && !hasBadges) {
      return const SizedBox.shrink();
    }

    final lineChildren = <Widget>[
      ...?valueLine == null ? null : [valueLine],
      if (valueLine != null && metaLine != null) ...[
        SizedBox(width: tokens.spaceXs2),
        _ValueMetaDot(tokens: tokens),
        SizedBox(width: tokens.spaceXs2),
      ],
      ...?metaLine == null ? null : [metaLine],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (lineChildren.isNotEmpty)
          Wrap(
            spacing: 0,
            runSpacing: tokens.spaceXs2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: lineChildren,
          ),
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

class _ValueTagLine extends StatelessWidget {
  const _ValueTagLine({
    required this.primary,
    required this.secondary,
  });

  final ValueChipData? primary;
  final ValueChipData? secondary;

  @override
  Widget build(BuildContext context) {
    if (primary == null && secondary == null) {
      return const SizedBox.shrink();
    }

    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    const primaryMaxChars = 20;
    const secondaryMaxChars = 24;

    final effectivePrimary = (primary ?? secondary)!;
    final effectiveSecondary = primary == null ? null : secondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ValueInlineLabel(
          data: effectivePrimary,
          maxLabelChars: primaryMaxChars,
          textColor: scheme.onSurfaceVariant,
        ),
        if (effectiveSecondary != null) ...[
          SizedBox(width: tokens.spaceXs2),
          _ValueInlineLabel(
            data: effectiveSecondary,
            maxLabelChars: secondaryMaxChars,
            textColor: scheme.onSurfaceVariant,
          ),
        ],
      ],
    );
  }
}

class _ValueInlineLabel extends StatelessWidget {
  const _ValueInlineLabel({
    required this.data,
    required this.maxLabelChars,
    required this.textColor,
  });

  final ValueChipData data;
  final int maxLabelChars;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
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

class _TaskMetaLine extends StatelessWidget {
  const _TaskMetaLine({
    required this.meta,
    required this.tokens,
    required this.compactPriorityPill,
  });

  final TasklyEntityMetaData meta;
  final TasklyTokens tokens;
  final bool compactPriorityPill;

  static bool hasMeta(TasklyEntityMetaData meta) {
    final hasDeadline = meta.deadlineDateLabel?.trim().isNotEmpty ?? false;
    final hasStart =
        !meta.showOnlyDeadlineDate &&
        (meta.startDateLabel?.trim().isNotEmpty ?? false);
    return meta.priority != null || hasStart || hasDeadline;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final startLabel = meta.showOnlyDeadlineDate
        ? ''
        : (meta.startDateLabel?.trim() ?? '');
    final deadlineLabel = meta.deadlineDateLabel?.trim() ?? '';
    final priority = meta.priority;
    final hasStart = startLabel.isNotEmpty;
    final hasDeadline = deadlineLabel.isNotEmpty;
    final hasPriority = priority != null;

    if (!hasPriority && !hasStart && !hasDeadline) {
      return const SizedBox.shrink();
    }

    final dueColor = meta.isOverdue || meta.isDueToday
        ? scheme.error
        : scheme.onSurfaceVariant;
    final baseStyle =
        Theme.of(context).textTheme.labelSmall ?? const TextStyle();
    final metaStyle = baseStyle.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );
    final dueStyle = baseStyle.copyWith(
      color: dueColor,
      fontWeight: FontWeight.w700,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        var showPriority = hasPriority;
        var showStart = hasStart;
        final showDeadline = hasDeadline;

        double totalWidth() => _metaLineWidth(
          context,
          showPriority: showPriority,
          showStart: showStart,
          showDeadline: showDeadline,
          startLabel: startLabel,
          deadlineLabel: deadlineLabel,
          metaStyle: metaStyle,
          dueStyle: dueStyle,
        );

        if (totalWidth() > constraints.maxWidth && showPriority) {
          showPriority = false;
        }

        if (totalWidth() > constraints.maxWidth && showStart && showDeadline) {
          showStart = false;
        }

        final children = <Widget>[
          if (showPriority && priority != null)
            PriorityPill(
              priority: priority,
              compact: compactPriorityPill,
              textStyle: metaStyle,
            ),
          if (showStart)
            MetaIconLabel(
              icon: Icons.calendar_today_rounded,
              label: startLabel,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
              textStyle: metaStyle,
            ),
          if (showDeadline)
            MetaIconLabel(
              icon: Icons.flag_rounded,
              label: deadlineLabel,
              color: dueColor,
              textStyle: dueStyle,
            ),
        ];

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i != children.length - 1) SizedBox(width: tokens.spaceSm),
            ],
          ],
        );
      },
    );
  }

  double _metaLineWidth(
    BuildContext context, {
    required bool showPriority,
    required bool showStart,
    required bool showDeadline,
    required String startLabel,
    required String deadlineLabel,
    required TextStyle metaStyle,
    required TextStyle dueStyle,
  }) {
    final widths = <double>[
      if (showPriority)
        _priorityPillWidth(context, meta.priority, compactPriorityPill),
      if (showStart) _metaIconLabelWidth(context, startLabel, metaStyle),
      if (showDeadline) _metaIconLabelWidth(context, deadlineLabel, dueStyle),
    ];

    if (widths.isEmpty) return 0;

    return widths.reduce((a, b) => a + b) +
        tokens.spaceSm * (widths.length - 1);
  }

  double _priorityPillWidth(
    BuildContext context,
    int? priority,
    bool compact,
  ) {
    if (priority == null) return 0;

    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w700,
    );
    final painter = TextPainter(
      text: TextSpan(text: 'P$priority', style: textStyle),
      maxLines: 1,
      textDirection: Directionality.of(context),
    )..layout();

    final padding = compact ? tokens.spaceXs : tokens.spaceXs2;
    return padding * 2 + painter.width;
  }

  double _metaIconLabelWidth(
    BuildContext context,
    String label,
    TextStyle textStyle,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: textStyle),
      maxLines: 1,
      textDirection: Directionality.of(context),
    )..layout();

    final iconSize = tokens.spaceMd2;
    final gap = tokens.spaceXs2;

    return iconSize + gap + painter.width;
  }
}

class _CompletionControl extends StatelessWidget {
  const _CompletionControl({
    required this.completed,
    required this.enabled,
    required this.size,
    required this.checkedFill,
    required this.semanticLabel,
    required this.onToggle,
  });

  final bool completed;
  final bool enabled;
  final double size;
  final Color checkedFill;
  final String? semanticLabel;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final borderColor = completed ? checkedFill : scheme.outlineVariant;
    final transparent = scheme.surface.withValues(alpha: 0);
    final iconColor = completed
        ? checkedFill.withValues(alpha: 0.95)
        : transparent;

    return Semantics(
      label: semanticLabel,
      button: enabled,
      child: InkResponse(
        onTap: enabled ? onToggle : null,
        radius: 22,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: transparent,
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Center(
            child: Icon(
              Icons.check_rounded,
              size: size * 0.7,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _PinnedTrailingIcon extends StatelessWidget {
  const _PinnedTrailingIcon({required this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      label: label ?? 'Pinned',
      child: Icon(
        Icons.push_pin_rounded,
        size: 18,
        color: scheme.primary,
      ),
    );
  }
}

class _PickerActionButton extends StatelessWidget {
  const _PickerActionButton({
    required this.selected,
    required this.enabled,
    required this.onPressed,
    this.tooltip,
  });

  final bool selected;
  final bool enabled;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = TasklyTokens.of(context);
    final bg = selected ? scheme.primaryContainer : scheme.primary;
    final fg = selected ? scheme.primary : scheme.onPrimary;

    return IconButton(
      onPressed: enabled ? onPressed : null,
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

Widget _buildSnoozeBackground(
  BuildContext context,
  ColorScheme scheme, {
  required String label,
  required bool isStartToEnd,
}) {
  final tokens = TasklyTokens.of(context);
  return Container(
    margin: EdgeInsets.symmetric(vertical: tokens.spaceXs),
    decoration: BoxDecoration(
      color: scheme.secondaryContainer,
      borderRadius: BorderRadius.circular(tokens.radiusMd),
    ),
    alignment: isStartToEnd ? Alignment.centerLeft : Alignment.centerRight,
    padding: EdgeInsets.only(
      left: isStartToEnd ? tokens.spaceXl : 0,
      right: isStartToEnd ? 0 : tokens.spaceXl,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.snooze_rounded,
          color: scheme.onSecondaryContainer,
          size: 22,
        ),
        SizedBox(width: tokens.spaceSm),
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: scheme.onSecondaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
