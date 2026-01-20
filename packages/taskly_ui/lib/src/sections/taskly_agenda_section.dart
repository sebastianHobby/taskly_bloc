import 'package:flutter/material.dart';

import 'package:taskly_ui/src/tiles/entity_tile_intents.dart';
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
    this.action,
    this.onTap,
  });

  final String bucketKey;
  final String title;
  final bool isCollapsed;

  final TasklyAgendaBucketHeaderAction? action;
  final VoidCallback? onTap;
}

final class TasklyAgendaBucketHeaderAction {
  const TasklyAgendaBucketHeaderAction({
    required this.label,
    this.icon,
    this.tooltip,
    this.onPressed,
  });

  final String label;
  final IconData? icon;
  final String? tooltip;
  final VoidCallback? onPressed;
}

final class TasklyAgendaDateHeaderRowModel extends TasklyAgendaRowModel {
  const TasklyAgendaDateHeaderRowModel({
    required super.key,
    required super.depth,
    required this.day,
    required this.title,
    this.subtitle,
    this.isTodayAnchor = false,
  });

  final DateTime day;
  final String title;
  final String? subtitle;
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

final class TasklyAgendaProjectRowModel extends TasklyAgendaRowModel {
  const TasklyAgendaProjectRowModel({
    required super.key,
    required super.depth,
    required this.entityId,
    required this.model,
    this.intent = const ProjectTileIntent.agenda(),
    this.actions = const ProjectTileActions(),
  });

  final String entityId;
  final ProjectTileModel model;

  final ProjectTileIntent intent;
  final ProjectTileActions actions;
}

final class TasklyAgendaCardHeaderAction {
  const TasklyAgendaCardHeaderAction({
    required this.label,
    this.icon,
    this.tooltip,
    this.onPressed,
  });

  final String label;
  final IconData? icon;
  final String? tooltip;
  final VoidCallback? onPressed;
}

final class TasklyAgendaCardModel {
  const TasklyAgendaCardModel({
    required this.key,
    required this.title,
    this.subtitle,
    this.headerKey,
    this.isCollapsed = false,
    this.onHeaderTap,
    this.action,
    this.plannedRows = const <TasklyAgendaRowModel>[],
    this.dueRows = const <TasklyAgendaRowModel>[],
  });

  final String key;
  final String title;
  final String? subtitle;

  /// Optional key applied to the card header container.
  ///
  /// This is typically used by the app to scroll to a specific date.
  final Key? headerKey;

  final bool isCollapsed;
  final VoidCallback? onHeaderTap;
  final TasklyAgendaCardHeaderAction? action;

  final List<TasklyAgendaRowModel> plannedRows;
  final List<TasklyAgendaRowModel> dueRows;
}

class TasklyAgendaSection extends StatelessWidget {
  const TasklyAgendaSection({
    required this.cards,
    this.controller,
    super.key,
  });

  final List<TasklyAgendaCardModel> cards;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: scheme.surfaceContainerLow,
            elevation: 0,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: _AgendaCard(card: card),
          ),
        );
      },
    );
  }
}

class _AgendaCard extends StatelessWidget {
  const _AgendaCard({required this.card});

  final TasklyAgendaCardModel card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final action = card.action;
    final hasPlanned = card.plannedRows.isNotEmpty;
    final hasDue = card.dueRows.isNotEmpty;

    final header = InkWell(
      key: card.headerKey,
      onTap: card.onHeaderTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                  if (card.subtitle != null && card.subtitle!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        card.subtitle!.trim(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    ),
                ],
              ),
            ),
            if (action != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Tooltip(
                  message: action.tooltip ?? action.label,
                  child: TextButton.icon(
                    onPressed: action.onPressed,
                    icon: action.icon == null
                        ? const SizedBox.shrink()
                        : Icon(action.icon, size: 18),
                    label: Text(action.label),
                  ),
                ),
              ),
            if (card.onHeaderTap != null)
              Icon(
                card.isCollapsed
                    ? Icons.expand_more_rounded
                    : Icons.expand_less_rounded,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
              ),
          ],
        ),
      ),
    );

    if (card.isCollapsed) {
      return Column(children: [header]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        if (hasPlanned) const _SectionLabel(label: 'PLANNED'),
        if (hasPlanned) ..._buildRows(context, card.plannedRows),
        if (hasPlanned && hasDue)
          Divider(
            height: 1,
            thickness: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.35),
          ),
        if (hasDue) const _SectionLabel(label: 'DUE'),
        if (hasDue) ..._buildRows(context, card.dueRows),
      ],
    );
  }

  List<Widget> _buildRows(
    BuildContext context,
    List<TasklyAgendaRowModel> rows,
  ) {
    return rows.map((r) => _AgendaCardRow(row: r)).toList(growable: false);
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _AgendaCardRow extends StatelessWidget {
  const _AgendaCardRow({required this.row});

  final TasklyAgendaRowModel row;

  @override
  Widget build(BuildContext context) {
    return switch (row) {
      TasklyAgendaTaskRowModel(
        :final depth,
        :final model,
        :final intent,
        :final markers,
        :final actions,
        :final supportingText,
      ) =>
        Padding(
          padding: EdgeInsets.only(left: depth * 12.0),
          child: TaskEntityTile(
            model: model,
            intent: intent,
            markers: markers,
            actions: actions,
            supportingText: supportingText,
          ),
        ),
      TasklyAgendaProjectRowModel(
        :final depth,
        :final model,
        :final intent,
        :final actions,
      ) =>
        Padding(
          padding: EdgeInsets.only(left: depth * 12.0),
          child: ProjectEntityTile(
            model: model,
            intent: intent,
            actions: actions,
          ),
        ),
      _ => const SizedBox.shrink(),
    };
  }
}
