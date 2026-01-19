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

class _ScheduleAccentRail extends StatelessWidget {
  const _ScheduleAccentRail({required this.state, required this.colorScheme});

  final BadgeKind state;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final Color baseColor = switch (state) {
      BadgeKind.starts => colorScheme.primary,
      BadgeKind.ongoing => colorScheme.onSurfaceVariant,
      BadgeKind.due => colorScheme.error,
      BadgeKind.pinned => colorScheme.primary,
    };

    final double railOpacity = switch (state) {
      BadgeKind.starts => 0.85,
      BadgeKind.ongoing => 0.55,
      BadgeKind.due => 0.85,
      BadgeKind.pinned => 0.85,
    };

    return SizedBox(
      width: 4,
      child: _Rail(
        state: state,
        color: baseColor.withValues(alpha: railOpacity),
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.state, required this.color});

  final BadgeKind state;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      BadgeKind.starts => _DashedRail(color: color),
      BadgeKind.ongoing => _SolidRail(color: color),
      BadgeKind.due => _NotchedRail(color: color),
      BadgeKind.pinned => _SolidRail(color: color),
    };
  }
}

class _SolidRail extends StatelessWidget {
  const _SolidRail({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(width: 2, color: color),
    );
  }
}

class _NotchedRail extends StatelessWidget {
  const _NotchedRail({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _SolidRail(color: color),
        Positioned(
          left: 0,
          top: 0,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
      ],
    );
  }
}

class _DashedRail extends StatelessWidget {
  const _DashedRail({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double segmentHeight = 5;
        const double gap = 4;
        final double unit = segmentHeight + gap;
        final int count = (constraints.maxHeight / unit).floor().clamp(1, 999);

        return Align(
          alignment: Alignment.centerLeft,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (int i = 0; i < count; i++)
                Container(
                  width: 2,
                  height: segmentHeight,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        );
      },
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

        '$done/$total',
