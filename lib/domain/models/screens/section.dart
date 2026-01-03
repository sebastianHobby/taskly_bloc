import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/screens/data_config.dart';
import 'package:taskly_bloc/domain/models/screens/related_data_config.dart';
import 'package:taskly_bloc/domain/models/screens/display_config.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/services/screens/section_data_result.dart';

part 'section.freezed.dart';
part 'section.g.dart';

/// A section within a screen (DR-017: Unified Screen Model).
/// All screens are composed of 1+ sections.
@Freezed(unionKey: 'type')
sealed class Section with _$Section {
  /// Data section displaying entities
  @FreezedUnionValue('data')
  const factory Section.data({
    required DataConfig config,
    @Default([]) List<RelatedDataConfig> relatedData,

    /// Display configuration (grouping, sorting, etc.)
    DisplayConfig? display,

    /// Optional section title
    String? title,
  }) = DataSection;

  /// Allocation section (Focus/Next Actions - uses AllocationOrchestrator)
  /// DR-021: Added displayMode for flexible rendering
  @FreezedUnionValue('allocation')
  const factory Section.allocation({
    /// Source filter for allocation (optional - defaults to all tasks)
    @NullableTaskQueryConverter() TaskQuery? sourceFilter,

    /// Max tasks to allocate (overrides global setting if set)
    int? maxTasks,

    /// Display mode for allocation results (DR-021)
    @Default(AllocationDisplayMode.pinnedFirst)
    AllocationDisplayMode displayMode,

    /// Whether to show excluded task warnings
    @Default(true) bool showExcludedWarnings,

    /// Optional section title
    String? title,
  }) = AllocationSection;

  /// Agenda section (date-grouped tasks like Today, Upcoming)
  @FreezedUnionValue('agenda')
  const factory Section.agenda({
    required AgendaDateField dateField,
    @Default(AgendaGrouping.standard) AgendaGrouping grouping,

    /// Additional filter on top of date grouping
    @NullableTaskQueryConverter() TaskQuery? additionalFilter,

    /// Optional section title
    String? title,
  }) = AgendaSection;

  factory Section.fromJson(Map<String, dynamic> json) =>
      _$SectionFromJson(json);
}

/// Date field for agenda grouping
enum AgendaDateField {
  @JsonValue('deadline_date')
  deadlineDate,
  @JsonValue('start_date')
  startDate,
  @JsonValue('scheduled_for')
  scheduledFor,
}

/// Grouping strategy for agenda sections
enum AgendaGrouping {
  @JsonValue('standard')
  standard, // Today, Tomorrow, This Week, Later
  @JsonValue('by_date')
  byDate, // Group by actual date
  @JsonValue('overdue_first')
  overdueFirst, // Overdue, Today, Tomorrow, etc.
}
