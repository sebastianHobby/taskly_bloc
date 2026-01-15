import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/allocation/model/focus_mode.dart';
import 'package:taskly_bloc/domain/core/model/project.dart';
import 'package:taskly_bloc/domain/core/model/task.dart';
import 'package:taskly_bloc/domain/screens/language/models/display_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_vm.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/style_pack_v2.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/agenda_section_renderer.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/attention_banner_section_renderer_v2.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/attention_inbox_section_renderer_v1.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/create_value_cta_section_renderer_v1.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/entity_header_section_renderer.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/hierarchy_value_project_task_renderer_v2.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/interleaved_list_renderer_v2.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/my_day_ranked_tasks_v1_section.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/task_list_renderer_v2.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/value_list_renderer_v2.dart';

/// Registry that renders a [SectionVm] into a sliver widget.
///
/// This centralizes the template-id/type switching so [SectionWidget] can stay
/// small and stable.
abstract interface class SectionRendererRegistry {
  /// Builds the sliver for a resolved section.
  Widget buildSection({
    required SectionVm section,
    required String? persistenceKey,
    required DisplayConfig? displayConfig,
    required FocusMode? focusMode,
    required void Function(dynamic entity)? onEntityTap,
    required VoidCallback? onEntityHeaderTap,
    required void Function(Task task)? onTaskComplete,
    required void Function(Task task, bool? value)? onTaskCheckboxChanged,
    required Future<void> Function(Task task, bool pinned)? onTaskPinnedChanged,
    required void Function(Project project, bool? value)?
    onProjectCheckboxChanged,
    required void Function(Task task)? onTaskDelete,
    required void Function(Project project)? onProjectDelete,
  });
}

/// Default renderer registry for the typed unified screen pipeline.
final class DefaultSectionRendererRegistry implements SectionRendererRegistry {
  const DefaultSectionRendererRegistry();

  @override
  Widget buildSection({
    required SectionVm section,
    required String? persistenceKey,
    required DisplayConfig? displayConfig,
    required FocusMode? focusMode,
    required void Function(dynamic entity)? onEntityTap,
    required VoidCallback? onEntityHeaderTap,
    required void Function(Task task)? onTaskComplete,
    required void Function(Task task, bool? value)? onTaskCheckboxChanged,
    required Future<void> Function(Task task, bool pinned)? onTaskPinnedChanged,
    required void Function(Project project, bool? value)?
    onProjectCheckboxChanged,
    required void Function(Task task)? onTaskDelete,
    required void Function(Project project)? onProjectDelete,
  }) {
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

    final sliver = section.map(
      taskListV2: (s) {
        if (result case final DataV2SectionResult d) {
          return TaskListRendererV2(
            data: d,
            params: s.params,
            title: s.title,
            compactTiles: s.params.pack == StylePackV2.compact,
            onTaskToggle: (taskId, val) {
              final task = d.allTasks.firstWhere((t) => t.id == taskId);
              onTaskCheckboxChanged?.call(task, val);
            },
          );
        }

        return SliverToBoxAdapter(child: _buildUnknownSection(section));
      },
      valueListV2: (s) {
        if (result case final DataV2SectionResult d) {
          return ValueListRendererV2(
            data: d,
            params: s.params,
            title: s.title,
            compactTiles: s.params.pack == StylePackV2.compact,
            persistenceKey: persistenceKey,
            enableSegmentedTabs:
                persistenceKey != null && persistenceKey.startsWith('values:'),
          );
        }

        return SliverToBoxAdapter(child: _buildUnknownSection(section));
      },
      interleavedListV2: (s) {
        if (result case final DataV2SectionResult d) {
          return InterleavedListRendererV2(
            items: d.items,
            enrichment: d.enrichment,
            params: s.params,
            title: s.title,
            persistenceKey: persistenceKey,
            compactTiles: s.params.pack == StylePackV2.compact,
            onTaskToggle: (taskId, val) {
              final task = d.allTasks.firstWhere((t) => t.id == taskId);
              onTaskCheckboxChanged?.call(task, val);
            },
            onTaskPinnedChanged: onTaskPinnedChanged == null
                ? null
                : (taskId, pinned) async {
                    final task = d.allTasks.firstWhere((t) => t.id == taskId);
                    await onTaskPinnedChanged.call(task, pinned);
                  },
          );
        }

        return SliverToBoxAdapter(child: _buildUnknownSection(section));
      },
      hierarchyValueProjectTaskV2: (s) {
        if (result case final HierarchyValueProjectTaskV2SectionResult d) {
          return HierarchyValueProjectTaskRendererV2(
            data: d,
            params: s.params,
            title: s.title,
            persistenceKey: persistenceKey,
            compactTiles: s.params.pack == StylePackV2.compact,
            onTaskToggle: (taskId, val) {
              final task = d.allTasks.firstWhere((t) => t.id == taskId);
              onTaskCheckboxChanged?.call(task, val);
            },
            onTaskPinnedChanged: onTaskPinnedChanged == null
                ? null
                : (taskId, pinned) async {
                    final task = d.allTasks.firstWhere((t) => t.id == taskId);
                    await onTaskPinnedChanged.call(task, pinned);
                  },
          );
        }

        return SliverToBoxAdapter(child: _buildUnknownSection(section));
      },
      agendaV2: (s) {
        if (result case final AgendaSectionResult d) {
          return SliverFillRemaining(
            hasScrollBody: true,
            child: AgendaSectionRenderer(
              params: s.params,
              data: d,
              showTagPills: s.params.enrichment.items.any(
                (i) => i.maybeMap(
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
          );
        }

        return SliverToBoxAdapter(child: _buildUnknownSection(section));
      },
      attentionBannerV2: (s) {
        if (result case final AttentionBannerV2SectionResult d) {
          return SliverToBoxAdapter(
            child: AttentionBannerSectionRendererV2(
              data: d,
              title: s.title,
            ),
          );
        }

        return SliverToBoxAdapter(child: _buildUnknownSection(section));
      },
      attentionInboxV1: (s) {
        return SliverFillRemaining(
          hasScrollBody: true,
          child: AttentionInboxSectionRendererV1(
            params: s.params,
          ),
        );
      },
      entityHeader: (s) {
        if (result is EntityHeaderProjectSectionResult ||
            result is EntityHeaderValueSectionResult ||
            result is EntityHeaderMissingSectionResult) {
          return SliverToBoxAdapter(
            child: EntityHeaderSectionRenderer(
              data: result!,
              onTap: onEntityHeaderTap,
              onProjectCheckboxChanged: (val) {
                if (result is EntityHeaderProjectSectionResult) {
                  onProjectCheckboxChanged?.call(result.project, val);
                }
              },
            ),
          );
        }

        return SliverToBoxAdapter(child: _buildUnknownSection(section));
      },
      myDayRankedTasksV1: (s) {
        if (result case final HierarchyValueProjectTaskV2SectionResult d) {
          return MyDayRankedTasksV1Section(
            data: d.items,
            title: s.title,
            enrichment: d.enrichment,
            onTaskCheckboxChanged: onTaskCheckboxChanged,
          );
        }

        return SliverToBoxAdapter(child: _buildUnknownSection(section));
      },
      createValueCtaV1: (s) {
        return SliverToBoxAdapter(
          child: CreateValueCtaSectionRendererV1(
            title: s.title ?? 'Create New Value',
          ),
        );
      },
      unknown: (_) => SliverToBoxAdapter(child: _buildUnknownSection(section)),
    );

    return SliverPadding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      sliver: sliver,
    );
  }

  Widget _buildUnknownSection(SectionVm section) {
    return Text('Unsupported section data: ${section.templateId}');
  }
}
