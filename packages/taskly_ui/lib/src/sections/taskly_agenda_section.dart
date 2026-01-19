import 'package:flutter/material.dart';

import 'package:taskly_ui/src/catalog/taskly_catalog_types.dart';
import 'package:taskly_ui/src/tiles/entity_tile_models.dart';
import 'package:taskly_ui/src/tiles/project_entity_tile.dart';
import 'package:taskly_ui/src/tiles/task_entity_tile.dart';

sealed class TasklyAgendaRowModel {
  const TasklyAgendaRowModel({required this.key, required this.depth});

  final String key;
  final int depth;
}

final class TasklyAgendaBucketHeaderRowModel extends TasklyAgendaRowModel {
  const TasklyAgendaBucketHeaderRowModel({
    required super.key,
    required super.depth,
    required this.bucketKey,
    required this.title,
    required this.isCollapsed,
    this.onTap,
  });

  final String bucketKey;
  final String title;
  final bool isCollapsed;
  final VoidCallback? onTap;
}

final class TasklyAgendaDateHeaderRowModel extends TasklyAgendaRowModel {
  const TasklyAgendaDateHeaderRowModel({
    required super.key,
    required super.depth,
    required this.day,
    required this.title,
    this.isTodayAnchor = false,
  });

  final DateTime day;
  final String title;
  final bool isTodayAnchor;
}

final class TasklyAgendaEmptyDayRowModel extends TasklyAgendaRowModel {
  const TasklyAgendaEmptyDayRowModel({
    required super.key,
    required super.depth,
    required this.day,
    required this.label,
  });

  final DateTime day;
  final String label;
}

final class TasklyAgendaTaskRowModel extends TasklyAgendaRowModel {
  const TasklyAgendaTaskRowModel({
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

final class TasklyAgendaProjectRowModel extends TasklyAgendaRowModel {
  const TasklyAgendaProjectRowModel({
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

class TasklyAgendaSection extends StatelessWidget {
  const TasklyAgendaSection({
    required this.rows,
    this.controller,
    this.todayAnchorKey,
    super.key,
  });

  final List<TasklyAgendaRowModel> rows;
  final ScrollController? controller;

  /// When provided, applied to the first date header row that has
  /// [TasklyAgendaDateHeaderRowModel.isTodayAnchor] set.
  final Key? todayAnchorKey;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        final leftIndent = 12.0 * row.depth;

        final child = switch (row) {
          TasklyAgendaBucketHeaderRowModel() => _BucketHeaderRow(row: row),
          TasklyAgendaDateHeaderRowModel() => _DateHeaderRow(row: row),
          TasklyAgendaEmptyDayRowModel() => _EmptyDayRow(row: row),
          TasklyAgendaTaskRowModel() => TaskEntityTile(
            model: row.model,
            badges: row.badges,
            trailing: row.trailing,
            onTap: row.onTap,
            onToggleCompletion: row.onToggleCompletion,
            onOverflowRequestedAt: row.onOverflowRequestedAt,
          ),
          TasklyAgendaProjectRowModel() => ProjectEntityTile(
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

        if (todayAnchorKey == null) {
          return KeyedSubtree(key: ValueKey(row.key), child: indented);
        }

        if (row is TasklyAgendaDateHeaderRowModel && row.isTodayAnchor) {
          return KeyedSubtree(
            key: ValueKey(row.key),
            child: KeyedSubtree(
              key: todayAnchorKey,
              child: indented,
            ),
          );
        }

        return KeyedSubtree(key: ValueKey(row.key), child: indented);
      },
    );
  }
}

class _BucketHeaderRow extends StatelessWidget {
  const _BucketHeaderRow({required this.row});

  final TasklyAgendaBucketHeaderRowModel row;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: row.onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                row.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Icon(
              row.isCollapsed ? Icons.chevron_right : Icons.expand_more,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateHeaderRow extends StatelessWidget {
  const _DateHeaderRow({required this.row});

  final TasklyAgendaDateHeaderRowModel row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Text(
        row.title,
        style: Theme.of(context).textTheme.labelLarge,
      ),
    );
  }
}

class _EmptyDayRow extends StatelessWidget {
  const _EmptyDayRow({required this.row});

  final TasklyAgendaEmptyDayRowModel row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Text(
        row.label,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
