@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:taskly_domain/src/settings/model/global_settings.dart';
import 'package:taskly_domain/src/settings/model/app_theme_mode.dart';

void main() {
  testSafe(
    'GlobalSettings.fromJson parses theme and defaults',
    () async {
      final settings = GlobalSettings.fromJson(<String, dynamic>{
        'themeMode': 'dark',
        'textScaleFactor': 1.25,
        'onboardingCompleted': true,
      });

      expect(settings.themeMode, AppThemeMode.dark);
      expect(settings.textScaleFactor, 1.25);
      expect(settings.onboardingCompleted, isTrue);
      expect(settings.planMyDayReminderEnabled, isTrue);
      expect(settings.planMyDayReminderTimeMinutes, 0);
    },
  );

  testSafe(
    'GlobalSettings.fromJson parses RGB hex color forms and falls back when invalid',
    () async {
      final a = GlobalSettings.fromJson(<String, dynamic>{
        'colorSchemeSeed': '#ABC',
      });

      expect(a.colorSchemeSeedArgb, 0xFFAABBCC);

      final b = GlobalSettings.fromJson(<String, dynamic>{
        'colorSchemeSeed': 'not-a-color',
      });

      expect(b.colorSchemeSeedArgb, GlobalSettings.defaultSeedArgb);
    },
  );

  testSafe('GlobalSettingsJson.toJson roundtrips via fromJson', () async {
    final original = GlobalSettings(
      themeMode: AppThemeMode.light,
      colorSchemeSeedArgb: 0xFF112233,
      localeCode: 'en',
      homeTimeZoneOffsetMinutes: -60,
      maintenanceDeadlineRiskDueWithinDays: 99,
      maintenanceDeadlineRiskMinUnscheduledCount: 0,
      maintenanceTaskStaleThresholdDays: 0,
      maintenanceProjectIdleThresholdDays: 200,
      planMyDayReminderTimeMinutes: 9999,
      textScaleFactor: 0.9,
      onboardingCompleted: true,
    );

    final json = original.toJson();
    final decoded = GlobalSettings.fromJson(json);

    expect(decoded.themeMode, AppThemeMode.light);
    expect(decoded.colorSchemeSeedArgb, 0xFF112233);
    expect(decoded.localeCode, 'en');
    expect(decoded.homeTimeZoneOffsetMinutes, -60);
    expect(
      decoded.maintenanceDeadlineRiskDueWithinDays,
      GlobalSettings.maintenanceDeadlineRiskDueWithinDaysMax,
    );
    expect(
      decoded.maintenanceDeadlineRiskMinUnscheduledCount,
      GlobalSettings.maintenanceDeadlineRiskMinUnscheduledCountMin,
    );
    expect(
      decoded.maintenanceTaskStaleThresholdDays,
      GlobalSettings.maintenanceStaleThresholdDaysMin,
    );
    expect(
      decoded.maintenanceProjectIdleThresholdDays,
      GlobalSettings.maintenanceStaleThresholdDaysMax,
    );
    expect(decoded.planMyDayReminderEnabled, isTrue);
    expect(decoded.planMyDayReminderTimeMinutes, 1439);
    expect(
      decoded.textScaleFactor,
      0.9,
    );
    expect(decoded.onboardingCompleted, isTrue);
  });
}
