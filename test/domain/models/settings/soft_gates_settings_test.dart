import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/settings/soft_gates_settings.dart';

void main() {
  group('SoftGatesSettings', () {
    group('constructor', () {
      test('creates with default values', () {
        const settings = SoftGatesSettings();

        expect(settings.urgentDeadlineWithinDays, 7);
        expect(settings.staleAfterDaysWithoutUpdates, 30);
      });

      test('creates with custom values', () {
        const settings = SoftGatesSettings(
          urgentDeadlineWithinDays: 3,
          staleAfterDaysWithoutUpdates: 60,
        );

        expect(settings.urgentDeadlineWithinDays, 3);
        expect(settings.staleAfterDaysWithoutUpdates, 60);
      });
    });

    group('fromJson', () {
      test('parses complete JSON', () {
        final json = {
          'urgentDeadlineWithinDays': 5,
          'staleAfterDaysWithoutUpdates': 45,
        };

        final settings = SoftGatesSettings.fromJson(json);

        expect(settings.urgentDeadlineWithinDays, 5);
        expect(settings.staleAfterDaysWithoutUpdates, 45);
      });

      test('parses empty JSON with defaults', () {
        final settings = SoftGatesSettings.fromJson({});

        expect(settings.urgentDeadlineWithinDays, 7);
        expect(settings.staleAfterDaysWithoutUpdates, 30);
      });

      test('parses null values with fallback defaults', () {
        final json = {
          'urgentDeadlineWithinDays': null,
          'staleAfterDaysWithoutUpdates': null,
        };

        final settings = SoftGatesSettings.fromJson(json);

        expect(settings.urgentDeadlineWithinDays, 7);
        expect(settings.staleAfterDaysWithoutUpdates, 30);
      });

      test('clamps zero to fallback', () {
        final json = {
          'urgentDeadlineWithinDays': 0,
          'staleAfterDaysWithoutUpdates': 0,
        };

        final settings = SoftGatesSettings.fromJson(json);

        expect(settings.urgentDeadlineWithinDays, 7);
        expect(settings.staleAfterDaysWithoutUpdates, 30);
      });

      test('clamps negative to fallback', () {
        final json = {
          'urgentDeadlineWithinDays': -5,
          'staleAfterDaysWithoutUpdates': -10,
        };

        final settings = SoftGatesSettings.fromJson(json);

        expect(settings.urgentDeadlineWithinDays, 7);
        expect(settings.staleAfterDaysWithoutUpdates, 30);
      });

      test('parses double values by truncating', () {
        final json = {
          'urgentDeadlineWithinDays': 5.9,
          'staleAfterDaysWithoutUpdates': 45.1,
        };

        final settings = SoftGatesSettings.fromJson(json);

        expect(settings.urgentDeadlineWithinDays, 5);
        expect(settings.staleAfterDaysWithoutUpdates, 45);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        const settings = SoftGatesSettings(
          urgentDeadlineWithinDays: 10,
          staleAfterDaysWithoutUpdates: 14,
        );

        final json = settings.toJson();

        expect(json['urgentDeadlineWithinDays'], 10);
        expect(json['staleAfterDaysWithoutUpdates'], 14);
      });

      test('round-trips through JSON', () {
        const original = SoftGatesSettings(
          urgentDeadlineWithinDays: 14,
          staleAfterDaysWithoutUpdates: 60,
        );

        final json = original.toJson();
        final restored = SoftGatesSettings.fromJson(json);

        expect(restored, original);
      });
    });

    group('copyWith', () {
      test('copies with no changes', () {
        const settings = SoftGatesSettings(
          urgentDeadlineWithinDays: 5,
          staleAfterDaysWithoutUpdates: 20,
        );

        final copied = settings.copyWith();

        expect(copied, settings);
      });

      test('copies with urgentDeadlineWithinDays change', () {
        const settings = SoftGatesSettings();

        final copied = settings.copyWith(urgentDeadlineWithinDays: 14);

        expect(copied.urgentDeadlineWithinDays, 14);
        expect(
          copied.staleAfterDaysWithoutUpdates,
          settings.staleAfterDaysWithoutUpdates,
        );
      });

      test('copies with staleAfterDaysWithoutUpdates change', () {
        const settings = SoftGatesSettings();

        final copied = settings.copyWith(staleAfterDaysWithoutUpdates: 90);

        expect(copied.staleAfterDaysWithoutUpdates, 90);
        expect(
          copied.urgentDeadlineWithinDays,
          settings.urgentDeadlineWithinDays,
        );
      });

      test('copies with both values changed', () {
        const settings = SoftGatesSettings();

        final copied = settings.copyWith(
          urgentDeadlineWithinDays: 3,
          staleAfterDaysWithoutUpdates: 15,
        );

        expect(copied.urgentDeadlineWithinDays, 3);
        expect(copied.staleAfterDaysWithoutUpdates, 15);
      });
    });

    group('equality', () {
      test('equal settings are equal', () {
        const settings1 = SoftGatesSettings(
          urgentDeadlineWithinDays: 5,
          staleAfterDaysWithoutUpdates: 25,
        );
        const settings2 = SoftGatesSettings(
          urgentDeadlineWithinDays: 5,
          staleAfterDaysWithoutUpdates: 25,
        );

        expect(settings1, settings2);
        expect(settings1.hashCode, settings2.hashCode);
      });

      test('different urgentDeadlineWithinDays are not equal', () {
        const settings1 = SoftGatesSettings(urgentDeadlineWithinDays: 7);
        const settings2 = SoftGatesSettings(urgentDeadlineWithinDays: 14);

        expect(settings1, isNot(settings2));
      });

      test('different staleAfterDaysWithoutUpdates are not equal', () {
        const settings1 = SoftGatesSettings(staleAfterDaysWithoutUpdates: 30);
        const settings2 = SoftGatesSettings(staleAfterDaysWithoutUpdates: 60);

        expect(settings1, isNot(settings2));
      });
    });
  });
}
