import 'package:flutter/foundation.dart';
import 'package:taskly_domain/src/preferences/model/sort_preferences.dart';
import 'package:taskly_domain/src/queries/occurrence_expansion.dart';
import 'package:taskly_domain/src/queries/occurrence_preview.dart';
import 'package:taskly_domain/src/queries/query_filter.dart';
import 'package:taskly_domain/src/queries/task_predicate.dart';

/// Unified query configuration for fetching tasks with filtering, sorting, and occurrence expansion.
///
/// Replaces TaskFilterConfig with a simpler, more explicit API that supports
/// 100% database-level filtering via SQL expressions.
@immutable
class TaskQuery {
  const TaskQuery({
    this.filter = const QueryFilter<TaskPredicate>.matchAll(),
    this.sortCriteria = const [],
    this.occurrenceExpansion,
    this.occurrencePreview,
  });

  factory TaskQuery.fromJson(Map<String, dynamic> json) {
    return TaskQuery(
      filter: QueryFilter.fromJson<TaskPredicate>(
        json['filter'] as Map<String, dynamic>? ?? const <String, dynamic>{},
        TaskPredicate.fromJson,
      ),
      sortCriteria:
          (json['sortCriteria'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(SortCriterion.fromJson)
              .toList(growable: false) ??
          const <SortCriterion>[],
      occurrenceExpansion: json['occurrenceExpansion'] != null
          ? OccurrenceExpansion.fromJson(
              json['occurrenceExpansion'] as Map<String, dynamic>,
            )
          : null,
      occurrencePreview: json['occurrencePreview'] != null
          ? OccurrencePreview.fromJson(
              json['occurrencePreview'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  // ========================================================================
  // Factory Methods
  // ========================================================================

  /// Factory: Inbox view (incomplete tasks with no project).
  factory TaskQuery.inbox({List<SortCriterion>? sortCriteria}) {
    return TaskQuery(
      filter: const QueryFilter<TaskPredicate>(
        shared: [
          TaskBoolPredicate(
            field: TaskBoolField.completed,
            operator: BoolOperator.isFalse,
          ),
          TaskProjectPredicate(operator: ProjectOperator.isNull),
        ],
      ),
      sortCriteria: sortCriteria ?? _defaultSortCriteria,
    );
  }

  /// Factory: All tasks (no filtering).
  factory TaskQuery.all({List<SortCriterion>? sortCriteria}) {
    return TaskQuery(
      sortCriteria: sortCriteria ?? _defaultSortCriteria,
    );
  }

  /// Factory: Incomplete tasks only.
  factory TaskQuery.incomplete({List<SortCriterion>? sortCriteria}) {
    return TaskQuery(
      filter: const QueryFilter<TaskPredicate>(
        shared: [
          TaskBoolPredicate(
            field: TaskBoolField.completed,
            operator: BoolOperator.isFalse,
          ),
        ],
      ),
      sortCriteria: sortCriteria ?? _defaultSortCriteria,
    );
  }

  /// Tasks in a specific project.
  factory TaskQuery.byProject(
    String projectId, {
    List<SortCriterion>? sortCriteria,
  }) {
    return TaskQuery(
      filter: QueryFilter<TaskPredicate>(
        shared: [
          TaskProjectPredicate(
            operator: ProjectOperator.matches,
            projectId: projectId,
          ),
        ],
      ),
      sortCriteria: sortCriteria ?? _defaultSortCriteria,
    );
  }

  /// Filtering predicates to apply.
  final QueryFilter<TaskPredicate> filter;

  /// Sort criteria for ordering results.
  final List<SortCriterion> sortCriteria;

  /// Optional configuration for expanding repeating tasks into occurrences.
  final OccurrenceExpansion? occurrenceExpansion;

  /// Optional configuration for previewing the next (single) occurrence.
  ///
  /// This is mutually exclusive with [occurrenceExpansion].
  final OccurrencePreview? occurrencePreview;

  // ========================================================================
  // Helper Properties
  // ========================================================================

  /// Whether this query should expand repeating tasks into occurrences.
  bool get shouldExpandOccurrences => occurrenceExpansion != null;

  /// Whether this query should compute a single next occurrence preview.
  bool get hasOccurrencePreview => occurrencePreview != null;

  /// Whether this query filters by project.
  bool get hasProjectFilter {
    return filter.shared.any((p) => p is TaskProjectPredicate) ||
        filter.orGroups.expand((g) => g).any((p) => p is TaskProjectPredicate);
  }

  /// Whether this query has any date-based filtering rules.
  bool get hasDateFilter {
    return filter.shared.any((p) => p is TaskDatePredicate) ||
        filter.orGroups.expand((g) => g).any((p) => p is TaskDatePredicate);
  }

  // ========================================================================
  // Modification Methods
  // ========================================================================

  TaskQuery copyWith({
    QueryFilter<TaskPredicate>? filter,
    List<SortCriterion>? sortCriteria,
    OccurrenceExpansion? occurrenceExpansion,
    bool clearOccurrenceExpansion = false,
    OccurrencePreview? occurrencePreview,
    bool clearOccurrencePreview = false,
  }) {
    final nextOccurrenceExpansion = clearOccurrenceExpansion
        ? null
        : (occurrenceExpansion ?? this.occurrenceExpansion);

    final nextOccurrencePreview = clearOccurrencePreview
        ? null
        : (occurrencePreview ?? this.occurrencePreview);

    assert(
      nextOccurrenceExpansion == null || nextOccurrencePreview == null,
      'TaskQuery cannot set both occurrenceExpansion and occurrencePreview.',
    );

    return TaskQuery(
      filter: filter ?? this.filter,
      sortCriteria: sortCriteria ?? this.sortCriteria,
      occurrenceExpansion: nextOccurrenceExpansion,
      occurrencePreview: nextOccurrencePreview,
    );
  }

  /// Creates a copy with additional shared predicates added.
  TaskQuery withAdditionalPredicates(List<TaskPredicate> predicates) {
    return copyWith(
      filter: filter.copyWith(shared: [...filter.shared, ...predicates]),
    );
  }

  /// Creates a copy with different sort criteria.
  TaskQuery withSortCriteria(List<SortCriterion> newSortCriteria) {
    return copyWith(sortCriteria: newSortCriteria);
  }

  /// Creates a copy with occurrence expansion enabled.
  TaskQuery withOccurrenceExpansion(OccurrenceExpansion expansion) {
    return copyWith(occurrenceExpansion: expansion);
  }

  /// Creates a copy with occurrence preview enabled.
  TaskQuery withOccurrencePreview(OccurrencePreview preview) {
    return copyWith(occurrencePreview: preview);
  }

  // ========================================================================
  // Equality & Hash
  // ========================================================================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskQuery &&
        other.filter == filter &&
        _listEquals(other.sortCriteria, sortCriteria) &&
        other.occurrenceExpansion == occurrenceExpansion &&
        other.occurrencePreview == occurrencePreview;
  }

  @override
  int get hashCode => Object.hash(
    filter,
    Object.hashAll(sortCriteria),
    occurrenceExpansion,
    occurrencePreview,
  );

  @override
  String toString() {
    return 'TaskQuery(filter: $filter, sortCriteria: $sortCriteria, '
        'occurrenceExpansion: $occurrenceExpansion, '
        'occurrencePreview: $occurrencePreview)';
  }

  // ========================================================================
  // JSON Serialization
  // ========================================================================

  Map<String, dynamic> toJson() => <String, dynamic>{
    'filter': filter.toJson((p) => p.toJson()),
    'sortCriteria': sortCriteria.map((s) => s.toJson()).toList(),
    'occurrenceExpansion': occurrenceExpansion?.toJson(),
    'occurrencePreview': occurrencePreview?.toJson(),
  };

  // ========================================================================
  // Private Helpers
  // ========================================================================

  static const _defaultSortCriteria = [
    SortCriterion(field: SortField.deadlineDate),
    SortCriterion(field: SortField.name),
  ];

  static bool _listEquals<T>(List<T> list1, List<T> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }
}
