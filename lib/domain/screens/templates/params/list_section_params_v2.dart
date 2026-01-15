import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/screens/language/models/data_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/value_stats.dart';
import 'package:taskly_bloc/domain/screens/templates/params/style_pack_v2.dart';

part 'list_section_params_v2.freezed.dart';
part 'list_section_params_v2.g.dart';

/// Date field used to derive agenda tags.
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

  /// Snapshot-backed allocation membership for the current UTC day.
  ///
  /// This is global state derived from the latest allocation snapshot.
  @FreezedUnionValue('allocation_membership')
  @JsonSerializable(disallowUnrecognizedKeys: true)
  const factory EnrichmentPlanItemV2.allocationMembership() =
      _AllocationMembershipItemV2;

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

    /// True when the task is allocated in the latest snapshot for today.
    @Default(<String, bool>{}) Map<String, bool> isAllocatedByTaskId,

    /// Stable ordering for allocated tasks (lower rank = earlier).
    ///
    /// Present only when the section requested allocation membership enrichment.
    @Default(<String, int>{}) Map<String, int> allocationRankByTaskId,

    /// Value grouping override for allocated tasks.
    ///
    /// When present, renderers may group tasks by this value id instead of
    /// task.primary/effective values.
    @Default(<String, String>{}) Map<String, String> qualifyingValueIdByTaskId,
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

/// Where a section's filter controls should be rendered.
///
/// This is presentation-only configuration: it affects UI placement but does
/// not change interpreter behavior or data fetching.
enum FilterBarPlacementV2 {
  /// Render filter controls inline in the section header area.
  @JsonValue('inline')
  inline,

  /// Render filter controls as a pinned sliver header.
  @JsonValue('pinned')
  pinned,
}

@freezed
abstract class SectionFilterSpecV2 with _$SectionFilterSpecV2 {
  @JsonSerializable(disallowUnrecognizedKeys: true)
  const factory SectionFilterSpecV2({
    @Default(false) bool enableProjectsOnlyToggle,
    @Default(false) bool enableValueDropdown,

    /// When true, show a toggle chip to only show tasks that are currently in
    /// Focus (My Day membership / pinned to focus).
    @Default(false) bool enableFocusOnlyToggle,

    /// When true, show a toggle chip to include/exclude items that start after
    /// today (local day boundary).
    @Default(false) bool enableIncludeFutureStartsToggle,
    @Default(ValueFilterModeV2.anyValues) ValueFilterModeV2 valueFilterMode,

    /// Presentation-only placement policy for the filter bar.
    @Default(FilterBarPlacementV2.inline)
    FilterBarPlacementV2 filterBarPlacement,

    /// When pinned, keep a consistent occupied area (avoid layout jumping).
    ///
    /// This is a visual policy; it does not affect data or interpreter output.
    @Default(false) bool reservePinnedSpace,
  }) = _SectionFilterSpecV2;

  factory SectionFilterSpecV2.fromJson(Map<String, dynamic> json) =>
      _$SectionFilterSpecV2FromJson(json);
}

/// Params for V2 list-style templates (task/project/value list families).
@freezed
abstract class ListSectionParamsV2 with _$ListSectionParamsV2 {
  @JsonSerializable(disallowUnrecognizedKeys: true)
  const factory ListSectionParamsV2({
    required DataConfig config,
    required StylePackV2 pack,
    @Default(ListSeparatorV2.divider) ListSeparatorV2 separator,
    @Default(EnrichmentPlanV2()) EnrichmentPlanV2 enrichment,
    SectionFilterSpecV2? filters,
  }) = _ListSectionParamsV2;

  factory ListSectionParamsV2.fromJson(Map<String, dynamic> json) =>
      _$ListSectionParamsV2FromJson(json);
}
