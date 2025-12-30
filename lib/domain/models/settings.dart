import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/domain/models/sort_preferences.dart';
import 'package:taskly_bloc/domain/filtering/task_rules.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';

/// Common date format patterns for use with intl DateFormat.
/// These follow the ICU date format patterns.
class DateFormatPatterns {
  static const String short = 'yMd'; // 12/30/2025
  static const String medium = 'yMMMd'; // Dec 30, 2025
  static const String long = 'yMMMMd'; // December 30, 2025
  static const String full = 'yMMMMEEEEd'; // Monday, December 30, 2025

  static const String defaultPattern = medium;

  /// Get localized DateFormat for the given pattern and locale
  static DateFormat getFormat(String pattern, [String? locale]) {
    try {
      return DateFormat(pattern, locale);
    } catch (e) {
      // Fallback to default pattern if invalid
      return DateFormat(defaultPattern, locale);
    }
  }
}

/// Global application settings
class GlobalSettings {
  const GlobalSettings({
    this.themeMode = ThemeMode.system,
    this.colorSchemeSeed = _defaultSeedColor,
    this.locale,
    this.dateFormatPattern = DateFormatPatterns.defaultPattern,
    this.textScaleFactor = 1.0,
    this.onboardingCompleted = false,
  });

  factory GlobalSettings.fromJson(Map<String, dynamic> json) {
    return GlobalSettings(
      themeMode: ThemeMode.values.firstWhere(
        (e) => e.name == json['themeMode'],
        orElse: () => ThemeMode.system,
      ),
      colorSchemeSeed: ColorUtils.fromHex(
        json['colorSchemeSeed'] as String?,
        fallback: _defaultSeedColor,
      ),
      locale: json['locale'] != null ? Locale(json['locale'] as String) : null,
      dateFormatPattern:
          json['dateFormatPattern'] as String? ??
          DateFormatPatterns.defaultPattern,
      textScaleFactor: (json['textScaleFactor'] as num?)?.toDouble() ?? 1.0,
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
    );
  }

  static const Color _defaultSeedColor = Color(0xFF6750A4);

  final ThemeMode themeMode;
  final Color colorSchemeSeed;
  final Locale? locale;

  /// ICU date format pattern (e.g., 'yMd', 'yMMMd', 'yMMMMd')
  final String dateFormatPattern;
  final double textScaleFactor;
  final bool onboardingCompleted;

  /// Get a DateFormat instance for this settings' pattern and locale
  DateFormat getDateFormat() {
    return DateFormatPatterns.getFormat(
      dateFormatPattern,
      locale?.languageCode,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'themeMode': themeMode.name,
    'colorSchemeSeed': ColorUtils.toHexWithHash(colorSchemeSeed),
    'locale': locale?.languageCode,
    'dateFormatPattern': dateFormatPattern,
    'textScaleFactor': textScaleFactor,
    'onboardingCompleted': onboardingCompleted,
  };

  GlobalSettings copyWith({
    ThemeMode? themeMode,
    Color? colorSchemeSeed,
    Locale? locale,
    String? dateFormatPattern,
    double? textScaleFactor,
    bool? onboardingCompleted,
  }) {
    return GlobalSettings(
      themeMode: themeMode ?? this.themeMode,
      colorSchemeSeed: colorSchemeSeed ?? this.colorSchemeSeed,
      locale: locale ?? this.locale,
      dateFormatPattern: dateFormatPattern ?? this.dateFormatPattern,
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GlobalSettings &&
        other.themeMode == themeMode &&
        other.colorSchemeSeed == colorSchemeSeed &&
        other.locale == locale &&
        other.dateFormatPattern == dateFormatPattern &&
        other.textScaleFactor == textScaleFactor &&
        other.onboardingCompleted == onboardingCompleted;
  }

  @override
  int get hashCode => Object.hash(
    themeMode,
    colorSchemeSeed,
    locale,
    dateFormatPattern,
    textScaleFactor,
    onboardingCompleted,
  );
}

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
    this.global = const GlobalSettings(),
    this.pageSortPreferences = const <String, SortPreferences>{},
    this.pageDisplaySettings = const <String, PageDisplaySettings>{},
    SoftGatesSettings? softGates,
    NextActionsSettings? nextActions,
  }) : softGates = softGates ?? const SoftGatesSettings(),
       nextActions = nextActions ?? const NextActionsSettings();

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final globalJson = json['global'] as Map<String, dynamic>?;
    final global = globalJson != null
        ? GlobalSettings.fromJson(globalJson)
        : const GlobalSettings();

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

    final softGatesJson = json['softGates'] as Map<String, dynamic>?;
    final softGates = softGatesJson == null
        ? const SoftGatesSettings()
        : SoftGatesSettings.fromJson(softGatesJson);
    return AppSettings(
      global: global,
      pageSortPreferences: sorts,
      pageDisplaySettings: displaySettings,
      softGates: softGates,
      nextActions: nextActions,
    );
  }

  final GlobalSettings global;
  final Map<String, SortPreferences> pageSortPreferences;
  final Map<String, PageDisplaySettings> pageDisplaySettings;
  final SoftGatesSettings softGates;
  final NextActionsSettings nextActions;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'global': global.toJson(),
    'pageSortPreferences': pageSortPreferences.map(
      (key, value) => MapEntry(key, value.toJson()),
    ),
    'pageDisplaySettings': pageDisplaySettings.map(
      (key, value) => MapEntry(key, value.toJson()),
    ),
    'softGates': softGates.toJson(),
    'nextActions': nextActions.toJson(),
  };

  AppSettings copyWith({
    GlobalSettings? global,
    Map<String, SortPreferences>? pageSortPreferences,
    Map<String, PageDisplaySettings>? pageDisplaySettings,
    SoftGatesSettings? softGates,
    NextActionsSettings? nextActions,
  }) {
    return AppSettings(
      global: global ?? this.global,
      pageSortPreferences: pageSortPreferences ?? this.pageSortPreferences,
      pageDisplaySettings: pageDisplaySettings ?? this.pageDisplaySettings,
      softGates: softGates ?? this.softGates,
      nextActions: nextActions ?? this.nextActions,
    );
  }

  AppSettings updateGlobal(GlobalSettings value) {
    return copyWith(global: value);
  }

  AppSettings updateSoftGates(SoftGatesSettings value) {
    return copyWith(softGates: value);
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
    return other.softGates == softGates && other.nextActions == nextActions;
  }

  @override
  int get hashCode => Object.hash(
    pageSortPreferences.entries
        .map((e) => Object.hash(e.key, e.value))
        .fold<int>(0, (prev, element) => prev ^ element.hashCode),
    pageDisplaySettings.entries
        .map((e) => Object.hash(e.key, e.value))
        .fold<int>(0, (prev, element) => prev ^ element.hashCode),
    softGates,
    nextActions,
  );
}

/// Settings controlling workflow-run soft gates (warnings).
class SoftGatesSettings {
  const SoftGatesSettings({
    this.urgentDeadlineWithinDays = 7,
    this.staleAfterDaysWithoutUpdates = 30,
  });

  factory SoftGatesSettings.fromJson(Map<String, dynamic> json) {
    int clampPositiveInt(Object? value, int fallback) {
      final parsed = value is int ? value : (value is num ? value.toInt() : 0);
      if (parsed <= 0) return fallback;
      return parsed;
    }

    return SoftGatesSettings(
      urgentDeadlineWithinDays: clampPositiveInt(
        json['urgentDeadlineWithinDays'],
        7,
      ),
      staleAfterDaysWithoutUpdates: clampPositiveInt(
        json['staleAfterDaysWithoutUpdates'],
        30,
      ),
    );
  }

  /// A task is urgent when its deadline is due within this many days
  /// (or overdue).
  final int urgentDeadlineWithinDays;

  /// A task is stale when it has not been updated within this many days.
  final int staleAfterDaysWithoutUpdates;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'urgentDeadlineWithinDays': urgentDeadlineWithinDays,
    'staleAfterDaysWithoutUpdates': staleAfterDaysWithoutUpdates,
  };

  SoftGatesSettings copyWith({
    int? urgentDeadlineWithinDays,
    int? staleAfterDaysWithoutUpdates,
  }) {
    return SoftGatesSettings(
      urgentDeadlineWithinDays:
          urgentDeadlineWithinDays ?? this.urgentDeadlineWithinDays,
      staleAfterDaysWithoutUpdates:
          staleAfterDaysWithoutUpdates ?? this.staleAfterDaysWithoutUpdates,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SoftGatesSettings &&
        other.urgentDeadlineWithinDays == urgentDeadlineWithinDays &&
        other.staleAfterDaysWithoutUpdates == staleAfterDaysWithoutUpdates;
  }

  @override
  int get hashCode =>
      Object.hash(urgentDeadlineWithinDays, staleAfterDaysWithoutUpdates);
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
