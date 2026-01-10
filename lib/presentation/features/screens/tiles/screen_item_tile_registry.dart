import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/models/screens/screen_item.dart';
import 'package:taskly_bloc/domain/models/screens/value_stats.dart' as domain;
import 'package:taskly_bloc/presentation/features/projects/widgets/project_list_tile.dart';
import 'package:taskly_bloc/presentation/features/tasks/widgets/task_list_tile.dart';
import 'package:taskly_bloc/presentation/features/values/widgets/enhanced_value_card.dart'
    as enhanced;

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
    Set<String> focusTaskIds = const {},
    Set<String> focusProjectIds = const {},
    void Function(String taskId, bool? value)? onTaskToggle,
    VoidCallback? onTap,
    ProjectTileStats? projectStats,
    domain.ValueStats? valueStats,
  }) {
    return switch (item) {
      ScreenItemTask(:final task) => TaskListTile(
        task: task,
        compact: compactTiles,
        isInFocus: focusTaskIds.contains(task.id),
        onCheckboxChanged: (t, val) => onTaskToggle?.call(t.id, val),
        onTap: onTap == null ? null : (_) => onTap(),
      ),
      ScreenItemProject(:final project) => ProjectListTile(
        project: project,
        compact: compactTiles,
        isInFocus: focusProjectIds.contains(project.id),
        taskCount: projectStats?.taskCount,
        completedTaskCount: projectStats?.completedTaskCount,
        onTap: onTap == null ? null : (_) => onTap(),
      ),
      ScreenItemValue(:final value) => enhanced.EnhancedValueCard.compact(
        value: value,
        stats: valueStats == null
            ? null
            : enhanced.ValueStats(
                targetPercent: valueStats.targetPercent,
                actualPercent: valueStats.actualPercent,
                taskCount: valueStats.taskCount,
                projectCount: valueStats.projectCount,
                weeklyTrend: valueStats.weeklyTrend,
                gapWarningThreshold: valueStats.gapWarningThreshold,
              ),
        onTap: onTap,
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
