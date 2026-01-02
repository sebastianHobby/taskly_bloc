import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/settings/next_actions_settings.dart';
import 'package:taskly_bloc/domain/models/sort_preferences.dart';

void main() {
  group('NextActionsSettings', () {
    group('constructor', () {
      test('creates with default values', () {
        const settings = NextActionsSettings();

        expect(settings.tasksPerProject, 2);
        expect(settings.includeInboxTasks, true);
        expect(settings.excludeFutureStartDates, true);
        expect(settings.sortPreferences, const SortPreferences());
      });

      test('creates with custom values', () {
        const sortPrefs = SortPreferences(
          criteria: [SortCriterion(field: SortField.deadlineDate)],
        );
        const settings = NextActionsSettings(
          tasksPerProject: 5,
          includeInboxTasks: false,
          excludeFutureStartDates: false,
          sortPreferences: sortPrefs,
        );

        expect(settings.tasksPerProject, 5);
        expect(settings.includeInboxTasks, false);
        expect(settings.excludeFutureStartDates, false);
        expect(settings.sortPreferences, sortPrefs);
      });
    });

    group('fromJson', () {
      test('parses complete JSON', () {
        final json = {
          'tasksPerProject': 3,
          'includeInboxTasks': false,
          'excludeFutureStartDates': false,
          'sortPreferences': {'criteria': <Map<String, dynamic>>[]},
        };

        final settings = NextActionsSettings.fromJson(json);

        expect(settings.tasksPerProject, 3);
        expect(settings.includeInboxTasks, false);
        expect(settings.excludeFutureStartDates, false);
        expect(settings.sortPreferences, const SortPreferences());
      });

      test('parses empty JSON with defaults', () {
        final settings = NextActionsSettings.fromJson({});

        expect(settings.tasksPerProject, 1);
        expect(settings.includeInboxTasks, true);
        expect(settings.excludeFutureStartDates, true);
        expect(settings.sortPreferences, const SortPreferences());
      });

      test('clamps tasksPerProject less than 1 to 1', () {
        final json = {'tasksPerProject': 0};

        final settings = NextActionsSettings.fromJson(json);

        expect(settings.tasksPerProject, 1);
      });

      test('clamps negative tasksPerProject to 1', () {
        final json = {'tasksPerProject': -5};

        final settings = NextActionsSettings.fromJson(json);

        expect(settings.tasksPerProject, 1);
      });

      test('parses null tasksPerProject as 1', () {
        final json = {'tasksPerProject': null};

        final settings = NextActionsSettings.fromJson(json);

        expect(settings.tasksPerProject, 1);
      });

      test('parses null booleans with defaults', () {
        final json = {
          'includeInboxTasks': null,
          'excludeFutureStartDates': null,
        };

        final settings = NextActionsSettings.fromJson(json);

        expect(settings.includeInboxTasks, true);
        expect(settings.excludeFutureStartDates, true);
      });

      test('parses null sortPreferences as default', () {
        final json = {'sortPreferences': null};

        final settings = NextActionsSettings.fromJson(json);

        expect(settings.sortPreferences, const SortPreferences());
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        const settings = NextActionsSettings(
          tasksPerProject: 4,
          includeInboxTasks: false,
          excludeFutureStartDates: true,
        );

        final json = settings.toJson();

        expect(json['tasksPerProject'], 4);
        expect(json['includeInboxTasks'], false);
        expect(json['excludeFutureStartDates'], true);
        expect(json['sortPreferences'], isA<Map>());
      });

      test('round-trips through JSON', () {
        const original = NextActionsSettings(
          tasksPerProject: 3,
          includeInboxTasks: false,
          excludeFutureStartDates: false,
        );

        final json = original.toJson();
        final restored = NextActionsSettings.fromJson(json);

        expect(restored, original);
      });
    });

    group('copyWith', () {
      test('copies with no changes', () {
        const settings = NextActionsSettings(
          tasksPerProject: 3,
          includeInboxTasks: false,
        );

        final copied = settings.copyWith();

        expect(copied, settings);
      });

      test('copies with tasksPerProject change', () {
        const settings = NextActionsSettings();

        final copied = settings.copyWith(tasksPerProject: 10);

        expect(copied.tasksPerProject, 10);
        expect(copied.includeInboxTasks, settings.includeInboxTasks);
      });

      test('copies with includeInboxTasks change', () {
        const settings = NextActionsSettings();

        final copied = settings.copyWith(includeInboxTasks: false);

        expect(copied.includeInboxTasks, false);
      });

      test('copies with excludeFutureStartDates change', () {
        const settings = NextActionsSettings();

        final copied = settings.copyWith(excludeFutureStartDates: false);

        expect(copied.excludeFutureStartDates, false);
      });

      test('copies with sortPreferences change', () {
        const settings = NextActionsSettings();
        const newPrefs = SortPreferences(
          criteria: [
            SortCriterion(
              field: SortField.name,
              direction: SortDirection.descending,
            ),
          ],
        );

        final copied = settings.copyWith(sortPreferences: newPrefs);

        expect(copied.sortPreferences, newPrefs);
      });

      test('copies with multiple changes', () {
        const settings = NextActionsSettings();

        final copied = settings.copyWith(
          tasksPerProject: 5,
          includeInboxTasks: false,
          excludeFutureStartDates: false,
        );

        expect(copied.tasksPerProject, 5);
        expect(copied.includeInboxTasks, false);
        expect(copied.excludeFutureStartDates, false);
      });
    });

    group('equality', () {
      test('equal settings are equal', () {
        const settings1 = NextActionsSettings(
          tasksPerProject: 3,
          includeInboxTasks: false,
        );
        const settings2 = NextActionsSettings(
          tasksPerProject: 3,
          includeInboxTasks: false,
        );

        expect(settings1, settings2);
        expect(settings1.hashCode, settings2.hashCode);
      });

      test('different tasksPerProject are not equal', () {
        const settings1 = NextActionsSettings(tasksPerProject: 2);
        const settings2 = NextActionsSettings(tasksPerProject: 5);

        expect(settings1, isNot(settings2));
      });

      test('different includeInboxTasks are not equal', () {
        const settings1 = NextActionsSettings(includeInboxTasks: true);
        const settings2 = NextActionsSettings(includeInboxTasks: false);

        expect(settings1, isNot(settings2));
      });

      test('different excludeFutureStartDates are not equal', () {
        const settings1 = NextActionsSettings(excludeFutureStartDates: true);
        const settings2 = NextActionsSettings(excludeFutureStartDates: false);

        expect(settings1, isNot(settings2));
      });

      test('different sortPreferences are not equal', () {
        const settings1 = NextActionsSettings();
        const settings2 = NextActionsSettings(
          sortPreferences: SortPreferences(
            criteria: [SortCriterion(field: SortField.deadlineDate)],
          ),
        );

        expect(settings1, isNot(settings2));
      });
    });
  });
}
