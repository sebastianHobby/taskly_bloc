import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/analytics/model/entity_type.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_item.dart';
import 'package:taskly_bloc/domain/screens/language/models/value_stats.dart'
    as domain;
import 'package:taskly_bloc/domain/screens/templates/params/entity_style_v1.dart';
import 'package:taskly_bloc/domain/screens/templates/params/entity_tile_capabilities.dart';
import 'package:taskly_bloc/domain/screens/templates/params/screen_item_tile_variants.dart';
import 'package:taskly_bloc/presentation/entity_views/project_view.dart';
import 'package:taskly_bloc/presentation/entity_views/task_view.dart';
import 'package:taskly_bloc/presentation/entity_views/value_view.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';

/// Presentation helpers for rendering a [ScreenItem] as a tile.
///
/// Centralizes tile construction so that USM renderers do not instantiate
/// `TaskView`/`ProjectView`/`ValueView` directly.
class ScreenItemTileBuilder {
  const ScreenItemTileBuilder();

  bool _isCompact(EntityStyleV1 style) {
    return style.density == EntityDensityV1.compact;
  }

  TaskViewVariant _taskVariant(EntityStyleV1 style) {
    return switch (style.taskVariant) {
      TaskTileVariant.listTile => TaskViewVariant.list,
      TaskTileVariant.agenda => TaskViewVariant.agendaCard,
    };
  }

  ProjectViewVariant _projectVariant(EntityStyleV1 style) {
    return switch (style.projectVariant) {
      ProjectTileVariant.listTile => ProjectViewVariant.list,
      ProjectTileVariant.agenda => ProjectViewVariant.agendaCard,
    };
  }

  ValueViewVariant _valueVariant(EntityStyleV1 style) {
    return switch (style.valueVariant) {
      ValueTileVariant.compactCard => ValueViewVariant.myValuesCardV1,
    };
  }

  Widget build(
    BuildContext context, {
    required ScreenItem item,
    required EntityStyleV1 entityStyle,
    bool isInFocus = false,
    VoidCallback? onTap,
    ProjectTileStats? projectStats,
    domain.ValueStats? valueStats,
    Widget? titlePrefix,
    Widget? statusBadge,
    Widget? taskTrailing,
    Widget? projectTrailing,
    bool showProjectTrailingProgressLabel = false,
    Color? accentColor,
    bool agendaInProgressStyle = false,
    DateTime? endDate,
  }) {
    return switch (item) {
      ScreenItemTask(:final task, :final tileCapabilities) => TaskView(
        task: task,
        tileCapabilities: tileCapabilities ?? const EntityTileCapabilities(),
        isInFocus: isInFocus,
        compact: _isCompact(entityStyle),
        variant: _taskVariant(entityStyle),
        onTap: onTap == null ? null : (_) => onTap(),
        titlePrefix: titlePrefix,
        statusBadge: statusBadge,
        trailing: taskTrailing,
        accentColor: accentColor,
        agendaInProgressStyle: agendaInProgressStyle,
        endDate: endDate,
      ),
      ScreenItemProject(:final project, :final tileCapabilities) => ProjectView(
        project: project,
        tileCapabilities: tileCapabilities ?? const EntityTileCapabilities(),
        compact: _isCompact(entityStyle),
        variant: _projectVariant(entityStyle),
        taskCount: projectStats?.taskCount ?? project.taskCount,
        completedTaskCount:
            projectStats?.completedTaskCount ?? project.completedTaskCount,
        onTap: onTap == null ? null : (_) => onTap(),
        titlePrefix: titlePrefix,
        statusBadge: statusBadge,
        trailing: projectTrailing,
        showTrailingProgressLabel: showProjectTrailingProgressLabel,
        accentColor: accentColor,
        agendaInProgressStyle: agendaInProgressStyle,
        endDate: endDate,
      ),
      ScreenItemValue(:final value) => ValueView(
        value: value,
        stats: valueStats,
        onTap:
            onTap ??
            () => Routing.toEntity(context, EntityType.value, value.id),
        compact: _isCompact(entityStyle),
        titlePrefix: titlePrefix,
        variant: _valueVariant(entityStyle),
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
