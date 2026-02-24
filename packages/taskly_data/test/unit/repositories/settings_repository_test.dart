@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';
import '../../helpers/test_db.dart';

import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:matcher/matcher.dart' as matcher;
import 'package:taskly_data/db.dart';
import 'package:taskly_data/src/repositories/settings_repository.dart';
import 'package:taskly_domain/taskly_domain.dart' hide Value;

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('SettingsRepository', () {
    testSafe('load returns default when no profile exists', () async {
      final db = createAutoClosingDb();
      final repo = SettingsRepository(driftDb: db);

      final result = await repo.load(SettingsKey.global);
      expect(result, equals(const GlobalSettings()));
    });

    testSafe('save and load global settings', () async {
      final db = createAutoClosingDb();
      final repo = SettingsRepository(driftDb: db);

      const settings = GlobalSettings(
        themeMode: AppThemeMode.dark,
        colorSchemeSeedArgb: 0xFF00FF00,
        localeCode: 'en',
        homeTimeZoneOffsetMinutes: 120,
        textScaleFactor: 1.1,
        onboardingCompleted: true,
      );

      await repo.save(SettingsKey.global, settings);
      final loaded = await repo.load(SettingsKey.global);
      expect(loaded, equals(settings));
    });

    testSafe('save and load allocation settings', () async {
      final db = createAutoClosingDb();
      final repo = SettingsRepository(driftDb: db);

      const allocation = AllocationConfig(
        suggestionsPerBatch: 7,
        hasSelectedFocusMode: true,
        suggestionSignal: SuggestionSignal.behaviorBased,
      );

      await repo.save(SettingsKey.allocation, allocation);
      final loaded = await repo.load(SettingsKey.allocation);
      expect(loaded, equals(allocation));
    });

    testSafe('save and load page sort preferences', () async {
      final db = createAutoClosingDb();
      final repo = SettingsRepository(driftDb: db);

      const prefs = SortPreferences(
        criteria: [SortCriterion(field: SortField.createdDate)],
      );

      await repo.save(SettingsKey.pageSort(PageKey.tasksInbox), prefs);
      final loaded = await repo.load(SettingsKey.pageSort(PageKey.tasksInbox));

      expect(loaded, equals(prefs));

      await repo.save(SettingsKey.pageSort(PageKey.tasksInbox), null);
      final cleared = await repo.load(SettingsKey.pageSort(PageKey.tasksInbox));
      expect(cleared, matcher.isNull);
    });

    testSafe('save and load page display preferences', () async {
      final db = createAutoClosingDb();
      final repo = SettingsRepository(driftDb: db);

      const prefs = DisplayPreferences(density: DisplayDensity.compact);

      await repo.save(SettingsKey.pageDisplay(PageKey.projectOverview), prefs);
      final loaded = await repo.load(
        SettingsKey.pageDisplay(PageKey.projectOverview),
      );

      expect(loaded, equals(prefs));

      await repo.save(SettingsKey.pageDisplay(PageKey.projectOverview), null);
      final cleared = await repo.load(
        SettingsKey.pageDisplay(PageKey.projectOverview),
      );
      expect(cleared, matcher.isNull);
    });

    testSafe('save and load micro-learning seen flag', () async {
      final db = createAutoClosingDb();
      final repo = SettingsRepository(driftDb: db);
      const tipId = 'projects_backlog';

      final initial = await repo.load(SettingsKey.microLearningSeen(tipId));
      expect(initial, isFalse);

      await repo.save(SettingsKey.microLearningSeen(tipId), true);
      final seen = await repo.load(SettingsKey.microLearningSeen(tipId));
      expect(seen, isTrue);

      await repo.save(SettingsKey.microLearningSeen(tipId), false);
      final cleared = await repo.load(SettingsKey.microLearningSeen(tipId));
      expect(cleared, isFalse);
    });

    testSafe('invalid JSON triggers repair and defaults', () async {
      final db = createAutoClosingDb();
      final repo = SettingsRepository(driftDb: db);

      await db
          .into(db.userProfileTable)
          .insert(
            UserProfileTableCompanion.insert(
              settingsOverrides: const drift.Value('not-json'),
              createdAt: drift.Value(DateTime.utc(2024, 1, 1)),
              updatedAt: drift.Value(DateTime.utc(2024, 1, 1)),
            ),
          );

      final loaded = await repo.load(SettingsKey.global);
      expect(loaded, equals(const GlobalSettings()));

      await Future<void>.delayed(const Duration(milliseconds: 10));

      final row = await db.select(db.userProfileTable).getSingle();
      final overrides =
          jsonDecode(row.settingsOverrides!) as Map<String, dynamic>;
      expect(overrides.containsKey('_repairs'), isTrue);
    });

    testSafe(
      'invalid singleton/object shapes are repaired and defaulted',
      () async {
        final db = createAutoClosingDb();
        final repo = SettingsRepository(driftDb: db);

        await db
            .into(db.userProfileTable)
            .insert(
              UserProfileTableCompanion.insert(
                settingsOverrides: const drift.Value(
                  '{"global":"bad","allocation":{"idleScale":"bad"}}',
                ),
                createdAt: drift.Value(DateTime.utc(2024, 1, 1)),
                updatedAt: drift.Value(DateTime.utc(2024, 1, 1)),
              ),
            );

        final global = await repo.load(SettingsKey.global);
        final allocation = await repo.load(SettingsKey.allocation);
        expect(global, equals(const GlobalSettings()));
        expect(allocation, equals(const AllocationConfig()));
      },
    );

    testSafe('invalid keyed groups and entries default and repair', () async {
      final db = createAutoClosingDb();
      final repo = SettingsRepository(driftDb: db);

      await db
          .into(db.userProfileTable)
          .insert(
            UserProfileTableCompanion.insert(
              settingsOverrides: const drift.Value(
                '{"pageSort":"oops","pageDisplay":{"project_overview":"oops"},'
                '"microLearningSeen":{"tip":"yes"}}',
              ),
              createdAt: drift.Value(DateTime.utc(2024, 1, 1)),
              updatedAt: drift.Value(DateTime.utc(2024, 1, 1)),
            ),
          );

      final sort = await repo.load(SettingsKey.pageSort(PageKey.tasksInbox));
      final display = await repo.load(
        SettingsKey.pageDisplay(PageKey.projectOverview),
      );
      final tipSeen = await repo.load(SettingsKey.microLearningSeen('tip'));

      expect(sort, isNull);
      expect(display, isNull);
      expect(tipSeen, isFalse);
    });

    testSafe('watch emits saved values for singleton settings', () async {
      final db = createAutoClosingDb();
      final repo = SettingsRepository(driftDb: db);

      final stream = repo.watch(SettingsKey.global);
      expect(await stream.first, equals(const GlobalSettings()));

      const updated = GlobalSettings(themeMode: AppThemeMode.dark);
      await repo.save(SettingsKey.global, updated);
      expect(await stream.firstWhere((v) => v == updated), equals(updated));
    });

    testSafe(
      'repairs invalid map shape and throttles repeated repair writes',
      () async {
        final db = createAutoClosingDb();
        final repo = SettingsRepository(driftDb: db);

        await db
            .into(db.userProfileTable)
            .insert(
              UserProfileTableCompanion.insert(
                settingsOverrides: const drift.Value('[]'),
                createdAt: drift.Value(DateTime.utc(2024, 1, 1)),
                updatedAt: drift.Value(DateTime.utc(2024, 1, 1)),
              ),
            );

        final first = await repo.load(SettingsKey.global);
        final second = await repo.load(SettingsKey.global);
        expect(first, equals(const GlobalSettings()));
        expect(second, equals(const GlobalSettings()));

        await Future<void>.delayed(const Duration(milliseconds: 10));
        final row = await db.select(db.userProfileTable).getSingle();
        final overrides =
            jsonDecode(row.settingsOverrides!) as Map<String, dynamic>;
        expect(overrides['_repairs'], isA<Map<String, dynamic>>());
      },
    );

    testSafe('long invalid JSON stores truncated repair preview', () async {
      final db = createAutoClosingDb();
      final repo = SettingsRepository(driftDb: db);

      final veryLongInvalid = '${List.filled(900, 'x').join()}{';
      await db
          .into(db.userProfileTable)
          .insert(
            UserProfileTableCompanion.insert(
              settingsOverrides: drift.Value(veryLongInvalid),
              createdAt: drift.Value(DateTime.utc(2024, 1, 2)),
              updatedAt: drift.Value(DateTime.utc(2024, 1, 2)),
            ),
          );

      await repo.load(SettingsKey.global);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final row = await db.select(db.userProfileTable).getSingle();
      final overrides =
          jsonDecode(row.settingsOverrides!) as Map<String, dynamic>;
      final repairs = overrides['_repairs'] as Map<String, dynamic>;
      final repair = repairs['settings_overrides'] as Map<String, dynamic>;
      final preview = repair['repaired_from'] as String;
      expect(preview.length, lessThanOrEqualTo(501));
    });

    testSafe(
      'singleton decode fromJson failure falls back to defaults',
      () async {
        final db = createAutoClosingDb();
        final repo = SettingsRepository(driftDb: db);

        await db
            .into(db.userProfileTable)
            .insert(
              UserProfileTableCompanion.insert(
                settingsOverrides: const drift.Value(
                  '{"global":{"themeMode":"BAD_ENUM"},"allocation":{"suggestionSignal":"BAD_SIGNAL"}}',
                ),
                createdAt: drift.Value(DateTime.utc(2024, 1, 3)),
                updatedAt: drift.Value(DateTime.utc(2024, 1, 3)),
              ),
            );

        final global = await repo.load(SettingsKey.global);
        final allocation = await repo.load(SettingsKey.allocation);
        expect(global, equals(const GlobalSettings()));
        expect(allocation, equals(const AllocationConfig()));
      },
    );

    testSafe(
      'keyed entry-not-map branches are repaired and defaulted',
      () async {
        final db = createAutoClosingDb();
        final repo = SettingsRepository(driftDb: db);

        await db
            .into(db.userProfileTable)
            .insert(
              UserProfileTableCompanion.insert(
                settingsOverrides: const drift.Value(
                  '{"pageSort":{"tasks_inbox":"oops"},'
                  '"pageDisplay":"oops"}',
                ),
                createdAt: drift.Value(DateTime.utc(2024, 1, 4)),
                updatedAt: drift.Value(DateTime.utc(2024, 1, 4)),
              ),
            );

        final sort = await repo.load(SettingsKey.pageSort(PageKey.tasksInbox));
        final display = await repo.load(
          SettingsKey.pageDisplay(PageKey.projectOverview),
        );
        expect(sort, isNull);
        expect(display, isNull);
      },
    );
  });
}
