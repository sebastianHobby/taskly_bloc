import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:taskly_ui/src/feed/taskly_feed_spec.dart';
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

  bool get _isBulkSelectionPreset =>
      preset is TasklyTaskRowPresetBulkSelection;

  bool get _isPickerPreset => preset is TasklyTaskRowPresetPicker;

  bool get _isPickerActionPreset => preset is TasklyTaskRowPresetPickerAction;

  bool get _isPickerLikePreset => _isPickerPreset || _isPickerActionPreset;

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

    final pinnedPrefix = markers.pinned
        ? _PinnedGlyph(label: model.labels?.pinnedSemanticLabel)
        : null;

    final Widget? titlePrefix = pinnedPrefix;

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
                                          : Icons.radio_button_unchecked_rounded,
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
                                tooltipSemanticLabel:
                                    model.labels?.supportingTooltipSemanticLabel,
                              ),
                            ],
                            const SizedBox(height: 6),
                            _MetaRow(
                              model: model,
                              markers: markers,
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
    required this.markers,
    required this.tokens,
  });

  final TasklyTaskRowData model;
  final TasklyTaskRowMarkers markers;
  final TasklyEntityTileTheme tokens;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final meta = model.meta;

    final valueChip = model.leadingChip;
    final hasValue = valueChip != null;
    final hasFocus = markers.focused;

    final plan = meta.startDateLabel?.trim();
    final due = meta.deadlineDateLabel?.trim();

    final hasPlan = plan != null && plan.isNotEmpty;
    final hasDue = due != null && due.isNotEmpty;
    final hasPriority = meta.priority != null;
    final hasMeta = hasPriority || hasPlan || hasDue;

    if (!hasValue && !hasFocus && !hasMeta) {
      return const SizedBox.shrink();
    }

    final dueColor = meta.isOverdue || meta.isDueToday
        ? scheme.error
        : scheme.onSurfaceVariant;

    final valueStyle = tokens.metaValue.copyWith(color: scheme.onSurfaceVariant);
    final dueValueStyle = tokens.metaValue.copyWith(color: dueColor);

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (valueChip case final value?)
          ValueChip(data: value),
        if (hasFocus) const _FocusPill(),
        if (hasPriority) PriorityPill(priority: meta.priority!),
        if (hasPlan)
          MetaIconLabel(
            icon: Icons.calendar_today_rounded,
            label: plan,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
            textStyle: valueStyle,
          ),
        if (hasDue)
          MetaIconLabel(
            icon: Icons.flag_rounded,
            label: due,
            color: dueColor,
            textStyle: dueValueStyle,
          ),
      ],
    );
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

class _FocusPill extends StatelessWidget {
  const _FocusPill();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.gps_fixed_rounded,
            size: 12,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            'FOCUS',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurfaceVariant,
              letterSpacing: 0.4,
            ),
          ),
        ],
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
