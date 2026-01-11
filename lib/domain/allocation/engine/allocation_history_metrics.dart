import 'package:taskly_bloc/core/utils/date_only.dart';
import 'package:taskly_bloc/domain/allocation/model/allocation_project_history_window.dart';
import 'package:taskly_bloc/domain/models/settings/project_health_review_settings.dart';

/// Shared helpers for allocation-history-derived metrics.
///
/// Phase 4 (project health reviews) and Phase 5 (stats/feedback loops) share
/// these computations to ensure consistent behavior and gating.
class AllocationHistoryMetrics {
  const AllocationHistoryMetrics._();

  static bool hasSufficientCoverage({
    required AllocationProjectHistoryWindow historyWindow,
    required ProjectHealthReviewSettings settings,
  }) {
    return historyWindow.snapshotCoverageDays >= settings.minCoverageDays;
  }

  /// Computes days since last allocation for a project.
  ///
  /// When [lastAllocatedDayUtc] is null (no allocation observed in the window),
  /// returns [settings.historyWindowDays] to match Phase 4 semantics.
  static int daysSinceLastAllocated({
    required DateTime todayUtc,
    required DateTime? lastAllocatedDayUtc,
    required ProjectHealthReviewSettings settings,
  }) {
    final todayDayUtc = dateOnly(todayUtc.toUtc());
    final lastDay = lastAllocatedDayUtc;
    return lastDay == null
        ? settings.historyWindowDays
        : todayDayUtc.difference(lastDay).inDays;
  }
}
