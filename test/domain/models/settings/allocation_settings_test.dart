import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/settings/allocation_settings.dart';

void main() {
  group('AllocationStrategyType', () {
    test('has all expected values', () {
      expect(AllocationStrategyType.values, [
        AllocationStrategyType.proportional,
        AllocationStrategyType.urgencyWeighted,
        AllocationStrategyType.roundRobin,
        AllocationStrategyType.minimumViable,
        AllocationStrategyType.dynamic,
        AllocationStrategyType.topCategories,
      ]);
    });
  });

  group('AllocationSettings', () {
    group('constructor', () {
      test('creates with default values', () {
        const settings = AllocationSettings();

        expect(settings.strategyType, AllocationStrategyType.proportional);
        expect(settings.urgencyInfluence, 0.4);
        expect(settings.minimumTasksPerCategory, 1);
        expect(settings.topNCategories, 3);
        expect(settings.dailyTaskLimit, 10);
        expect(settings.showExcludedUrgentWarning, true);
      });

      test('creates with custom values', () {
        const settings = AllocationSettings(
          strategyType: AllocationStrategyType.urgencyWeighted,
          urgencyInfluence: 0.8,
          minimumTasksPerCategory: 2,
          topNCategories: 5,
          dailyTaskLimit: 20,
          showExcludedUrgentWarning: false,
        );

        expect(settings.strategyType, AllocationStrategyType.urgencyWeighted);
        expect(settings.urgencyInfluence, 0.8);
        expect(settings.minimumTasksPerCategory, 2);
        expect(settings.topNCategories, 5);
        expect(settings.dailyTaskLimit, 20);
        expect(settings.showExcludedUrgentWarning, false);
      });
    });

    group('fromJson', () {
      test('parses complete JSON', () {
        final json = {
          'strategyType': 'roundRobin',
          'urgencyInfluence': 0.6,
          'minimumTasksPerCategory': 3,
          'topNCategories': 4,
          'dailyTaskLimit': 15,
          'showExcludedUrgentWarning': false,
        };

        final settings = AllocationSettings.fromJson(json);

        expect(settings.strategyType, AllocationStrategyType.roundRobin);
        expect(settings.urgencyInfluence, 0.6);
        expect(settings.minimumTasksPerCategory, 3);
        expect(settings.topNCategories, 4);
        expect(settings.dailyTaskLimit, 15);
        expect(settings.showExcludedUrgentWarning, false);
      });

      test('parses empty JSON with defaults', () {
        final settings = AllocationSettings.fromJson(const {});

        expect(settings.strategyType, AllocationStrategyType.proportional);
        expect(settings.urgencyInfluence, 0.4);
        expect(settings.minimumTasksPerCategory, 1);
        expect(settings.topNCategories, 3);
        expect(settings.dailyTaskLimit, 10);
        expect(settings.showExcludedUrgentWarning, true);
      });

      test('parses all strategy types', () {
        for (final type in AllocationStrategyType.values) {
          final json = {'strategyType': type.name};
          final settings = AllocationSettings.fromJson(json);
          expect(settings.strategyType, type);
        }
      });

      test('parses null strategyType as proportional', () {
        final settings = AllocationSettings.fromJson(const {
          'strategyType': null,
        });

        expect(settings.strategyType, AllocationStrategyType.proportional);
      });

      test('parses unknown strategyType as proportional', () {
        final settings = AllocationSettings.fromJson(const {
          'strategyType': 'unknownStrategy',
        });

        expect(settings.strategyType, AllocationStrategyType.proportional);
      });

      test('parses urgencyInfluence from int', () {
        final settings = AllocationSettings.fromJson(const {
          'urgencyInfluence': 1,
        });

        expect(settings.urgencyInfluence, 1.0);
      });

      test('parses null values with defaults', () {
        final json = {
          'strategyType': null,
          'urgencyInfluence': null,
          'minimumTasksPerCategory': null,
          'topNCategories': null,
          'dailyTaskLimit': null,
          'showExcludedUrgentWarning': null,
        };

        final settings = AllocationSettings.fromJson(json);

        expect(settings.strategyType, AllocationStrategyType.proportional);
        expect(settings.urgencyInfluence, 0.4);
        expect(settings.minimumTasksPerCategory, 1);
        expect(settings.topNCategories, 3);
        expect(settings.dailyTaskLimit, 10);
        expect(settings.showExcludedUrgentWarning, true);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        const settings = AllocationSettings(
          strategyType: AllocationStrategyType.dynamic,
          urgencyInfluence: 0.5,
          minimumTasksPerCategory: 2,
          topNCategories: 6,
          dailyTaskLimit: 25,
          showExcludedUrgentWarning: false,
        );

        final json = settings.toJson();

        expect(json['strategyType'], 'dynamic');
        expect(json['urgencyInfluence'], 0.5);
        expect(json['minimumTasksPerCategory'], 2);
        expect(json['topNCategories'], 6);
        expect(json['dailyTaskLimit'], 25);
        expect(json['showExcludedUrgentWarning'], false);
      });

      test('round-trips through JSON', () {
        const original = AllocationSettings(
          strategyType: AllocationStrategyType.topCategories,
          urgencyInfluence: 0.75,
          minimumTasksPerCategory: 3,
          topNCategories: 4,
          dailyTaskLimit: 12,
          showExcludedUrgentWarning: true,
        );

        final json = original.toJson();
        final restored = AllocationSettings.fromJson(json);

        expect(restored, original);
      });
    });

    group('copyWith', () {
      test('copies with no changes', () {
        const settings = AllocationSettings(
          strategyType: AllocationStrategyType.minimumViable,
          dailyTaskLimit: 15,
        );

        final copied = settings.copyWith();

        expect(copied, settings);
      });

      test('copies with strategyType change', () {
        const settings = AllocationSettings();

        final copied = settings.copyWith(
          strategyType: AllocationStrategyType.urgencyWeighted,
        );

        expect(copied.strategyType, AllocationStrategyType.urgencyWeighted);
        expect(copied.dailyTaskLimit, settings.dailyTaskLimit);
      });

      test('copies with urgencyInfluence change', () {
        const settings = AllocationSettings();

        final copied = settings.copyWith(urgencyInfluence: 0.9);

        expect(copied.urgencyInfluence, 0.9);
      });

      test('copies with minimumTasksPerCategory change', () {
        const settings = AllocationSettings();

        final copied = settings.copyWith(minimumTasksPerCategory: 5);

        expect(copied.minimumTasksPerCategory, 5);
      });

      test('copies with topNCategories change', () {
        const settings = AllocationSettings();

        final copied = settings.copyWith(topNCategories: 10);

        expect(copied.topNCategories, 10);
      });

      test('copies with dailyTaskLimit change', () {
        const settings = AllocationSettings();

        final copied = settings.copyWith(dailyTaskLimit: 30);

        expect(copied.dailyTaskLimit, 30);
      });

      test('copies with showExcludedUrgentWarning change', () {
        const settings = AllocationSettings();

        final copied = settings.copyWith(showExcludedUrgentWarning: false);

        expect(copied.showExcludedUrgentWarning, false);
      });

      test('copies with multiple changes', () {
        const settings = AllocationSettings();

        final copied = settings.copyWith(
          strategyType: AllocationStrategyType.roundRobin,
          dailyTaskLimit: 20,
          showExcludedUrgentWarning: false,
        );

        expect(copied.strategyType, AllocationStrategyType.roundRobin);
        expect(copied.dailyTaskLimit, 20);
        expect(copied.showExcludedUrgentWarning, false);
        expect(copied.urgencyInfluence, settings.urgencyInfluence);
      });
    });

    group('equality', () {
      test('equal settings are equal', () {
        const settings1 = AllocationSettings(
          strategyType: AllocationStrategyType.dynamic,
          dailyTaskLimit: 15,
        );
        const settings2 = AllocationSettings(
          strategyType: AllocationStrategyType.dynamic,
          dailyTaskLimit: 15,
        );

        expect(settings1, settings2);
        expect(settings1.hashCode, settings2.hashCode);
      });

      test('different strategyType are not equal', () {
        const settings1 = AllocationSettings(
          strategyType: AllocationStrategyType.proportional,
        );
        const settings2 = AllocationSettings(
          strategyType: AllocationStrategyType.roundRobin,
        );

        expect(settings1, isNot(settings2));
      });

      test('different urgencyInfluence are not equal', () {
        const settings1 = AllocationSettings(urgencyInfluence: 0.4);
        const settings2 = AllocationSettings(urgencyInfluence: 0.5);

        expect(settings1, isNot(settings2));
      });

      test('different minimumTasksPerCategory are not equal', () {
        const settings1 = AllocationSettings(minimumTasksPerCategory: 1);
        const settings2 = AllocationSettings(minimumTasksPerCategory: 2);

        expect(settings1, isNot(settings2));
      });

      test('different topNCategories are not equal', () {
        const settings1 = AllocationSettings(topNCategories: 3);
        const settings2 = AllocationSettings(topNCategories: 5);

        expect(settings1, isNot(settings2));
      });

      test('different dailyTaskLimit are not equal', () {
        const settings1 = AllocationSettings(dailyTaskLimit: 10);
        const settings2 = AllocationSettings(dailyTaskLimit: 20);

        expect(settings1, isNot(settings2));
      });

      test('different showExcludedUrgentWarning are not equal', () {
        const settings1 = AllocationSettings(showExcludedUrgentWarning: true);
        const settings2 = AllocationSettings(showExcludedUrgentWarning: false);

        expect(settings1, isNot(settings2));
      });

      test('identical returns true for same instance', () {
        const settings = AllocationSettings();

        expect(settings == settings, true);
      });
    });

    group('alwaysIncludeUrgent', () {
      test('defaults to false', () {
        const settings = AllocationSettings();
        expect(settings.alwaysIncludeUrgent, false);
      });

      test('can be set to true', () {
        const settings = AllocationSettings(alwaysIncludeUrgent: true);
        expect(settings.alwaysIncludeUrgent, true);
      });

      test('fromJson parses alwaysIncludeUrgent', () {
        final settings = AllocationSettings.fromJson(const {
          'alwaysIncludeUrgent': true,
        });
        expect(settings.alwaysIncludeUrgent, true);
      });

      test('toJson includes alwaysIncludeUrgent', () {
        const settings = AllocationSettings(alwaysIncludeUrgent: true);
        expect(settings.toJson()['alwaysIncludeUrgent'], true);
      });

      test('copyWith updates alwaysIncludeUrgent', () {
        const settings = AllocationSettings();
        final updated = settings.copyWith(alwaysIncludeUrgent: true);
        expect(updated.alwaysIncludeUrgent, true);
      });

      test('different alwaysIncludeUrgent values are not equal', () {
        const settings1 = AllocationSettings(alwaysIncludeUrgent: true);
        const settings2 = AllocationSettings(alwaysIncludeUrgent: false);
        expect(settings1, isNot(settings2));
      });
    });
  });
}
