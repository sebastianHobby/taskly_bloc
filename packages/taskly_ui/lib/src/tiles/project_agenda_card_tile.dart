import 'package:flutter/material.dart';

import 'package:taskly_ui/src/tiles/entity_meta_line.dart';
import 'package:taskly_ui/src/tiles/entity_tile_models.dart';
import 'package:taskly_ui/src/tiles/_agenda_card_container.dart';

class ProjectAgendaCardTile extends StatelessWidget {
  const ProjectAgendaCardTile({
    required this.model,
    this.onTap,
    this.trailing,
    this.titlePrefix,
    this.statusBadge,
    super.key,
  });

  final ProjectAgendaCardModel model;

  final VoidCallback? onTap;

  /// App-owned trailing widget (overflow/menu/actions).
  final Widget? trailing;

  final Widget? titlePrefix;
  final Widget? statusBadge;

  bool get _hasKnownProgress {
    final total = model.base.taskCount;
    final done = model.base.completedTaskCount;
    if (total == null || done == null) return false;
    return total > 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final base = model.base;

    final outline = scheme.outlineVariant.withValues(alpha: 0.35);
    final backgroundColor = scheme.surfaceContainerLow;

    return Material(
      key: Key('project-${base.id}'),
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AgendaCardContainer(
          dashedOutline: model.inProgressStyle,
          accentColor: model.accentColor,
          outlineColor: outline,
          backgroundColor: backgroundColor,
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  model.inProgressStyle ? 28 : 14,
                  10,
                  14,
                  10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox.square(
                      dimension: 44,
                      child: Center(
                        child: Icon(
                          Icons.folder_outlined,
                          size: 22,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (titlePrefix != null) ...[
                                titlePrefix!,
                                const SizedBox(width: 10),
                              ],
                              Expanded(
                                child: Text(
                                  base.title,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    decoration: base.completed
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: base.completed
                                        ? scheme.onSurface.withValues(
                                            alpha: 0.5,
                                          )
                                        : scheme.onSurface,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (statusBadge != null) ...[
                                const SizedBox(width: 10),
                                statusBadge!,
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: EntityMetaLine(model: base.meta),
                              ),
                            ],
                          ),
                          if (base.taskCount == 0 &&
                              base.emptyTasksLabel != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              base.emptyTasksLabel!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 72,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ?trailing,
                        ],
                      ),
                    ),
                    if (model.inProgressStyle && model.endDayLabel != null) ...[
                      const SizedBox(width: 12),
                      EndDayMarker(label: model.endDayLabel!),
                    ],
                  ],
                ),
              ),
              if (_hasKnownProgress)
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 0,
                  child: _ProjectProgressBar(
                    projectName: base.title,
                    isOverdue: base.meta.isOverdue,
                    taskCount: base.taskCount!,
                    completedTaskCount: base.completedTaskCount!,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectProgressBar extends StatelessWidget {
  const _ProjectProgressBar({
    required this.projectName,
    required this.isOverdue,
    required this.taskCount,
    required this.completedTaskCount,
  });

  final String projectName;
  final bool isOverdue;
  final int taskCount;
  final int completedTaskCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final clampedTotal = taskCount <= 0 ? 1 : taskCount;
    final progress = (completedTaskCount / clampedTotal).clamp(0.0, 1.0);

    final fill = isOverdue ? scheme.error : scheme.primary;
    final track = scheme.outlineVariant.withValues(alpha: 0.35);

    return Semantics(
      label: 'Project progress for $projectName',
      value: '$completedTaskCount of $taskCount',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 2,
          backgroundColor: track,
          valueColor: AlwaysStoppedAnimation<Color>(fill),
        ),
      ),
    );
  }
}
