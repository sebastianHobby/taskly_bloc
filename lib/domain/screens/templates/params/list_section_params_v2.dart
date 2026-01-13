import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/screens/language/models/data_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/value_stats.dart';
import 'package:taskly_bloc/domain/screens/templates/params/screen_item_tile_variants.dart';

part 'list_section_params_v2.freezed.dart';
part 'list_section_params_v2.g.dart';

/// Date field used to derive agenda tags.
///
/// Kept in V2 params so `TaskTileVariant.agenda` can be used outside `agenda_v2`.
enum AgendaDateFieldV2 {
  @JsonValue('deadline_date')
  deadlineDate,

  @JsonValue('start_date')
  startDate,

  @JsonValue('scheduled_for')
  scheduledFor,
}

/// A typed agenda tag that can be rendered as a small pill.
enum AgendaTagV2 {
  @JsonValue('starts')
  starts,

  @JsonValue('due')
  due,

  @JsonValue('in_progress')
  inProgress,
}

@freezed
abstract class TilePolicyV2 with _$TilePolicyV2 {
  @JsonSerializable(disallowUnrecognizedKeys: true)
  const factory TilePolicyV2({
    required TaskTileVariant task,
    required ProjectTileVariant project,
    required ValueTileVariant value,
  }) = _TilePolicyV2;

  factory TilePolicyV2.fromJson(Map<String, dynamic> json) =>
      _$TilePolicyV2FromJson(json);
}

@Freezed(unionKey: 'type')
sealed class EnrichmentPlanItemV2 with _$EnrichmentPlanItemV2 {
  @FreezedUnionValue('value_stats')
  @JsonSerializable(disallowUnrecognizedKeys: true)
  const factory EnrichmentPlanItemV2.valueStats() = _ValueStatsItemV2;

  @FreezedUnionValue('open_task_counts')
  @JsonSerializable(disallowUnrecognizedKeys: true)
  const factory EnrichmentPlanItemV2.openTaskCounts() = _OpenTaskCountsItemV2;

  @FreezedUnionValue('agenda_tags')
  @JsonSerializable(disallowUnrecognizedKeys: true)
  const factory EnrichmentPlanItemV2.agendaTags({
    required AgendaDateFieldV2 dateField,
  }) = _AgendaTagsItemV2;

  factory EnrichmentPlanItemV2.fromJson(Map<String, dynamic> json) =>
      _$EnrichmentPlanItemV2FromJson(json);
}

@freezed
abstract class EnrichmentPlanV2 with _$EnrichmentPlanV2 {
  @JsonSerializable(disallowUnrecognizedKeys: true)
  const factory EnrichmentPlanV2({
    @Default(<EnrichmentPlanItemV2>[]) List<EnrichmentPlanItemV2> items,
  }) = _EnrichmentPlanV2;

  factory EnrichmentPlanV2.fromJson(Map<String, dynamic> json) =>
      _$EnrichmentPlanV2FromJson(json);
}

@freezed
abstract class OpenTaskCountsV2 with _$OpenTaskCountsV2 {
  @JsonSerializable(disallowUnrecognizedKeys: true)
  const factory OpenTaskCountsV2({
    @Default(<String, int>{}) Map<String, int> byProjectId,
    @Default(<String, int>{}) Map<String, int> byValueId,
  }) = _OpenTaskCountsV2;

  factory OpenTaskCountsV2.fromJson(Map<String, dynamic> json) =>
      _$OpenTaskCountsV2FromJson(json);
}

@freezed
abstract class EnrichmentResultV2 with _$EnrichmentResultV2 {
  @JsonSerializable(disallowUnrecognizedKeys: true)
  const factory EnrichmentResultV2({
    @Default(<String, ValueStats>{})
    Map<String, ValueStats> valueStatsByValueId,

    /// The total number of recent completions used to compute `actualPercent`.
    int? totalRecentCompletions,
    OpenTaskCountsV2? openTaskCounts,
    @Default(<String, AgendaTagV2>{})
    Map<String, AgendaTagV2> agendaTagByTaskId,
  }) = _EnrichmentResultV2;

  factory EnrichmentResultV2.fromJson(Map<String, dynamic> json) =>
      _$EnrichmentResultV2FromJson(json);
}

/// Separator behavior for a flat list.
enum ListSeparatorV2 {
  @JsonValue('divider')
  divider,

  @JsonValue('spaced_8')
  spaced8,

  @JsonValue('interleaved_auto')
  interleavedAuto,
}

/// Declares optional, presentation-only filter controls for list-style sections.
///
/// This spec controls which filter widgets are shown. Filter state is ephemeral
/// and owned by the presentation layer.
enum ValueFilterModeV2 {
  /// Include an entity if it has the selected value in its values list.
  @JsonValue('any_values')
  anyValues,

  /// Include a task only if its primary value matches the selection.
  @JsonValue('primary_only')
  primaryOnly,
}

@freezed
abstract class SectionFilterSpecV2 with _$SectionFilterSpecV2 {
  @JsonSerializable(disallowUnrecognizedKeys: true)
  const factory SectionFilterSpecV2({
    @Default(false) bool enableProjectsOnlyToggle,
    @Default(false) bool enableValueDropdown,
    @Default(ValueFilterModeV2.anyValues) ValueFilterModeV2 valueFilterMode,
  }) = _SectionFilterSpecV2;

  factory SectionFilterSpecV2.fromJson(Map<String, dynamic> json) =>
      _$SectionFilterSpecV2FromJson(json);
}

@Freezed(unionKey: 'type')
sealed class SectionLayoutSpecV2 with _$SectionLayoutSpecV2 {
  @FreezedUnionValue('flat_list')
  @JsonSerializable(disallowUnrecognizedKeys: true)
  const factory SectionLayoutSpecV2.flatList({
    @Default(ListSeparatorV2.divider) ListSeparatorV2 separator,
  }) = _FlatListV2;

  @FreezedUnionValue('timeline_month_sections')
  @JsonSerializable(disallowUnrecognizedKeys: true)
  const factory SectionLayoutSpecV2.timelineMonthSections({
    @Default(true) bool pinnedSectionHeaders,
  }) = _TimelineMonthSectionsV2;

  @FreezedUnionValue('hierarchy_value_project_task')
  @JsonSerializable(disallowUnrecognizedKeys: true)
  const factory SectionLayoutSpecV2.hierarchyValueProjectTask({
    @Default(true) bool pinnedValueHeaders,
    @Default(false) bool pinnedProjectHeaders,

    /// When true, tasks with no project are rendered in a single global Inbox
    /// group instead of being shown under each Value group.
    @Default(false) bool singleInboxGroupForNoProjectTasks,
  }) = _HierarchyValueProjectTaskV2;

  factory SectionLayoutSpecV2.fromJson(Map<String, dynamic> json) =>
      _$SectionLayoutSpecV2FromJson(json);
}

/// Params for V2 list-style templates (task/project/value list families).
@freezed
abstract class ListSectionParamsV2 with _$ListSectionParamsV2 {
  @JsonSerializable(disallowUnrecognizedKeys: true)
  const factory ListSectionParamsV2({
    required DataConfig config,
    required TilePolicyV2 tiles,
    required SectionLayoutSpecV2 layout,
    @Default(EnrichmentPlanV2()) EnrichmentPlanV2 enrichment,
    SectionFilterSpecV2? filters,
  }) = _ListSectionParamsV2;

  factory ListSectionParamsV2.fromJson(Map<String, dynamic> json) =>
      _$ListSectionParamsV2FromJson(json);
}
