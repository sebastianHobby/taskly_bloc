import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/allocation/model/focus_mode.dart';
import 'package:taskly_bloc/domain/core/model/task.dart';
import 'package:taskly_bloc/domain/core/model/project.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/screens/language/models/display_config.dart';
import 'package:taskly_bloc/domain/screens/templates/params/agenda_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/hierarchy_value_project_task_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/interleaved_list_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/style_pack_v2.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_vm.dart';

import 'package:taskly_bloc/presentation/screens/templates/renderers/allocation_section_renderer.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/allocation_alerts_section_renderer.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/agenda_section_renderer.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/check_in_summary_section_renderer.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/entity_header_section_renderer.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/issues_summary_section_renderer.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/hierarchy_value_project_task_renderer_v2.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/interleaved_list_renderer_v2.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/project_list_renderer_v2.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/task_list_renderer_v2.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/value_list_renderer_v2.dart';

/// Widget that renders a section from ScreenBloc state.
///
/// Handles different section types (data, allocation, agenda) and
/// displays appropriate UI for each.
class SectionWidget extends StatelessWidget {
  /// Creates a SectionWidget.
  const SectionWidget({
    required this.section,
    super.key,
    this.displayConfig,
    this.focusMode,
    this.onEntityTap,
    this.onTaskComplete,
    this.onTaskCheckboxChanged,
    this.onProjectCheckboxChanged,
    this.onTaskDelete,
    this.onProjectDelete,
  });

  /// The section data to render
  final SectionVm section;

  /// Optional display configuration override
  final DisplayConfig? displayConfig;

  /// Current focus mode (for allocation sections)
  final FocusMode? focusMode;

  /// Callback when an entity is tapped
  final void Function(dynamic entity)? onEntityTap;

  /// Callback when a task is completed.
  final void Function(Task task)? onTaskComplete;

  /// Callback when a task checkbox is changed
  final void Function(Task task, bool? value)? onTaskCheckboxChanged;

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
      final IssuesSummarySectionResult d
          when section.templateId == SectionTemplateId.issuesSummary =>
        SliverToBoxAdapter(
          child: IssuesSummarySectionRenderer(data: d, title: section.title),
        ),
      final CheckInSummarySectionResult d
          when section.templateId == SectionTemplateId.checkInSummary =>
        SliverToBoxAdapter(
          child: CheckInSummarySectionRenderer(data: d, title: section.title),
        ),
      final AllocationAlertsSectionResult d
          when section.templateId == SectionTemplateId.allocationAlerts =>
        SliverToBoxAdapter(
          child: AllocationAlertsSectionRenderer(data: d, title: section.title),
        ),
      EntityHeaderProjectSectionResult() ||
      EntityHeaderValueSectionResult() ||
      EntityHeaderMissingSectionResult()
          when section.templateId == SectionTemplateId.entityHeader =>
        SliverToBoxAdapter(
          child: EntityHeaderSectionRenderer(
            data: result! as SectionDataResult,
            onProjectCheckboxChanged: (val) {
              if (result is EntityHeaderProjectSectionResult) {
                onProjectCheckboxChanged?.call(result.project, val);
              }
            },
          ),
        ),
      final AllocationSectionResult d
          when section.templateId == SectionTemplateId.allocation =>
        AllocationSectionRenderer(
          data: d,
          onTaskToggle: (taskId, val) {
            final task = d.allocatedTasks.firstWhere((t) => t.id == taskId);
            onTaskCheckboxChanged?.call(task, val);
          },
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
        SectionTemplateId.projectListV2 => ProjectListRendererV2(
          data: d,
          params: section.params as ListSectionParamsV2,
          title: section.title,
          compactTiles:
              (section.params as ListSectionParamsV2).pack ==
              StylePackV2.compact,
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
          compactTiles:
              (section.params as InterleavedListSectionParamsV2).pack ==
              StylePackV2.compact,
          onTaskToggle: (taskId, val) {
            final task = d.allTasks.firstWhere((t) => t.id == taskId);
            onTaskCheckboxChanged?.call(task, val);
          },
        ),
        SectionTemplateId.hierarchyValueProjectTaskV2 =>
          HierarchyValueProjectTaskRendererV2(
            data: d,
            params: section.params as HierarchyValueProjectTaskSectionParamsV2,
            title: section.title,
            compactTiles:
                (section.params as HierarchyValueProjectTaskSectionParamsV2)
                    .pack ==
                StylePackV2.compact,
            onTaskToggle: (taskId, val) {
              final task = d.allTasks.firstWhere((t) => t.id == taskId);
              onTaskCheckboxChanged?.call(task, val);
            },
          ),
        _ => SliverToBoxAdapter(child: _buildUnsupportedSection(d)),
      },
      final AgendaSectionResult d
          when section.templateId == SectionTemplateId.agendaV2 =>
        SliverToBoxAdapter(
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
