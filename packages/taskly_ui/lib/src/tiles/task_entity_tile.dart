import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:taskly_ui/src/models/value_chip_data.dart';
import 'package:taskly_ui/src/tiles/entity_tile_intents.dart';
import 'package:taskly_ui/src/tiles/entity_tile_models.dart';
import 'package:taskly_ui/src/tiles/entity_tile_theme.dart';

/// Canonical Task tile (rows/cards) aligned to Stitch mockups.
///
/// This is a pure UI component: data in / events out.
class TaskEntityTile extends StatelessWidget {
  const TaskEntityTile({
    required this.model,
    required this.actions,
    this.intent = const TaskTileIntent.standardList(),
    this.markers = const TaskTileMarkers(),
    this.leadingAccentColor,
    this.compact = false,
    this.supportingText,
    this.supportingTooltipText,
    this.completedStatusLabel,
    this.pinnedSemanticLabel,
    this.supportingTooltipSemanticLabel,
    this.snoozeTooltip,
    this.selectionPillLabel,
    this.selectionPillSelectedLabel,
    this.bulkSelectTooltip,
    this.bulkDeselectTooltip,
    super.key,
  });

  final TaskTileModel model;

  final TaskTileIntent intent;
  final TaskTileMarkers markers;
  final TaskTileActions actions;

  /// Optional left-edge accent (used to subtly emphasize urgency).
  final Color? leadingAccentColor;

  /// When true, uses a denser layout for list/agenda contexts.
  final bool compact;

  /// Optional supporting text shown between title and meta line.
  final String? supportingText;

  /// Optional tooltip text for the supporting text.
  ///
  /// When provided, a small info icon is rendered next to the supporting text.
  final String? supportingTooltipText;

  /// Optional label used for the completed status label in selection flows.
  final String? completedStatusLabel;

  /// Optional semantics label for the pinned marker icon.
  final String? pinnedSemanticLabel;

  /// Optional semantics label for the supporting-tooltip info button.
  final String? supportingTooltipSemanticLabel;

  /// Optional tooltip for the snooze icon in selection flows.
  final String? snoozeTooltip;

  /// Optional label for the selection pill in selection flows.
  final String? selectionPillLabel;

  /// Optional label for the selection pill when selected.
  final String? selectionPillSelectedLabel;

  /// Optional tooltip for bulk-selection (not selected).
  final String? bulkSelectTooltip;

  /// Optional tooltip for bulk-selection (selected).
  final String? bulkDeselectTooltip;

  bool get _isSelectionIntent =>
      intent is TaskTileIntentSelection ||
      intent is TaskTileIntentBulkSelection;

  bool get _isBulkSelectionIntent => intent is TaskTileIntentBulkSelection;

  bool get _isPickerSelectionIntent => intent is TaskTileIntentSelection;

  bool? get _selected => switch (intent) {
    TaskTileIntentSelection(:final selected) => selected,
    TaskTileIntentBulkSelection(:final selected) => selected,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = TasklyEntityTileTheme.of(context);

    final effectiveCompact = compact || MediaQuery.sizeOf(context).width < 420;

    final pinnedPrefix = markers.pinned
        ? _PinnedGlyph(label: pinnedSemanticLabel)
        : null;

    final Widget? titlePrefix = pinnedPrefix;

    final completionEnabled =
        !_isSelectionIntent && actions.onToggleCompletion != null;

    // Bulk selection UX: hide completion affordance and show selection control.
    // Keep left-side spacing so rows don't horizontally jump when entering/exiting
    // selection mode.
    final showCompletionControl = !_isBulkSelectionIntent;

    final VoidCallback? onTap = switch (intent) {
      TaskTileIntentSelection() => actions.onToggleSelected ?? actions.onTap,
      TaskTileIntentBulkSelection() =>
        actions.onToggleSelected ?? actions.onTap,
      _ => actions.onTap,
    };

    final String? pickerPillLabel = switch (intent) {
      TaskTileIntentSelection(:final selected) =>
        selected
            ? (selectionPillSelectedLabel ?? 'Added')
            : (selectionPillLabel ?? 'Add'),
      _ => null,
    };

    final bool showCompletedStatusPill =
        _isPickerSelectionIntent &&
        actions.onToggleSelected == null &&
        model.completed &&
        (completedStatusLabel?.trim().isNotEmpty ?? false);

    final effectiveSupportingText = supportingText?.trim();
    final hasSupportingText =
        effectiveSupportingText != null && effectiveSupportingText.isNotEmpty;

    final baseOpacity = model.deemphasized ? 0.6 : 1.0;
    final completedOpacity = model.completed ? 0.75 : 1.0;
    final opacity = (baseOpacity * completedOpacity).clamp(0.0, 1.0);

    final borderColor = scheme.outlineVariant.withValues(alpha: 0.55);

    final tile = DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(tokens.taskRadius),
        border: Border.all(color: borderColor),
        boxShadow: [tokens.shadow],
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
                      SizedBox(width: effectiveCompact ? 10 : 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TopRow(
                              leadingChip: model.leadingChip,
                              priority: model.meta.priority,
                              selected: _isBulkSelectionIntent
                                  ? _selected
                                  : null,
                              bulkSelectTooltip: bulkSelectTooltip,
                              bulkDeselectTooltip: bulkDeselectTooltip,
                              onToggleSelected: actions.onToggleSelected,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (titlePrefix != null) ...[
                                  Padding(
                                    padding: const EdgeInsets.only(top: 1),
                                    child: titlePrefix,
                                  ),
                                  const SizedBox(width: 6),
                                ],
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
                              ],
                            ),
                            if (hasSupportingText) ...[
                              const SizedBox(height: 6),
                              _SupportingText(
                                text: effectiveSupportingText,
                                tooltipText: supportingTooltipText,
                                tooltipSemanticLabel:
                                    supportingTooltipSemanticLabel,
                              ),
                            ],
                            const SizedBox(height: 8),
                            _PlanDueRow(meta: model.meta, tokens: tokens),
                          ],
                        ),
                      ),
                      if (_isPickerSelectionIntent) ...[
                        const SizedBox(width: 8),
                        if (showCompletedStatusPill)
                          _PickerStatusPill(
                            label: completedStatusLabel!.trim(),
                          )
                        else if (pickerPillLabel != null)
                          _PickerSelectionPill(
                            label: pickerPillLabel,
                            selected: _selected ?? false,
                            enabled: actions.onToggleSelected != null,
                            onPressed: actions.onToggleSelected,
                          ),
                        if (intent is TaskTileIntentSelection &&
                            actions.onSnoozeRequested != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: snoozeTooltip ?? 'Snooze',
                            onPressed: actions.onSnoozeRequested,
                            style: IconButton.styleFrom(
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              minimumSize: const Size(40, 40),
                              padding: const EdgeInsets.all(8),
                            ),
                            icon: Icon(
                              Icons.snooze,
                              size: 20,
                              color: scheme.onSurfaceVariant.withValues(
                                alpha: 0.85,
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

class _TopRow extends StatelessWidget {
  const _TopRow({
    required this.leadingChip,
    required this.priority,
    required this.selected,
    required this.bulkSelectTooltip,
    required this.bulkDeselectTooltip,
    required this.onToggleSelected,
  });

  final ValueChipData? leadingChip;
  final int? priority;

  final bool? selected;
  final String? bulkSelectTooltip;
  final String? bulkDeselectTooltip;
  final VoidCallback? onToggleSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = TasklyEntityTileTheme.of(context);

    final chip = leadingChip;

    Widget? selectionWidget;
    if (selected != null) {
      selectionWidget = IconButton(
        tooltip: (selected ?? false)
            ? (bulkDeselectTooltip ?? 'Deselect')
            : (bulkSelectTooltip ?? 'Select'),
        onPressed: onToggleSelected,
        icon: Icon(
          (selected ?? false)
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          color: (selected ?? false) ? scheme.primary : scheme.onSurfaceVariant,
        ),
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: const Size(40, 40),
          padding: const EdgeInsets.all(8),
        ),
      );
    }

    return Row(
      children: [
        if (chip != null) _ValueChip(data: chip, textStyle: tokens.chipText),
        const Spacer(),
        _PriorityBadge(priority: priority, tokens: tokens),
        ...?(selectionWidget == null ? null : [selectionWidget]),
      ],
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

class _PlanDueRow extends StatelessWidget {
  const _PlanDueRow({required this.meta, required this.tokens});

  final EntityMetaLineModel meta;
  final TasklyEntityTileTheme tokens;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final plan = meta.startDateLabel?.trim();
    final due = meta.deadlineDateLabel?.trim();

    final hasPlan = plan != null && plan.isNotEmpty;
    final hasDue = due != null && due.isNotEmpty;

    if (!hasPlan && !hasDue) return const SizedBox.shrink();

    final dueColor = meta.isOverdue || meta.isDueToday
        ? scheme.error
        : scheme.onSurfaceVariant;

    final valueStyle = tokens.metaValue.copyWith(color: scheme.onSurface);
    final dueValueStyle = tokens.metaValue.copyWith(color: dueColor);

    Widget item({
      required IconData icon,
      required TextStyle valueStyle,
      required String value,
      required Color iconColor,
    }) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: valueStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        if (hasPlan)
          Flexible(
            fit: FlexFit.loose,
            child: item(
              icon: Icons.calendar_today_rounded,
              valueStyle: valueStyle,
              value: plan,
              iconColor: scheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
        if (hasPlan && hasDue) ...[
          const SizedBox(width: 12),
          Container(
            width: 1,
            height: 12,
            color: scheme.outlineVariant.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 12),
        ],
        if (hasDue)
          Flexible(
            fit: FlexFit.loose,
            child: item(
              icon: Icons.flag_rounded,
              valueStyle: dueValueStyle,
              value: due,
              iconColor: dueColor,
            ),
          ),
      ],
    );
  }
}

class _CompletionControl extends StatelessWidget {
  const _CompletionControl({
    required this.completed,
    required this.enabled,
    required this.semanticLabel,
    required this.onToggle,
  });

  final bool completed;
  final bool enabled;
  final String? semanticLabel;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final borderColor = completed ? scheme.primary : scheme.outlineVariant;
    const fillColor = Colors.transparent;
    final iconColor = completed
        ? scheme.primary.withValues(alpha: 0.95)
        : Colors.transparent;

    return Semantics(
      label: semanticLabel,
      button: enabled,
      child: InkResponse(
        onTap: enabled ? onToggle : null,
        radius: 22,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fillColor,
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Center(
            child: Icon(
              Icons.check_rounded,
              size: 16,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _ValueChip extends StatelessWidget {
  const _ValueChip({required this.data, required this.textStyle});

  final ValueChipData data;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    final fg = data.color;
    final bg = data.color.withValues(alpha: isDark ? 0.22 : 0.14);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(data.icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority, required this.tokens});

  final int? priority;
  final TasklyEntityTileTheme tokens;

  @override
  Widget build(BuildContext context) {
    final p = priority;
    if (p == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final String label = 'P$p';

    final Color bg;
    final Color fg;
    final BorderSide? border;

    if (p == 1) {
      bg = scheme.error;
      fg = scheme.onError;
      border = null;
    } else if (p == 2) {
      bg = scheme.surfaceContainerHighest.withValues(alpha: 0.95);
      fg = scheme.onSurfaceVariant.withValues(alpha: 0.85);
      border = null;
    } else {
      bg = scheme.surfaceContainerHighest.withValues(alpha: 0.65);
      fg = scheme.onSurfaceVariant.withValues(alpha: 0.7);
      border = null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: border == null ? null : Border.fromBorderSide(border),
      ),
      child: Text(
        label,
        style: tokens.priorityBadge.copyWith(color: fg),
      ),
    );
  }
}

class _PinnedGlyph extends StatelessWidget {
  const _PinnedGlyph({required this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      label: label ?? 'Pinned',
      child: SizedBox(
        width: 18,
        child: Align(
          alignment: Alignment.topCenter,
          child: Icon(
            Icons.push_pin_rounded,
            size: 16,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
          ),
        ),
      ),
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

    final Color bg = selected
        ? scheme.primaryContainer
        : scheme.surfaceContainerHighest.withValues(alpha: 0.9);

    final Color fg = selected ? scheme.onPrimaryContainer : scheme.onSurface;

    return TextButton(
      onPressed: enabled ? onPressed : null,
      style: TextButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        minimumSize: const Size(0, 40),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: selected
              ? BorderSide.none
              : BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.8)),
        ),
      ),
      child: Text(
        effectiveLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
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
