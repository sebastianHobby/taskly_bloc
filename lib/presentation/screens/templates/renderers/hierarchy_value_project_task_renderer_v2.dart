import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/templates/params/hierarchy_value_project_task_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/interleaved_list_section_params_v2.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/interleaved_list_renderer_v2.dart';

class HierarchyValueProjectTaskRendererV2 extends StatelessWidget {
  const HierarchyValueProjectTaskRendererV2({
    required this.data,
    required this.params,
    this.title,
    this.compactTiles = false,
    this.onTaskToggle,
    this.onTaskPinnedChanged,
    super.key,
    this.persistenceKey,
  });

  final HierarchyValueProjectTaskV2SectionResult data;
  final HierarchyValueProjectTaskSectionParamsV2 params;
  final String? title;
  final bool compactTiles;
  final void Function(String, bool?)? onTaskToggle;
  final Future<void> Function(String taskId, bool pinned)? onTaskPinnedChanged;
  final String? persistenceKey;

  InterleavedListSectionParamsV2 _toInterleavedParams() {
    return InterleavedListSectionParamsV2(
      sources: params.sources,
      pack: params.pack,
      enrichment: params.enrichment,
      filters: params.filters,
    );
  }

  @override
  Widget build(BuildContext context) {
    return InterleavedListRendererV2(
      items: data.items,
      enrichment: data.enrichment,
      params: _toInterleavedParams(),
      title: title,
      persistenceKey: persistenceKey,
      compactTiles: compactTiles,
      onTaskToggle: onTaskToggle,
      onTaskPinnedChanged: onTaskPinnedChanged,
      renderMode: InterleavedListRenderModeV2.hierarchyValueProjectTask,
      pinnedProjectHeaders: params.pinnedProjectHeaders,
      singleInboxGroupForNoProjectTasks:
          params.singleInboxGroupForNoProjectTasks,
    );
  }
}
