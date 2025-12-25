import 'package:flutter/foundation.dart';
import 'package:taskly_bloc/core/shared/models/sort_preferences.dart';
import 'package:taskly_bloc/domain/filtering/task_rules.dart';

/// Metadata about filter application status.
///
/// Tracks which rules and sort criteria were applied at the database level
/// (SQL) versus which need to be applied in-memory (Dart).
@immutable
class FilterResultMetadata {
  /// Creates filter result metadata.
  const FilterResultMetadata({
    required this.appliedRules,
    required this.pendingRules,
    required this.appliedSort,
    required this.pendingSort,
    this.occurrencesExpanded = false,
    this.expansionRange,
  });

  /// Rules successfully applied at the database level.
  final List<TaskRule> appliedRules;

  /// Rules that need to be applied in-memory (Dart).
  final List<TaskRule> pendingRules;

  /// Sort criteria successfully applied at the database level.
  final List<SortCriterion> appliedSort;

  /// Sort criteria that need to be applied in-memory (Dart).
  final List<SortCriterion> pendingSort;

  /// Whether occurrences have been expanded from repeating tasks.
  final bool occurrencesExpanded;

  /// The date range used for occurrence expansion, if applicable.
  final DateRange? expansionRange;

  /// Whether all filtering has been fully applied (no pending operations).
  bool get isFullyApplied => pendingRules.isEmpty && pendingSort.isEmpty;

  /// Whether there are rules pending in-memory application.
  bool get hasPendingRules => pendingRules.isNotEmpty;

  /// Whether there are sort criteria pending in-memory application.
  bool get hasPendingSort => pendingSort.isNotEmpty;

  /// Whether post-processing (finalization) is required.
  bool get requiresPostProcessing => !isFullyApplied;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FilterResultMetadata &&
        _listEquals(other.appliedRules, appliedRules) &&
        _listEquals(other.pendingRules, pendingRules) &&
        _listEquals(other.appliedSort, appliedSort) &&
        _listEquals(other.pendingSort, pendingSort) &&
        other.occurrencesExpanded == occurrencesExpanded &&
        other.expansionRange == expansionRange;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(appliedRules),
    Object.hashAll(pendingRules),
    Object.hashAll(appliedSort),
    Object.hashAll(pendingSort),
    occurrencesExpanded,
    expansionRange,
  );
}

/// Represents a date range for filtering.
@immutable
class DateRange {
  /// Creates a date range.
  const DateRange({
    required this.start,
    required this.end,
  });

  /// The start date of the range (inclusive).
  final DateTime start;

  /// The end date of the range (inclusive).
  final DateTime end;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DateRange && other.start == start && other.end == end;
  }

  @override
  int get hashCode => Object.hash(start, end);
}

bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
