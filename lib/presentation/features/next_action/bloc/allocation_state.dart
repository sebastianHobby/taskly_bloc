part of 'allocation_bloc.dart';

/// Status of allocation
enum AllocationStatus {
  initial,
  loading,
  success,
  failure,
}

/// State for allocation screen
@freezed
abstract class AllocationState with _$AllocationState {
  const factory AllocationState({
    @Default(AllocationStatus.initial) AllocationStatus status,
    @Default([]) List<AllocatedTask> pinnedTasks,
    @Default({}) Map<String, AllocationGroup> tasksByValue,
    @Default([]) List<ExcludedTask> excludedUrgent,
    @Default(0) int excludedCount,
    @Default(0) int unrankedCount,
    AllocationReasoning? reasoning,
    DateTime? lastRefreshed,
    String? errorMessage,
    @Default(false) bool showExcludedWarning,
  }) = _AllocationState;

  const AllocationState._();

  /// Total number of allocated tasks (pinned + regular)
  int get totalAllocatedCount =>
      pinnedTasks.length +
      tasksByValue.values.fold(0, (sum, group) => sum + group.tasks.length);

  /// Whether there are excluded urgent tasks
  bool get hasExcludedUrgent => excludedUrgent.isNotEmpty;

  /// Whether there are more tasks available for allocation
  bool get hasMoreTasksAvailable => excludedCount > 0;

  /// Whether the allocation is empty
  bool get isEmpty => pinnedTasks.isEmpty && tasksByValue.isEmpty;
}

/// Group of tasks allocated to a value
@freezed
abstract class AllocationGroup with _$AllocationGroup {
  const factory AllocationGroup({
    required String valueId,
    required String valueName,
    required List<AllocatedTask> tasks,
    required double weight,
    required int quota,
    String? color,
  }) = _AllocationGroup;
}
