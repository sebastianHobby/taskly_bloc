import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/task.dart';

part 'allocation_result.freezed.dart';

/// Result of task allocation with transparency
@freezed
abstract class AllocationResult with _$AllocationResult {
  const factory AllocationResult({
    required List<AllocatedTask> allocatedTasks,
    required AllocationReasoning reasoning,
    required List<ExcludedTask> excludedTasks,
    @Default([]) List<AllocationWarning> warnings,
  }) = _AllocationResult;
}

/// Task with allocation context
@freezed
abstract class AllocatedTask with _$AllocatedTask {
  const factory AllocatedTask({
    required Task task,
    required String qualifyingValueId, // Value that qualified this task
    required double allocationScore,

    /// True if this task was included due to urgency override (Firefighter mode)
    /// rather than value-based allocation.
    @Default(false) bool isUrgentOverride,
  }) = _AllocatedTask;
}

/// Task that was excluded from allocation
@freezed
abstract class ExcludedTask with _$ExcludedTask {
  const factory ExcludedTask({
    required Task task,
    required String reason,
    required ExclusionType exclusionType,
    bool? isUrgent,
  }) = _ExcludedTask;
}

/// Reasons for task exclusion
enum ExclusionType {
  @JsonValue('no_category')
  noCategory,
  @JsonValue('low_priority')
  lowPriority,
  @JsonValue('category_limit_reached')
  categoryLimitReached,
  @JsonValue('completed')
  completed,
}

/// Warning about allocation issues
@freezed
abstract class AllocationWarning with _$AllocationWarning {
  const factory AllocationWarning({
    required WarningType type,
    required String message,
    required String suggestedAction,
    List<String>? affectedTaskIds,
  }) = _AllocationWarning;
}

/// Types of allocation warnings
enum WarningType {
  @JsonValue('excluded_urgent_task')
  excludedUrgentTask,
  @JsonValue('unbalanced_allocation')
  unbalancedAllocation,
  @JsonValue('no_tasks_in_category')
  noTasksInCategory,
  @JsonValue('exceeded_total_limit')
  exceededTotalLimit,

  /// A project's deadline is approaching within the configured threshold.
  @JsonValue('project_deadline_approaching')
  projectDeadlineApproaching,

  /// An urgent task was excluded because it has no value assigned.
  @JsonValue('urgent_task_excluded')
  urgentTaskExcluded,
}

/// Reasoning behind allocation decisions
@freezed
abstract class AllocationReasoning with _$AllocationReasoning {
  const factory AllocationReasoning({
    required String strategyUsed,
    required Map<String, int> categoryAllocations, // categoryId -> count
    required Map<String, double> categoryWeights, // categoryId -> weight
    double? urgencyInfluence,
    String? explanation,
  }) = _AllocationReasoning;
}
