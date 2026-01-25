import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:taskly_ui/src/feed/taskly_feed_spec.dart';
import 'package:taskly_ui/src/models/value_chip_data.dart';
import 'package:taskly_ui/src/primitives/meta_badges.dart';
import 'package:taskly_ui/src/tiles/entity_tile_theme.dart';
import 'package:taskly_ui/src/primitives/value_chip_widget.dart';

/// Canonical Task tile (rows/cards) aligned to Stitch mockups.
///
/// This is a pure UI component: data in / events out.
class TaskEntityTile extends StatelessWidget {
  const TaskEntityTile({
    required this.model,
    required this.actions,
    this.style = const TasklyTaskRowStyle.standard(),
    this.leadingAccentColor,
    super.key,
  });

  final TasklyTaskRowData model;

  final TasklyTaskRowStyle style;
  final TasklyTaskRowActions actions;

  /// Optional left-edge accent (used to subtly emphasize urgency).
  final Color? leadingAccentColor;

  bool get _isSelectionStyle =>
      style is TasklyTaskRowStylePicker ||
      style is TasklyTaskRowStylePickerAction ||
      style is TasklyTaskRowStylePlanPick ||
      style is TasklyTaskRowStyleBulkSelection;

  bool get _isBulkSelectionStyle => style is TasklyTaskRowStyleBulkSelection;

  bool get _isPickerStyle => style is TasklyTaskRowStylePicker;

  bool get _isPickerActionStyle => style is TasklyTaskRowStylePickerAction;

  bool get _isPlanPickStyle => style is TasklyTaskRowStylePlanPick;

  bool get _isPickerLikeStyle =>
      _isPickerStyle || _isPickerActionStyle || _isPlanPickStyle;

  bool get _isPinnedToggleStyle => style is TasklyTaskRowStylePinnedToggle;

  bool? get _selected => switch (style) {
    TasklyTaskRowStylePicker(:final selected) => selected,
    TasklyTaskRowStylePickerAction(:final selected) => selected,
    TasklyTaskRowStylePlanPick(:final selected) => selected,
    TasklyTaskRowStyleBulkSelection(:final selected) => selected,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = TasklyEntityTileTheme.of(context);

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
    final showCompletionControl =
        !_isBulkSelectionStyle && !_isPickerLikeStyle;

    final VoidCallback? onTap = switch (style) {
      TasklyTaskRowStylePicker() => actions.onToggleSelected ?? actions.onTap,
      TasklyTaskRowStylePickerAction() =>
        actions.onToggleSelected ?? actions.onTap,
      TasklyTaskRowStylePlanPick() =>
        actions.onToggleSelected ?? actions.onTap,
      TasklyTaskRowStyleBulkSelection() =>
        actions.onToggleSelected ?? actions.onTap,
      _ => actions.onTap,
    };

    final String? pickerPillLabel = switch (style) {
      TasklyTaskRowStylePicker(:final selected) =>
        selected
            ? (model.labels?.selectionPillSelectedLabel ?? 'Added')
            : (model.labels?.selectionPillLabel ?? 'Add'),
      _ => null,
    };
    final addTooltipLabel = (_selected ?? false)
        ? (model.labels?.selectionPillSelectedLabel ?? 'Added')
        : (model.labels?.selectionPillLabel ?? 'Add');

    final bool showCompletedStatusPill =
        _isPickerStyle &&
        actions.onToggleSelected == null &&
        model.completed &&
        (model.labels?.completedStatusLabel?.trim().isNotEmpty ?? false);

    final baseOpacity = model.deemphasized ? 0.6 : 1.0;
    final completedOpacity = model.completed ? 0.75 : 1.0;
    final opacity = (baseOpacity * completedOpacity).clamp(0.0, 1.0);

    final isPlanPickSelected = _isPlanPickStyle && (_selected ?? false);
    final selectedTint = scheme.primaryContainer.withValues(alpha: 0.16);
    final tileSurface = isPlanPickSelected
        ? Color.alphaBlend(selectedTint, tokens.cardSurfaceColor)
        : tokens.cardSurfaceColor;

    final titleStyle = isMobileWidth
        ? tokens.taskTitle.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: (tokens.taskTitle.fontSize ?? 16) + 1,
          )
        : tokens.taskTitle;

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
            onTap: onTap,
            onLongPress: actions.onLongPress,
            child: Stack(
              children: [
                if (leadingAccentColor != null)
                  Positioned.fill(
                    left: 0,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(width: 4, color: leadingAccentColor),
                    ),
                  ),
                Padding(
                  padding: effectivePadding.copyWith(
                    left: (leadingAccentColor == null)
                        ? effectivePadding.left
                        : (effectivePadding.left + 2),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showCompletionControl) ...[
                        _CompletionControl(
                          completed: model.completed,
                          enabled: completionEnabled,
                          size: tokens.checkboxSize,
                          checkedFill: tokens.checkboxCheckedFill,
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
                        SizedBox(width: effectiveCompact ? 6 : 8),
                      ] else if (_isBulkSelectionStyle) ...[
                        const SizedBox(width: 24, height: 24),
                        SizedBox(width: effectiveCompact ? 6 : 8),
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
                                  const SizedBox(width: 6),
                                  _PinnedTrailingIcon(
                                    label: model.labels?.pinnedSemanticLabel,
                                    tooltip: model.labels?.pinnedLabel,
                                    onPressed: _isPinnedToggleStyle
                                        ? () => actions.onTogglePinned?.call(
                                            false,
                                          )
                                        : null,
                                  ),
                                ],
                                if (_isBulkSelectionStyle) ...[
                                  const SizedBox(width: 6),
                                  IconButton(
                                    tooltip: (_selected ?? false)
                                        ? (model.labels?.bulkDeselectTooltip ??
                                              'Deselect')
                                        : (model.labels?.bulkSelectTooltip ??
                                              'Select'),
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
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      minimumSize: const Size(40, 40),
                                      padding: const EdgeInsets.all(8),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            _MetaRow(
                              model: model,
                              tokens: tokens,
                              compactPriorityPill: _isPlanPickStyle,
                              primaryIconOnly: model.primaryValueIconOnly,
                            ),
                          ],
                        ),
                      ),
                      if (_isPickerLikeStyle) ...[
                        const SizedBox(width: 8),
                        if (_isPlanPickStyle)
                          _PickerActionCluster(
                            selected: _selected ?? false,
                            addTooltip: addTooltipLabel,
                            snoozeTooltip: model.labels?.snoozeTooltip,
                            onAddPressed: actions.onToggleSelected,
                            onSnoozePressed: actions.onSnoozeRequested,
                          )
                        else if (_isPickerActionStyle)
                          _PickerActionButton(
                            selected: _selected ?? false,
                            enabled: actions.onToggleSelected != null,
                            onPressed: actions.onToggleSelected,
                          )
                        else if (showCompletedStatusPill)
                          _PickerStatusPill(
                            label: model.labels!.completedStatusLabel!.trim(),
                          )
                        else if (pickerPillLabel != null)
                          _PickerSelectionPill(
                            label: pickerPillLabel,
                            selected: _selected ?? false,
                            enabled: actions.onToggleSelected != null,
                            onPressed: actions.onToggleSelected,
                          ),
                        if (!_isPlanPickStyle &&
                            _isPickerLikeStyle &&
                            actions.onSnoozeRequested != null) ...[
                          const SizedBox(width: 6),
                          TextButton(
                            onPressed: actions.onSnoozeRequested,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 6,
                              ),
                              minimumSize: const Size(0, 32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              model.labels?.snoozeTooltip ?? 'Snooze',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
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

    return Opacity(
      key: Key('task-${model.id}'),
      opacity: opacity,
      child: tile,
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.model,
    required this.tokens,
    required this.compactPriorityPill,
    required this.primaryIconOnly,
  });

  final TasklyTaskRowData model;
  final TasklyEntityTileTheme tokens;
  final bool compactPriorityPill;
  final bool primaryIconOnly;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final meta = model.meta;

    final valueChip = model.leadingChip;
    final secondaryChips = model.secondaryChips;
    final hasValue = valueChip != null || secondaryChips.isNotEmpty;
    final plan = meta.startDateLabel?.trim() ?? '';
    final due = meta.deadlineDateLabel?.trim() ?? '';

    final hasPlan = plan.isNotEmpty;
    final hasDue = due.isNotEmpty;
    final hasPriority = meta.priority != null;
    final hasMeta = hasPriority || hasPlan || hasDue;

    if (!hasValue && !hasMeta) {
      return const SizedBox.shrink();
    }

    final dueColor = meta.isOverdue || meta.isDueToday
        ? scheme.error
        : scheme.onSurfaceVariant;

    final valueStyle = tokens.metaValue.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final dueValueStyle = tokens.metaValue.copyWith(color: dueColor);

    final screenWidth = MediaQuery.sizeOf(context).width;
    final primaryLabelMaxWidth = screenWidth < 420
        ? 80.0
        : screenWidth < 600
        ? 96.0
        : 140.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final rightWidth = _rightMetaWidth(
          context,
          showDue: hasDue,
          dueLabel: due,
          dueStyle: dueValueStyle,
        );

        final maxLeftWidth = _leftMaxWidth(
          constraints.maxWidth,
          rightWidth,
          spacing,
        );

        final leftLayout = _resolveLeftLayout(
          context,
          maxLeftWidth: maxLeftWidth,
          leadingChip: valueChip,
          secondaryChips: secondaryChips,
          hasPriority: hasPriority,
          priority: meta.priority,
          hasPlan: hasPlan,
          planLabel: plan,
          planStyle: valueStyle,
          compactPriorityPill: compactPriorityPill,
          primaryIconOnly: primaryIconOnly,
          primaryLabelMaxWidth: primaryLabelMaxWidth,
        );

        final items = <Widget>[
          for (final chip in leftLayout.chips)
            ValueChip(
              data: chip.data,
              iconOnly: chip.iconOnly,
              maxLabelWidth: chip.maxLabelWidth,
            ),
          if (leftLayout.showPriority)
            PriorityPill(
              priority: meta.priority!,
              compact: compactPriorityPill,
            ),
          if (leftLayout.showPlan)
            MetaIconLabel(
              icon: Icons.calendar_today_rounded,
              label: plan,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
              textStyle: valueStyle,
            ),
        ];

        final leftMeta = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              items[i],
              if (i != items.length - 1) const SizedBox(width: spacing),
            ],
          ],
        );

        if (!hasDue) {
          return leftMeta;
        }

        final rightMeta = MetaIconLabel(
          icon: Icons.flag_rounded,
          label: due,
          color: dueColor,
          textStyle: dueValueStyle,
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: leftMeta),
            const SizedBox(width: spacing),
            rightMeta,
          ],
        );
      },
    );
  }

  _LeftMetaLayout _resolveLeftLayout(
    BuildContext context, {
    required double maxLeftWidth,
    required ValueChipData? leadingChip,
    required List<ValueChipData> secondaryChips,
    required bool hasPriority,
    required int? priority,
    required bool hasPlan,
    required String planLabel,
    required TextStyle planStyle,
    required bool compactPriorityPill,
    required bool primaryIconOnly,
    required double primaryLabelMaxWidth,
  }) {
    if (maxLeftWidth <= 0) {
      return const _LeftMetaLayout.empty();
    }

    final candidates = <_LeftLayoutCandidate>[
      _LeftLayoutCandidate(
        showPriority: hasPriority,
        showPlan: hasPlan,
      ),
      if (hasPriority)
        _LeftLayoutCandidate(
          showPriority: false,
          showPlan: hasPlan,
        ),
      if (hasPlan)
        const _LeftLayoutCandidate(
          showPriority: false,
          showPlan: false,
        ),
      if (!hasPriority && !hasPlan)
        const _LeftLayoutCandidate(
          showPriority: false,
          showPlan: false,
        ),
    ];

    _LeftMetaLayout? fallback;
    final seen = <String>{};

    for (final candidate in candidates) {
      final key = '${candidate.showPriority}-${candidate.showPlan}';
      if (!seen.add(key)) continue;

      final layout = _buildLayout(
        context,
        maxLeftWidth: maxLeftWidth,
        leadingChip: leadingChip,
        secondaryChips: secondaryChips,
        showPriority: candidate.showPriority,
        priority: priority,
        showPlan: candidate.showPlan,
        planLabel: planLabel,
        planStyle: planStyle,
        compactPriorityPill: compactPriorityPill,
        primaryIconOnly: primaryIconOnly,
        primaryLabelMaxWidth: primaryLabelMaxWidth,
      );
      fallback ??= layout;
      if (layout.totalWidth <= maxLeftWidth) {
        return layout;
      }
    }

    return fallback ?? const _LeftMetaLayout.empty();
  }

  _LeftMetaLayout _buildLayout(
    BuildContext context, {
    required double maxLeftWidth,
    required ValueChipData? leadingChip,
    required List<ValueChipData> secondaryChips,
    required bool showPriority,
    required int? priority,
    required bool showPlan,
    required String planLabel,
    required TextStyle planStyle,
    required bool compactPriorityPill,
    required bool primaryIconOnly,
    required double primaryLabelMaxWidth,
  }) {
    final renders = <_ChipRender>[];
    if (leadingChip != null) {
      renders.add(
        _ChipRender(
          data: leadingChip,
          iconOnly: primaryIconOnly,
          maxLabelWidth: primaryLabelMaxWidth,
        ),
      );
    }
    for (final chip in secondaryChips) {
      renders.add(
        _ChipRender(
          data: ValueChipData(
            label: chip.label,
            icon: chip.icon,
            color: chip.color.withValues(alpha: 0.55),
            semanticLabel: chip.semanticLabel ?? chip.label,
          ),
          iconOnly: true,
          maxLabelWidth: primaryLabelMaxWidth,
        ),
      );
    }

    final minChipCount = renders.isEmpty ? 0 : 1;
    final current = List<_ChipRender>.from(renders);

    while (current.length > minChipCount &&
        _leftMetaWidth(
              context,
              chips: current,
              showPriority: showPriority,
              priority: priority,
              compactPriorityPill: compactPriorityPill,
              showPlan: showPlan,
              planLabel: planLabel,
              planStyle: planStyle,
            ) >
            maxLeftWidth) {
      current.removeLast();
    }

    final totalWidth = _leftMetaWidth(
      context,
      chips: current,
      showPriority: showPriority,
      priority: priority,
      compactPriorityPill: compactPriorityPill,
      showPlan: showPlan,
      planLabel: planLabel,
      planStyle: planStyle,
    );

    return _LeftMetaLayout(
      chips: current,
      showPriority: showPriority,
      showPlan: showPlan,
      totalWidth: totalWidth,
      hasPrimaryChip: leadingChip != null,
    );
  }

  double _leftMetaWidth(
    BuildContext context, {
    required List<_ChipRender> chips,
    required bool showPriority,
    required int? priority,
    required bool compactPriorityPill,
    required bool showPlan,
    required String planLabel,
    required TextStyle planStyle,
  }) {
    const spacing = 8.0;
    final widths = <double>[
      for (final chip in chips)
        _chipWidth(
          context,
          chip,
        ),
      if (showPriority)
        _priorityPillWidth(
          context,
          priority,
          compact: compactPriorityPill,
        ),
      if (showPlan)
        _metaIconLabelWidth(
          context,
          label: planLabel,
          textStyle: planStyle,
        ),
    ];

    if (widths.isEmpty) {
      return 0;
    }

    return widths.reduce((a, b) => a + b) + spacing * (widths.length - 1);
  }

  double _chipWidth(
    BuildContext context,
    _ChipRender chip,
  ) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 11,
      height: 1.1,
      letterSpacing: 0.2,
    );
    const iconSize = 14.0;
    const gap = 6.0;
    const padding = 8.0;
    const iconOnlyPadding = 6.0;
    const border = 2.0;

    if (chip.iconOnly) {
      return iconOnlyPadding * 2 + iconSize + border;
    }

    final painter = TextPainter(
      text: TextSpan(text: chip.data.label, style: textStyle),
      maxLines: 1,
      textDirection: Directionality.of(context),
    )..layout();

    final textWidth = painter.width.clamp(0, chip.maxLabelWidth);

    return padding * 2 + iconSize + gap + textWidth + border;
  }

  double _priorityPillWidth(
    BuildContext context,
    int? priority, {
    required bool compact,
  }) {
    if (priority == null) {
      return 0;
    }

    final theme = Theme.of(context);
    final textStyle = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: compact ? 10 : null,
    );
    final painter = TextPainter(
      text: TextSpan(text: 'P$priority', style: textStyle),
      maxLines: 1,
      textDirection: Directionality.of(context),
    )..layout();

    final padding = compact ? 4.0 : 6.0;

    return padding * 2 + painter.width;
  }

  double _rightMetaWidth(
    BuildContext context, {
    required bool showDue,
    required String dueLabel,
    required TextStyle dueStyle,
  }) {
    if (!showDue) {
      return 0;
    }

    return _metaIconLabelWidth(
      context,
      label: dueLabel,
      textStyle: dueStyle,
    );
  }

  double _metaIconLabelWidth(
    BuildContext context, {
    required String label,
    required TextStyle textStyle,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: textStyle),
      maxLines: 1,
      textDirection: Directionality.of(context),
    )..layout();

    const iconSize = 14.0;
    const gap = 6.0;

    return iconSize + gap + painter.width;
  }

  double _leftMaxWidth(double total, double rightWidth, double spacing) {
    final remaining = total - rightWidth - (rightWidth == 0 ? 0 : spacing);
    return remaining < 0 ? 0 : remaining;
  }
}

class _ChipRender {
  const _ChipRender({
    required this.data,
    required this.maxLabelWidth,
    this.iconOnly = false,
  });

  final ValueChipData data;
  final bool iconOnly;
  final double maxLabelWidth;
}

class _LeftLayoutCandidate {
  const _LeftLayoutCandidate({
    required this.showPriority,
    required this.showPlan,
  });

  final bool showPriority;
  final bool showPlan;
}

class _LeftMetaLayout {
  const _LeftMetaLayout({
    required this.chips,
    required this.showPriority,
    required this.showPlan,
    required this.totalWidth,
    required this.hasPrimaryChip,
  });

  const _LeftMetaLayout.empty()
    : chips = const <_ChipRender>[],
      showPriority = false,
      showPlan = false,
      totalWidth = 0,
      hasPrimaryChip = false;

  final List<_ChipRender> chips;
  final bool showPriority;
  final bool showPlan;
  final double totalWidth;
  final bool hasPrimaryChip;
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
  const _PinnedTrailingIcon({
    required this.label,
    this.tooltip,
    this.onPressed,
  });

  final String? label;
  final String? tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final icon = Icon(
      Icons.push_pin_rounded,
      size: 18,
      color: scheme.primary,
    );

    final child = onPressed == null
        ? icon
        : IconButton(
            onPressed: onPressed,
            tooltip: tooltip ?? label ?? 'Pinned',
            icon: icon,
            style: IconButton.styleFrom(
              minimumSize: const Size(36, 36),
              padding: const EdgeInsets.all(6),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          );

    return Semantics(
      label: label ?? 'Pinned',
      child: child,
    );
  }
}

class _PickerSelectionPill extends StatelessWidget {
  const _PickerSelectionPill({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onPressed,
  });

  final String? label;
  final bool selected;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final effectiveLabel = label?.trim();
    if (effectiveLabel == null || effectiveLabel.isEmpty) {
      return const SizedBox.shrink();
    }

    final Color fg = selected ? scheme.primary : scheme.onSurfaceVariant;

    return TextButton(
      onPressed: enabled ? onPressed : null,
      style: TextButton.styleFrom(
        foregroundColor: fg,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        effectiveLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _PickerActionButton extends StatelessWidget {
  const _PickerActionButton({
    required this.selected,
    required this.enabled,
    required this.onPressed,
  });

  final bool selected;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = selected ? scheme.primaryContainer : scheme.primary;
    final fg = selected ? scheme.primary : scheme.onPrimary;

    return IconButton(
      onPressed: enabled ? onPressed : null,
      icon: Icon(selected ? Icons.check_rounded : Icons.add_rounded),
      style: IconButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        minimumSize: const Size(36, 36),
        padding: const EdgeInsets.all(6),
      ),
    );
  }
}

class _PickerActionCluster extends StatelessWidget {
  const _PickerActionCluster({
    required this.selected,
    required this.addTooltip,
    required this.snoozeTooltip,
    required this.onAddPressed,
    required this.onSnoozePressed,
  });

  final bool selected;
  final String? addTooltip;
  final String? snoozeTooltip;
  final VoidCallback? onAddPressed;
  final VoidCallback? onSnoozePressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = scheme.surfaceContainerHighest.withValues(alpha: 0.8);
    final border = scheme.outlineVariant.withValues(alpha: 0.7);
    final divider = scheme.outlineVariant.withValues(alpha: 0.55);
    final addBg = selected ? scheme.primaryContainer : scheme.primary;
    final addFg = selected ? scheme.primary : scheme.onPrimary;

    final add = IconButton(
      onPressed: onAddPressed,
      tooltip: addTooltip,
      icon: Icon(selected ? Icons.check_rounded : Icons.add_rounded),
      style: IconButton.styleFrom(
        backgroundColor: addBg,
        foregroundColor: addFg,
        minimumSize: const Size(32, 32),
        padding: const EdgeInsets.all(6),
      ),
    );

    final snooze = IconButton(
      onPressed: onSnoozePressed,
      tooltip: snoozeTooltip,
      icon: const Icon(Icons.snooze_rounded),
      style: IconButton.styleFrom(
        minimumSize: const Size(32, 32),
        padding: const EdgeInsets.all(6),
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          add,
          Container(
            width: 1,
            height: 22,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: divider,
          ),
          snooze,
        ],
      ),
    );
  }
}

class _PickerStatusPill extends StatelessWidget {
  const _PickerStatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.8)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: scheme.onSurfaceVariant,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
