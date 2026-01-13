import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/core/model/task.dart';
import 'package:taskly_bloc/domain/core/model/project.dart';
import 'package:taskly_bloc/domain/core/model/value.dart';
import 'package:taskly_bloc/domain/core/model/value_priority.dart';
import 'package:taskly_bloc/domain/allocation/model/allocation_result.dart';
import 'package:taskly_bloc/domain/screens/language/models/enrichment_result.dart';
import 'package:taskly_bloc/domain/screens/language/models/agenda_data.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_item.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';
import 'package:taskly_bloc/domain/allocation/model/focus_mode.dart';
import 'package:taskly_bloc/domain/attention/model/attention_item.dart';

part 'section_data_result.freezed.dart';

/// Display mode for allocation section (DR-021)
enum AllocationDisplayMode {
  /// Flat list of all allocated tasks
  flat,

  /// Tasks grouped by their qualifying value
  groupedByValue,

  /// Tasks grouped by their project
  groupedByProject,

  /// Pinned tasks first, then grouped by value
  pinnedFirst,
}

/// A group of tasks allocated to a specific value (DR-020)
@freezed
abstract class AllocationValueGroup with _$AllocationValueGroup {
  const factory AllocationValueGroup({
    required String valueId,
    required String valueName,
    required List<AllocatedTask> tasks,
    required double weight,
    required int quota,
    @Default(ValuePriority.medium) ValuePriority valuePriority,
    String? color,
    String? iconName,
  }) = _AllocationValueGroup;
}

/// Result of fetching data for a section.
///
/// Each variant contains the data appropriate for that section type.
/// Used by ScreenBloc to populate section UIs with their data.
@freezed
sealed class SectionDataResult with _$SectionDataResult {
  /// Data section result - generic entity list with optional enrichment.
  const factory SectionDataResult.data({
    required List<ScreenItem> items,

    /// Computed enrichment data (e.g., value statistics).
    /// Present when the section requested enrichment via EnrichmentConfig.
    EnrichmentResult? enrichment,
  }) = DataSectionResult;

  /// V2 data section result - generic entity list with typed V2 enrichment.
  ///
  /// Unlike the `data` variant, this carries no related-entities sidecar.
  const factory SectionDataResult.dataV2({
    required List<ScreenItem> items,
    EnrichmentResultV2? enrichment,
  }) = DataV2SectionResult;

  /// Allocation section result - tasks allocated for focus/next actions (DR-020)
  ///
  /// Enriched with pinned tasks, value grouping, reasoning, and excluded task info.
  const factory SectionDataResult.allocation({
    /// All allocated tasks (flat list for backward compatibility)
    required List<Task> allocatedTasks,

    /// Total tasks available for allocation (before filtering)
    required int totalAvailable,

    /// Pinned tasks (shown first, regardless of value)
    @Default([]) List<AllocatedTask> pinnedTasks,

    /// Tasks grouped by their qualifying value
    @Default({}) Map<String, AllocationValueGroup> tasksByValue,

    /// Reasoning behind allocation decisions
    AllocationReasoning? reasoning,

    /// Count of tasks excluded from allocation
    @Default(0) int excludedCount,

    /// Urgent tasks that were excluded from allocation (for problem detection).
    /// These are tasks that the allocation layer determined are urgent but
    /// were excluded (e.g., due to UrgentTaskBehavior.warnOnly setting).
    @Default([]) List<ExcludedTask> excludedUrgentTasks,

    /// Full list of excluded tasks (for Outside Focus section)
    @Default([]) List<ExcludedTask> excludedTasks,

    /// The focus mode used for this allocation
    FocusMode? activeFocusMode,

    /// Display mode for this allocation section
    @Default(AllocationDisplayMode.pinnedFirst)
    AllocationDisplayMode displayMode,

    /// Whether to show excluded section
    @Default(false) bool showExcludedSection,

    /// True if allocation cannot proceed because user has no values defined.
    /// When true, the UI should show a gateway prompting value setup.
    @Default(false) bool requiresValueSetup,
  }) = AllocationSectionResult;

  /// Agenda section result - timeline with tasks and projects grouped by date
  const factory SectionDataResult.agenda({
    required AgendaData agendaData,
  }) = AgendaSectionResult;

  /// Issues summary section result - attention issues requiring action.
  const factory SectionDataResult.issuesSummary({
    required List<AttentionItem> items,
    required int criticalCount,
    required int warningCount,
  }) = IssuesSummarySectionResult;

  /// Allocation alerts section result - urgent excluded tasks.
  const factory SectionDataResult.allocationAlerts({
    required List<AttentionItem> alerts,
    required int totalExcluded,
  }) = AllocationAlertsSectionResult;

  /// Check-in summary section result - due reviews.
  const factory SectionDataResult.checkInSummary({
    required List<AttentionItem> dueReviews,
    required bool hasOverdue,
  }) = CheckInSummarySectionResult;

  /// Entity header for project detail screens.
  const factory SectionDataResult.entityHeaderProject({
    required Project project,
    @Default(true) bool showCheckbox,
    @Default(true) bool showMetadata,
  }) = EntityHeaderProjectSectionResult;

  /// Entity header for value detail screens.
  const factory SectionDataResult.entityHeaderValue({
    required Value value,
    int? taskCount,
    @Default(true) bool showMetadata,
  }) = EntityHeaderValueSectionResult;

  /// Missing entity header result (entity not found or unsupported type).
  const factory SectionDataResult.entityHeaderMissing({
    required String entityType,
    required String entityId,
  }) = EntityHeaderMissingSectionResult;

  const SectionDataResult._();

  /// Get all tasks from any result type
  List<Task> get allTasks => switch (this) {
    DataSectionResult(:final items) =>
      items
          .whereType<ScreenItemTask>()
          .map((i) => i.task)
          .whereType<Task>()
          .toList(),
    DataV2SectionResult(:final items) =>
      items
          .whereType<ScreenItemTask>()
          .map((i) => i.task)
          .whereType<Task>()
          .toList(),
    AllocationSectionResult(:final allocatedTasks) => allocatedTasks,
    AgendaSectionResult(:final agendaData) =>
      agendaData.groups
          .expand((g) => g.items)
          .where((i) => i.isTask)
          .map((i) => i.task)
          .whereType<Task>()
          .toList(),
    _ => [],
  };

  /// Get all projects from any result type
  List<Project> get allProjects => switch (this) {
    DataSectionResult(:final items) =>
      items
          .whereType<ScreenItemProject>()
          .map((i) => i.project)
          .whereType<Project>()
          .toList(),
    DataV2SectionResult(:final items) =>
      items
          .whereType<ScreenItemProject>()
          .map((i) => i.project)
          .whereType<Project>()
          .toList(),
    AgendaSectionResult(:final agendaData) =>
      agendaData.groups
          .expand((g) => g.items)
          .where((i) => i.isProject)
          .map((i) => i.project)
          .whereType<Project>()
          .toList(),
    EntityHeaderProjectSectionResult(:final project) => [project],
    _ => [],
  };

  /// Get all values from any result type
  List<Value> get allValues => switch (this) {
    DataSectionResult(:final items) =>
      items.whereType<ScreenItemValue>().map((i) => i.value).toList(),
    DataV2SectionResult(:final items) =>
      items.whereType<ScreenItemValue>().map((i) => i.value).toList(),
    EntityHeaderValueSectionResult(:final value) => [value],
    _ => [],
  };

  /// Count of primary entities for logging
  int get primaryCount => switch (this) {
    DataSectionResult(:final items) => items.length,
    DataV2SectionResult(:final items) => items.length,
    AllocationSectionResult(:final allocatedTasks) => allocatedTasks.length,
    AgendaSectionResult(:final agendaData) =>
      agendaData.groups.fold(0, (sum, g) => sum + g.items.length) +
          agendaData.overdueItems.length,
    _ => 0,
  };
}
