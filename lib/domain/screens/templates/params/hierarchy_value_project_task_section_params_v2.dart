import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/screens/language/models/data_config.dart';
import 'package:taskly_bloc/domain/screens/templates/params/entity_style_v1.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';

part 'hierarchy_value_project_task_section_params_v2.freezed.dart';
part 'hierarchy_value_project_task_section_params_v2.g.dart';

/// Params for the dedicated Value → Project → Task hierarchy section.
///
/// This template is intentionally specialized (unlike `interleaved_list_v2`) so
/// screens can opt into the hierarchy UX without configuring a generic layout
/// mode.
@freezed
abstract class HierarchyValueProjectTaskSectionParamsV2
    with _$HierarchyValueProjectTaskSectionParamsV2 {
  @JsonSerializable(disallowUnrecognizedKeys: true)
  const factory HierarchyValueProjectTaskSectionParamsV2({
    /// Data sources. Typically one or more task queries.
    required List<DataConfig> sources,

    /// Optional per-module override for entity tile styling.
    EntityStyleOverrideV1? entityStyleOverride,

    /// Controls whether Value headers are pinned (sticky).
    @Default(true) bool pinnedValueHeaders,

    /// Controls whether Project headers are pinned (sticky).
    @Default(false) bool pinnedProjectHeaders,

    /// When true, tasks with no project are rendered in a single global Inbox
    /// group instead of being shown under each Value group.
    @Default(false) bool singleInboxGroupForNoProjectTasks,

    @Default(EnrichmentPlanV2()) EnrichmentPlanV2 enrichment,

    /// Optional presentation-only filter controls.
    SectionFilterSpecV2? filters,
  }) = _HierarchyValueProjectTaskSectionParamsV2;

  factory HierarchyValueProjectTaskSectionParamsV2.fromJson(
    Map<String, dynamic> json,
  ) => _$HierarchyValueProjectTaskSectionParamsV2FromJson(json);
}
