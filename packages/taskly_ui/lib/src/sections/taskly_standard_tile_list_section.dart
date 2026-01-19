import 'package:flutter/material.dart';

import 'package:taskly_ui/src/catalog/taskly_catalog_types.dart';
import 'package:taskly_ui/src/tiles/entity_tile_models.dart';
import 'package:taskly_ui/src/tiles/project_entity_tile.dart';
import 'package:taskly_ui/src/tiles/task_entity_tile.dart';

sealed class TasklyStandardTileListRowModel {
  const TasklyStandardTileListRowModel({
    required this.key,
    required this.depth,
  });

  final String key;
  final int depth;
}

final class TasklyStandardTileListHeaderRowModel
    extends TasklyStandardTileListRowModel {
  const TasklyStandardTileListHeaderRowModel({
    required super.key,
    required super.depth,
    required this.title,
    this.onTap,
  });

  final String title;
  final VoidCallback? onTap;
}

final class TasklyStandardTileListIconHeaderRowModel
    extends TasklyStandardTileListRowModel {
  const TasklyStandardTileListIconHeaderRowModel({
    required super.key,
    required super.depth,
    required this.title,
    required this.leadingIcon,
    this.onTap,
    this.trailingIcon = Icons.chevron_right,
  });

  final String title;
  final IconData leadingIcon;
  final VoidCallback? onTap;
  final IconData? trailingIcon;
}

final class TasklyStandardTileListTaskRowModel
    extends TasklyStandardTileListRowModel {
  const TasklyStandardTileListTaskRowModel({
    required super.key,
    required super.depth,
    required this.entityId,
    required this.model,
    this.badges = const [],
    this.trailing = TrailingSpec.none,
    this.onTap,
    this.onToggleCompletion,
    this.onOverflowRequestedAt,
  });

  final String entityId;
  final TaskTileModel model;

  final List<BadgeSpec> badges;
  final TrailingSpec trailing;

  final VoidCallback? onTap;
  final ValueChanged<bool?>? onToggleCompletion;
  final ValueChanged<Offset>? onOverflowRequestedAt;
}

final class TasklyStandardTileListProjectRowModel
    extends TasklyStandardTileListRowModel {
  const TasklyStandardTileListProjectRowModel({
    required super.key,
    required super.depth,
    required this.entityId,
    required this.model,
    this.badges = const [],
    this.trailing = TrailingSpec.none,
    this.onTap,
    this.onOverflowRequestedAt,
  });

  final String entityId;
  final ProjectTileModel model;

  final List<BadgeSpec> badges;
  final TrailingSpec trailing;

  final VoidCallback? onTap;
  final ValueChanged<Offset>? onOverflowRequestedAt;
}

class TasklyStandardTileListSection extends StatelessWidget {
  const TasklyStandardTileListSection({
    required this.rows,
    this.controller,
    super.key,
  });

  final List<TasklyStandardTileListRowModel> rows;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        final leftIndent = 12.0 * row.depth;

        final child = switch (row) {
          TasklyStandardTileListHeaderRowModel() => _HeaderRow(row: row),
          TasklyStandardTileListIconHeaderRowModel() => _IconHeaderRow(
            row: row,
          ),
          TasklyStandardTileListTaskRowModel() => TaskEntityTile(
            model: row.model,
            badges: row.badges,
            trailing: row.trailing,
            onTap: row.onTap,
            onToggleCompletion: row.onToggleCompletion,
            onOverflowRequestedAt: row.onOverflowRequestedAt,
          ),
          TasklyStandardTileListProjectRowModel() => ProjectEntityTile(
            model: row.model,
            badges: row.badges,
            trailing: row.trailing,
            onTap: row.onTap,
            onOverflowRequestedAt: row.onOverflowRequestedAt,
          ),
        };

        final indented = leftIndent <= 0
            ? child
            : Padding(
                padding: EdgeInsets.only(left: leftIndent),
                child: child,
              );

        return KeyedSubtree(key: ValueKey(row.key), child: indented);
      },
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.row});

  final TasklyStandardTileListHeaderRowModel row;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      row.title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: row.onTap == null
          ? text
          : InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: row.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: text,
              ),
            ),
    );
  }
}

class _IconHeaderRow extends StatelessWidget {
  const _IconHeaderRow({required this.row});

  final TasklyStandardTileListIconHeaderRowModel row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final child = Row(
      children: [
        Icon(row.leadingIcon, size: 18, color: scheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            row.title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
        if (row.trailingIcon != null)
          Icon(row.trailingIcon, size: 18, color: scheme.onSurfaceVariant),
      ],
    );

    final padded = Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: child,
      ),
    );

    if (row.onTap == null) return padded;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: row.onTap,
      child: padded,
    );
  }
}
