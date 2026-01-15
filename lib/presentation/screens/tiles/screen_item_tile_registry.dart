import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_item.dart';
import 'package:taskly_bloc/domain/screens/language/models/value_stats.dart'
    as domain;
import 'package:taskly_bloc/domain/analytics/model/entity_type.dart';
import 'package:taskly_bloc/presentation/entity_views/project_view.dart';
import 'package:taskly_bloc/presentation/entity_views/task_view.dart';
import 'package:taskly_bloc/presentation/entity_views/value_view.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';

/// Presentation helpers for rendering a [ScreenItem] as a tile.
///
/// This keeps list-based templates (task/project/value/agenda/interleaved) from
/// doing runtime casting.
class ScreenItemTileRegistry {
  const ScreenItemTileRegistry();

  Widget build(
    BuildContext context, {
    required ScreenItem item,
    bool isInFocus = false,
    bool compactTiles = false,
    void Function(String taskId, bool? value)? onTaskToggle,
    VoidCallback? onTap,
    ProjectTileStats? projectStats,
    domain.ValueStats? valueStats,
    Widget? titlePrefix,
    Widget? projectTrailing,
    bool showProjectTrailingProgressLabel = false,
    ScreenItemGroupingContext? groupingContext,
    bool suppressValueChipsWhenValueImplied = false,
  }) {
    final effectiveProjectId = groupingContext?.projectId?.trim();
    final effectiveValueId = groupingContext?.valueId?.trim();
    final projectIsImplied =
        effectiveProjectId != null && effectiveProjectId.isNotEmpty;
    final valueIsImplied =
        effectiveValueId != null && effectiveValueId.isNotEmpty;

    final showValueChips =
        !(valueIsImplied && suppressValueChipsWhenValueImplied);
    final maxSecondaryValueChips = valueIsImplied
        ? (showValueChips ? 2 : 0)
        : 1;

    return switch (item) {
      ScreenItemTask(:final task) => TaskView(
        task: task,
        isInFocus: isInFocus,
        compact: compactTiles,
        onCheckboxChanged: (t, val) => onTaskToggle?.call(t.id, val),
        onTap: onTap == null ? null : (_) => onTap(),
        titlePrefix: titlePrefix,
        showProjectNameInMeta: true,
        projectNameIsTertiary: projectIsImplied,
        groupedValueId: valueIsImplied ? effectiveValueId : null,
        showPrimaryValueChip: showValueChips,
        maxSecondaryValueChips: maxSecondaryValueChips,
        excludeValueIdFromChips: valueIsImplied ? effectiveValueId : null,
      ),
      ScreenItemProject(:final project) => ProjectView(
        project: project,
        compact: compactTiles,
        taskCount: projectStats?.taskCount ?? project.taskCount,
        completedTaskCount:
            projectStats?.completedTaskCount ?? project.completedTaskCount,
        onTap: onTap == null ? null : (_) => onTap(),
        titlePrefix: titlePrefix,
        trailing: projectTrailing,
        showTrailingProgressLabel: showProjectTrailingProgressLabel,
        groupedValueId: valueIsImplied ? effectiveValueId : null,
        showPrimaryValueChip: showValueChips,
        maxSecondaryValueChips: maxSecondaryValueChips,
        excludeValueIdFromChips: valueIsImplied ? effectiveValueId : null,
      ),
      ScreenItemValue(:final value) => ValueView(
        value: value,
        stats: valueStats,
        onTap:
            onTap ??
            () => Routing.toEntity(context, EntityType.value, value.id),
        compact: compactTiles,
        titlePrefix: titlePrefix,
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

/// Context passed by grouped list renderers to avoid repeating implied metadata.
///
/// Example:
/// - If tasks are rendered under a project header, set [projectId] so task tiles
///   don't repeat the project name.
/// - If tasks are rendered under a value header, set [valueId] so task tiles
///   don't repeat the value chip.
@immutable
class ScreenItemGroupingContext {
  const ScreenItemGroupingContext({
    this.valueId,
    this.projectId,
  });

  final String? valueId;
  final String? projectId;
}
