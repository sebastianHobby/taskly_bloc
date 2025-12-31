import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';

/// Tests to ensure translation completeness across all supported locales.
///
/// These tests verify that:
/// 1. All supported locales can be loaded
/// 2. All translations return non-empty strings
/// 3. Placeholder substitution works correctly
/// 4. Key translations are semantically appropriate per locale
void main() {
  group('Translation Completeness Tests', () {
    late AppLocalizations enL10n;
    late AppLocalizations esL10n;

    setUpAll(() async {
      // Load both localizations
      enL10n = await AppLocalizations.delegate.load(const Locale('en'));
      esL10n = await AppLocalizations.delegate.load(const Locale('es'));
    });

    group('Locale Loading', () {
      test('English locale loads successfully', () {
        expect(enL10n, isNotNull);
        expect(enL10n.localeName, equals('en'));
      });

      test('Spanish locale loads successfully', () {
        expect(esL10n, isNotNull);
        expect(esL10n.localeName, equals('es'));
      });

      test('All supported locales are declared', () {
        expect(
          AppLocalizations.supportedLocales,
          containsAll([const Locale('en'), const Locale('es')]),
        );
      });
    });

    group('Core App Strings', () {
      test('cancel label exists in all locales', () {
        expect(enL10n.cancelLabel, isNotEmpty);
        expect(esL10n.cancelLabel, isNotEmpty);
      });

      test('save button exists in all locales', () {
        expect(enL10n.saveButton, isNotEmpty);
        expect(esL10n.saveButton, isNotEmpty);
      });

      test('done button exists in all locales', () {
        expect(enL10n.doneButton, isNotEmpty);
        expect(esL10n.doneButton, isNotEmpty);
      });

      test('confirm button exists in all locales', () {
        expect(enL10n.confirmButton, isNotEmpty);
        expect(esL10n.confirmButton, isNotEmpty);
      });

      test('discard button exists in all locales', () {
        expect(enL10n.discardButton, isNotEmpty);
        expect(esL10n.discardButton, isNotEmpty);
      });

      test('reset button exists in all locales', () {
        expect(enL10n.resetButton, isNotEmpty);
        expect(esL10n.resetButton, isNotEmpty);
      });
    });

    group('Recurrence Picker Strings', () {
      test('recurrenceRepeatTitle exists in all locales', () {
        expect(enL10n.recurrenceRepeatTitle, isNotEmpty);
        expect(esL10n.recurrenceRepeatTitle, isNotEmpty);
      });

      test('recurrence frequency options exist in all locales', () {
        expect(enL10n.recurrenceNever, isNotEmpty);
        expect(esL10n.recurrenceNever, isNotEmpty);

        expect(enL10n.recurrenceDaily, isNotEmpty);
        expect(esL10n.recurrenceDaily, isNotEmpty);

        expect(enL10n.recurrenceWeekly, isNotEmpty);
        expect(esL10n.recurrenceWeekly, isNotEmpty);

        expect(enL10n.recurrenceMonthly, isNotEmpty);
        expect(esL10n.recurrenceMonthly, isNotEmpty);

        expect(enL10n.recurrenceYearly, isNotEmpty);
        expect(esL10n.recurrenceYearly, isNotEmpty);
      });

      test('recurrence UI labels exist in all locales', () {
        expect(enL10n.recurrenceEvery, isNotEmpty);
        expect(esL10n.recurrenceEvery, isNotEmpty);

        expect(enL10n.recurrenceOnDays, isNotEmpty);
        expect(esL10n.recurrenceOnDays, isNotEmpty);

        expect(enL10n.recurrenceEnds, isNotEmpty);
        expect(esL10n.recurrenceEnds, isNotEmpty);

        expect(enL10n.recurrenceAfter, isNotEmpty);
        expect(esL10n.recurrenceAfter, isNotEmpty);

        expect(enL10n.recurrenceTimesLabel, isNotEmpty);
        expect(esL10n.recurrenceTimesLabel, isNotEmpty);

        expect(enL10n.recurrenceOn, isNotEmpty);
        expect(esL10n.recurrenceOn, isNotEmpty);

        expect(enL10n.recurrenceSelectDate, isNotEmpty);
        expect(esL10n.recurrenceSelectDate, isNotEmpty);

        expect(enL10n.recurrenceDoesNotRepeat, isNotEmpty);
        expect(esL10n.recurrenceDoesNotRepeat, isNotEmpty);
      });
    });

    group('Settings Strings', () {
      test('settingsTitle exists in all locales', () {
        expect(enL10n.settingsTitle, isNotEmpty);
        expect(esL10n.settingsTitle, isNotEmpty);
      });

      test('settings sections exist in all locales', () {
        expect(enL10n.settingsAppearanceSection, isNotEmpty);
        expect(esL10n.settingsAppearanceSection, isNotEmpty);

        expect(enL10n.settingsLanguageRegionSection, isNotEmpty);
        expect(esL10n.settingsLanguageRegionSection, isNotEmpty);

        expect(enL10n.settingsAdvancedSection, isNotEmpty);
        expect(esL10n.settingsAdvancedSection, isNotEmpty);
      });

      test('theme settings exist in all locales', () {
        expect(enL10n.settingsThemeMode, isNotEmpty);
        expect(esL10n.settingsThemeMode, isNotEmpty);

        expect(enL10n.settingsThemeModeSubtitle, isNotEmpty);
        expect(esL10n.settingsThemeModeSubtitle, isNotEmpty);

        expect(enL10n.settingsTextSize, isNotEmpty);
        expect(esL10n.settingsTextSize, isNotEmpty);
      });

      test('language settings exist in all locales', () {
        expect(enL10n.settingsLanguage, isNotEmpty);
        expect(esL10n.settingsLanguage, isNotEmpty);

        expect(enL10n.settingsLanguageSubtitle, isNotEmpty);
        expect(esL10n.settingsLanguageSubtitle, isNotEmpty);

        expect(enL10n.settingsLanguageSystem, isNotEmpty);
        expect(esL10n.settingsLanguageSystem, isNotEmpty);
      });

      test('date format settings exist in all locales', () {
        expect(enL10n.settingsDateFormat, isNotEmpty);
        expect(esL10n.settingsDateFormat, isNotEmpty);

        expect(enL10n.settingsDateFormatShort, isNotEmpty);
        expect(esL10n.settingsDateFormatShort, isNotEmpty);

        expect(enL10n.settingsDateFormatMedium, isNotEmpty);
        expect(esL10n.settingsDateFormatMedium, isNotEmpty);

        expect(enL10n.settingsDateFormatLong, isNotEmpty);
        expect(esL10n.settingsDateFormatLong, isNotEmpty);

        expect(enL10n.settingsDateFormatFull, isNotEmpty);
        expect(esL10n.settingsDateFormatFull, isNotEmpty);

        expect(enL10n.settingsDateFormatCustom, isNotEmpty);
        expect(esL10n.settingsDateFormatCustom, isNotEmpty);
      });

      test('reset settings exist in all locales', () {
        expect(enL10n.settingsResetToDefaults, isNotEmpty);
        expect(esL10n.settingsResetToDefaults, isNotEmpty);

        expect(enL10n.settingsResetTitle, isNotEmpty);
        expect(esL10n.settingsResetTitle, isNotEmpty);

        expect(enL10n.settingsResetConfirmation, isNotEmpty);
        expect(esL10n.settingsResetConfirmation, isNotEmpty);

        expect(enL10n.settingsResetSuccess, isNotEmpty);
        expect(esL10n.settingsResetSuccess, isNotEmpty);
      });
    });

    group('Sort Strings', () {
      test('sort field labels exist in all locales', () {
        expect(enL10n.sortFieldCreatedDate, isNotEmpty);
        expect(esL10n.sortFieldCreatedDate, isNotEmpty);

        expect(enL10n.sortFieldUpdatedDate, isNotEmpty);
        expect(esL10n.sortFieldUpdatedDate, isNotEmpty);

        expect(enL10n.sortFieldNextActionPriority, isNotEmpty);
        expect(esL10n.sortFieldNextActionPriority, isNotEmpty);
      });

      test('sortOrderHelp exists in all locales', () {
        expect(enL10n.sortOrderHelp, isNotEmpty);
        expect(esL10n.sortOrderHelp, isNotEmpty);
      });
    });

    group('Validation Strings', () {
      test('validation messages exist in all locales', () {
        expect(enL10n.validationRequired, isNotEmpty);
        expect(esL10n.validationRequired, isNotEmpty);

        expect(enL10n.validationInvalid, isNotEmpty);
        expect(esL10n.validationInvalid, isNotEmpty);

        expect(enL10n.validationMustBeGreaterThanZero, isNotEmpty);
        expect(esL10n.validationMustBeGreaterThanZero, isNotEmpty);
      });

      test('validationMaxValue with placeholder works correctly', () {
        final enResult = enL10n.validationMaxValue(999);
        final esResult = esL10n.validationMaxValue(999);

        expect(enResult, contains('999'));
        expect(esResult, contains('999'));
      });
    });

    group('Placeholder Substitution', () {
      test('settingsDateFormatExample substitutes placeholder correctly', () {
        const exampleDate = '2025-12-30';
        final enResult = enL10n.settingsDateFormatExample(exampleDate);
        final esResult = esL10n.settingsDateFormatExample(exampleDate);

        expect(enResult, contains(exampleDate));
        expect(esResult, contains(exampleDate));
      });
    });

    group('Semantic Correctness', () {
      test('Spanish translations are in Spanish', () {
        // Verify key Spanish translations contain Spanish words
        expect(esL10n.settingsTitle.toLowerCase(), contains('config'));
        expect(esL10n.cancelLabel.toLowerCase(), contains('cancel'));
        expect(esL10n.saveButton.toLowerCase(), contains('guard'));
        expect(esL10n.recurrenceNever.toLowerCase(), contains('nunca'));
        expect(esL10n.recurrenceDaily.toLowerCase(), contains('diari'));
      });

      test('English translations are in English', () {
        // Verify key English translations contain English words
        expect(enL10n.settingsTitle.toLowerCase(), contains('setting'));
        expect(enL10n.cancelLabel.toLowerCase(), contains('cancel'));
        expect(enL10n.saveButton.toLowerCase(), contains('save'));
        expect(enL10n.recurrenceNever.toLowerCase(), contains('never'));
        expect(enL10n.recurrenceDaily.toLowerCase(), contains('daily'));
      });
    });

    group('Unsaved Changes Dialog', () {
      test('unsavedChangesTitle exists in all locales', () {
        expect(enL10n.unsavedChangesTitle, isNotEmpty);
        expect(esL10n.unsavedChangesTitle, isNotEmpty);
      });
    });
  });
}
