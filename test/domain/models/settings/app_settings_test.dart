import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/settings.dart';
import 'package:taskly_bloc/domain/models/sort_preferences.dart';

void main() {
  group('AppSettings', () {
    group('constructor', () {
      test('creates with default values', () {
        const settings = AppSettings();

        expect(settings.global, const GlobalSettings());
        expect(settings.pageSortPreferences, isEmpty);
        expect(settings.pageDisplaySettings, isEmpty);
        expect(settings.screenPreferences, isEmpty);
        expect(settings.allocation, const AllocationConfig());
        expect(settings.valueRanking, const ValueRanking());
        expect(settings.softGates, const SoftGatesSettings());
        expect(settings.nextActions, const NextActionsSettings());
      });

      test('creates with custom values', () {
        const global = GlobalSettings(themeMode: AppThemeMode.dark);
        const sortPrefs = {'page1': SortPreferences()};
        const displaySettings = {'page1': PageDisplaySettings()};
        const screenPrefs = {'screen1': ScreenPreferences()};
        const allocation = AllocationConfig(dailyLimit: 20);
        const valueRanking = ValueRanking();
        const softGates = SoftGatesSettings(urgentDeadlineWithinDays: 5);
        const nextActions = NextActionsSettings(tasksPerProject: 3);

        const settings = AppSettings(
          global: global,
          pageSortPreferences: sortPrefs,
          pageDisplaySettings: displaySettings,
          screenPreferences: screenPrefs,
          allocation: allocation,
          valueRanking: valueRanking,
          softGates: softGates,
          nextActions: nextActions,
        );

        expect(settings.global, global);
        expect(settings.pageSortPreferences, sortPrefs);
        expect(settings.pageDisplaySettings, displaySettings);
        expect(settings.screenPreferences, screenPrefs);
        expect(settings.allocation, allocation);
        expect(settings.valueRanking, valueRanking);
        expect(settings.softGates, softGates);
        expect(settings.nextActions, nextActions);
      });
    });

    group('fromJson', () {
      test('parses complete JSON', () {
        final json = {
          'global': {'themeMode': 'dark'},
          'pageSortPreferences': {
            'page1': {'criteria': <Map<String, dynamic>>[]},
          },
          'pageDisplaySettings': {
            'page1': {'hideCompleted': false},
          },
          'screenPreferences': {
            'screen1': {'sortOrder': 5, 'isActive': true},
          },
          'allocation': {'daily_limit': 15},
          'valueRanking': {'items': <Map<String, dynamic>>[]},
          'softGates': {'urgentDeadlineWithinDays': 3},
          'nextActions': {'tasksPerProject': 4},
        };

        final settings = AppSettings.fromJson(json);

        expect(settings.global.themeMode, AppThemeMode.dark);
        expect(settings.pageSortPreferences.containsKey('page1'), true);
        expect(settings.pageDisplaySettings['page1']?.hideCompleted, false);
        expect(settings.screenPreferences['screen1']?.sortOrder, 5);
        expect(settings.allocation.dailyLimit, 15);
        expect(settings.softGates.urgentDeadlineWithinDays, 3);
        expect(settings.nextActions.tasksPerProject, 4);
      });

      test('parses empty JSON with defaults', () {
        final settings = AppSettings.fromJson({});

        expect(settings.global, const GlobalSettings());
        expect(settings.pageSortPreferences, isEmpty);
        expect(settings.pageDisplaySettings, isEmpty);
        expect(settings.screenPreferences, isEmpty);
        expect(settings.allocation, const AllocationConfig());
        expect(settings.valueRanking, const ValueRanking());
        expect(settings.softGates, const SoftGatesSettings());
        expect(settings.nextActions, const NextActionsSettings());
      });

      test('ignores non-map values in pageSortPreferences', () {
        final json = {
          'pageSortPreferences': {
            'valid': {'criteria': <Map<String, dynamic>>[]},
            'invalid': 'not a map',
          },
        };

        final settings = AppSettings.fromJson(json);

        expect(settings.pageSortPreferences.containsKey('valid'), true);
        expect(settings.pageSortPreferences.containsKey('invalid'), false);
      });

      test('ignores non-map values in pageDisplaySettings', () {
        final json = {
          'pageDisplaySettings': {
            'valid': {'hideCompleted': true},
            'invalid': 123,
          },
        };

        final settings = AppSettings.fromJson(json);

        expect(settings.pageDisplaySettings.containsKey('valid'), true);
        expect(settings.pageDisplaySettings.containsKey('invalid'), false);
      });

      test('ignores non-map values in screenPreferences', () {
        final json = {
          'screenPreferences': {
            'valid': {'isActive': true},
            'invalid': <dynamic>[],
          },
        };

        final settings = AppSettings.fromJson(json);

        expect(settings.screenPreferences.containsKey('valid'), true);
        expect(settings.screenPreferences.containsKey('invalid'), false);
      });

      test('handles null allocation json', () {
        final json = {'allocation': null};

        final settings = AppSettings.fromJson(json);

        expect(settings.allocation, const AllocationConfig());
      });

      test('handles null valueRanking json', () {
        final json = {'valueRanking': null};

        final settings = AppSettings.fromJson(json);

        expect(settings.valueRanking, const ValueRanking());
      });

      test('handles null softGates json', () {
        final json = {'softGates': null};

        final settings = AppSettings.fromJson(json);

        expect(settings.softGates, const SoftGatesSettings());
      });

      test('handles null nextActions json', () {
        final json = {'nextActions': null};

        final settings = AppSettings.fromJson(json);

        expect(settings.nextActions, const NextActionsSettings());
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        const settings = AppSettings(
          global: GlobalSettings(themeMode: AppThemeMode.light),
          pageSortPreferences: {'p1': SortPreferences()},
          pageDisplaySettings: {
            'p1': PageDisplaySettings(hideCompleted: false),
          },
          screenPreferences: {'s1': ScreenPreferences(sortOrder: 1)},
          allocation: AllocationConfig(dailyLimit: 5),
          valueRanking: ValueRanking(),
          softGates: SoftGatesSettings(urgentDeadlineWithinDays: 10),
          nextActions: NextActionsSettings(tasksPerProject: 2),
        );

        final json = settings.toJson();

        expect(json['global'], isA<Map>());
        expect(json['pageSortPreferences'], isA<Map>());
        expect(json['pageDisplaySettings'], isA<Map>());
        expect(json['screenPreferences'], isA<Map>());
        expect(json['allocation'], isA<Map>());
        expect(json['valueRanking'], isA<Map>());
        expect(json['softGates'], isA<Map>());
        expect(json['nextActions'], isA<Map>());
      });

      test('round-trips through JSON', () {
        const settings = AppSettings(
          global: GlobalSettings(themeMode: AppThemeMode.dark),
          allocation: AllocationConfig(dailyLimit: 8),
        );

        final json = settings.toJson();
        final restored = AppSettings.fromJson(json);

        expect(restored.global.themeMode, settings.global.themeMode);
        expect(
          restored.allocation.dailyLimit,
          settings.allocation.dailyLimit,
        );
      });
    });

    group('copyWith', () {
      test('copies with no changes', () {
        const settings = AppSettings();

        final copied = settings.copyWith();

        expect(copied, settings);
      });

      test('copies with global change', () {
        const settings = AppSettings();
        const newGlobal = GlobalSettings(themeMode: AppThemeMode.dark);

        final copied = settings.copyWith(global: newGlobal);

        expect(copied.global, newGlobal);
      });

      test('copies with pageSortPreferences change', () {
        const settings = AppSettings();
        const newPrefs = {'page1': SortPreferences()};

        final copied = settings.copyWith(pageSortPreferences: newPrefs);

        expect(copied.pageSortPreferences, newPrefs);
      });

      test('copies with pageDisplaySettings change', () {
        const settings = AppSettings();
        const newDisplay = {'page1': PageDisplaySettings()};

        final copied = settings.copyWith(pageDisplaySettings: newDisplay);

        expect(copied.pageDisplaySettings, newDisplay);
      });

      test('copies with screenPreferences change', () {
        const settings = AppSettings();
        const newScreenPrefs = {'screen1': ScreenPreferences()};

        final copied = settings.copyWith(screenPreferences: newScreenPrefs);

        expect(copied.screenPreferences, newScreenPrefs);
      });

      test('copies with allocation change', () {
        const settings = AppSettings();
        const newAllocation = AllocationConfig(dailyLimit: 20);

        final copied = settings.copyWith(allocation: newAllocation);

        expect(copied.allocation, newAllocation);
      });

      test('copies with valueRanking change', () {
        const settings = AppSettings();
        const newRanking = ValueRanking(
          items: [ValueRankItem(valueId: 'test', weight: 5)],
        );

        final copied = settings.copyWith(valueRanking: newRanking);

        expect(copied.valueRanking, newRanking);
      });

      test('copies with softGates change', () {
        const settings = AppSettings();
        const newSoftGates = SoftGatesSettings(urgentDeadlineWithinDays: 14);

        final copied = settings.copyWith(softGates: newSoftGates);

        expect(copied.softGates, newSoftGates);
      });

      test('copies with nextActions change', () {
        const settings = AppSettings();
        const newNextActions = NextActionsSettings(tasksPerProject: 5);

        final copied = settings.copyWith(nextActions: newNextActions);

        expect(copied.nextActions, newNextActions);
      });
    });

    group('update methods', () {
      test('updateGlobal updates global settings', () {
        const settings = AppSettings();
        const newGlobal = GlobalSettings(themeMode: AppThemeMode.dark);

        final updated = settings.updateGlobal(newGlobal);

        expect(updated.global, newGlobal);
      });

      test('updateSoftGates updates soft gates settings', () {
        const settings = AppSettings();
        const newSoftGates = SoftGatesSettings(urgentDeadlineWithinDays: 5);

        final updated = settings.updateSoftGates(newSoftGates);

        expect(updated.softGates, newSoftGates);
      });

      test('updateNextActions updates next actions settings', () {
        const settings = AppSettings();
        const newNextActions = NextActionsSettings(tasksPerProject: 3);

        final updated = settings.updateNextActions(newNextActions);

        expect(updated.nextActions, newNextActions);
      });

      test('updateAllocation updates allocation settings', () {
        const settings = AppSettings();
        const newAllocation = AllocationConfig(dailyLimit: 25);

        final updated = settings.updateAllocation(newAllocation);

        expect(updated.allocation, newAllocation);
      });

      test('updateValueRanking updates value ranking', () {
        const settings = AppSettings();
        const newRanking = ValueRanking(
          items: [ValueRankItem(valueId: 'x', weight: 8)],
        );

        final updated = settings.updateValueRanking(newRanking);

        expect(updated.valueRanking, newRanking);
      });
    });

    group('sortFor', () {
      test('returns sort preferences for existing page', () {
        const prefs = SortPreferences();
        const settings = AppSettings(
          pageSortPreferences: {'myPage': prefs},
        );

        expect(settings.sortFor('myPage'), prefs);
      });

      test('returns null for non-existing page', () {
        const settings = AppSettings();

        expect(settings.sortFor('nonExistent'), isNull);
      });
    });

    group('displaySettingsFor', () {
      test('returns display settings for existing page', () {
        const display = PageDisplaySettings(hideCompleted: false);
        const settings = AppSettings(
          pageDisplaySettings: {'myPage': display},
        );

        expect(settings.displaySettingsFor('myPage'), display);
      });

      test('returns default settings for non-existing page', () {
        const settings = AppSettings();

        expect(
          settings.displaySettingsFor('nonExistent'),
          const PageDisplaySettings(),
        );
      });
    });

    group('screenPreferencesFor', () {
      test('returns screen preferences for existing screen', () {
        const prefs = ScreenPreferences(sortOrder: 5);
        const settings = AppSettings(
          screenPreferences: {'myScreen': prefs},
        );

        expect(settings.screenPreferencesFor('myScreen'), prefs);
      });

      test('returns default preferences for non-existing screen', () {
        const settings = AppSettings();

        expect(
          settings.screenPreferencesFor('nonExistent'),
          const ScreenPreferences(),
        );
      });
    });

    group('upsertPageSort', () {
      test('adds new page sort preferences', () {
        const settings = AppSettings();
        const newPrefs = SortPreferences();

        final updated = settings.upsertPageSort(
          pageKey: 'newPage',
          preferences: newPrefs,
        );

        expect(updated.pageSortPreferences['newPage'], newPrefs);
      });

      test('updates existing page sort preferences', () {
        const oldPrefs = SortPreferences();
        const settings = AppSettings(
          pageSortPreferences: {'existingPage': oldPrefs},
        );
        const newPrefs = SortPreferences(
          criteria: [
            SortCriterion(
              field: SortField.name,
              direction: SortDirection.descending,
            ),
          ],
        );

        final updated = settings.upsertPageSort(
          pageKey: 'existingPage',
          preferences: newPrefs,
        );

        expect(updated.pageSortPreferences['existingPage'], newPrefs);
      });
    });

    group('upsertPageDisplaySettings', () {
      test('adds new page display settings', () {
        const settings = AppSettings();
        const newDisplay = PageDisplaySettings(hideCompleted: false);

        final updated = settings.upsertPageDisplaySettings(
          pageKey: 'newPage',
          settings: newDisplay,
        );

        expect(updated.pageDisplaySettings['newPage'], newDisplay);
      });

      test('updates existing page display settings', () {
        const oldDisplay = PageDisplaySettings();
        const settings = AppSettings(
          pageDisplaySettings: {'existingPage': oldDisplay},
        );
        const newDisplay = PageDisplaySettings(hideCompleted: false);

        final updated = settings.upsertPageDisplaySettings(
          pageKey: 'existingPage',
          settings: newDisplay,
        );

        expect(updated.pageDisplaySettings['existingPage'], newDisplay);
      });
    });

    group('upsertScreenPreferences', () {
      test('adds new screen preferences', () {
        const settings = AppSettings();
        const newPrefs = ScreenPreferences(sortOrder: 10);

        final updated = settings.upsertScreenPreferences(
          screenKey: 'newScreen',
          preferences: newPrefs,
        );

        expect(updated.screenPreferences['newScreen'], newPrefs);
      });

      test('updates existing screen preferences', () {
        const oldPrefs = ScreenPreferences(sortOrder: 1);
        const settings = AppSettings(
          screenPreferences: {'existingScreen': oldPrefs},
        );
        const newPrefs = ScreenPreferences(sortOrder: 99);

        final updated = settings.upsertScreenPreferences(
          screenKey: 'existingScreen',
          preferences: newPrefs,
        );

        expect(updated.screenPreferences['existingScreen'], newPrefs);
      });
    });

    group('equality', () {
      test('equal settings are equal', () {
        const settings1 = AppSettings();
        const settings2 = AppSettings();

        expect(settings1, settings2);
        expect(settings1.hashCode, settings2.hashCode);
      });

      test('different global are not equal', () {
        const settings1 = AppSettings();
        const settings2 = AppSettings(
          global: GlobalSettings(themeMode: AppThemeMode.dark),
        );

        expect(settings1, isNot(settings2));
      });

      test('different pageSortPreferences length are not equal', () {
        const settings1 = AppSettings();
        const settings2 = AppSettings(
          pageSortPreferences: {'page1': SortPreferences()},
        );

        expect(settings1, isNot(settings2));
      });

      test('different pageSortPreferences values are not equal', () {
        const settings1 = AppSettings(
          pageSortPreferences: {
            'page1': SortPreferences(
              criteria: [SortCriterion(field: SortField.name)],
            ),
          },
        );
        const settings2 = AppSettings(
          pageSortPreferences: {
            'page1': SortPreferences(
              criteria: [SortCriterion(field: SortField.deadlineDate)],
            ),
          },
        );

        expect(settings1, isNot(settings2));
      });

      test('different pageDisplaySettings length are not equal', () {
        const settings1 = AppSettings();
        const settings2 = AppSettings(
          pageDisplaySettings: {'page1': PageDisplaySettings()},
        );

        expect(settings1, isNot(settings2));
      });

      test('different pageDisplaySettings values are not equal', () {
        const settings1 = AppSettings(
          pageDisplaySettings: {
            'page1': PageDisplaySettings(hideCompleted: true),
          },
        );
        const settings2 = AppSettings(
          pageDisplaySettings: {
            'page1': PageDisplaySettings(hideCompleted: false),
          },
        );

        expect(settings1, isNot(settings2));
      });

      test('different screenPreferences length are not equal', () {
        const settings1 = AppSettings();
        const settings2 = AppSettings(
          screenPreferences: {'screen1': ScreenPreferences()},
        );

        expect(settings1, isNot(settings2));
      });

      test('different screenPreferences values are not equal', () {
        const settings1 = AppSettings(
          screenPreferences: {
            'screen1': ScreenPreferences(sortOrder: 1),
          },
        );
        const settings2 = AppSettings(
          screenPreferences: {
            'screen1': ScreenPreferences(sortOrder: 2),
          },
        );

        expect(settings1, isNot(settings2));
      });

      test('different allocation are not equal', () {
        const settings1 = AppSettings();
        const settings2 = AppSettings(
          allocation: AllocationConfig(dailyLimit: 99),
        );

        expect(settings1, isNot(settings2));
      });

      test('different valueRanking are not equal', () {
        const settings1 = AppSettings();
        const settings2 = AppSettings(
          valueRanking: ValueRanking(
            items: [ValueRankItem(valueId: 'x', weight: 5)],
          ),
        );

        expect(settings1, isNot(settings2));
      });

      test('different softGates are not equal', () {
        const settings1 = AppSettings();
        const settings2 = AppSettings(
          softGates: SoftGatesSettings(urgentDeadlineWithinDays: 99),
        );

        expect(settings1, isNot(settings2));
      });

      test('different nextActions are not equal', () {
        const settings1 = AppSettings();
        const settings2 = AppSettings(
          nextActions: NextActionsSettings(tasksPerProject: 99),
        );

        expect(settings1, isNot(settings2));
      });

      test('not equal to non-AppSettings', () {
        const settings = AppSettings();
        // ignore: unrelated_type_equality_checks
        expect(settings == 'not settings', false);
      });
    });
  });
}
