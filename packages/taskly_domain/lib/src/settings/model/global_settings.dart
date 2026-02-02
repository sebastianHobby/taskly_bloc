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
    @Default(1.0) double textScaleFactor,
    @Default(false) bool onboardingCompleted,
    @Default(false) bool guidedTourCompleted,
  }) = _GlobalSettings;

  factory GlobalSettings.fromJson(Map<String, dynamic> json) {
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
      textScaleFactor: (json['textScaleFactor'] as num?)?.toDouble() ?? 1.0,
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
      guidedTourCompleted: json['guidedTourCompleted'] as bool? ?? false,
    );
  }

  /// Default home timezone offset minutes (GMT+10).
  ///
  /// This matches Australia (AEST) as a sensible product default.
  static const int defaultHomeTimeZoneOffsetMinutes = 10 * 60;

  /// Default seed color (Material Purple).
  static const int defaultSeedArgb = 0xFF6750A4;

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

  static const int maintenanceStaleThresholdDaysMin = 1;
  static const int maintenanceStaleThresholdDaysMax = 90;
  static const int maintenanceDeadlineRiskDueWithinDaysMin = 1;
  static const int maintenanceDeadlineRiskDueWithinDaysMax = 30;
  static const int maintenanceDeadlineRiskMinUnscheduledCountMin = 1;
  static const int maintenanceDeadlineRiskMinUnscheduledCountMax = 20;

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
    'textScaleFactor': textScaleFactor,
    'onboardingCompleted': onboardingCompleted,
    'guidedTourCompleted': guidedTourCompleted,
  };
}
