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
        'guidedTourCompleted': true,
      });

      expect(settings.themeMode, AppThemeMode.dark);
      expect(settings.myDayShowRoutines, isTrue);
      expect(settings.textScaleFactor, 1.25);
      expect(settings.onboardingCompleted, isTrue);
      expect(settings.guidedTourCompleted, isTrue);
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
      myDayShowRoutines: false,
      maintenanceDeadlineRiskDueWithinDays: 99,
      maintenanceDeadlineRiskMinUnscheduledCount: 0,
      maintenanceTaskStaleThresholdDays: 0,
      maintenanceProjectIdleThresholdDays: 200,
      textScaleFactor: 0.9,
      onboardingCompleted: true,
      guidedTourCompleted: true,
    );

    final json = original.toJson();
    final decoded = GlobalSettings.fromJson(json);

    expect(decoded.themeMode, AppThemeMode.light);
    expect(decoded.colorSchemeSeedArgb, 0xFF112233);
    expect(decoded.localeCode, 'en');
    expect(decoded.homeTimeZoneOffsetMinutes, -60);
    expect(decoded.myDayShowRoutines, isFalse);
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
    expect(
      decoded.textScaleFactor,
      0.9,
    );
    expect(decoded.onboardingCompleted, isTrue);
    expect(decoded.guidedTourCompleted, isTrue);
  });
}
