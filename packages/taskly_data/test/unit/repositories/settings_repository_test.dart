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
  });
}
