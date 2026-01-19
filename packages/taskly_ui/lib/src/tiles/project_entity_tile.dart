import 'package:flutter/material.dart';

import 'package:taskly_ui/src/catalog/taskly_catalog_types.dart';
import 'package:taskly_ui/src/tiles/entity_tile_models.dart';
import 'package:taskly_ui/src/tiles/project_list_row_tile.dart';

class ProjectEntityTile extends StatelessWidget {
  const ProjectEntityTile({
    required this.model,
    this.variant = TileVariant.standard,
    this.badges = const [],
    this.trailing = TrailingSpec.none,
    this.onTap,
    this.onOverflowRequestedAt,
    super.key,
  });

  final ProjectTileModel model;
  final TileVariant variant;

  final List<BadgeSpec> badges;
  final TrailingSpec trailing;

  final VoidCallback? onTap;

  /// Called when the overflow button is pressed.
  ///
  /// The [Offset] is the global position of the tap.
  final ValueChanged<Offset>? onOverflowRequestedAt;

  @override
  Widget build(BuildContext context) {
    final bool pinned = badges.any((b) => b.kind == BadgeKind.pinned);
    final Widget? titlePrefix = pinned ? const _PinnedGlyph() : null;

    return ProjectListRowTile(
      model: model,
      onTap: onTap,
      titlePrefix: titlePrefix,
      trailing: _TrailingOverflowButton(
        trailing: trailing,
        onOverflowRequestedAt: onOverflowRequestedAt,
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
    required this.trailing,
    required this.onOverflowRequestedAt,
  });

  final TrailingSpec trailing;
  final ValueChanged<Offset>? onOverflowRequestedAt;

  @override
  Widget build(BuildContext context) {
    if (trailing != TrailingSpec.overflowButton) return const SizedBox.shrink();
    if (onOverflowRequestedAt == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final iconColor = scheme.onSurfaceVariant.withValues(alpha: 0.85);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) => onOverflowRequestedAt!(details.globalPosition),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Icon(Icons.more_horiz, size: 20, color: iconColor),
      ),
    );
  }
}
