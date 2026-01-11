import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/models/screens/screen_item.dart';
import 'package:taskly_bloc/domain/models/screens/value_stats.dart' as domain;
import 'package:taskly_bloc/presentation/entity_views/project_view.dart';
import 'package:taskly_bloc/presentation/entity_views/task_view.dart';
import 'package:taskly_bloc/presentation/entity_views/value_view.dart';

/// Presentation helpers for rendering a [ScreenItem] as a tile.
///
/// This keeps list-based templates (task/project/value/agenda/interleaved) from
/// doing runtime casting.
class ScreenItemTileRegistry {
  const ScreenItemTileRegistry();

  Widget build(
    BuildContext context, {
    required ScreenItem item,
    bool compactTiles = false,
    void Function(String taskId, bool? value)? onTaskToggle,
    void Function(String projectId, bool? value)? onProjectToggle,
    VoidCallback? onTap,
    ProjectTileStats? projectStats,
    domain.ValueStats? valueStats,
  }) {
    return switch (item) {
      ScreenItemTask(:final task) => TaskView(
        task: task,
        compact: compactTiles,
        onCheckboxChanged: (t, val) => onTaskToggle?.call(t.id, val),
        onTap: onTap == null ? null : (_) => onTap(),
      ),
      ScreenItemProject(:final project) => ProjectView(
        project: project,
        compact: compactTiles,
        taskCount: projectStats?.taskCount,
        completedTaskCount: projectStats?.completedTaskCount,
        onCheckboxChanged: onProjectToggle == null
            ? null
            : (p, val) => onProjectToggle(p.id, val),
        onTap: onTap == null ? null : (_) => onTap(),
      ),
      ScreenItemValue(:final value) => ValueView(
        value: value,
        stats: valueStats,
        onTap: onTap,
        compact: true,
      ),
      ScreenItemHeader(:final title) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      ),
      ScreenItemDivider() => const Divider(height: 1),
    };
  }
}

class ProjectTileStats {
  const ProjectTileStats({
    required this.taskCount,
    required this.completedTaskCount,
  });

  final int taskCount;
  final int completedTaskCount;
}
