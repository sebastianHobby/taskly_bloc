import 'package:flutter/foundation.dart';
import 'package:taskly_bloc/domain/models/sort_preferences.dart';
import 'package:taskly_bloc/domain/queries/value_match_mode.dart';
import 'package:taskly_bloc/domain/queries/occurrence_expansion.dart';
import 'package:taskly_bloc/domain/queries/project_predicate.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart'
    show BoolOperator, DateOperator, ValueOperator;

/// Unified query configuration for fetching projects.
///
/// Mirrors the `TaskQuery` pattern to provide a single place to define
/// filtering rules, sorting, and optional occurrence expansion.
///
/// Note: This currently reuses the existing rule types from `task_rules.dart`
/// (for example `BooleanRule`, `DateRule`, `ValueRule`) because the fields
/// map cleanly to the `Project` schema.
@immutable
class ProjectQuery {
  const ProjectQuery({
    this.filter = const QueryFilter<ProjectPredicate>.matchAll(),
    this.sortCriteria = const <SortCriterion>[],
    this.occurrenceExpansion,
  });

  factory ProjectQuery.fromJson(Map<String, dynamic> json) {
    return ProjectQuery(
      filter: QueryFilter.fromJson<ProjectPredicate>(
        json['filter'] as Map<String, dynamic>? ?? const <String, dynamic>{},
        ProjectPredicate.fromJson,
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
    );
  }

  // ========================================================================
  // Factory Methods
  // ========================================================================

  /// Factory: Single project by ID.
  factory ProjectQuery.byId(String projectId) {
    return ProjectQuery(
      filter: QueryFilter<ProjectPredicate>(
        shared: [ProjectIdPredicate(id: projectId)],
      ),
    );
  }

  /// Factory: All projects (no filtering).
  factory ProjectQuery.all({List<SortCriterion>? sortCriteria}) {
    return ProjectQuery(sortCriteria: sortCriteria ?? _defaultSortCriteria);
  }

  /// Factory: Incomplete projects only.
  factory ProjectQuery.incomplete({List<SortCriterion>? sortCriteria}) {
    return ProjectQuery(
      filter: const QueryFilter<ProjectPredicate>(
        shared: [
          ProjectBoolPredicate(
            field: ProjectBoolField.completed,
            operator: BoolOperator.isFalse,
          ),
        ],
      ),
      sortCriteria: sortCriteria ?? _defaultSortCriteria,
    );
  }

  /// Factory: Active projects (not completed) - alias for incomplete.
  factory ProjectQuery.active({List<SortCriterion>? sortCriteria}) {
    return ProjectQuery.incomplete(sortCriteria: sortCriteria);
  }

  /// Factory: Completed projects only.
  factory ProjectQuery.completed({List<SortCriterion>? sortCriteria}) {
    return ProjectQuery(
      filter: const QueryFilter<ProjectPredicate>(
        shared: [
          ProjectBoolPredicate(
            field: ProjectBoolField.completed,
            operator: BoolOperator.isTrue,
          ),
        ],
      ),
      sortCriteria: sortCriteria ?? _defaultSortCriteria,
    );
  }

  /// Factory: Projects with specific values.
  factory ProjectQuery.byValues(
    List<String> valueIds, {
    ValueMatchMode mode = ValueMatchMode.any,
    List<SortCriterion>? sortCriteria,
  }) {
    final valueOp = switch (mode) {
      ValueMatchMode.any => ValueOperator.hasAny,
      ValueMatchMode.all => ValueOperator.hasAll,
      ValueMatchMode.none => ValueOperator.isNull,
    };
    return ProjectQuery(
      filter: QueryFilter<ProjectPredicate>(
        shared: [
          ProjectValuePredicate(
            operator: valueOp,
            valueIds: valueIds,
          ),
        ],
      ),
      sortCriteria: sortCriteria ?? _defaultSortCriteria,
    );
  }

  /// Factory: Schedule view (incomplete projects with dates in range).
  ///
  /// Enables occurrence expansion over the range.
  factory ProjectQuery.schedule({
    required DateTime rangeStart,
    required DateTime rangeEnd,
    List<SortCriterion>? sortCriteria,
  }) {
    return ProjectQuery(
      filter: QueryFilter<ProjectPredicate>(
        shared: [
          const ProjectBoolPredicate(
            field: ProjectBoolField.completed,
            operator: BoolOperator.isFalse,
          ),
          ProjectDatePredicate(
            field: ProjectDateField.startDate,
            operator: DateOperator.between,
            startDate: rangeStart,
            endDate: rangeEnd,
          ),
        ],
      ),
      sortCriteria: sortCriteria ?? _defaultSortCriteria,
      occurrenceExpansion: OccurrenceExpansion(
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      ),
    );
  }

  /// Filtering predicates to apply.
  final QueryFilter<ProjectPredicate> filter;

  /// Sort criteria for ordering results.
  final List<SortCriterion> sortCriteria;

  /// Optional configuration for expanding repeating projects into occurrences.
  final OccurrenceExpansion? occurrenceExpansion;

  // ========================================================================
  // Helper Properties
  // ========================================================================

  /// Whether this query should expand repeating projects into occurrences.
  bool get shouldExpandOccurrences => occurrenceExpansion != null;

  /// Whether this query has any date-based filtering rules.
  bool get hasDateFilter {
    return filter.shared.any((p) => p is ProjectDatePredicate) ||
        filter.orGroups.expand((g) => g).any((p) => p is ProjectDatePredicate);
  }

  // ========================================================================
  // Equality & Hash
  // ========================================================================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProjectQuery &&
        other.filter == filter &&
        listEquals(other.sortCriteria, sortCriteria) &&
        other.occurrenceExpansion == occurrenceExpansion;
  }

  @override
  int get hashCode => Object.hash(
    filter,
    Object.hashAll(sortCriteria),
    occurrenceExpansion,
  );

  @override
  String toString() {
    return 'ProjectQuery(filter: $filter, sortCriteria: $sortCriteria, '
        'occurrenceExpansion: $occurrenceExpansion)';
  }

  // ========================================================================
  // JSON Serialization
  // ========================================================================

  Map<String, dynamic> toJson() => <String, dynamic>{
    'filter': filter.toJson((p) => p.toJson()),
    'sortCriteria': sortCriteria.map((s) => s.toJson()).toList(),
    'occurrenceExpansion': occurrenceExpansion?.toJson(),
  };

  static const _defaultSortCriteria = [
    SortCriterion(field: SortField.deadlineDate),
    SortCriterion(field: SortField.name),
  ];
}
