import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_domain/src/settings/model/app_theme_mode.dart';

part 'global_settings.freezed.dart';

/// Global application settings.
@freezed
abstract class GlobalSettings with _$GlobalSettings {
  const factory GlobalSettings({
    @Default(AppThemeMode.system) AppThemeMode themeMode,
    @Default(GlobalSettings.defaultSeedArgb) int colorSchemeSeedArgb,
    String? localeCode,

    /// Fixed "home" timezone offset in minutes.
    ///
    /// This is intentionally stored as an offset (not device-local timezone) so
    /// the app's notion of "day" can be stable across travel.
    ///
    /// Note: this does not model DST transitions; it's a fixed offset.
    @Default(GlobalSettings.defaultHomeTimeZoneOffsetMinutes)
    int homeTimeZoneOffsetMinutes,

    /// My Day ritual: include tasks due within this many days.
    ///
    /// Clamped to 1-30 days.
    @Default(GlobalSettings.defaultMyDayDueWindowDays) int myDayDueWindowDays,

    /// My Day ritual: show the time-sensitive (triage) step.
    @Default(true) bool myDayDueSoonEnabled,

    /// My Day ritual: show planned tasks within the triage step.
    @Default(false) bool myDayShowAvailableToStart,

    /// My Day ritual: show the routines step.
    @Default(true) bool myDayShowRoutines,

    /// My Day ritual: count triage picks against value quotas.
    @Default(true) bool myDayCountTriagePicksAgainstValueQuotas,

    /// My Day ritual: count routine picks against value quotas.
    @Default(true) bool myDayCountRoutinePicksAgainstValueQuotas,

    /// Weekly review scheduling.
    @Default(true) bool weeklyReviewEnabled,
    @Default(GlobalSettings.defaultWeeklyReviewDayOfWeek)
    int weeklyReviewDayOfWeek,
    @Default(GlobalSettings.defaultWeeklyReviewTimeMinutes)
    int weeklyReviewTimeMinutes,
    @Default(GlobalSettings.defaultWeeklyReviewCadenceWeeks)
    int weeklyReviewCadenceWeeks,
    DateTime? weeklyReviewLastCompletedAt,

    /// Values summary in weekly review.
    @Default(true) bool valuesSummaryEnabled,
    @Default(GlobalSettings.defaultValuesSummaryWeeks)
    int valuesSummaryWindowWeeks,
    @Default(GlobalSettings.defaultValuesSummaryWinsCount)
    int valuesSummaryWinsCount,

    /// Maintenance checks in weekly review.
    @Default(true) bool maintenanceEnabled,
    @Default(true) bool maintenanceDeadlineRiskEnabled,
    @Default(GlobalSettings.defaultMaintenanceDeadlineRiskDueWithinDays)
    int maintenanceDeadlineRiskDueWithinDays,
    @Default(GlobalSettings.defaultMaintenanceDeadlineRiskMinUnscheduledCount)
    int maintenanceDeadlineRiskMinUnscheduledCount,
    @Default(true) bool maintenanceDueSoonEnabled,
    @Default(true) bool maintenanceStaleEnabled,
    @Default(GlobalSettings.defaultMaintenanceTaskStaleThresholdDays)
    int maintenanceTaskStaleThresholdDays,
    @Default(GlobalSettings.defaultMaintenanceProjectIdleThresholdDays)
    int maintenanceProjectIdleThresholdDays,
    @Default(true) bool maintenanceFrequentSnoozedEnabled,
    @Default(true) bool maintenanceMissingNextActionsEnabled,
    @Default(GlobalSettings.defaultMaintenanceMissingNextActionsMinOpenTasks)
    int maintenanceMissingNextActionsMinOpenTasks,
    @Default(1.0) double textScaleFactor,
    @Default(false) bool onboardingCompleted,
  }) = _GlobalSettings;

  factory GlobalSettings.fromJson(Map<String, dynamic> json) {
    final rawMyDayDueWindowDays =
        (json['myDayDueWindowDays'] as num?)?.toInt() ??
        defaultMyDayDueWindowDays;

    final rawMyDayDueSoonEnabled = json['myDayDueSoonEnabled'] as bool?;
    final rawMyDayShowAvailableToStart =
        json['myDayShowAvailableToStart'] as bool?;
    final rawMyDayShowRoutines = json['myDayShowRoutines'] as bool?;
    final rawMyDayCountTriagePicksAgainstValueQuotas =
        json['myDayCountTriagePicksAgainstValueQuotas'] as bool?;
    final rawMyDayCountRoutinePicksAgainstValueQuotas =
        json['myDayCountRoutinePicksAgainstValueQuotas'] as bool?;

    final rawWeeklyReviewDay =
        (json['weeklyReviewDayOfWeek'] as num?)?.toInt() ??
        defaultWeeklyReviewDayOfWeek;
    final rawWeeklyReviewTimeMinutes =
        (json['weeklyReviewTimeMinutes'] as num?)?.toInt() ??
        defaultWeeklyReviewTimeMinutes;
    final rawWeeklyReviewCadenceWeeks =
        (json['weeklyReviewCadenceWeeks'] as num?)?.toInt() ??
        defaultWeeklyReviewCadenceWeeks;
    final rawWeeklyReviewCompleted =
        json['weeklyReviewLastCompletedAt'] as String?;

    final rawValuesWindowWeeks =
        (json['valuesSummaryWindowWeeks'] as num?)?.toInt() ??
        defaultValuesSummaryWeeks;
    final rawValuesWinsCount =
        (json['valuesSummaryWinsCount'] as num?)?.toInt() ??
        defaultValuesSummaryWinsCount;

    final rawMaintenanceDeadlineRiskDueWithinDays =
        (json['maintenanceDeadlineRiskDueWithinDays'] as num?)?.toInt() ??
        defaultMaintenanceDeadlineRiskDueWithinDays;
    final rawMaintenanceDeadlineRiskMinUnscheduledCount =
        (json['maintenanceDeadlineRiskMinUnscheduledCount'] as num?)?.toInt() ??
        defaultMaintenanceDeadlineRiskMinUnscheduledCount;
    final rawMaintenanceTaskStaleThresholdDays =
        (json['maintenanceTaskStaleThresholdDays'] as num?)?.toInt() ??
        defaultMaintenanceTaskStaleThresholdDays;
    final rawMaintenanceProjectIdleThresholdDays =
        (json['maintenanceProjectIdleThresholdDays'] as num?)?.toInt() ??
        defaultMaintenanceProjectIdleThresholdDays;
    final rawMaintenanceMissingNextActionsMinOpenTasks =
        (json['maintenanceMissingNextActionsMinOpenTasks'] as num?)?.toInt() ??
        defaultMaintenanceMissingNextActionsMinOpenTasks;

    return GlobalSettings(
      themeMode: AppThemeMode.fromName(json['themeMode'] as String?),
      colorSchemeSeedArgb: _rgbHexToArgb(
        json['colorSchemeSeed'] as String?,
        fallbackArgb: defaultSeedArgb,
      ),
      localeCode: json['locale'] as String?,
      homeTimeZoneOffsetMinutes:
          (json['homeTimeZoneOffsetMinutes'] as num?)?.toInt() ??
          defaultHomeTimeZoneOffsetMinutes,
      myDayDueWindowDays: rawMyDayDueWindowDays.clamp(1, 30),
      myDayDueSoonEnabled: rawMyDayDueSoonEnabled ?? true,
      myDayShowAvailableToStart: rawMyDayShowAvailableToStart ?? false,
      myDayShowRoutines: rawMyDayShowRoutines ?? true,
      myDayCountTriagePicksAgainstValueQuotas:
          rawMyDayCountTriagePicksAgainstValueQuotas ?? true,
      myDayCountRoutinePicksAgainstValueQuotas:
          rawMyDayCountRoutinePicksAgainstValueQuotas ?? true,
      weeklyReviewEnabled: json['weeklyReviewEnabled'] as bool? ?? true,
      weeklyReviewDayOfWeek: rawWeeklyReviewDay.clamp(1, 7),
      weeklyReviewTimeMinutes: rawWeeklyReviewTimeMinutes.clamp(0, 1439),
      weeklyReviewCadenceWeeks: rawWeeklyReviewCadenceWeeks.clamp(1, 12),
      weeklyReviewLastCompletedAt: rawWeeklyReviewCompleted == null
          ? null
          : DateTime.tryParse(rawWeeklyReviewCompleted),
      valuesSummaryEnabled: json['valuesSummaryEnabled'] as bool? ?? true,
      valuesSummaryWindowWeeks: rawValuesWindowWeeks.clamp(1, 12),
      valuesSummaryWinsCount: rawValuesWinsCount.clamp(1, 5),
      maintenanceEnabled: json['maintenanceEnabled'] as bool? ?? true,
      maintenanceDeadlineRiskEnabled:
          json['maintenanceDeadlineRiskEnabled'] as bool? ?? true,
      maintenanceDeadlineRiskDueWithinDays:
          rawMaintenanceDeadlineRiskDueWithinDays.clamp(
            maintenanceDeadlineRiskDueWithinDaysMin,
            maintenanceDeadlineRiskDueWithinDaysMax,
          ),
      maintenanceDeadlineRiskMinUnscheduledCount:
          rawMaintenanceDeadlineRiskMinUnscheduledCount.clamp(
            maintenanceDeadlineRiskMinUnscheduledCountMin,
            maintenanceDeadlineRiskMinUnscheduledCountMax,
          ),
      maintenanceDueSoonEnabled:
          json['maintenanceDueSoonEnabled'] as bool? ?? true,
      maintenanceStaleEnabled: json['maintenanceStaleEnabled'] as bool? ?? true,
      maintenanceTaskStaleThresholdDays: rawMaintenanceTaskStaleThresholdDays
          .clamp(
            maintenanceStaleThresholdDaysMin,
            maintenanceStaleThresholdDaysMax,
          ),
      maintenanceProjectIdleThresholdDays:
          rawMaintenanceProjectIdleThresholdDays.clamp(
            maintenanceStaleThresholdDaysMin,
            maintenanceStaleThresholdDaysMax,
          ),
      maintenanceFrequentSnoozedEnabled:
          json['maintenanceFrequentSnoozedEnabled'] as bool? ?? true,
      maintenanceMissingNextActionsEnabled:
          json['maintenanceMissingNextActionsEnabled'] as bool? ?? true,
      maintenanceMissingNextActionsMinOpenTasks:
          rawMaintenanceMissingNextActionsMinOpenTasks.clamp(
            maintenanceMissingNextActionsMinOpenTasksMin,
            maintenanceMissingNextActionsMinOpenTasksMax,
          ),
      textScaleFactor: (json['textScaleFactor'] as num?)?.toDouble() ?? 1.0,
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
    );
  }

  /// Default home timezone offset minutes (GMT+10).
  ///
  /// This matches Australia (AEST) as a sensible product default.
  static const int defaultHomeTimeZoneOffsetMinutes = 10 * 60;

  /// Default seed color (Material Purple).
  static const int defaultSeedArgb = 0xFF6750A4;

  /// Default My Day due window (days).
  static const int defaultMyDayDueWindowDays = 7;

  /// Default weekly review day (Monday).
  static const int defaultWeeklyReviewDayOfWeek = DateTime.monday;

  /// Default weekly review time (9:00 AM).
  static const int defaultWeeklyReviewTimeMinutes = 9 * 60;

  /// Default weekly review cadence (weeks).
  static const int defaultWeeklyReviewCadenceWeeks = 1;

  /// Default values summary window (weeks).
  static const int defaultValuesSummaryWeeks = 4;

  /// Default value wins count.
  static const int defaultValuesSummaryWinsCount = 3;

  /// Default stale-task threshold (days).
  static const int defaultMaintenanceTaskStaleThresholdDays = 30;

  /// Default idle-project threshold (days).
  static const int defaultMaintenanceProjectIdleThresholdDays = 30;

  /// Default deadline-risk horizon (days).
  static const int defaultMaintenanceDeadlineRiskDueWithinDays = 14;

  /// Default minimum unscheduled task count for deadline risk.
  static const int defaultMaintenanceDeadlineRiskMinUnscheduledCount = 5;

  /// Default minimum open-task count for missing next actions.
  static const int defaultMaintenanceMissingNextActionsMinOpenTasks = 1;

  static const int maintenanceStaleThresholdDaysMin = 1;
  static const int maintenanceStaleThresholdDaysMax = 90;
  static const int maintenanceDeadlineRiskDueWithinDaysMin = 1;
  static const int maintenanceDeadlineRiskDueWithinDaysMax = 30;
  static const int maintenanceDeadlineRiskMinUnscheduledCountMin = 1;
  static const int maintenanceDeadlineRiskMinUnscheduledCountMax = 20;
  static const int maintenanceMissingNextActionsMinOpenTasksMin = 1;
  static const int maintenanceMissingNextActionsMinOpenTasksMax = 10;

  /// Parses `#RRGGBB`, `RRGGBB`, `#RGB`, or `RGB` into an ARGB int.
  ///
  /// Uses an opaque alpha channel (`FF`). Returns [fallbackArgb] if invalid.
  static int _rgbHexToArgb(String? hex, {required int fallbackArgb}) {
    if (hex == null || hex.isEmpty) return fallbackArgb;

    final normalized = hex.replaceAll('#', '').toUpperCase();

    final String fullHex;
    if (normalized.length == 3) {
      fullHex = normalized.split('').map((c) => '$c$c').join();
    } else if (normalized.length == 6) {
      fullHex = normalized;
    } else {
      return fallbackArgb;
    }

    final rgb = int.tryParse(fullHex, radix: 16);
    if (rgb == null) return fallbackArgb;
    return 0xFF000000 | rgb;
  }

  /// Converts an ARGB int to `#RRGGBB` (alpha is ignored).
  static String _argbToRgbHexWithHash(int argb) {
    final rgb = argb & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}

/// Extension for JSON serialization (manual, not using json_serializable).
extension GlobalSettingsJson on GlobalSettings {
  Map<String, dynamic> toJson() => <String, dynamic>{
    'themeMode': themeMode.name,
    'colorSchemeSeed': GlobalSettings._argbToRgbHexWithHash(
      colorSchemeSeedArgb,
    ),
    'locale': localeCode,
    'homeTimeZoneOffsetMinutes': homeTimeZoneOffsetMinutes,
    'myDayDueWindowDays': myDayDueWindowDays.clamp(1, 30),
    'myDayDueSoonEnabled': myDayDueSoonEnabled,
    'myDayShowAvailableToStart': myDayShowAvailableToStart,
    'myDayShowRoutines': myDayShowRoutines,
    'myDayCountTriagePicksAgainstValueQuotas':
        myDayCountTriagePicksAgainstValueQuotas,
    'myDayCountRoutinePicksAgainstValueQuotas':
        myDayCountRoutinePicksAgainstValueQuotas,
    'weeklyReviewEnabled': weeklyReviewEnabled,
    'weeklyReviewDayOfWeek': weeklyReviewDayOfWeek.clamp(1, 7),
    'weeklyReviewTimeMinutes': weeklyReviewTimeMinutes.clamp(0, 1439),
    'weeklyReviewCadenceWeeks': weeklyReviewCadenceWeeks.clamp(1, 12),
    'weeklyReviewLastCompletedAt': weeklyReviewLastCompletedAt
        ?.toUtc()
        .toIso8601String(),
    'valuesSummaryEnabled': valuesSummaryEnabled,
    'valuesSummaryWindowWeeks': valuesSummaryWindowWeeks.clamp(1, 12),
    'valuesSummaryWinsCount': valuesSummaryWinsCount.clamp(1, 5),
    'maintenanceEnabled': maintenanceEnabled,
    'maintenanceDeadlineRiskEnabled': maintenanceDeadlineRiskEnabled,
    'maintenanceDeadlineRiskDueWithinDays': maintenanceDeadlineRiskDueWithinDays
        .clamp(
          GlobalSettings.maintenanceDeadlineRiskDueWithinDaysMin,
          GlobalSettings.maintenanceDeadlineRiskDueWithinDaysMax,
        ),
    'maintenanceDeadlineRiskMinUnscheduledCount':
        maintenanceDeadlineRiskMinUnscheduledCount.clamp(
          GlobalSettings.maintenanceDeadlineRiskMinUnscheduledCountMin,
          GlobalSettings.maintenanceDeadlineRiskMinUnscheduledCountMax,
        ),
    'maintenanceDueSoonEnabled': maintenanceDueSoonEnabled,
    'maintenanceStaleEnabled': maintenanceStaleEnabled,
    'maintenanceTaskStaleThresholdDays': maintenanceTaskStaleThresholdDays
        .clamp(
          GlobalSettings.maintenanceStaleThresholdDaysMin,
          GlobalSettings.maintenanceStaleThresholdDaysMax,
        ),
    'maintenanceProjectIdleThresholdDays': maintenanceProjectIdleThresholdDays
        .clamp(
          GlobalSettings.maintenanceStaleThresholdDaysMin,
          GlobalSettings.maintenanceStaleThresholdDaysMax,
        ),
    'maintenanceFrequentSnoozedEnabled': maintenanceFrequentSnoozedEnabled,
    'maintenanceMissingNextActionsEnabled':
        maintenanceMissingNextActionsEnabled,
    'maintenanceMissingNextActionsMinOpenTasks':
        maintenanceMissingNextActionsMinOpenTasks.clamp(
          GlobalSettings.maintenanceMissingNextActionsMinOpenTasksMin,
          GlobalSettings.maintenanceMissingNextActionsMinOpenTasksMax,
        ),
    'textScaleFactor': textScaleFactor,
    'onboardingCompleted': onboardingCompleted,
  };
}
