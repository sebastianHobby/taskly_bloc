import 'package:flutter/foundation.dart';
import 'package:taskly_bloc/domain/time/date_only.dart';
import 'package:taskly_bloc/presentation/shared/models/sort_preferences.dart';
import 'package:taskly_bloc/domain/wellbeing/model/mood_rating.dart';
import 'package:taskly_bloc/domain/queries/journal_predicate.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart'
    show DateOperator;

/// Unified query configuration for fetching journal entries.
///
/// Mirrors the `TaskQuery` and `LabelQuery` patterns to provide filtering
/// and sorting for journal entries.
@immutable
class JournalQuery {
  const JournalQuery({
    this.filter = const QueryFilter<JournalPredicate>.matchAll(),
    this.sortCriteria = const <SortCriterion>[],
  });

  factory JournalQuery.fromJson(Map<String, dynamic> json) {
    return JournalQuery(
      filter: QueryFilter.fromJson<JournalPredicate>(
        json['filter'] as Map<String, dynamic>? ?? const <String, dynamic>{},
        JournalPredicate.fromJson,
      ),
      sortCriteria:
          (json['sortCriteria'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(SortCriterion.fromJson)
              .toList(growable: false) ??
          const <SortCriterion>[],
    );
  }

  // ========================================================================
  // Factory Methods
  // ========================================================================

  /// Factory: All journal entries (no filtering).
  factory JournalQuery.all({List<SortCriterion>? sortCriteria}) {
    return JournalQuery(
      sortCriteria: sortCriteria ?? _defaultSortCriteria,
    );
  }

  /// Factory: Specific entry by ID.
  factory JournalQuery.byId(String id) {
    return JournalQuery(
      filter: QueryFilter<JournalPredicate>(
        shared: [JournalIdPredicate(id: id)],
      ),
    );
  }

  /// Factory: Entries for a specific date.
  factory JournalQuery.forDate(DateTime date) {
    return JournalQuery(
      filter: QueryFilter<JournalPredicate>(
        shared: [
          JournalDatePredicate(
            operator: DateOperator.on,
            date: dateOnly(date),
          ),
        ],
      ),
      sortCriteria: _defaultSortCriteria,
    );
  }

  /// Factory: Entries within a date range.
  factory JournalQuery.dateRange({
    required DateTime startDate,
    required DateTime endDate,
    List<SortCriterion>? sortCriteria,
  }) {
    return JournalQuery(
      filter: QueryFilter<JournalPredicate>(
        shared: [
          JournalDatePredicate(
            operator: DateOperator.between,
            startDate: dateOnly(startDate),
            endDate: dateOnly(endDate),
          ),
        ],
      ),
      sortCriteria: sortCriteria ?? _defaultSortCriteria,
    );
  }

  /// Factory: Recent entries (last N days).
  factory JournalQuery.recent({
    int days = 7,
    List<SortCriterion>? sortCriteria,
  }) {
    final now = DateTime.now();
    final startDate = dateOnly(now.subtract(Duration(days: days)));
    return JournalQuery(
      filter: QueryFilter<JournalPredicate>(
        shared: [
          JournalDatePredicate(
            operator: DateOperator.onOrAfter,
            date: startDate,
          ),
        ],
      ),
      sortCriteria: sortCriteria ?? _defaultSortCriteria,
    );
  }

  /// Factory: Entries with specific mood or better.
  factory JournalQuery.moodAtLeast(
    MoodOperator moodOperator,
    int moodValue, {
    List<SortCriterion>? sortCriteria,
  }) {
    return JournalQuery(
      filter: QueryFilter<JournalPredicate>(
        shared: [
          JournalMoodPredicate(
            operator: moodOperator,
            value: MoodRating.fromValue(moodValue),
          ),
        ],
      ),
      sortCriteria: sortCriteria ?? _defaultSortCriteria,
    );
  }

  /// Factory: Search by text content.
  factory JournalQuery.search(
    String searchTerm, {
    List<SortCriterion>? sortCriteria,
  }) {
    return JournalQuery(
      filter: QueryFilter<JournalPredicate>(
        shared: [
          JournalTextPredicate(
            operator: TextOperator.contains,
            value: searchTerm,
          ),
        ],
      ),
      sortCriteria: sortCriteria ?? _defaultSortCriteria,
    );
  }

  /// Filtering predicates to apply.
  final QueryFilter<JournalPredicate> filter;

  /// Sort criteria for ordering results.
  final List<SortCriterion> sortCriteria;

  // ========================================================================
  // Helper Properties
  // ========================================================================

  /// Whether this query filters by date.
  bool get hasDateFilter {
    return filter.shared.any((p) => p is JournalDatePredicate) ||
        filter.orGroups.expand((g) => g).any((p) => p is JournalDatePredicate);
  }

  /// Whether this query filters by specific ID.
  bool get hasIdFilter {
    return filter.shared.any((p) => p is JournalIdPredicate) ||
        filter.orGroups.expand((g) => g).any((p) => p is JournalIdPredicate);
  }

  // ========================================================================
  // Modification Methods
  // ========================================================================

  /// Add an additional predicate to the shared filter.
  JournalQuery addPredicate(JournalPredicate predicate) {
    return copyWith(
      filter: filter.copyWith(
        shared: [...filter.shared, predicate],
      ),
    );
  }

  /// Creates a copy of this JournalQuery with the given fields replaced.
  JournalQuery copyWith({
    QueryFilter<JournalPredicate>? filter,
    List<SortCriterion>? sortCriteria,
  }) {
    return JournalQuery(
      filter: filter ?? this.filter,
      sortCriteria: sortCriteria ?? this.sortCriteria,
    );
  }

  // ========================================================================
  // JSON Serialization
  // ========================================================================

  Map<String, dynamic> toJson() => <String, dynamic>{
    'filter': filter.toJson((p) => p.toJson()),
    'sortCriteria': sortCriteria.map((s) => s.toJson()).toList(),
  };

  // ========================================================================
  // Equality & Hash
  // ========================================================================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JournalQuery &&
        other.filter == filter &&
        listEquals(other.sortCriteria, sortCriteria);
  }

  @override
  int get hashCode => Object.hash(filter, Object.hashAll(sortCriteria));

  // ========================================================================
  // Defaults
  // ========================================================================

  /// Default sort: newest entries first.
  static const List<SortCriterion> _defaultSortCriteria = [
    SortCriterion(
      field: SortField.createdDate,
      direction: SortDirection.descending,
    ),
  ];
}
