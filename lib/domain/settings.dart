import 'package:flutter/foundation.dart';
import 'package:taskly_bloc/core/shared/models/sort_preferences.dart';
import 'package:taskly_bloc/domain/filtering/task_rules.dart';

/// Display settings for a specific page.
class PageDisplaySettings {
  const PageDisplaySettings({
    this.hideCompleted = true,
    this.completedSectionCollapsed = false,
    this.showNextActionsBanner = true,
  });

  factory PageDisplaySettings.fromJson(Map<String, dynamic> json) {
    return PageDisplaySettings(
      hideCompleted: json['hideCompleted'] as bool? ?? true,
      completedSectionCollapsed:
          json['completedSectionCollapsed'] as bool? ?? false,
      showNextActionsBanner: json['showNextActionsBanner'] as bool? ?? true,
    );
  }

  final bool hideCompleted;
  final bool completedSectionCollapsed;
  final bool showNextActionsBanner;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'hideCompleted': hideCompleted,
    'completedSectionCollapsed': completedSectionCollapsed,
    'showNextActionsBanner': showNextActionsBanner,
  };

  PageDisplaySettings copyWith({
    bool? hideCompleted,
    bool? completedSectionCollapsed,
    bool? showNextActionsBanner,
  }) {
    return PageDisplaySettings(
      hideCompleted: hideCompleted ?? this.hideCompleted,
      completedSectionCollapsed:
          completedSectionCollapsed ?? this.completedSectionCollapsed,
      showNextActionsBanner:
          showNextActionsBanner ?? this.showNextActionsBanner,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PageDisplaySettings &&
        other.hideCompleted == hideCompleted &&
        other.completedSectionCollapsed == completedSectionCollapsed &&
        other.showNextActionsBanner == showNextActionsBanner;
  }

  @override
  int get hashCode => Object.hash(
    hideCompleted,
    completedSectionCollapsed,
    showNextActionsBanner,
  );
}

class AppSettings {
  const AppSettings({
    this.pageSortPreferences = const <String, SortPreferences>{},
    this.pageDisplaySettings = const <String, PageDisplaySettings>{},
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

    final rawDisplaySettings =
        json['pageDisplaySettings'] as Map<String, dynamic>?;
    final displaySettings = <String, PageDisplaySettings>{};
    rawDisplaySettings?.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        displaySettings[key] = PageDisplaySettings.fromJson(value);
      }
    });

    final nextActionsJson = json['nextActions'] as Map<String, dynamic>?;
    final nextActions = nextActionsJson == null
        ? NextActionsSettings.withDefaults()
        : NextActionsSettings.fromJson(nextActionsJson);
    return AppSettings(
      pageSortPreferences: sorts,
      pageDisplaySettings: displaySettings,
      nextActions: nextActions,
    );
  }

  final Map<String, SortPreferences> pageSortPreferences;
  final Map<String, PageDisplaySettings> pageDisplaySettings;
  final NextActionsSettings nextActions;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'pageSortPreferences': pageSortPreferences.map(
      (key, value) => MapEntry(key, value.toJson()),
    ),
    'pageDisplaySettings': pageDisplaySettings.map(
      (key, value) => MapEntry(key, value.toJson()),
    ),
    'nextActions': nextActions.toJson(),
  };

  AppSettings copyWith({
    Map<String, SortPreferences>? pageSortPreferences,
    Map<String, PageDisplaySettings>? pageDisplaySettings,
    NextActionsSettings? nextActions,
  }) {
    return AppSettings(
      pageSortPreferences: pageSortPreferences ?? this.pageSortPreferences,
      pageDisplaySettings: pageDisplaySettings ?? this.pageDisplaySettings,
      nextActions: nextActions ?? this.nextActions,
    );
  }

  SortPreferences? sortFor(String pageKey) => pageSortPreferences[pageKey];

  PageDisplaySettings displaySettingsFor(String pageKey) =>
      pageDisplaySettings[pageKey] ?? const PageDisplaySettings();

  AppSettings upsertPageSort({
    required String pageKey,
    required SortPreferences preferences,
  }) {
    final updated = Map<String, SortPreferences>.from(pageSortPreferences)
      ..[pageKey] = preferences;
    return copyWith(pageSortPreferences: updated);
  }

  AppSettings upsertPageDisplaySettings({
    required String pageKey,
    required PageDisplaySettings settings,
  }) {
    final updated = Map<String, PageDisplaySettings>.from(pageDisplaySettings)
      ..[pageKey] = settings;
    return copyWith(pageDisplaySettings: updated);
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
    if (other.pageDisplaySettings.length != pageDisplaySettings.length) {
      return false;
    }
    for (final entry in pageDisplaySettings.entries) {
      final otherValue = other.pageDisplaySettings[entry.key];
      if (otherValue != entry.value) return false;
    }
    return other.nextActions == nextActions;
  }

  @override
  int get hashCode => Object.hash(
    pageSortPreferences.entries
        .map((e) => Object.hash(e.key, e.value))
        .fold<int>(0, (prev, element) => prev ^ element.hashCode),
    pageDisplaySettings.entries
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
        listEquals(other.bucketRules, bucketRules);
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
