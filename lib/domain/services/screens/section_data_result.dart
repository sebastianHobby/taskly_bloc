import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/models/priority/allocation_result.dart';
import 'package:taskly_bloc/domain/models/screens/enrichment_result.dart';

part 'section_data_result.freezed.dart';

/// Display mode for allocation section (DR-021)
enum AllocationDisplayMode {
  /// Flat list of all allocated tasks
  flat,

  /// Tasks grouped by their qualifying value
  groupedByValue,

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
    String? color,
  }) = _AllocationValueGroup;
}

/// Result of fetching data for a section.
///
/// Each variant contains the data appropriate for that section type.
/// Used by ScreenBloc to populate section UIs with their data.
@freezed
sealed class SectionDataResult with _$SectionDataResult {
  /// Data section result - generic entity list with optional related data
  const factory SectionDataResult.data({
    required List<dynamic> primaryEntities,
    required String primaryEntityType,
    @Default({}) Map<String, List<dynamic>> relatedEntities,

    /// Computed enrichment data (e.g., value statistics).
    /// Present when the section requested enrichment via EnrichmentConfig.
    EnrichmentResult? enrichment,
  }) = DataSectionResult;

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

    /// Display mode for this allocation section
    @Default(AllocationDisplayMode.pinnedFirst)
    AllocationDisplayMode displayMode,

    /// True if allocation cannot proceed because user has no values defined.
    /// When true, the UI should show a gateway prompting value setup.
    @Default(false) bool requiresValueSetup,
  }) = AllocationSectionResult;

  /// Agenda section result - tasks grouped by date
  const factory SectionDataResult.agenda({
    required Map<String, List<Task>> groupedTasks,
    required List<String> groupOrder,
  }) = AgendaSectionResult;

  const SectionDataResult._();

  /// Get all tasks from any result type
  List<Task> get allTasks => switch (this) {
    DataSectionResult(:final primaryEntities, :final primaryEntityType) =>
      primaryEntityType == 'task' ? primaryEntities.cast<Task>() : [],
    AllocationSectionResult(:final allocatedTasks) => allocatedTasks,
    AgendaSectionResult(:final groupedTasks) =>
      groupedTasks.values.expand((list) => list).toList(),
  };

  /// Get all projects from any result type
  List<Project> get allProjects => switch (this) {
    DataSectionResult(:final primaryEntities, :final primaryEntityType) =>
      primaryEntityType == 'project' ? primaryEntities.cast<Project>() : [],
    _ => [],
  };

  /// Get all labels from any result type
  List<Label> get allLabels => switch (this) {
    DataSectionResult(:final primaryEntities, :final primaryEntityType) =>
      primaryEntityType == 'label' || primaryEntityType == 'value'
          ? primaryEntities.cast<Label>()
          : [],
    _ => [],
  };

  /// Get related tasks (if any)
  List<Task> get relatedTasks => switch (this) {
    DataSectionResult(:final relatedEntities) =>
      (relatedEntities['tasks'] as List<Task>?) ?? [],
    _ => [],
  };

  /// Get related projects (if any)
  List<Project> get relatedProjects => switch (this) {
    DataSectionResult(:final relatedEntities) =>
      (relatedEntities['projects'] as List<Project>?) ?? [],
    _ => [],
  };
}
