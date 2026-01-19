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
    return ProjectListRowTile(
      model: model,
      onTap: onTap,
      titlePrefix: _ScheduleGlyphColumn(badges: badges),
      scheduleState: _firstScheduleState(badges),
      trailing: _TrailingOverflowButton(
        trailing: trailing,
        onOverflowRequestedAt: onOverflowRequestedAt,
      ),
    );
  }
}

BadgeKind? _firstScheduleState(List<BadgeSpec> badges) {
  for (final badge in badges) {
    switch (badge.kind) {
      case BadgeKind.starts:
      case BadgeKind.ongoing:
      case BadgeKind.due:
        return badge.kind;
      case BadgeKind.pinned:
        continue;
    }
  }
  return null;
}

class _ScheduleGlyphColumn extends StatelessWidget {
  const _ScheduleGlyphColumn({required this.badges});

  final List<BadgeSpec> badges;

  @override
  Widget build(BuildContext context) {
    final BadgeKind? state = _firstScheduleState(badges);
    if (state == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;

    final (IconData icon, Color color, String label) = switch (state) {
      BadgeKind.starts => (Icons.play_arrow_rounded, scheme.primary, 'Starts'),
      BadgeKind.ongoing => (
        Icons.timelapse_rounded,
        scheme.onSurfaceVariant,
        'Ongoing',
      ),
      BadgeKind.due => (Icons.flag_outlined, scheme.error, 'Due'),
      _ => (Icons.timelapse_rounded, scheme.onSurfaceVariant, ''),
    };

    return Semantics(
      label: label.isEmpty ? null : label,
      child: SizedBox(
        width: 22,
        child: Align(
          alignment: Alignment.topCenter,
          child: Icon(icon, size: 16, color: color),
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
