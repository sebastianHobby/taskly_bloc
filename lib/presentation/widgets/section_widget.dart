import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/allocation/model/focus_mode.dart';
import 'package:taskly_bloc/domain/core/model/task.dart';
import 'package:taskly_bloc/domain/core/model/project.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/screens/language/models/display_config.dart';
import 'package:taskly_bloc/domain/screens/templates/params/agenda_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/attention_inbox_section_params_v1.dart';
import 'package:taskly_bloc/domain/screens/templates/params/hierarchy_value_project_task_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/interleaved_list_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/style_pack_v2.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_vm.dart';

import 'package:taskly_bloc/presentation/screens/templates/renderers/attention_banner_section_renderer_v2.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/attention_inbox_section_renderer_v1.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/agenda_section_renderer.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/entity_header_section_renderer.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/hierarchy_value_project_task_renderer_v2.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/interleaved_list_renderer_v2.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/task_list_renderer_v2.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/value_list_renderer_v2.dart';

/// Widget that renders a section from interpreted screen data.
///
/// Handles different section types (data, allocation, agenda) and
/// displays appropriate UI for each.
class SectionWidget extends StatelessWidget {
  /// Creates a SectionWidget.
  const SectionWidget({
    required this.section,
    super.key,
    this.persistenceKey,
    this.displayConfig,
    this.focusMode,
    this.onEntityTap,
    this.onEntityHeaderTap,
    this.onTaskComplete,
    this.onTaskCheckboxChanged,
    this.onTaskPinnedChanged,
    this.onProjectCheckboxChanged,
    this.onTaskDelete,
    this.onProjectDelete,
  });

  /// The section data to render
  final SectionVm section;

  /// Stable key for persisting presentation-only UI state (e.g. via PageStorage).
  ///
  /// This is derived in the unified screen rendering path and should be stable
  /// for a given screen + section instance.
  final String? persistenceKey;

  /// Optional display configuration override
  final DisplayConfig? displayConfig;

  /// Current focus mode (for allocation sections)
  final FocusMode? focusMode;

  /// Callback when an entity is tapped
  final void Function(dynamic entity)? onEntityTap;

  /// Callback when the entity header module is tapped.
  ///
  /// This is separate from [onEntityTap] so detail pages can open editors from
  /// the header while list items still navigate to their routes.
  final VoidCallback? onEntityHeaderTap;

  /// Callback when a task is completed.
  final void Function(Task task)? onTaskComplete;

  /// Callback when a task checkbox is changed
  final void Function(Task task, bool? value)? onTaskCheckboxChanged;

  /// Callback when a task is pinned/unpinned for allocation (My Day).
  final Future<void> Function(Task task, bool pinned)? onTaskPinnedChanged;

  /// Callback when a project checkbox is changed
  final void Function(Project project, bool? value)? onProjectCheckboxChanged;

  /// Callback when a task is deleted
  final void Function(Task task)? onTaskDelete;

  /// Callback when a project is deleted
  final void Function(Project project)? onProjectDelete;

  @override
  Widget build(BuildContext context) {
    if (section.templateId == SectionTemplateId.statisticsDashboard) {
      return const SliverPadding(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        sliver: SliverToBoxAdapter(
          child: Text('Statistics dashboard not implemented yet.'),
        ),
      );
    }

    if (section.isLoading) {
      return const SliverPadding(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        sliver: SliverToBoxAdapter(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (section.error case final error?) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        sliver: SliverToBoxAdapter(child: Text('Section error: $error')),
      );
    }

    final result = section.data;

    final sliver = switch (result) {
      AttentionBannerV2SectionResult()
          when section.templateId == SectionTemplateId.attentionBannerV2 =>
        SliverToBoxAdapter(
          child: AttentionBannerSectionRendererV2(
            data: result as SectionDataResult,
            title: section.title,
          ),
        ),
      EntityHeaderProjectSectionResult() ||
      EntityHeaderValueSectionResult() ||
      EntityHeaderMissingSectionResult()
          when section.templateId == SectionTemplateId.entityHeader =>
        SliverToBoxAdapter(
          child: EntityHeaderSectionRenderer(
            data: result! as SectionDataResult,
            onTap: onEntityHeaderTap,
            onProjectCheckboxChanged: (val) {
              if (result is EntityHeaderProjectSectionResult) {
                onProjectCheckboxChanged?.call(result.project, val);
              }
            },
          ),
        ),
      _ when section.templateId == SectionTemplateId.attentionInboxV1 =>
        SliverFillRemaining(
          hasScrollBody: true,
          child: AttentionInboxSectionRendererV1(
            params: section.params as AttentionInboxSectionParamsV1,
          ),
        ),
      final DataSectionResult d => SliverToBoxAdapter(
        child: _buildUnsupportedSection(d),
      ),
      final DataV2SectionResult d => switch (section.templateId) {
        SectionTemplateId.taskListV2 => TaskListRendererV2(
          data: d,
          params: section.params as ListSectionParamsV2,
          title: section.title,
          compactTiles:
              (section.params as ListSectionParamsV2).pack ==
              StylePackV2.compact,
          onTaskToggle: (taskId, val) {
            final task = d.allTasks.firstWhere((t) => t.id == taskId);
            onTaskCheckboxChanged?.call(task, val);
          },
        ),
        SectionTemplateId.valueListV2 => ValueListRendererV2(
          data: d,
          params: section.params as ListSectionParamsV2,
          title: section.title,
          compactTiles:
              (section.params as ListSectionParamsV2).pack ==
              StylePackV2.compact,
        ),
        SectionTemplateId.interleavedListV2 => InterleavedListRendererV2(
          data: d,
          params: section.params as InterleavedListSectionParamsV2,
          title: section.title,
          persistenceKey: persistenceKey,
          compactTiles:
              (section.params as InterleavedListSectionParamsV2).pack ==
              StylePackV2.compact,
          onTaskToggle: (taskId, val) {
            final task = d.allTasks.firstWhere((t) => t.id == taskId);
            onTaskCheckboxChanged?.call(task, val);
          },
          onTaskPinnedChanged: onTaskPinnedChanged == null
              ? null
              : (taskId, pinned) async {
                  final task = d.allTasks.firstWhere((t) => t.id == taskId);
                  await onTaskPinnedChanged!.call(task, pinned);
                },
        ),
        SectionTemplateId.hierarchyValueProjectTaskV2 =>
          HierarchyValueProjectTaskRendererV2(
            data: d,
            params: section.params as HierarchyValueProjectTaskSectionParamsV2,
            title: section.title,
            persistenceKey: persistenceKey,
            compactTiles:
                (section.params as HierarchyValueProjectTaskSectionParamsV2)
                    .pack ==
                StylePackV2.compact,
            onTaskToggle: (taskId, val) {
              final task = d.allTasks.firstWhere((t) => t.id == taskId);
              onTaskCheckboxChanged?.call(task, val);
            },
            onTaskPinnedChanged: onTaskPinnedChanged == null
                ? null
                : (taskId, pinned) async {
                    final task = d.allTasks.firstWhere((t) => t.id == taskId);
                    await onTaskPinnedChanged!.call(task, pinned);
                  },
          ),
        _ => SliverToBoxAdapter(child: _buildUnsupportedSection(d)),
      },
      final AgendaSectionResult d
          when section.templateId == SectionTemplateId.agendaV2 =>
        SliverFillRemaining(
          hasScrollBody: true,
          child: AgendaSectionRenderer(
            data: d,
            showTagPills: (section.params as AgendaSectionParamsV2)
                .enrichment
                .items
                .any(
                  (i) => i.maybeWhen(
                    agendaTags: (_) => true,
                    orElse: () => false,
                  ),
                ),
            onTaskToggle: (taskId, val) {
              final task = d.agendaData.groups
                  .expand((g) => g.items)
                  .where((item) => item.isTask && item.task?.id == taskId)
                  .map((item) => item.task)
                  .whereType<Task>()
                  .first;
              onTaskCheckboxChanged?.call(task, val);
            },
            onTaskTap: (task) => onEntityTap?.call(task),
          ),
        ),
      _ => SliverToBoxAdapter(child: _buildUnknownSection()),
    };

    return SliverPadding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      sliver: sliver,
    );
  }

  Widget _buildUnsupportedSection(SectionDataResult result) {
    return Text('Unsupported section type: ${result.runtimeType}');
  }

  Widget _buildUnknownSection() {
    return Text('Unsupported section data: ${section.templateId}');
  }
}
