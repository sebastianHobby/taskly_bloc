import 'package:flutter/material.dart';

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
    super.key,
  });

  final TaskTileModel model;

  final TaskTileIntent intent;
  final TaskTileMarkers markers;
  final TaskTileActions actions;

  /// Optional supporting text shown between title and meta line.
  final String? supportingText;

  @override
  Widget build(BuildContext context) {
    final Widget? titlePrefix = markers.pinned ? const _PinnedGlyph() : null;

    final effectiveSupportingText = supportingText;
    final Widget? footer =
        (effectiveSupportingText == null ||
            effectiveSupportingText.trim().isEmpty)
        ? null
        : Text(
            _capWithEllipsis(effectiveSupportingText.trim(), 20),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
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
      _ => TaskListRowTile(
        model: model,
        onTap: actions.onTap,
        onToggleCompletion: actions.onToggleCompletion,
        subtitle: null,
        titlePrefix: titlePrefix,
        footer: footer,
        trailing: _TrailingOverflowButton(
          onOverflowMenuRequestedAt: actions.onOverflowMenuRequestedAt,
        ),
      ),
    };
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

class _TrailingOverflowButton extends StatelessWidget {
  const _TrailingOverflowButton({
    required this.onOverflowMenuRequestedAt,
  });

  final ValueChanged<Offset>? onOverflowMenuRequestedAt;

  @override
  Widget build(BuildContext context) {
    if (onOverflowMenuRequestedAt == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final iconColor = scheme.onSurfaceVariant.withValues(alpha: 0.85);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) =>
          onOverflowMenuRequestedAt!(details.globalPosition),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Icon(Icons.more_horiz, size: 20, color: iconColor),
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
