import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/templates/params/entity_style_v1.dart';
import 'package:taskly_bloc/domain/screens/templates/params/hierarchy_value_project_task_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/interleaved_list_section_params_v2.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/interleaved_list_renderer_v2.dart';

class HierarchyValueProjectTaskRendererV2 extends StatelessWidget {
  const HierarchyValueProjectTaskRendererV2({
    required this.data,
    required this.params,
    required this.entityStyle,
    this.title,
    super.key,
    this.persistenceKey,
  });

  final HierarchyValueProjectTaskV2SectionResult data;
  final HierarchyValueProjectTaskSectionParamsV2 params;
  final EntityStyleV1 entityStyle;
  final String? title;
  final String? persistenceKey;

  InterleavedListSectionParamsV2 _toInterleavedParams() {
    return InterleavedListSectionParamsV2(
      sources: params.sources,
      entityStyleOverride: params.entityStyleOverride,
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
      entityStyle: entityStyle,
      title: title,
      persistenceKey: persistenceKey,
      renderMode: InterleavedListRenderModeV2.hierarchyValueProjectTask,
      pinnedProjectHeaders: params.pinnedProjectHeaders,
      singleInboxGroupForNoProjectTasks:
          params.singleInboxGroupForNoProjectTasks,
    );
  }
}
