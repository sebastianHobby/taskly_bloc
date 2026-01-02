@Tags(['integration', 'repository'])
@Skip('Integration tests disabled - pump/async issues being investigated')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/sort_preferences.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/settings_repository.dart';
import 'package:taskly_bloc/domain/models/settings.dart';
import 'package:taskly_bloc/domain/models/page_key.dart';

import '../helpers/test_db.dart';

/// Integration tests for Settings persistence using a real in-memory database.
///
/// These tests verify settings management including NextActionsSettings,
/// PageSort preferences, and PageDisplaySettings.
///
/// Coverage:
/// - ✅ Default settings when empty
/// - ✅ NextActionsSettings CRUD
/// - ✅ PageSort preferences
/// - ✅ PageDisplaySettings
/// - ✅ Stream reactivity
void main() {
  late AppDatabase db;
  late SettingsRepository settingsRepo;

  setUp(() {
    db = createTestDb();
    settingsRepo = SettingsRepository(driftDb: db);
  });

  tearDown(() async {
    await closeTestDb(db);
  });

  group('AppSettings Persistence', () {
    test('returns default settings when database is empty', () async {
      final settings = await settingsRepo.loadAll();
      expect(settings, isNotNull);
      expect(settings.pageSortPreferences, isEmpty);
      expect(settings.pageDisplaySettings, isEmpty);
    });

    test('watchAll emits default settings initially', () async {
      final settings = await settingsRepo.watchAll().first;
      expect(settings, isNotNull);
      expect(settings.pageSortPreferences, isEmpty);
    });
  });

  group('NextActionsSettings', () {
    test('loads default NextActionsSettings', () async {
      final settings = await settingsRepo.loadNextActionsSettings();
      expect(settings.tasksPerProject, 2);
      expect(settings.includeInboxTasks, isTrue);
      expect(settings.excludeFutureStartDates, isTrue);
    });

    test('saves and loads NextActionsSettings', () async {
      // Arrange
      const customSettings = NextActionsSettings(
        tasksPerProject: 5,
        includeInboxTasks: false,
        excludeFutureStartDates: false,
      );

      // Act
      await settingsRepo.saveNextActionsSettings(customSettings);
      final loaded = await settingsRepo.loadNextActionsSettings();

      // Assert
      expect(loaded.tasksPerProject, 5);
      expect(loaded.includeInboxTasks, isFalse);
      expect(loaded.excludeFutureStartDates, isFalse);
    });

    test('watchNextActionsSettings emits updates', () async {
      final emissions = <NextActionsSettings>[];
      final subscription = settingsRepo.watchNextActionsSettings().listen(
        emissions.add,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Save new settings
      await settingsRepo.saveNextActionsSettings(
        const NextActionsSettings(tasksPerProject: 10),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emissions.length, greaterThanOrEqualTo(1));
      expect(emissions.last.tasksPerProject, 10);

      await subscription.cancel();
    });

    test('preserves bucket rules when saving', () async {
      // Arrange - Use settings with default bucket rules
      final settingsWithRules = NextActionsSettings.withDefaults(
        tasksPerProject: 3,
      );

      // Act
      await settingsRepo.saveNextActionsSettings(settingsWithRules);
      final loaded = await settingsRepo.loadNextActionsSettings();

      // Assert - Rules should be preserved
      expect(loaded.bucketRules, isNotEmpty);
      expect(loaded.tasksPerProject, 3);
    });
  });

  group('PageSort Preferences', () {
    test('returns null for unset page sort', () async {
      final sort = await settingsRepo.loadPageSort(PageKey.tasksInbox);
      expect(sort, isNull);
    });

    test('saves and loads page sort preferences', () async {
      // Arrange
      const pageKey = PageKey.tasksToday;
      const sortPrefs = SortPreferences(
        criteria: [
          SortCriterion(field: SortField.deadlineDate),
          SortCriterion(
            field: SortField.name,
            direction: SortDirection.descending,
          ),
        ],
      );

      // Act
      await settingsRepo.savePageSort(pageKey, sortPrefs);
      final loaded = await settingsRepo.loadPageSort(pageKey);

      // Assert
      expect(loaded, isNotNull);
      expect(loaded!.criteria, hasLength(2));
      expect(loaded.criteria.first.field, SortField.deadlineDate);
      expect(loaded.criteria.first.direction, SortDirection.ascending);
    });

    test('watchPageSort emits updates for specific page', () async {
      const pageKey = PageKey.tasksInbox;
      final emissions = <SortPreferences?>[];
      final subscription = settingsRepo
          .watchPageSort(pageKey)
          .listen(emissions.add);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Save sort preferences
      await settingsRepo.savePageSort(
        pageKey,
        const SortPreferences(
          criteria: [SortCriterion(field: SortField.createdDate)],
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emissions.last, isNotNull);
      expect(emissions.last!.criteria.first.field, SortField.createdDate);

      await subscription.cancel();
    });

    test('saves sort preferences for multiple pages independently', () async {
      // Arrange & Act
      await settingsRepo.savePageSort(
        PageKey.tasksToday,
        const SortPreferences(
          criteria: [SortCriterion(field: SortField.deadlineDate)],
        ),
      );
      await settingsRepo.savePageSort(
        PageKey.tasksInbox,
        const SortPreferences(
          criteria: [SortCriterion(field: SortField.name)],
        ),
      );

      // Assert
      final todaySort = await settingsRepo.loadPageSort(PageKey.tasksToday);
      final inboxSort = await settingsRepo.loadPageSort(PageKey.tasksInbox);

      expect(todaySort!.criteria.first.field, SortField.deadlineDate);
      expect(inboxSort!.criteria.first.field, SortField.name);
    });
  });

  group('PageDisplaySettings', () {
    test('returns default display settings for unset page', () async {
      final settings = await settingsRepo.loadPageDisplaySettings(
        PageKey.tasksInbox,
      );
      expect(settings.hideCompleted, isTrue); // default
      expect(settings.completedSectionCollapsed, isFalse); // default
    });

    test('saves and loads page display settings', () async {
      // Arrange
      const pageKey = PageKey.projectOverview;
      const displaySettings = PageDisplaySettings(
        hideCompleted: false,
        completedSectionCollapsed: true,
        showNextActionsBanner: false,
      );

      // Act
      await settingsRepo.savePageDisplaySettings(pageKey, displaySettings);
      final loaded = await settingsRepo.loadPageDisplaySettings(pageKey);

      // Assert
      expect(loaded.hideCompleted, isFalse);
      expect(loaded.completedSectionCollapsed, isTrue);
      expect(loaded.showNextActionsBanner, isFalse);
    });

    test('watchPageDisplaySettings emits updates', () async {
      const pageKey = PageKey.labelOverview;
      final emissions = <PageDisplaySettings>[];
      final subscription = settingsRepo
          .watchPageDisplaySettings(pageKey)
          .listen(emissions.add);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Save display settings
      await settingsRepo.savePageDisplaySettings(
        pageKey,
        const PageDisplaySettings(hideCompleted: false),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(emissions.last.hideCompleted, isFalse);

      await subscription.cancel();
    });

    test('saves display settings for multiple pages independently', () async {
      // Arrange & Act
      await settingsRepo.savePageDisplaySettings(
        PageKey.tasksToday,
        const PageDisplaySettings(),
      );
      await settingsRepo.savePageDisplaySettings(
        PageKey.tasksUpcoming,
        const PageDisplaySettings(hideCompleted: false),
      );

      // Assert
      final todayDisplay = await settingsRepo.loadPageDisplaySettings(
        PageKey.tasksToday,
      );
      final upcomingDisplay = await settingsRepo.loadPageDisplaySettings(
        PageKey.tasksUpcoming,
      );

      expect(todayDisplay.hideCompleted, isTrue);
      expect(upcomingDisplay.hideCompleted, isFalse);
    });
  });

  group('Settings Persistence Across Operations', () {
    test('settings persist across multiple updates', () async {
      // Save NextActionsSettings
      await settingsRepo.saveNextActionsSettings(
        const NextActionsSettings(tasksPerProject: 7),
      );

      // Save PageSort
      await settingsRepo.savePageSort(
        PageKey.tasksInbox,
        const SortPreferences(
          criteria: [SortCriterion(field: SortField.name)],
        ),
      );

      // Save PageDisplaySettings
      await settingsRepo.savePageDisplaySettings(
        PageKey.tasksInbox,
        const PageDisplaySettings(hideCompleted: false),
      );

      // Verify all settings
      final nextActions = await settingsRepo.loadNextActionsSettings();
      final sort = await settingsRepo.loadPageSort(PageKey.tasksInbox);
      final display = await settingsRepo.loadPageDisplaySettings(
        PageKey.tasksInbox,
      );

      expect(nextActions.tasksPerProject, 7);
      expect(sort!.criteria.first.field, SortField.name);
      expect(display.hideCompleted, isFalse);
    });

    test('updating one setting type does not affect others', () async {
      // First, set up all settings
      await settingsRepo.saveNextActionsSettings(
        const NextActionsSettings(tasksPerProject: 4),
      );
      await settingsRepo.savePageSort(
        PageKey.tasksToday,
        const SortPreferences(
          criteria: [SortCriterion(field: SortField.deadlineDate)],
        ),
      );

      // Update only NextActionsSettings
      await settingsRepo.saveNextActionsSettings(
        const NextActionsSettings(tasksPerProject: 8),
      );

      // Verify PageSort is unchanged
      final sort = await settingsRepo.loadPageSort(PageKey.tasksToday);
      expect(sort!.criteria.first.field, SortField.deadlineDate);

      // Verify NextActionsSettings is updated
      final nextActions = await settingsRepo.loadNextActionsSettings();
      expect(nextActions.tasksPerProject, 8);
    });
  });
}
