import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/settings_repository.dart';
import 'package:taskly_bloc/domain/settings.dart';
import '../helpers/test_db.dart';

void main() {
  group('NextActionsSettings persistence', () {
    late AppDatabase testDb;
    late SettingsRepository repo;

    setUp(() {
      testDb = createTestDb();
      repo = SettingsRepository(driftDb: testDb);
    });

    tearDown(() async {
      await closeTestDb(testDb);
    });

    test('includeInboxTasks=true is persisted and restored', () async {
      // Save settings with includeInboxTasks=true
      const nextActions = NextActionsSettings(
        tasksPerProject: 5,
        includeInboxTasks: true,
      );

      await repo.saveNextActionsSettings(nextActions);

      // Load settings
      final loaded = await repo.loadAll();

      expect(loaded.nextActions.includeInboxTasks, true);
      expect(loaded.nextActions.tasksPerProject, 5);
    });

    test('includeInboxTasks can be toggled from false to true', () async {
      // Save initial settings with includeInboxTasks=false
      const initialSettings = NextActionsSettings(
        tasksPerProject: 3,
      );
      await repo.saveNextActionsSettings(initialSettings);

      // Verify initial state
      var loaded = await repo.loadAll();
      expect(loaded.nextActions.includeInboxTasks, false);

      // Update to includeInboxTasks=true
      const updatedSettings = NextActionsSettings(
        tasksPerProject: 3,
        includeInboxTasks: true,
      );
      await repo.saveNextActionsSettings(updatedSettings);

      // Verify updated state
      loaded = await repo.loadAll();
      expect(
        loaded.nextActions.includeInboxTasks,
        true,
        reason: 'includeInboxTasks should be true after update',
      );
      expect(loaded.nextActions.tasksPerProject, 3);
    });

    test('tasksPerProject is persisted correctly', () async {
      // Save with tasksPerProject=7
      const nextActionsSettings = NextActionsSettings(
        tasksPerProject: 7,
      );
      await repo.saveNextActionsSettings(nextActionsSettings);

      // Load and verify
      final loaded = await repo.loadAll();
      expect(loaded.nextActions.tasksPerProject, 7);
      expect(loaded.nextActions.includeInboxTasks, false);
    });

    test('watchAll stream emits updated settings', () async {
      // Set up stream listener
      final stream = repo.watchAll();
      final settingsList = <AppSettings>[];
      final subscription = stream.listen(settingsList.add);

      // Allow initial emit
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Save first settings
      const settings1 = NextActionsSettings();
      await repo.saveNextActionsSettings(settings1);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Save second settings with includeInboxTasks=true
      const settings2 = NextActionsSettings(
        includeInboxTasks: true,
      );
      await repo.saveNextActionsSettings(settings2);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      await subscription.cancel();

      // Verify stream emitted correct values
      expect(settingsList.length, greaterThanOrEqualTo(2));
      expect(
        settingsList.last.nextActions.includeInboxTasks,
        true,
        reason: 'Last emitted settings should have includeInboxTasks=true',
      );
    });
  });
}
