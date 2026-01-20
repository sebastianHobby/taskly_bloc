import 'package:flutter/material.dart';

import 'package:taskly_ui/src/tiles/entity_tile_intents.dart';
import 'package:taskly_ui/src/tiles/entity_tile_models.dart';
import 'package:taskly_ui/src/tiles/project_list_row_tile.dart';

class ProjectEntityTile extends StatelessWidget {
  const ProjectEntityTile({
    required this.model,
    this.intent = const ProjectTileIntent.standardList(),
    this.actions = const ProjectTileActions(),
    super.key,
  });

  final ProjectTileModel model;

  final ProjectTileIntent intent;
  final ProjectTileActions actions;

  @override
  Widget build(BuildContext context) {
    final titlePrefix = model.pinned ? const _PinnedGlyph() : null;

    return switch (intent) {
      ProjectTileIntentBulkSelection(:final selected) => ProjectListRowTile(
        model: model,
        onTap: actions.onToggleSelected ?? actions.onTap,
        onLongPress: actions.onLongPress,
        titlePrefix: titlePrefix,
        trailing: _BulkSelectIcon(
          selected: selected,
          onPressed: actions.onToggleSelected ?? actions.onTap,
        ),
      ),
      _ => ProjectListRowTile(
        model: model,
        onTap: actions.onTap,
        onLongPress: actions.onLongPress,
        titlePrefix: titlePrefix,
        trailing: _TrailingOverflowButton(
          onOverflowMenuRequestedAt: actions.onOverflowMenuRequestedAt,
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
  final VoidCallback? onPressed;

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
