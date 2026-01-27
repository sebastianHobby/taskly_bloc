import 'package:flutter/foundation.dart';
import 'package:taskly_domain/src/preferences/model/sort_preferences.dart';
import 'package:taskly_domain/src/queries/value_match_mode.dart';
import 'package:taskly_domain/src/queries/occurrence_expansion.dart';
import 'package:taskly_domain/src/queries/occurrence_preview.dart';
import 'package:taskly_domain/src/queries/project_predicate.dart';
import 'package:taskly_domain/src/queries/query_filter.dart';
import 'package:taskly_domain/src/queries/task_predicate.dart'
    show BoolOperator, ValueOperator;

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
    this.occurrencePreview,
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

  /// Filtering predicates to apply.
  final QueryFilter<ProjectPredicate> filter;

  /// Sort criteria for ordering results.
  final List<SortCriterion> sortCriteria;

  /// Optional configuration for expanding repeating projects into occurrences.
  final OccurrenceExpansion? occurrenceExpansion;

  /// Optional configuration for previewing the next (single) occurrence.
  ///
  /// This is mutually exclusive with [occurrenceExpansion].
  final OccurrencePreview? occurrencePreview;

  // ========================================================================
  // Helper Properties
  // ========================================================================

  /// Whether this query should expand repeating projects into occurrences.
  bool get shouldExpandOccurrences => occurrenceExpansion != null;

  /// Whether this query should compute a single next occurrence preview.
  bool get hasOccurrencePreview => occurrencePreview != null;

  /// Whether this query has any date-based filtering rules.
  bool get hasDateFilter {
    return filter.shared.any((p) => p is ProjectDatePredicate) ||
        filter.orGroups.expand((g) => g).any((p) => p is ProjectDatePredicate);
  }

  // ========================================================================
  // Modification Methods
  // ========================================================================

  ProjectQuery copyWith({
    QueryFilter<ProjectPredicate>? filter,
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
      'ProjectQuery cannot set both occurrenceExpansion and occurrencePreview.',
    );

    return ProjectQuery(
      filter: filter ?? this.filter,
      sortCriteria: sortCriteria ?? this.sortCriteria,
      occurrenceExpansion: nextOccurrenceExpansion,
      occurrencePreview: nextOccurrencePreview,
    );
  }

  /// Creates a copy with additional shared predicates added.
  ProjectQuery withAdditionalPredicates(List<ProjectPredicate> predicates) {
    return copyWith(
      filter: filter.copyWith(shared: [...filter.shared, ...predicates]),
    );
  }

  /// Creates a copy with occurrence expansion enabled.
  ProjectQuery withOccurrenceExpansion(OccurrenceExpansion expansion) {
    return copyWith(occurrenceExpansion: expansion);
  }

  /// Creates a copy with occurrence preview enabled.
  ProjectQuery withOccurrencePreview(OccurrencePreview preview) {
    return copyWith(occurrencePreview: preview);
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
    return 'ProjectQuery(filter: $filter, sortCriteria: $sortCriteria, '
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

  static const _defaultSortCriteria = [
    SortCriterion(field: SortField.deadlineDate),
    SortCriterion(field: SortField.name),
  ];
}
