import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:taskly_bloc/presentation/theme/app_theme_mode.dart';

import 'package:taskly_domain/taskly_domain.dart';
void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  group('GlobalSettings', () {
    group('constructor', () {
      test('creates with default values', () {
        const settings = GlobalSettings();

        expect(settings.themeMode, AppThemeMode.system);
        expect(settings.colorSchemeSeedArgb, 0xFF6750A4);
        expect(settings.localeCode, isNull);
        expect(settings.textScaleFactor, 1.0);
        expect(settings.onboardingCompleted, false);
      });

      test('creates with custom values', () {
        const settings = GlobalSettings(
          themeMode: AppThemeMode.dark,
          colorSchemeSeedArgb: 0xFF00FF00,
          localeCode: 'es',
          textScaleFactor: 1.5,
          onboardingCompleted: true,
        );

        expect(settings.themeMode, AppThemeMode.dark);
        expect(settings.colorSchemeSeedArgb, 0xFF00FF00);
        expect(settings.localeCode, 'es');
        expect(settings.textScaleFactor, 1.5);
        expect(settings.onboardingCompleted, true);
      });
    });

    group('fromJson', () {
      test('parses complete JSON', () {
        final json = {
          'themeMode': 'dark',
          'colorSchemeSeed': '#FF5733',
          'locale': 'fr',
          'textScaleFactor': 1.2,
          'onboardingCompleted': true,
        };

        final settings = GlobalSettings.fromJson(json);

        expect(settings.themeMode, AppThemeMode.dark);
        expect(settings.colorSchemeSeedArgb, 0xFFFF5733);
        expect(settings.localeCode, 'fr');
        expect(settings.textScaleFactor, 1.2);
        expect(settings.onboardingCompleted, true);
      });

      test('parses empty JSON with defaults', () {
        final settings = GlobalSettings.fromJson({});

        expect(settings.themeMode, AppThemeMode.system);
        expect(settings.colorSchemeSeedArgb, 0xFF6750A4);
        expect(settings.localeCode, isNull);
        expect(settings.textScaleFactor, 1.0);
        expect(settings.onboardingCompleted, false);
      });

      test('parses color with hash prefix', () {
        final settings = GlobalSettings.fromJson({
          'colorSchemeSeed': '#AABBCC',
        });

        expect(settings.colorSchemeSeedArgb, 0xFFAABBCC);
      });

      test('parses color without hash prefix', () {
        final settings = GlobalSettings.fromJson({
          'colorSchemeSeed': '112233',
        });

        expect(settings.colorSchemeSeedArgb, 0xFF112233);
      });

      test('parses 3-character shorthand color', () {
        final settings = GlobalSettings.fromJson({
          'colorSchemeSeed': '#ABC',
        });

        expect(settings.colorSchemeSeedArgb, 0xFFAABBCC);
      });

      test('parses 3-character shorthand without hash', () {
        final settings = GlobalSettings.fromJson({
          'colorSchemeSeed': 'DEF',
        });

        expect(settings.colorSchemeSeedArgb, 0xFFDDEEFF);
      });

      test('returns fallback for invalid color length', () {
        final settings = GlobalSettings.fromJson({
          'colorSchemeSeed': 'ABCD',
        });

        expect(settings.colorSchemeSeedArgb, 0xFF6750A4);
      });

      test('returns fallback for empty color', () {
        final settings = GlobalSettings.fromJson({
          'colorSchemeSeed': '',
        });

        expect(settings.colorSchemeSeedArgb, 0xFF6750A4);
      });

      test('returns fallback for invalid hex characters', () {
        final settings = GlobalSettings.fromJson({
          'colorSchemeSeed': 'ZZZZZZ',
        });

        expect(settings.colorSchemeSeedArgb, 0xFF6750A4);
      });

      test('handles null color value', () {
        final settings = GlobalSettings.fromJson({
          'colorSchemeSeed': null,
        });

        expect(settings.colorSchemeSeedArgb, 0xFF6750A4);
      });

      test('parses textScaleFactor from double', () {
        final settings = GlobalSettings.fromJson({
          'textScaleFactor': 1.5,
        });

        expect(settings.textScaleFactor, 1.5);
      });

      test('parses textScaleFactor from int', () {
        final settings = GlobalSettings.fromJson({
          'textScaleFactor': 2,
        });

        expect(settings.textScaleFactor, 2.0);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        const settings = GlobalSettings(
          themeMode: AppThemeMode.light,
          colorSchemeSeedArgb: 0xFF123456,
          localeCode: 'de',
          textScaleFactor: 1.1,
          onboardingCompleted: true,
        );

        final json = settings.toJson();

        expect(json['themeMode'], 'light');
        expect(json['colorSchemeSeed'], '#123456');
        expect(json['locale'], 'de');
        expect(json['textScaleFactor'], 1.1);
        expect(json['onboardingCompleted'], true);
      });

      test('serializes null locale', () {
        const settings = GlobalSettings(localeCode: null);

        final json = settings.toJson();

        expect(json['locale'], isNull);
      });

      test('round-trips through JSON', () {
        const original = GlobalSettings(
          themeMode: AppThemeMode.dark,
          colorSchemeSeedArgb: 0xFFABCDEF,
          localeCode: 'ja',
          textScaleFactor: 1.25,
          onboardingCompleted: true,
        );

        final json = original.toJson();
        final restored = GlobalSettings.fromJson(json);

        expect(restored, original);
      });
    });

    group('copyWith', () {
      test('copies with no changes', () {
        const settings = GlobalSettings(
          themeMode: AppThemeMode.dark,
          localeCode: 'en',
        );

        final copied = settings.copyWith();

        expect(copied, settings);
      });

      test('copies with themeMode change', () {
        const settings = GlobalSettings(themeMode: AppThemeMode.system);

        final copied = settings.copyWith(themeMode: AppThemeMode.light);

        expect(copied.themeMode, AppThemeMode.light);
        expect(copied.colorSchemeSeedArgb, settings.colorSchemeSeedArgb);
      });

      test('copies with colorSchemeSeedArgb change', () {
        const settings = GlobalSettings();

        final copied = settings.copyWith(colorSchemeSeedArgb: 0xFF00FF00);

        expect(copied.colorSchemeSeedArgb, 0xFF00FF00);
        expect(copied.themeMode, settings.themeMode);
      });

      test('copies with localeCode change', () {
        const settings = GlobalSettings();

        final copied = settings.copyWith(localeCode: 'es');

        expect(copied.localeCode, 'es');
      });

      test('copies with textScaleFactor change', () {
        const settings = GlobalSettings();

        final copied = settings.copyWith(textScaleFactor: 2);

        expect(copied.textScaleFactor, 2.0);
      });

      test('copies with onboardingCompleted change', () {
        const settings = GlobalSettings();

        final copied = settings.copyWith(onboardingCompleted: true);

        expect(copied.onboardingCompleted, true);
      });

      test('copies with multiple changes', () {
        const settings = GlobalSettings();

        final copied = settings.copyWith(
          themeMode: AppThemeMode.dark,
          localeCode: 'fr',
          onboardingCompleted: true,
        );

        expect(copied.themeMode, AppThemeMode.dark);
        expect(copied.localeCode, 'fr');
        expect(copied.onboardingCompleted, true);
      });
    });

    group('equality', () {
      test('equal settings are equal', () {
        const settings1 = GlobalSettings(
          themeMode: AppThemeMode.dark,
          colorSchemeSeedArgb: 0xFF123456,
        );
        const settings2 = GlobalSettings(
          themeMode: AppThemeMode.dark,
          colorSchemeSeedArgb: 0xFF123456,
        );

        expect(settings1, settings2);
        expect(settings1.hashCode, settings2.hashCode);
      });

      test('different themeMode are not equal', () {
        const settings1 = GlobalSettings(themeMode: AppThemeMode.dark);
        const settings2 = GlobalSettings(themeMode: AppThemeMode.light);

        expect(settings1, isNot(settings2));
      });

      test('different colorSchemeSeedArgb are not equal', () {
        const settings1 = GlobalSettings(colorSchemeSeedArgb: 0xFF111111);
        const settings2 = GlobalSettings(colorSchemeSeedArgb: 0xFF222222);

        expect(settings1, isNot(settings2));
      });

      test('different localeCode are not equal', () {
        const settings1 = GlobalSettings(localeCode: 'en');
        const settings2 = GlobalSettings(localeCode: 'es');

        expect(settings1, isNot(settings2));
      });

      test('different textScaleFactor are not equal', () {
        const settings1 = GlobalSettings(textScaleFactor: 1);
        const settings2 = GlobalSettings(textScaleFactor: 1.5);

        expect(settings1, isNot(settings2));
      });

      test('different onboardingCompleted are not equal', () {
        const settings1 = GlobalSettings(onboardingCompleted: false);
        const settings2 = GlobalSettings(onboardingCompleted: true);

        expect(settings1, isNot(settings2));
      });
    });
  });

  group('AppThemeMode', () {
    group('fromName', () {
      test('parses system', () {
        expect(AppThemeMode.fromName('system'), AppThemeMode.system);
      });

      test('parses light', () {
        expect(AppThemeMode.fromName('light'), AppThemeMode.light);
      });

      test('parses dark', () {
        expect(AppThemeMode.fromName('dark'), AppThemeMode.dark);
      });

      test('returns system for null', () {
        expect(AppThemeMode.fromName(null), AppThemeMode.system);
      });

      test('returns system for unknown value', () {
        expect(AppThemeMode.fromName('invalid'), AppThemeMode.system);
      });
    });
  });
}
