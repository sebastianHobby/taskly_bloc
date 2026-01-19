import 'package:flutter/material.dart';

import 'package:taskly_ui/src/catalog/taskly_catalog_types.dart';
import 'package:taskly_ui/src/primitives/taskly_badge.dart';
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
    return ProjectListRowTile(
      model: model,
      onTap: onTap,
      titlePrefix: _Badges(badges: badges),
      trailing: _TrailingOverflowButton(
        trailing: trailing,
        onOverflowRequestedAt: onOverflowRequestedAt,
      ),
    );
  }
}

class _Badges extends StatelessWidget {
  const _Badges({required this.badges});

  final List<BadgeSpec> badges;

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final badge in badges)
          TasklyBadge(
            label: badge.label,
            color: switch (badge.kind) {
              BadgeKind.due => scheme.error,
              BadgeKind.starts => scheme.primary,
              BadgeKind.ongoing => scheme.onSurfaceVariant,
              BadgeKind.pinned => scheme.secondary,
            },
          ),
      ],
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
        child: Icon(
          Icons.more_horiz,
          size: 20,
          color: iconColor,
        ),
      ),
    );
  }
}
