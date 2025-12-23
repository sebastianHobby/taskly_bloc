import 'package:flutter/foundation.dart';
import 'package:taskly_bloc/core/shared/models/sort_preferences.dart';
import 'package:taskly_bloc/features/tasks/utils/task_selector.dart';

class AppSettings {
  const AppSettings({
    this.pageSortPreferences = const <String, SortPreferences>{},
    NextActionsSettings? nextActions,
  }) : nextActions = nextActions ?? const NextActionsSettings();

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final rawSorts = json['pageSortPreferences'] as Map<String, dynamic>?;
    final sorts = <String, SortPreferences>{};
    rawSorts?.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        sorts[key] = SortPreferences.fromJson(value);
      }
    });
    final nextActionsJson = json['nextActions'] as Map<String, dynamic>?;
    final nextActions = nextActionsJson == null
        ? NextActionsSettings.withDefaults()
        : NextActionsSettings.fromJson(nextActionsJson);
    return AppSettings(
      pageSortPreferences: sorts,
      nextActions: nextActions,
    );
  }

  final Map<String, SortPreferences> pageSortPreferences;
  final NextActionsSettings nextActions;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'pageSortPreferences': pageSortPreferences.map(
      (key, value) => MapEntry(key, value.toJson()),
    ),
    'nextActions': nextActions.toJson(),
  };

  AppSettings copyWith({
    Map<String, SortPreferences>? pageSortPreferences,
    NextActionsSettings? nextActions,
  }) {
    return AppSettings(
      pageSortPreferences: pageSortPreferences ?? this.pageSortPreferences,
      nextActions: nextActions ?? this.nextActions,
    );
  }

  SortPreferences? sortFor(String pageKey) => pageSortPreferences[pageKey];

  AppSettings upsertPageSort({
    required String pageKey,
    required SortPreferences preferences,
  }) {
    final updated = Map<String, SortPreferences>.from(pageSortPreferences)
      ..[pageKey] = preferences;
    return copyWith(pageSortPreferences: updated);
  }

  AppSettings updateNextActions(NextActionsSettings value) {
    return copyWith(nextActions: value);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AppSettings) return false;
    if (other.pageSortPreferences.length != pageSortPreferences.length) {
      return false;
    }
    for (final entry in pageSortPreferences.entries) {
      final otherValue = other.pageSortPreferences[entry.key];
      if (otherValue != entry.value) return false;
    }
    return other.nextActions == nextActions;
  }

  @override
  int get hashCode => Object.hash(
    pageSortPreferences.entries
        .map((e) => Object.hash(e.key, e.value))
        .fold<int>(0, (prev, element) => prev ^ element.hashCode),
    nextActions,
  );
}

/// Keys for persisted page-specific settings.
class SettingsPageKey {
  static const inbox = 'inbox';
  static const today = 'today';
  static const upcoming = 'upcoming';
  static const tasks = 'tasks';
  static const projects = 'projects';
  static const labels = 'labels';
  static const values = 'values';
  static const nextActions = 'nextActions';
}

class NextActionsSettings {
  const NextActionsSettings({
    this.tasksPerProject = 2,
    this.bucketRules = const <TaskPriorityBucketRule>[],
    this.includeInboxTasks = false,
    this.sortPreferences = const SortPreferences(),
  });

  /// Creates settings with default bucket rules applied if none provided.
  factory NextActionsSettings.withDefaults({
    int? tasksPerProject,
    List<TaskPriorityBucketRule>? bucketRules,
    bool? includeInboxTasks,
    SortPreferences? sortPreferences,
  }) {
    return NextActionsSettings(
      tasksPerProject: tasksPerProject ?? 2,
      bucketRules: bucketRules ?? defaultBucketRules,
      includeInboxTasks: includeInboxTasks ?? false,
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
      includeInboxTasks: json['includeInboxTasks'] as bool? ?? false,
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
  final SortPreferences sortPreferences;

  /// Returns the effective bucket rules, using defaults if none are configured.
  List<TaskPriorityBucketRule> get effectiveBucketRules =>
      bucketRules.isEmpty ? defaultBucketRules : bucketRules;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'tasksPerProject': tasksPerProject,
    'bucketRules': bucketRules.map((rule) => rule.toJson()).toList(),
    'includeInboxTasks': includeInboxTasks,
    'sortPreferences': sortPreferences.toJson(),
  };

  NextActionsSettings copyWith({
    int? tasksPerProject,
    List<TaskPriorityBucketRule>? bucketRules,
    bool? includeInboxTasks,
    SortPreferences? sortPreferences,
  }) {
    return NextActionsSettings(
      tasksPerProject: tasksPerProject ?? this.tasksPerProject,
      bucketRules: bucketRules ?? this.bucketRules,
      includeInboxTasks: includeInboxTasks ?? this.includeInboxTasks,
      sortPreferences: sortPreferences ?? this.sortPreferences,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is NextActionsSettings &&
        other.tasksPerProject == tasksPerProject &&
        other.includeInboxTasks == includeInboxTasks &&
        other.sortPreferences == sortPreferences &&
        listEquals(other.bucketRules, bucketRules);
  }

  @override
  int get hashCode => Object.hash(
    tasksPerProject,
    includeInboxTasks,
    sortPreferences,
    Object.hashAll(bucketRules),
  );
}
