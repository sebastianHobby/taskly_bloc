import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/allocation/model/focus_mode.dart';
import 'package:taskly_bloc/domain/models/task.dart';

part 'allocation_result.freezed.dart';

/// Result of task allocation with transparency
@freezed
abstract class AllocationResult with _$AllocationResult {
  const factory AllocationResult({
    required List<AllocatedTask> allocatedTasks,
    required AllocationReasoning reasoning,
    required List<ExcludedTask> excludedTasks,

    /// The focus mode used for this allocation
    FocusMode? activeFocusMode,

    /// True if allocation cannot proceed because user has no values defined.
    /// When true, the UI should show a gateway prompting value setup.
    @Default(false) bool requiresValueSetup,
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
