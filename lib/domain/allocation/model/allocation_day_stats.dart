import 'package:flutter/foundation.dart';

/// Day-level stats derived from allocation snapshots + completion history.
///
/// All dates are UTC date-only days.
@immutable
class AllocationDayStats {
  const AllocationDayStats({
    required this.dayUtc,
    required this.allocatedTaskCount,
    required this.allocatedCompletedCount,
    required this.allocatedNotCompletedCount,
    required this.completedUnallocatedCount,
    required this.allocatedByEffectivePrimaryValueId,
    required this.completedByEffectivePrimaryValueId,
    required this.allocatedTasksInProject,
    required this.completedTasksInProject,
    required this.projectProgressedToday,
    required this.daysSinceLastAllocatedForProject,
    required this.daysSinceLastAllocatedCoverageSufficient,
    required this.repeatAllocatedNotCompletedByTaskId,
    required this.repeatWindowDays,
    required this.repeatCoverageDays,
  });

  /// UTC date-only day that these stats are computed for.
  final DateTime dayUtc;

  /// Number of tasks present in the allocation snapshot for [dayUtc].
  final int allocatedTaskCount;

  /// Number of allocated tasks that were completed on [dayUtc].
  final int allocatedCompletedCount;

  /// Number of allocated tasks that were NOT completed on [dayUtc].
  final int allocatedNotCompletedCount;

  /// Number of tasks completed on [dayUtc] that were NOT allocated that day.
  final int completedUnallocatedCount;

  /// Distribution of allocated tasks by effective primary value.
  ///
  /// Uses snapshot-captured `effectivePrimaryValueId` when available.
  final Map<String, int> allocatedByEffectivePrimaryValueId;

  /// Distribution of completed tasks by effective primary value.
  ///
  /// Uses effective-value resolution at query time (task overrides project).
  final Map<String, int> completedByEffectivePrimaryValueId;

  /// Allocated tasks grouped by snapshot-captured project id.
  final Map<String, int> allocatedTasksInProject;

  /// Completed tasks grouped by the task's current project id.
  final Map<String, int> completedTasksInProject;

  /// Project progress proxy v1: any completion in the project on [dayUtc].
  final Map<String, bool> projectProgressedToday;

  /// Allocation-derived “days since last allocated” per project.
  ///
  /// Values are null when unavailable.
  final Map<String, int?> daysSinceLastAllocatedForProject;

  /// Whether allocation snapshot coverage was sufficient to compute
  /// [daysSinceLastAllocatedForProject] reliably.
  final bool daysSinceLastAllocatedCoverageSufficient;

  /// Repeat metric over a rolling window: number of days a task appeared in the
  /// allocated set but was not completed that day.
  final Map<String, int> repeatAllocatedNotCompletedByTaskId;

  /// Size of the rolling window for [repeatAllocatedNotCompletedByTaskId].
  final int repeatWindowDays;

  /// Number of days within the repeat window that had an allocation snapshot.
  final int repeatCoverageDays;
}
