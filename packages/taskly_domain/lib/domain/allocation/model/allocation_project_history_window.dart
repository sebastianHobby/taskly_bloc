import 'package:flutter/foundation.dart';

/// Allocation snapshot history summary for a rolling UTC day window.
@immutable
class AllocationProjectHistoryWindow {
  const AllocationProjectHistoryWindow({
    required this.windowStartDayUtc,
    required this.windowEndDayUtc,
    required this.snapshotDaysUtc,
    required this.lastAllocatedDayByProjectId,
  });

  /// Inclusive start of the window (UTC date-only).
  final DateTime windowStartDayUtc;

  /// Inclusive end of the window (UTC date-only).
  final DateTime windowEndDayUtc;

  /// Distinct UTC days that have at least one allocation snapshot.
  final Set<DateTime> snapshotDaysUtc;

  /// Latest UTC day within the window where a project had an allocated task.
  final Map<String, DateTime> lastAllocatedDayByProjectId;

  int get snapshotCoverageDays => snapshotDaysUtc.length;
}
