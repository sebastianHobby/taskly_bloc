import 'package:flutter/material.dart';

import 'package:taskly_ui/src/primitives/pinned_gutter_marker.dart';
import 'package:taskly_ui/src/tiles/entity_meta_line.dart';
import 'package:taskly_ui/src/tiles/entity_tile_models.dart';

class ProjectListRowTile extends StatelessWidget {
  const ProjectListRowTile({
    required this.model,
    this.onTap,
    this.trailing,
    this.titlePrefix,
    this.statusBadge,
    super.key,
    this.compact = false,
  });

  final ProjectTileModel model;

  final VoidCallback? onTap;

  /// App-owned trailing widget (overflow/menu/actions).
  final Widget? trailing;

  final Widget? titlePrefix;
  final Widget? statusBadge;

  final bool compact;

  bool get _hasKnownProgress {
    final total = model.taskCount;
    final done = model.completedTaskCount;
    if (total == null || done == null) return false;
    return total > 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      key: Key('project-${model.id}'),
      decoration: BoxDecoration(
        color: model.completed
            ? scheme.surfaceContainerLowest.withValues(alpha: 0.5)
            : scheme.surface,
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: compact ? 10 : 12,
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
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Text(
                                model.title,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  decoration: model.completed
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: model.completed
                                      ? scheme.onSurface.withValues(alpha: 0.5)
                                      : scheme.onSurface,
                                ),
                                maxLines: compact ? 1 : 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (statusBadge != null) ...[
                              const SizedBox(width: 10),
                              statusBadge!,
                            ],
                          ],
                        ),
                        EntityMetaLine(model: model.meta),
                        if (model.taskCount == 0 &&
                            model.emptyTasksLabel != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            model.emptyTasksLabel!,
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
                        if (model.showTrailingProgressLabel)
                          _ProjectProgressLabel(
                            taskCount: model.taskCount,
                            completedTaskCount: model.completedTaskCount,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (model.pinned)
              Positioned(
                left: 0,
                top: compact ? 12 : 14,
                child: IgnorePointer(
                  child: PinnedGutterMarker(color: scheme.primary),
                ),
              ),
            if (_hasKnownProgress)
              Positioned(
                left: 16,
                right: 16,
                bottom: 0,
                child: _ProjectProgressBar(
                  projectName: model.title,
                  isOverdue: model.meta.isOverdue,
                  taskCount: model.taskCount!,
                  completedTaskCount: model.completedTaskCount!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProjectProgressLabel extends StatelessWidget {
  const _ProjectProgressLabel({
    required this.taskCount,
    required this.completedTaskCount,
  });

  final int? taskCount;
  final int? completedTaskCount;

  @override
  Widget build(BuildContext context) {
    final total = taskCount;
    final done = completedTaskCount;
    if (total == null || done == null || total <= 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        '$done/$total',
        style: theme.textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
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
