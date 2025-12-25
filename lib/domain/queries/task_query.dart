import 'package:flutter/foundation.dart';
import 'package:taskly_bloc/core/shared/models/sort_preferences.dart';
import 'package:taskly_bloc/core/utils/date_only.dart';
import 'package:taskly_bloc/domain/filtering/task_rules.dart';
import 'package:taskly_bloc/domain/label.dart';
import 'package:taskly_bloc/domain/queries/occurrence_expansion.dart';

/// Unified query configuration for fetching tasks with filtering, sorting, and occurrence expansion.
///
/// Replaces TaskFilterConfig with a simpler, more explicit API that supports
/// 100% database-level filtering via SQL expressions.
@immutable
class TaskQuery {
  const TaskQuery({
    this.rules = const [],
    this.sortCriteria = const [],
    this.occurrenceExpansion,
  });

  // ========================================================================
  // Factory Methods
  // ========================================================================

  /// Factory: Inbox view (incomplete tasks only).
  factory TaskQuery.inbox({List<SortCriterion>? sortCriteria}) {
    return TaskQuery(
      rules: const [
        BooleanRule(
          field: BooleanRuleField.completed,
          operator: BooleanRuleOperator.isFalse,
        ),
      ],
      sortCriteria: sortCriteria ?? _defaultSortCriteria,
    );
  }

  /// Factory: Today view (due today or earlier, incomplete).
  factory TaskQuery.today({
    required DateTime now,
    List<SortCriterion>? sortCriteria,
  }) {
    final today = dateOnly(now);
    return TaskQuery(
      rules: [
        const BooleanRule(
          field: BooleanRuleField.completed,
          operator: BooleanRuleOperator.isFalse,
        ),
        DateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.onOrBefore,
          date: today,
        ),
      ],
      sortCriteria: sortCriteria ?? _defaultSortCriteria,
    );
  }

  /// Factory: Upcoming view (incomplete tasks with deadlines).
  factory TaskQuery.upcoming({List<SortCriterion>? sortCriteria}) {
    return TaskQuery(
      rules: const [
        BooleanRule(
          field: BooleanRuleField.completed,
          operator: BooleanRuleOperator.isFalse,
        ),
        DateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.isNotNull,
        ),
      ],
      sortCriteria: sortCriteria ?? _defaultSortCriteria,
    );
  }

  /// Factory: Project view (tasks in a specific project).
  factory TaskQuery.forProject({
    required String projectId,
    List<SortCriterion>? sortCriteria,
  }) {
    return TaskQuery(
      rules: [
        ProjectRule(
          operator: ProjectRuleOperator.matches,
          projectId: projectId,
        ),
      ],
      sortCriteria: sortCriteria ?? _defaultSortCriteria,
    );
  }

  /// Factory: Label view (tasks with a specific label).
  factory TaskQuery.forLabel({
    required String labelId,
    LabelType labelType = LabelType.label,
    List<SortCriterion>? sortCriteria,
  }) {
    return TaskQuery(
      rules: [
        LabelRule(
          operator: LabelRuleOperator.hasAll,
          labelIds: [labelId],
          labelType: labelType,
        ),
      ],
      sortCriteria: sortCriteria ?? _defaultSortCriteria,
    );
  }

  /// Factory: Next Actions view (incomplete, no project).
  factory TaskQuery.nextActions({List<SortCriterion>? sortCriteria}) {
    return TaskQuery(
      rules: const [
        BooleanRule(
          field: BooleanRuleField.completed,
          operator: BooleanRuleOperator.isFalse,
        ),
        ProjectRule(
          operator: ProjectRuleOperator.isNull,
        ),
      ],
      sortCriteria: sortCriteria ?? _defaultSortCriteria,
    );
  }

  /// Factory: Schedule view (incomplete tasks with start or due dates in range).
  factory TaskQuery.schedule({
    required DateTime rangeStart,
    required DateTime rangeEnd,
    List<SortCriterion>? sortCriteria,
  }) {
    return TaskQuery(
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

  /// Factory: All tasks (no filtering).
  factory TaskQuery.all({List<SortCriterion>? sortCriteria}) {
    return TaskQuery(
      sortCriteria: sortCriteria ?? _defaultSortCriteria,
    );
  }

  /// Filtering rules to apply (AND logic between rules).
  final List<TaskRule> rules;

  /// Sort criteria for ordering results.
  final List<SortCriterion> sortCriteria;

  /// Optional configuration for expanding repeating tasks into occurrences.
  final OccurrenceExpansion? occurrenceExpansion;

  // ========================================================================
  // Helper Properties
  // ========================================================================

  /// Whether this query requires label data to be loaded.
  bool get needsLabels {
    return rules.any((rule) => rule is LabelRule);
  }

  /// Whether this query should expand repeating tasks into occurrences.
  bool get shouldExpandOccurrences => occurrenceExpansion != null;

  /// Whether this query filters by project.
  bool get hasProjectFilter {
    return rules.any((rule) => rule is ProjectRule);
  }

  /// Whether this query has any date-based filtering rules.
  bool get hasDateFilter {
    return rules.any((rule) => rule is DateRule);
  }

  // ========================================================================
  // Modification Methods
  // ========================================================================

  TaskQuery copyWith({
    List<TaskRule>? rules,
    List<SortCriterion>? sortCriteria,
    OccurrenceExpansion? occurrenceExpansion,
    bool clearOccurrenceExpansion = false,
  }) {
    return TaskQuery(
      rules: rules ?? this.rules,
      sortCriteria: sortCriteria ?? this.sortCriteria,
      occurrenceExpansion: clearOccurrenceExpansion
          ? null
          : (occurrenceExpansion ?? this.occurrenceExpansion),
    );
  }

  /// Creates a copy with additional rules added.
  TaskQuery withAdditionalRules(List<TaskRule> additionalRules) {
    return copyWith(
      rules: [...rules, ...additionalRules],
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

  // ========================================================================
  // Equality & Hash
  // ========================================================================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskQuery &&
        _listEquals(other.rules, rules) &&
        _listEquals(other.sortCriteria, sortCriteria) &&
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
    return 'TaskQuery(rules: $rules, sortCriteria: $sortCriteria, '
        'occurrenceExpansion: $occurrenceExpansion)';
  }

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
