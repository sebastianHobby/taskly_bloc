import 'package:flutter/material.dart';

import 'package:taskly_ui/src/tiles/entity_tile_intents.dart';
import 'package:taskly_ui/src/tiles/entity_tile_models.dart';
import 'package:taskly_ui/src/tiles/project_list_row_tile.dart';

class ProjectEntityTile extends StatelessWidget {
  const ProjectEntityTile({
    required this.model,
    this.intent = const ProjectTileIntent.standardList(),
    this.actions = const ProjectTileActions(),
    this.titlePrefixOverride,
    this.leadingAccentColor,
    this.compact = false,
    super.key,
  });

  final ProjectTileModel model;

  final ProjectTileIntent intent;
  final ProjectTileActions actions;

  /// Optional override for the leading title prefix (e.g., urgency glyph).
  ///
  /// When provided and the project is pinned, both glyphs are shown.
  final Widget? titlePrefixOverride;

  /// Optional left-edge accent (used to subtly emphasize urgency).
  final Color? leadingAccentColor;

  /// When true, uses a denser layout for list/agenda contexts.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final pinnedPrefix = model.pinned ? const _PinnedGlyph() : null;

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

    return switch (intent) {
      ProjectTileIntentBulkSelection(:final selected) => ProjectListRowTile(
        model: model,
        onTap: actions.onToggleSelected ?? actions.onTap,
        onLongPress: actions.onLongPress,
        compact: compact,
        titlePrefix: titlePrefix,
        leadingAccentColor: leadingAccentColor,
        trailing: _BulkSelectIcon(
          selected: selected,
          onPressed: actions.onToggleSelected ?? actions.onTap,
        ),
      ),
      _ => ProjectListRowTile(
        model: model,
        onTap: actions.onTap,
        onLongPress: actions.onLongPress,
        compact: compact,
        titlePrefix: titlePrefix,
        leadingAccentColor: leadingAccentColor,
        trailing: const SizedBox.shrink(),
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
