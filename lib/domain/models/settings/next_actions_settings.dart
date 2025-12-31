import 'package:collection/collection.dart';
import 'package:taskly_bloc/domain/filtering/task_rules.dart';
import 'package:taskly_bloc/domain/models/sort_preferences.dart';

class NextActionsSettings {
  const NextActionsSettings({
    this.tasksPerProject = 2,
    this.bucketRules = const <TaskPriorityBucketRule>[],
    this.includeInboxTasks = true,
    this.excludeFutureStartDates = true,
    this.sortPreferences = const SortPreferences(),
  });

  /// Creates settings with default bucket rules applied if none provided.
  factory NextActionsSettings.withDefaults({
    int? tasksPerProject,
    List<TaskPriorityBucketRule>? bucketRules,
    bool? includeInboxTasks,
    bool? excludeFutureStartDates,
    SortPreferences? sortPreferences,
  }) {
    return NextActionsSettings(
      tasksPerProject: tasksPerProject ?? 2,
      bucketRules: bucketRules ?? defaultBucketRules,
      includeInboxTasks: includeInboxTasks ?? true,
      excludeFutureStartDates: excludeFutureStartDates ?? true,
      sortPreferences: sortPreferences ?? const SortPreferences(),
    );
  }

  factory NextActionsSettings.fromJson(Map<String, dynamic> json) {
    final tasksPerProject = json['tasksPerProject'] as int?;
    final rawBucketRules = json['bucketRules'] as List<dynamic>?;
    final bucketRules = (rawBucketRules ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(TaskPriorityBucketRule.fromJson)
        .toList(growable: false);

    return NextActionsSettings(
      tasksPerProject: tasksPerProject == null || tasksPerProject < 1
          ? 1
          : tasksPerProject,
      bucketRules: bucketRules,
      includeInboxTasks: json['includeInboxTasks'] as bool? ?? true,
      excludeFutureStartDates: json['excludeFutureStartDates'] as bool? ?? true,
      sortPreferences: json['sortPreferences'] == null
          ? const SortPreferences()
          : SortPreferences.fromJson(
              json['sortPreferences'] as Map<String, dynamic>,
            ),
    );
  }

  static List<TaskPriorityBucketRule> get defaultBucketRules => [
    TaskPriorityBucketRule(
      priority: 1,
      name: 'Upcoming deadline with no start date',
      ruleSets: [
        TaskRuleSet(
          operator: RuleSetOperator.and,
          rules: const [
            DateRule(
              field: DateRuleField.deadlineDate,
              operator: DateRuleOperator.relative,
              relativeComparison: RelativeComparison.onOrAfter,
              relativeDays: 1,
            ),
            DateRule(
              field: DateRuleField.deadlineDate,
              operator: DateRuleOperator.relative,
              relativeComparison: RelativeComparison.onOrBefore,
              relativeDays: 90,
            ),
            DateRule(
              field: DateRuleField.startDate,
              operator: DateRuleOperator.isNull,
            ),
          ],
        ),
      ],
      sortCriterion: const SortCriterion(field: SortField.deadlineDate),
    ),
    TaskPriorityBucketRule(
      priority: 2,
      name: 'Unscheduled and 30+ days old without updates',
      ruleSets: [
        TaskRuleSet(
          operator: RuleSetOperator.and,
          rules: const [
            DateRule(
              field: DateRuleField.updatedAt,
              operator: DateRuleOperator.relative,
              relativeComparison: RelativeComparison.before,
              relativeDays: -30,
            ),
            DateRule(
              field: DateRuleField.startDate,
              operator: DateRuleOperator.isNull,
            ),
            DateRule(
              field: DateRuleField.deadlineDate,
              operator: DateRuleOperator.isNull,
            ),
          ],
        ),
      ],
      sortCriterion: const SortCriterion(field: SortField.updatedDate),
    ),
    TaskPriorityBucketRule(
      priority: 3,
      name: 'Unscheduled tasks',
      ruleSets: [
        TaskRuleSet(
          operator: RuleSetOperator.and,
          rules: const [
            DateRule(
              field: DateRuleField.deadlineDate,
              operator: DateRuleOperator.isNull,
            ),
            DateRule(
              field: DateRuleField.startDate,
              operator: DateRuleOperator.isNull,
            ),
          ],
        ),
      ],
      sortCriterion: const SortCriterion(field: SortField.name),
    ),
  ];

  final int tasksPerProject;
  final List<TaskPriorityBucketRule> bucketRules;
  final bool includeInboxTasks;
  final bool excludeFutureStartDates;
  final SortPreferences sortPreferences;

  /// Returns the effective bucket rules, using defaults if none are configured.
  List<TaskPriorityBucketRule> get effectiveBucketRules =>
      bucketRules.isEmpty ? defaultBucketRules : bucketRules;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'tasksPerProject': tasksPerProject,
    'bucketRules': bucketRules.map((rule) => rule.toJson()).toList(),
    'includeInboxTasks': includeInboxTasks,
    'excludeFutureStartDates': excludeFutureStartDates,
    'sortPreferences': sortPreferences.toJson(),
  };

  NextActionsSettings copyWith({
    int? tasksPerProject,
    List<TaskPriorityBucketRule>? bucketRules,
    bool? includeInboxTasks,
    bool? excludeFutureStartDates,
    SortPreferences? sortPreferences,
  }) {
    return NextActionsSettings(
      tasksPerProject: tasksPerProject ?? this.tasksPerProject,
      bucketRules: bucketRules ?? this.bucketRules,
      includeInboxTasks: includeInboxTasks ?? this.includeInboxTasks,
      excludeFutureStartDates:
          excludeFutureStartDates ?? this.excludeFutureStartDates,
      sortPreferences: sortPreferences ?? this.sortPreferences,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is NextActionsSettings &&
        other.tasksPerProject == tasksPerProject &&
        other.includeInboxTasks == includeInboxTasks &&
        other.excludeFutureStartDates == excludeFutureStartDates &&
        other.sortPreferences == sortPreferences &&
        const ListEquality<TaskPriorityBucketRule>().equals(
          other.bucketRules,
          bucketRules,
        );
  }

  @override
  int get hashCode => Object.hash(
    tasksPerProject,
    includeInboxTasks,
    excludeFutureStartDates,
    sortPreferences,
    Object.hashAll(bucketRules),
  );
}
