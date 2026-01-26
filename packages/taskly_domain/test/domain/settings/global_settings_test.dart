@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:taskly_domain/src/settings/model/global_settings.dart';
import 'package:taskly_domain/src/settings/model/app_theme_mode.dart';

void main() {
  testSafe(
    'GlobalSettings.fromJson parses theme and clamps myDayDueWindowDays',
    () async {
      final settings = GlobalSettings.fromJson(<String, dynamic>{
        'themeMode': 'dark',
        'myDayDueWindowDays': 100,
        'myDayShowAvailableToStart': false,
        'textScaleFactor': 1.25,
        'onboardingCompleted': true,
      });

      expect(settings.themeMode, AppThemeMode.dark);
      expect(settings.myDayDueWindowDays, 30);
      expect(settings.myDayDueSoonEnabled, isTrue);
      expect(settings.myDayShowAvailableToStart, isFalse);
      expect(settings.myDayShowRoutines, isTrue);
      expect(settings.myDayCountTriagePicksAgainstValueQuotas, isTrue);
      expect(settings.myDayCountRoutinePicksAgainstValueQuotas, isTrue);
      expect(settings.textScaleFactor, 1.25);
      expect(settings.onboardingCompleted, isTrue);
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
      myDayDueWindowDays: 0, // should clamp on write
      myDayDueSoonEnabled: false,
      myDayShowAvailableToStart: true,
      myDayShowRoutines: false,
      myDayCountTriagePicksAgainstValueQuotas: false,
      myDayCountRoutinePicksAgainstValueQuotas: false,
      textScaleFactor: 0.9,
      onboardingCompleted: true,
    );

    final json = original.toJson();
    final decoded = GlobalSettings.fromJson(json);

    expect(decoded.themeMode, AppThemeMode.light);
    expect(decoded.colorSchemeSeedArgb, 0xFF112233);
    expect(decoded.localeCode, 'en');
    expect(decoded.homeTimeZoneOffsetMinutes, -60);
    expect(decoded.myDayDueWindowDays, 1);
    expect(decoded.myDayDueSoonEnabled, isFalse);
    expect(decoded.myDayShowAvailableToStart, isTrue);
    expect(decoded.myDayShowRoutines, isFalse);
    expect(decoded.myDayCountTriagePicksAgainstValueQuotas, isFalse);
    expect(decoded.myDayCountRoutinePicksAgainstValueQuotas, isFalse);
    expect(decoded.textScaleFactor, 0.9);
    expect(decoded.onboardingCompleted, isTrue);
  });
}
