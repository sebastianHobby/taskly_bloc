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
    this.preset = const TasklyTaskRowPreset.standard(),
    this.markers = const TasklyTaskRowMarkers(),
    this.leadingAccentColor,
    super.key,
  });

  final TasklyTaskRowData model;

  final TasklyTaskRowPreset preset;
  final TasklyTaskRowMarkers markers;
  final TasklyTaskRowActions actions;

  /// Optional left-edge accent (used to subtly emphasize urgency).
  final Color? leadingAccentColor;

  bool get _isSelectionPreset =>
      preset is TasklyTaskRowPresetPicker ||
      preset is TasklyTaskRowPresetPickerAction ||
      preset is TasklyTaskRowPresetBulkSelection;

  bool get _isBulkSelectionPreset => preset is TasklyTaskRowPresetBulkSelection;

  bool get _isPickerPreset => preset is TasklyTaskRowPresetPicker;

  bool get _isPickerActionPreset => preset is TasklyTaskRowPresetPickerAction;

  bool get _isPickerLikePreset => _isPickerPreset || _isPickerActionPreset;

  bool get _isPinnedTogglePreset => preset is TasklyTaskRowPresetPinnedToggle;

  bool? get _selected => switch (preset) {
    TasklyTaskRowPresetPicker(:final selected) => selected,
    TasklyTaskRowPresetPickerAction(:final selected) => selected,
    TasklyTaskRowPresetBulkSelection(:final selected) => selected,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = TasklyEntityTileTheme.of(context);

    final effectiveCompact = MediaQuery.sizeOf(context).width < 420;

    final completionEnabled =
        !_isSelectionPreset && actions.onToggleCompletion != null;

    // Bulk selection UX: hide completion affordance and show selection control.
    // Keep left-side spacing so rows don't horizontally jump when entering/exiting
    // selection mode.
    final showCompletionControl = !_isBulkSelectionPreset;

    final VoidCallback? onTap = switch (preset) {
      TasklyTaskRowPresetPicker() => actions.onToggleSelected ?? actions.onTap,
      TasklyTaskRowPresetPickerAction() =>
        actions.onToggleSelected ?? actions.onTap,
      TasklyTaskRowPresetBulkSelection() =>
        actions.onToggleSelected ?? actions.onTap,
      _ => actions.onTap,
    };

    final String? pickerPillLabel = switch (preset) {
      TasklyTaskRowPresetPicker(:final selected) =>
        selected
            ? (model.labels?.selectionPillSelectedLabel ?? 'Added')
            : (model.labels?.selectionPillLabel ?? 'Add'),
      _ => null,
    };

    final bool showCompletedStatusPill =
        _isPickerPreset &&
        actions.onToggleSelected == null &&
        model.completed &&
        (model.labels?.completedStatusLabel?.trim().isNotEmpty ?? false);

    final effectiveSupportingText = model.supportingText?.trim();
    final hasSupportingText =
        effectiveSupportingText != null && effectiveSupportingText.isNotEmpty;

    final baseOpacity = model.deemphasized ? 0.6 : 1.0;
    final completedOpacity = model.completed ? 0.75 : 1.0;
    final opacity = (baseOpacity * completedOpacity).clamp(0.0, 1.0);

    final tile = DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.cardSurfaceColor,
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
                  padding: tokens.taskPadding.copyWith(
                    left: (leadingAccentColor == null)
                        ? tokens.taskPadding.left
                        : (tokens.taskPadding.left + 2),
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
                      ] else ...[
                        const SizedBox(width: 24, height: 24),
                      ],
                      SizedBox(width: effectiveCompact ? 6 : 8),
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
                                    style: tokens.taskTitle.copyWith(
                                      color: scheme.onSurface,
                                      decoration: model.completed
                                          ? TextDecoration.lineThrough
                                          : null,
                                      decorationColor: scheme.onSurface
                                          .withValues(alpha: 0.55),
                                    ),
                                  ),
                                ),
                                if (markers.pinned) ...[
                                  const SizedBox(width: 6),
                                  _PinnedTrailingIcon(
                                    label: model.labels?.pinnedSemanticLabel,
                                    tooltip: model.labels?.pinnedLabel,
                                    onPressed: _isPinnedTogglePreset
                                        ? () => actions.onTogglePinned?.call(
                                            false,
                                          )
                                        : null,
                                  ),
                                ],
                                if (_isBulkSelectionPreset) ...[
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
                            if (hasSupportingText) ...[
                              const SizedBox(height: 4),
                              _SupportingText(
                                text: effectiveSupportingText,
                                tooltipText: model.supportingTooltipText,
                                tooltipSemanticLabel: model
                                    .labels
                                    ?.supportingTooltipSemanticLabel,
                              ),
                            ],
                            const SizedBox(height: 6),
                            _MetaRow(
                              model: model,
                              tokens: tokens,
                            ),
                          ],
                        ),
                      ),
                      if (_isPickerLikePreset) ...[
                        const SizedBox(width: 8),
                        if (_isPickerActionPreset)
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
                        if (_isPickerPreset &&
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

class _SupportingText extends StatelessWidget {
  const _SupportingText({
    required this.text,
    required this.tooltipText,
    required this.tooltipSemanticLabel,
  });

  final String? text;
  final String? tooltipText;
  final String? tooltipSemanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = TasklyEntityTileTheme.of(context);

    final effectiveText = text?.trim();
    if (effectiveText == null || effectiveText.isEmpty) {
      return const SizedBox.shrink();
    }

    final effectiveTooltipText = tooltipText?.trim();
    final hasTooltip =
        effectiveTooltipText != null && effectiveTooltipText.isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: Text(
            effectiveText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tokens.subtitle.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        if (hasTooltip) ...[
          const SizedBox(width: 6),
          Semantics(
            button: true,
            label: tooltipSemanticLabel ?? 'More info',
            child: Tooltip(
              message: effectiveTooltipText,
              triggerMode: TooltipTriggerMode.tap,
              showDuration: const Duration(seconds: 10),
              child: IconButton(
                tooltip: tooltipSemanticLabel,
                onPressed: () {},
                icon: Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                ),
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  minimumSize: const Size(32, 32),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.model,
    required this.tokens,
  });

  final TasklyTaskRowData model;
  final TasklyEntityTileTheme tokens;

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

    const chipMaxWidth = 110.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        var showPriority = hasPriority;
        var showPlan = hasPlan;

        double rightWidth = _rightMetaWidth(
          context,
          showPlan: showPlan,
          showDue: hasDue,
          planLabel: plan,
          dueLabel: due,
          planStyle: valueStyle,
          dueStyle: dueValueStyle,
        );

        double maxLeftWidth = _leftMaxWidth(
          constraints.maxWidth,
          rightWidth,
          spacing,
        );

        final minPrimaryWidth = valueChip == null
            ? 0.0
            : _chipWidth(
                context,
                valueChip,
                chipMaxWidth,
                iconOnly: false,
              );
        double minLeftWidth(bool includePriority) {
          if (minPrimaryWidth == 0) {
            return 0;
          }

          final widths = <double>[minPrimaryWidth];
          if (includePriority) {
            widths.add(_priorityPillWidth(context, meta.priority));
          }

          return widths.reduce((a, b) => a + b) + spacing * (widths.length - 1);
        }

        if (showPriority && minLeftWidth(true) > maxLeftWidth) {
          showPriority = false;
        }

        if (showPlan && minLeftWidth(showPriority) > maxLeftWidth) {
          showPlan = false;
          rightWidth = _rightMetaWidth(
            context,
            showPlan: showPlan,
            showDue: hasDue,
            planLabel: plan,
            dueLabel: due,
            planStyle: valueStyle,
            dueStyle: dueValueStyle,
          );
          maxLeftWidth = _leftMaxWidth(
            constraints.maxWidth,
            rightWidth,
            spacing,
          );
          if (showPriority && minLeftWidth(true) > maxLeftWidth) {
            showPriority = false;
          }
        }

        final valueChips = _resolveValueChips(
          context,
          maxWidth: maxLeftWidth,
          leadingChip: valueChip,
          secondaryChips: secondaryChips,
          showPriority: showPriority,
          priority: meta.priority,
          maxLabelWidth: chipMaxWidth,
        );

        final items = <Widget>[
          for (final chip in valueChips)
            ValueChip(
              data: chip.data,
              iconOnly: chip.iconOnly,
              maxLabelWidth: chipMaxWidth,
            ),
          if (showPriority) PriorityPill(priority: meta.priority!),
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

        if (!showPlan && !hasDue) {
          return leftMeta;
        }

        final rightMeta = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showPlan) ...[
              MetaIconLabel(
                icon: Icons.calendar_today_rounded,
                label: plan,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                textStyle: valueStyle,
              ),
              if (hasDue) const SizedBox(width: spacing),
            ],
            if (hasDue)
              MetaIconLabel(
                icon: Icons.flag_rounded,
                label: due,
                color: dueColor,
                textStyle: dueValueStyle,
              ),
          ],
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

  List<_ChipRender> _resolveValueChips(
    BuildContext context, {
    required double maxWidth,
    required ValueChipData? leadingChip,
    required List<ValueChipData> secondaryChips,
    required bool showPriority,
    required int? priority,
    required double maxLabelWidth,
  }) {
    final chips = <ValueChipData>[...secondaryChips];
    if (leadingChip != null) {
      chips.insert(0, leadingChip);
    }

    if (chips.isEmpty) {
      return const <_ChipRender>[];
    }

    final fixedWidths = <double>[
      if (showPriority) _priorityPillWidth(context, priority),
    ];

    const spacing = 8.0;

    double totalWidthFor(List<_ChipRender> renders) {
      final chipWidths = [
        for (final render in renders)
          _chipWidth(
            context,
            render.data,
            maxLabelWidth,
            iconOnly: render.iconOnly,
          ),
      ];
      final allWidths = <double>[
        ...chipWidths,
        ...fixedWidths,
      ];

      if (allWidths.isEmpty) {
        return 0;
      }

      return allWidths.reduce((a, b) => a + b) +
          spacing * (allWidths.length - 1);
    }

    final fullRenders = <_ChipRender>[
      for (final chip in chips) _ChipRender(data: chip),
    ];

    if (totalWidthFor(fullRenders) <= maxWidth) {
      return fullRenders;
    }

    final primary = leadingChip;
    final secondary = leadingChip == null ? chips : chips.skip(1).toList();

    final iconOnlyRenders = <_ChipRender>[
      if (primary != null) _ChipRender(data: primary),
      for (final chip in secondary)
        _ChipRender(
          data: chip,
          iconOnly: true,
        ),
    ];

    if (totalWidthFor(iconOnlyRenders) <= maxWidth) {
      return iconOnlyRenders;
    }

    for (var visibleCount = secondary.length; visibleCount >= 0; visibleCount--) {
      final renders = <_ChipRender>[
        if (primary != null) _ChipRender(data: primary),
        for (final chip in secondary.take(visibleCount))
          _ChipRender(
            data: chip,
            iconOnly: true,
          ),
      ];

      if (totalWidthFor(renders) <= maxWidth) {
        return renders;
      }
    }

    return primary == null
        ? const <_ChipRender>[]
        : <_ChipRender>[_ChipRender(data: primary)];
  }

  double _chipWidth(
    BuildContext context,
    ValueChipData chip,
    double maxLabelWidth, {
    required bool iconOnly,
  }) {
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

    if (iconOnly) {
      return iconOnlyPadding * 2 + iconSize + border;
    }

    final painter = TextPainter(
      text: TextSpan(text: chip.label, style: textStyle),
      maxLines: 1,
      textDirection: Directionality.of(context),
    )..layout();

    final textWidth = painter.width.clamp(0, maxLabelWidth);

    return padding * 2 + iconSize + gap + textWidth + border;
  }

  double _priorityPillWidth(BuildContext context, int? priority) {
    if (priority == null) {
      return 0;
    }

    final theme = Theme.of(context);
    final textStyle = theme.textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w700,
    );
    final painter = TextPainter(
      text: TextSpan(text: 'P$priority', style: textStyle),
      maxLines: 1,
      textDirection: Directionality.of(context),
    )..layout();

    const padding = 6.0;

    return padding * 2 + painter.width;
  }

  double _rightMetaWidth(
    BuildContext context, {
    required bool showPlan,
    required bool showDue,
    required String planLabel,
    required String dueLabel,
    required TextStyle planStyle,
    required TextStyle dueStyle,
  }) {
    if (!showPlan && !showDue) {
      return 0;
    }

    const spacing = 8.0;
    final widths = <double>[
      if (showPlan)
        _metaIconLabelWidth(
          context,
          label: planLabel,
          textStyle: planStyle,
        ),
      if (showDue)
        _metaIconLabelWidth(
          context,
          label: dueLabel,
          textStyle: dueStyle,
        ),
    ];

    return widths.reduce((a, b) => a + b) + spacing * (widths.length - 1);
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
    this.iconOnly = false,
  });

  final ValueChipData data;
  final bool iconOnly;
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
