import 'package:flutter/material.dart';

import 'package:taskly_ui/src/models/value_chip_data.dart';
import 'package:taskly_ui/src/primitives/date_chip.dart';
import 'package:taskly_ui/src/primitives/value_icon.dart';
import 'package:taskly_ui/src/tiles/entity_tile_intents.dart';
import 'package:taskly_ui/src/tiles/entity_tile_models.dart';
import 'package:taskly_ui/src/tiles/task_list_row_tile.dart';

class TaskEntityTile extends StatelessWidget {
  const TaskEntityTile({
    required this.model,
    required this.actions,
    this.intent = const TaskTileIntent.standardList(),
    this.markers = const TaskTileMarkers(),
    this.titlePrefixOverride,
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

  /// Optional override for the leading title prefix (e.g., urgency glyph).
  ///
  /// When provided and the task is pinned, both glyphs are shown.
  final Widget? titlePrefixOverride;

  /// Optional left-edge accent (used to subtly emphasize urgency).
  final Color? leadingAccentColor;

  /// When true, uses a denser layout for list/agenda contexts.
  final bool compact;

  /// Optional supporting text shown between title and meta line.
  final String? supportingText;

  /// Optional tooltip text for the supporting text.
  ///
  /// When provided, a small info icon is rendered next to the supporting text.
  /// The tooltip is shown on tap.
  final String? supportingTooltipText;

  /// Optional label used for the completed status chip in selection flows.
  ///
  /// When null, the default English label is used.
  final String? completedStatusLabel;

  /// Optional semantics label for the pinned marker icon.
  ///
  /// When null, the default English label is used.
  final String? pinnedSemanticLabel;

  /// Optional semantics label for the supporting-tooltip info button.
  ///
  /// When null, the default English label is used.
  final String? supportingTooltipSemanticLabel;

  /// Optional tooltip for the snooze icon in selection flows.
  ///
  /// When null, the default English label is used.
  final String? snoozeTooltip;

  /// Optional label for the selection pill in selection flows.
  ///
  /// When null, the default English label is used.
  final String? selectionPillLabel;

  /// Optional label for the selection pill when the row is already selected.
  ///
  /// When null, the default English label is used.
  final String? selectionPillSelectedLabel;

  /// Optional tooltip for bulk-selection (not selected).
  ///
  /// When null, the default English label is used.
  final String? bulkSelectTooltip;

  /// Optional tooltip for bulk-selection (selected).
  ///
  /// When null, the default English label is used.
  final String? bulkDeselectTooltip;

  @override
  Widget build(BuildContext context) {
    final pinnedPrefix = markers.pinned
        ? _PinnedGlyph(label: pinnedSemanticLabel)
        : null;

    final Widget? titlePrefix = switch ((titlePrefixOverride, pinnedPrefix)) {
      (null, null) => null,
      (final Widget a?, null) => a,
      (null, final Widget b?) => b,
      (final Widget a?, final Widget b?) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          a,
          const SizedBox(width: 6),
          b,
        ],
      ),
    };

    final effectiveSupportingText = supportingText?.trim();
    final effectiveTooltipText = supportingTooltipText?.trim();
    final hasSupportingText =
        effectiveSupportingText != null && effectiveSupportingText.isNotEmpty;
    final hasTooltip =
        effectiveTooltipText != null && effectiveTooltipText.isNotEmpty;

    final scheme = Theme.of(context).colorScheme;
    final footerTextStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    final Widget? footer = !hasSupportingText
        ? null
        : Row(
            children: [
              Expanded(
                child: Text(
                  _capWithEllipsis(effectiveSupportingText, 40),
                  style: footerTextStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),
              if (hasTooltip) ...[
                const SizedBox(width: 6),
                Semantics(
                  button: true,
                  label: supportingTooltipSemanticLabel ?? 'Why suggested',
                  child: Tooltip(
                    message: effectiveTooltipText,
                    triggerMode: TooltipTriggerMode.tap,
                    showDuration: const Duration(seconds: 10),
                    child: IconButton(
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

    return switch (intent) {
      TaskTileIntentSelection(:final selected) => TaskListRowTile(
        model: model,
        onTap: actions.onToggleSelected ?? actions.onTap,
        onToggleCompletion: null,
        subtitle: null,
        titlePrefix: titlePrefix,
        footer: footer,
        leadingAccentColor: leadingAccentColor,
        compact: compact,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (actions.onSnoozeRequested != null)
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
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
                ),
              ),
            if (actions.onToggleSelected != null || actions.onTap != null)
              _SelectPill(
                selected: selected,
                onPressed: actions.onToggleSelected ?? actions.onTap,
                label: selectionPillLabel,
                selectedLabel: selectionPillSelectedLabel,
              )
            else if (model.completed)
              _CompletedStatusChip(
                label: completedStatusLabel,
              ),
          ],
        ),
      ),
      TaskTileIntentBulkSelection(:final selected) => TaskListRowTile(
        model: model,
        onTap: actions.onToggleSelected ?? actions.onTap,
        onLongPress: actions.onLongPress,
        onToggleCompletion: null,
        subtitle: null,
        titlePrefix: titlePrefix,
        footer: footer,
        leadingAccentColor: leadingAccentColor,
        compact: compact,
        trailing: _BulkSelectIcon(
          selected: selected,
          onPressed: actions.onToggleSelected ?? actions.onTap,
          tooltipSelected: bulkDeselectTooltip,
          tooltipNotSelected: bulkSelectTooltip,
        ),
      ),
      _ => TaskListRowTile(
        model: model,
        onTap: actions.onTap,
        onLongPress: actions.onLongPress,
        onToggleCompletion: actions.onToggleCompletion,
        subtitle: null,
        titlePrefix: titlePrefix,
        footer: footer,
        leadingAccentColor: leadingAccentColor,
        compact: compact,
        trailing: _TitleTrailing(
          meta: model.meta,
          titlePrimaryValue: model.titlePrimaryValue,
        ),
      ),
    };
  }
}

class _TitleTrailing extends StatelessWidget {
  const _TitleTrailing({required this.meta, required this.titlePrimaryValue});

  final EntityMetaLineModel meta;
  final ValueChipData? titlePrimaryValue;

  @override
  Widget build(BuildContext context) {
    final deadlineLabel = meta.deadlineDateLabel?.trim();
    final showDeadlineChip =
        meta.showDeadlineChipOnTitleLine &&
        deadlineLabel != null &&
        deadlineLabel.isNotEmpty;

    final showValueIcon = titlePrimaryValue != null;
    if (!showDeadlineChip && !showValueIcon) return const SizedBox.shrink();

    final children = <Widget>[];

    if (showDeadlineChip) {
      children.add(
        _TapAbsorber(
          child: DateChip.deadline(
            context: context,
            label: deadlineLabel,
            isOverdue: meta.isOverdue,
            isDueToday: meta.isDueToday,
            isDueSoon: meta.isDueSoon,
          ),
        ),
      );
    }

    if (showDeadlineChip && showValueIcon) {
      children.add(const SizedBox(width: 8));
    }

    if (showValueIcon) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: ValueIcon(data: titlePrimaryValue!),
        ),
      );
    }

    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }
}

class _TapAbsorber extends StatelessWidget {
  const _TapAbsorber({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(child: ExcludeSemantics(child: child));
  }
}

class _BulkSelectIcon extends StatelessWidget {
  const _BulkSelectIcon({
    required this.selected,
    required this.onPressed,
    this.tooltipSelected,
    this.tooltipNotSelected,
  });

  final bool selected;
  final VoidCallback? onPressed;
  final String? tooltipSelected;
  final String? tooltipNotSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: selected
          ? (tooltipSelected ?? 'Deselect')
          : (tooltipNotSelected ?? 'Select'),
      onPressed: onPressed,
      icon: Icon(
        selected
            ? Icons.check_circle_rounded
            : Icons.radio_button_unchecked_rounded,
        color: selected ? scheme.primary : scheme.onSurfaceVariant,
      ),
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.all(10),
      ),
    );
  }
}

String _capWithEllipsis(String text, int maxChars) {
  if (maxChars <= 0) return '…';
  if (text.length <= maxChars) return text;
  return '${text.substring(0, maxChars)}…';
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

class _SelectPill extends StatelessWidget {
  const _SelectPill({
    required this.selected,
    required this.onPressed,
    this.label,
    this.selectedLabel,
  });

  final bool selected;
  final VoidCallback? onPressed;
  final String? label;
  final String? selectedLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final effectiveLabel = selected
        ? (selectedLabel ?? 'Added')
        : (label ?? 'Add');

    final background = selected
        ? scheme.surfaceContainerLow
        : scheme.surfaceContainerHighest;

    final foreground = scheme.onSurfaceVariant;

    final border = selected ? Border.all(color: scheme.outlineVariant) : null;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        constraints: const BoxConstraints(minWidth: 64),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: border,
        ),
        child: Text(
          effectiveLabel,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _CompletedStatusChip extends StatelessWidget {
  const _CompletedStatusChip({required this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 6),
          Text(
            label ?? 'Completed',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
