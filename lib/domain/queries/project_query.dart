import 'package:flutter/foundation.dart';
import 'package:taskly_bloc/core/shared/models/sort_preferences.dart';
import 'package:taskly_bloc/domain/filtering/task_rules.dart';
import 'package:taskly_bloc/domain/queries/occurrence_expansion.dart';

/// Unified query configuration for fetching projects.
///
/// Mirrors the `TaskQuery` pattern to provide a single place to define
/// filtering rules, sorting, and optional occurrence expansion.
///
/// Note: This currently reuses the existing rule types from `task_rules.dart`
/// (for example `BooleanRule`, `DateRule`, `LabelRule`) because the fields
/// map cleanly to the `Project` schema.
@immutable
class ProjectQuery {
  const ProjectQuery({
    this.rules = const <TaskRule>[],
    this.sortCriteria = const <SortCriterion>[],
    this.occurrenceExpansion,
  });

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
      rules: const [
        BooleanRule(
          field: BooleanRuleField.completed,
          operator: BooleanRuleOperator.isFalse,
        ),
      ],
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
      rules: [
        const BooleanRule(
          field: BooleanRuleField.completed,
          operator: BooleanRuleOperator.isFalse,
        ),
        DateRule(
          field: DateRuleField.startDate,
          operator: DateRuleOperator.between,
          startDate: rangeStart,
          endDate: rangeEnd,
        ),
      ],
      sortCriteria: sortCriteria ?? _defaultSortCriteria,
      occurrenceExpansion: OccurrenceExpansion(
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      ),
    );
  }

  /// Filtering rules to apply (AND logic between rules).
  final List<TaskRule> rules;

  /// Sort criteria for ordering results.
  final List<SortCriterion> sortCriteria;

  /// Optional configuration for expanding repeating projects into occurrences.
  final OccurrenceExpansion? occurrenceExpansion;

  // ========================================================================
  // Helper Properties
  // ========================================================================

  /// Whether this query should expand repeating projects into occurrences.
  bool get shouldExpandOccurrences => occurrenceExpansion != null;

  // ========================================================================
  // Equality & Hash
  // ========================================================================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProjectQuery &&
        listEquals(other.rules, rules) &&
        listEquals(other.sortCriteria, sortCriteria) &&
        other.occurrenceExpansion == occurrenceExpansion;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(rules),
    Object.hashAll(sortCriteria),
    occurrenceExpansion,
  );

  @override
  String toString() {
    return 'ProjectQuery(rules: $rules, sortCriteria: $sortCriteria, '
        'occurrenceExpansion: $occurrenceExpansion)';
  }

  static const _defaultSortCriteria = [
    SortCriterion(field: SortField.deadlineDate),
    SortCriterion(field: SortField.name),
  ];
}
