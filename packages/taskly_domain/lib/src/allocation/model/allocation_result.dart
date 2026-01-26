import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_domain/src/allocation/model/focus_mode.dart';
import 'package:taskly_domain/src/core/model/task.dart';

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

    /// Projects selected as anchors (project-first allocation).
    @Default(<String>[]) List<String> anchorProjectIds,

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

    /// Reasons explaining why this task was selected.
    ///
    /// Ordered by priority for UI display.
    @Default(<AllocationReasonCode>[]) List<AllocationReasonCode> reasonCodes,

    /// True if this task was included due to urgency override (Firefighter mode)
    /// rather than value-based allocation.
    @Default(false) bool isUrgentOverride,
  }) = _AllocatedTask;
}

/// Reasons explaining why a task was selected by allocation.
enum AllocationReasonCode {
  /// Task aligns with a value (explicit or inherited).
  valueAlignment,

  /// Task advances multiple values (efficient leverage / cross-category impact).
  crossValue,

  /// Task supports a value that has been neglected.
  neglectBalance,

  /// Task is urgent due to deadline proximity or being overdue.
  urgency,

  /// Task is high priority and received a priority boost.
  priority,
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
