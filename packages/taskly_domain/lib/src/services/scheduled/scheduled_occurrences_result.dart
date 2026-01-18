import 'package:flutter/foundation.dart';

import 'package:taskly_domain/src/models/scheduled/scheduled_occurrence.dart';

/// Result of watching scheduled occurrences for a date range.
@immutable
final class ScheduledOccurrencesResult {
  const ScheduledOccurrencesResult({
    required this.rangeStartDay,
    required this.rangeEndDay,
    required this.overdue,
    required this.occurrences,
  });

  /// Inclusive start of the requested window (home-day key).
  final DateTime rangeStartDay;

  /// Inclusive end of the requested window (home-day key).
  final DateTime rangeEndDay;

  /// Overdue items (deadline < rangeStartDay).
  final List<ScheduledOccurrence> overdue;

  /// Occurrences within the requested window.
  final List<ScheduledOccurrence> occurrences;
}
