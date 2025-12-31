import 'package:flutter/foundation.dart';
import 'package:taskly_bloc/domain/models/sort_preferences.dart';
import 'package:taskly_bloc/core/utils/date_only.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/queries/occurrence_expansion.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart';

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
  });

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

  /// Factory: Today view (due today or earlier, incomplete).
  factory TaskQuery.today({
    required DateTime now,
    List<SortCriterion>? sortCriteria,
  }) {
    final today = dateOnly(now);
    return TaskQuery(
      filter: QueryFilter<TaskPredicate>(
        shared: [
          const TaskBoolPredicate(
            field: TaskBoolField.completed,
            operator: BoolOperator.isFalse,
          ),
          TaskDatePredicate(
            field: TaskDateField.deadlineDate,
            operator: DateOperator.onOrBefore,
            date: today,
          ),
        ],
      ),
      sortCriteria: sortCriteria ?? _defaultSortCriteria,
    );
  }

  /// Factory: Upcoming view (incomplete tasks with deadlines).
  factory TaskQuery.upcoming({List<SortCriterion>? sortCriteria}) {
    return TaskQuery(
      filter: const QueryFilter<TaskPredicate>(
        shared: [
          TaskBoolPredicate(
            field: TaskBoolField.completed,
            operator: BoolOperator.isFalse,
          ),
          TaskDatePredicate(
            field: TaskDateField.deadlineDate,
            operator: DateOperator.isNotNull,
          ),
        ],
      ),
      sortCriteria: sortCriteria ?? _defaultSortCriteria,
    );
  }

  /// Factory: Project view (tasks in a specific project).
  factory TaskQuery.forProject({
    required String projectId,
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

  /// Factory: Label view (tasks with a specific label).
  factory TaskQuery.forLabel({
    required String labelId,
    LabelType labelType = LabelType.label,
    List<SortCriterion>? sortCriteria,
  }) {
    return TaskQuery(
      filter: QueryFilter<TaskPredicate>(
        shared: [
          TaskLabelPredicate(
            operator: LabelOperator.hasAll,
            labelIds: [labelId],
            labelType: labelType,
          ),
        ],
      ),
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
      filter: QueryFilter<TaskPredicate>(
        shared: [
          const TaskBoolPredicate(
            field: TaskBoolField.completed,
            operator: BoolOperator.isFalse,
          ),
          TaskDatePredicate(
            field: TaskDateField.startDate,
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

  /// Factory: All tasks (no filtering).
  factory TaskQuery.all({List<SortCriterion>? sortCriteria}) {
    return TaskQuery(
      sortCriteria: sortCriteria ?? _defaultSortCriteria,
    );
  }

  /// Filtering predicates to apply.
  final QueryFilter<TaskPredicate> filter;

  /// Sort criteria for ordering results.
  final List<SortCriterion> sortCriteria;

  /// Optional configuration for expanding repeating tasks into occurrences.
  final OccurrenceExpansion? occurrenceExpansion;

  // ========================================================================
  // Helper Properties
  // ========================================================================

  /// Whether this query requires label data to be loaded.
  bool get needsLabels {
    return filter.shared.any((p) => p is TaskLabelPredicate) ||
        filter.orGroups.expand((g) => g).any((p) => p is TaskLabelPredicate);
  }

  /// Whether this query should expand repeating tasks into occurrences.
  bool get shouldExpandOccurrences => occurrenceExpansion != null;

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
  }) {
    return TaskQuery(
      filter: filter ?? this.filter,
      sortCriteria: sortCriteria ?? this.sortCriteria,
      occurrenceExpansion: clearOccurrenceExpansion
          ? null
          : (occurrenceExpansion ?? this.occurrenceExpansion),
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

  // ========================================================================
  // Equality & Hash
  // ========================================================================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskQuery &&
        other.filter == filter &&
        _listEquals(other.sortCriteria, sortCriteria) &&
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
    return 'TaskQuery(filter: $filter, sortCriteria: $sortCriteria, '
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
