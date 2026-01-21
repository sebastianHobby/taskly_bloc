import 'package:flutter/material.dart';

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
    this.supportingText,
    this.supportingTooltipText,
    super.key,
  });

  final TaskTileModel model;

  final TaskTileIntent intent;
  final TaskTileMarkers markers;
  final TaskTileActions actions;

  /// Optional supporting text shown between title and meta line.
  final String? supportingText;

  /// Optional tooltip text for the supporting text.
  ///
  /// When provided, a small info icon is rendered next to the supporting text.
  /// The tooltip is shown on tap.
  final String? supportingTooltipText;

  @override
  Widget build(BuildContext context) {
    final Widget? titlePrefix = markers.pinned ? const _PinnedGlyph() : null;

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
                  label: 'Why suggested',
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (actions.onSnoozeRequested != null)
              IconButton(
                tooltip: 'Snooze',
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
            _SelectPill(
              selected: selected,
              onPressed: actions.onToggleSelected ?? actions.onTap,
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
        trailing: _BulkSelectIcon(
          selected: selected,
          onPressed: actions.onToggleSelected ?? actions.onTap,
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
        trailing: model.titlePrimaryValue == null
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.only(top: 2),
                child: ValueIcon(data: model.titlePrimaryValue!),
              ),
      ),
    };
  }
}

class _BulkSelectIcon extends StatelessWidget {
  const _BulkSelectIcon({
    required this.selected,
    required this.onPressed,
  });

  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
  const _PinnedGlyph();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Pinned',
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
  });

  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final label = selected ? 'Added' : 'Add';

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
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
