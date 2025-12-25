import 'package:flutter/foundation.dart';

/// Configuration for expanding repeating tasks into occurrences within a date range.
@immutable
class OccurrenceExpansion {
  const OccurrenceExpansion({
    required this.rangeStart,
    required this.rangeEnd,
  });

  /// Start of the occurrence expansion date range (inclusive).
  final DateTime rangeStart;

  /// End of the occurrence expansion date range (inclusive).
  final DateTime rangeEnd;

  OccurrenceExpansion copyWith({
    DateTime? rangeStart,
    DateTime? rangeEnd,
  }) {
    return OccurrenceExpansion(
      rangeStart: rangeStart ?? this.rangeStart,
      rangeEnd: rangeEnd ?? this.rangeEnd,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OccurrenceExpansion &&
        other.rangeStart == rangeStart &&
        other.rangeEnd == rangeEnd;
  }

  @override
  int get hashCode => Object.hash(rangeStart, rangeEnd);

  @override
  String toString() {
    return 'OccurrenceExpansion(rangeStart: $rangeStart, rangeEnd: $rangeEnd)';
  }
}
