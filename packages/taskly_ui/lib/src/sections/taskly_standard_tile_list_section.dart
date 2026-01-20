import 'package:flutter/material.dart';

import 'package:taskly_ui/src/tiles/entity_tile_intents.dart';
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
    required this.actions,
    this.intent = const TaskTileIntent.standardList(),
    this.markers = const TaskTileMarkers(),
    this.supportingText,
  });

  final String entityId;
  final TaskTileModel model;

  final TaskTileIntent intent;
  final TaskTileMarkers markers;
  final TaskTileActions actions;
  final String? supportingText;
}

final class TasklyStandardTileListProjectRowModel
    extends TasklyStandardTileListRowModel {
  const TasklyStandardTileListProjectRowModel({
    required super.key,
    required super.depth,
    required this.entityId,
    required this.model,
    this.intent = const ProjectTileIntent.standardList(),
    this.actions = const ProjectTileActions(),
  });

  final String entityId;
  final ProjectTileModel model;

  final ProjectTileIntent intent;
  final ProjectTileActions actions;
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
        final leftIndent = 10.0 * row.depth;

        final child = switch (row) {
          TasklyStandardTileListHeaderRowModel() => _HeaderRow(row: row),
          TasklyStandardTileListIconHeaderRowModel() => _IconHeaderRow(
            row: row,
          ),
          TasklyStandardTileListTaskRowModel() => TaskEntityTile(
            model: row.model,
            intent: row.intent,
            markers: row.markers,
            actions: row.actions,
            supportingText: row.supportingText,
          ),
          TasklyStandardTileListProjectRowModel() => ProjectEntityTile(
            model: row.model,
            intent: row.intent,
            actions: row.actions,
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final text = Text(
      row.title,
      style: theme.textTheme.titleSmall?.copyWith(
        color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
    );

    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: text,
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: row.onTap == null
          ? content
          : InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: row.onTap,
              child: content,
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

    final bool tappable = row.onTap != null;

    final child = Row(
      children: [
        Icon(row.leadingIcon, size: 18, color: scheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            row.title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
        if (tappable && row.trailingIcon != null)
          Icon(row.trailingIcon, size: 18, color: scheme.onSurfaceVariant),
      ],
    );

    final padded = Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: child,
      ),
    );

    if (!tappable) return padded;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: row.onTap,
      child: padded,
    );
  }
}
