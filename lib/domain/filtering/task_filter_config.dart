import 'package:flutter/foundation.dart';
import 'package:taskly_bloc/core/shared/models/sort_preferences.dart';
import 'package:taskly_bloc/core/utils/date_only.dart';
import 'package:taskly_bloc/domain/filtering/filter_result_metadata.dart';
import 'package:taskly_bloc/domain/filtering/task_rules.dart';
import 'package:taskly_bloc/domain/label.dart';

/// Configuration for task filtering with pre-partitioned rules.
///
/// Rules are separated into SQL-expressible and Dart-only rules at
/// construction time to optimize database queries.
@immutable
class TaskFilterConfig {
  /// Creates a task filter configuration.
  const TaskFilterConfig({
    required this.sqlRules,
    required this.dartRules,
    this.sortCriteria = const [],
    this.withRelated = false,
    this.expandOccurrences = false,
    this.occurrenceRange,
  });

  /// Factory: Inbox view (incomplete tasks).
  factory TaskFilterConfig.inbox({
    List<SortCriterion>? sortCriteria,
  }) {
    return TaskFilterConfig.fromRules(
      rules: const [
        BooleanRule(
          field: BooleanRuleField.completed,
          operator: BooleanRuleOperator.isFalse,
        ),
      ],
      sortCriteria: sortCriteria ?? _defaultSortCriteria,
      withRelated: true,
    );
  }

  /// Factory: Today view (due or starting today or earlier, incomplete).
  factory TaskFilterConfig.today({
    required DateTime now,
    List<SortCriterion>? sortCriteria,
  }) {
    final today = dateOnly(now);
    return TaskFilterConfig.fromRules(
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
      withRelated: true,
    );
  }

  /// Factory: Upcoming view (incomplete, with deadlines).
  factory TaskFilterConfig.upcoming({
    List<SortCriterion>? sortCriteria,
  }) {
    return TaskFilterConfig.fromRules(
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
      withRelated: true,
    );
  }

  /// Factory: Project view (tasks in a specific project).
  factory TaskFilterConfig.forProject({
    required String projectId,
    List<SortCriterion>? sortCriteria,
  }) {
    return TaskFilterConfig.fromRules(
      rules: [
        ProjectRule(
          operator: ProjectRuleOperator.matches,
          projectId: projectId,
        ),
      ],
      sortCriteria: sortCriteria ?? _defaultSortCriteria,
      withRelated: true,
    );
  }

  /// Factory: Label view (tasks with a specific label).
  factory TaskFilterConfig.forLabel({
    required String labelId,
    LabelType labelType = LabelType.label,
    List<SortCriterion>? sortCriteria,
  }) {
    return TaskFilterConfig.fromRules(
      rules: [
        LabelRule(
          operator: LabelRuleOperator.hasAll,
          labelIds: [labelId],
          labelType: labelType,
        ),
      ],
      sortCriteria: sortCriteria ?? _defaultSortCriteria,
      withRelated: true,
    );
  }

  /// Factory: Next Actions view (incomplete, no project or is next action).
  factory TaskFilterConfig.nextActions({
    List<SortCriterion>? sortCriteria,
  }) {
    return TaskFilterConfig.fromRules(
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
      withRelated: true,
    );
  }

  /// Factory: All tasks (no filtering).
  factory TaskFilterConfig.all({
    List<SortCriterion>? sortCriteria,
  }) {
    return TaskFilterConfig.fromRules(
      rules: const [],
      sortCriteria: sortCriteria ?? _defaultSortCriteria,
      withRelated: true,
    );
  }

  /// Factory that partitions rules into SQL and Dart.
  factory TaskFilterConfig.fromRules({
    required List<TaskRule> rules,
    List<SortCriterion>? sortCriteria,
    bool withRelated = false,
    bool expandOccurrences = false,
    DateRange? occurrenceRange,
  }) {
    final partitioned = _partitionRules(rules);
    return TaskFilterConfig(
      sqlRules: partitioned.sqlRules,
      dartRules: partitioned.dartRules,
      sortCriteria: sortCriteria ?? const [],
      withRelated: withRelated,
      expandOccurrences: expandOccurrences,
      occurrenceRange: occurrenceRange,
    );
  }

  /// Rules that can be expressed in SQL.
  final List<TaskRule> sqlRules;

  /// Rules that must be evaluated in Dart.
  final List<TaskRule> dartRules;

  /// Sort criteria to apply.
  final List<SortCriterion> sortCriteria;

  /// Whether to include related entities (projects, labels).
  final bool withRelated;

  /// Whether to expand occurrences for repeating tasks.
  final bool expandOccurrences;

  /// Date range for occurrence expansion.
  final DateRange? occurrenceRange;

  /// All rules combined.
  List<TaskRule> get allRules => [...sqlRules, ...dartRules];

  /// Whether this config has any pending Dart-side operations.
  bool get requiresPostProcessing => dartRules.isNotEmpty;

  /// Default sort criteria.
  static const List<SortCriterion> _defaultSortCriteria = [
    SortCriterion(field: SortField.deadlineDate),
    SortCriterion(field: SortField.startDate),
    SortCriterion(field: SortField.name),
  ];

  /// Partitions rules into SQL-expressible and Dart-only.
  static _PartitionedRules _partitionRules(List<TaskRule> rules) {
    final sqlRules = <TaskRule>[];
    final dartRules = <TaskRule>[];

    for (final rule in rules) {
      if (_isSqlExpressible(rule)) {
        sqlRules.add(rule);
      } else {
        dartRules.add(rule);
      }
    }

    return _PartitionedRules(
      sqlRules: sqlRules,
      dartRules: dartRules,
    );
  }

  /// Determines if a rule can be expressed in SQL.
  ///
  /// SQL-expressible rules:
  /// - DateRule: All operators supported
  /// - BooleanRule: All operators supported
  /// - ProjectRule: All operators supported
  ///
  /// Dart-only rules:
  /// - LabelRule: Requires join operations not easily expressible
  /// - ValueRule: Requires join operations not easily expressible
  static bool _isSqlExpressible(TaskRule rule) {
    return switch (rule) {
      DateRule() => true,
      BooleanRule() => true,
      ProjectRule() => true,
      LabelRule() => false,
      ValueRule() => false,
      _ => false,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskFilterConfig &&
        _listEquals(other.sqlRules, sqlRules) &&
        _listEquals(other.dartRules, dartRules) &&
        _listEquals(other.sortCriteria, sortCriteria) &&
        other.withRelated == withRelated &&
        other.expandOccurrences == expandOccurrences &&
        other.occurrenceRange == occurrenceRange;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(sqlRules),
    Object.hashAll(dartRules),
    Object.hashAll(sortCriteria),
    withRelated,
    expandOccurrences,
    occurrenceRange,
  );
}

/// Internal class to hold partitioned rules.
class _PartitionedRules {
  const _PartitionedRules({
    required this.sqlRules,
    required this.dartRules,
  });

  final List<TaskRule> sqlRules;
  final List<TaskRule> dartRules;
}

bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
