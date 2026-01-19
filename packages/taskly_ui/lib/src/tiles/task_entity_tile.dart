import 'package:flutter/material.dart';

import 'package:taskly_ui/src/catalog/taskly_catalog_types.dart';
import 'package:taskly_ui/src/tiles/entity_tile_models.dart';
import 'package:taskly_ui/src/tiles/task_list_row_tile.dart';

class TaskEntityTile extends StatelessWidget {
  const TaskEntityTile({
    required this.model,
    this.variant = TileVariant.standard,
    this.badges = const [],
    this.trailing = TrailingSpec.none,
    this.onTap,
      titlePrefix = null,
  final TaskTileModel model;
  final TileVariant variant;

  final List<BadgeSpec> badges;
  final TrailingSpec trailing;
}
    final (IconData? icon, Color color, String label) = switch (state) {
      BadgeKind.starts => (Icons.play_arrow_rounded, scheme.primary, 'Starts'),
      BadgeKind.ongoing => (
        Icons.timelapse_rounded,
        scheme.onSurfaceVariant,
        'Ongoing',
      ),
      BadgeKind.due => (Icons.flag_outlined, scheme.error, 'Due'),
      _ => (null, scheme.onSurfaceVariant, ''),
    };

    final semanticLabel = [
      if (state != null) label,
      if (pinned) 'Pinned',
    ].join(', ');

    return Semantics(
      label = semanticLabel.isEmpty ? null : semanticLabel,
      child = SizedBox(
        width: 22,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (icon != null)
              Align(
                alignment: Alignment.topCenter,
                child: Icon(icon, size: 16, color: color),
              ),
            if (pinned)
              Positioned(
                right: -1,
                top: -1,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: scheme.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
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
    if (trailing != TrailingSpec.overflowButton) {
      return const SizedBox.shrink();
    }
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
