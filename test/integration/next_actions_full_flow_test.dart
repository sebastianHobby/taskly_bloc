import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/settings_repository.dart';
import 'package:taskly_bloc/domain/settings.dart';
import 'package:taskly_bloc/features/settings/settings.dart';
import '../helpers/test_db.dart';

void main() {
  group('Next Actions Full Flow - includeInboxTasks bug reproduction', () {
    late AppDatabase testDb;
    late SettingsRepository settingsRepo;
    late SettingsBloc settingsBloc;

    setUp(() async {
      testDb = createTestDb();
      settingsRepo = SettingsRepository(driftDb: testDb);
      settingsBloc = SettingsBloc(settingsRepository: settingsRepo);

      // Start the settings subscription (this happens at app startup)
      settingsBloc.add(const SettingsSubscriptionRequested());

      // Wait for initial load
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });

    tearDown(() async {
      await settingsBloc.close();
      await closeTestDb(testDb);
    });

    test(
      'Simulates user bug: change includeInboxTasks from false to true',
      () async {
        // Step 1: Initial state - includeInboxTasks should be false (default)
        expect(
          settingsBloc.state.settings?.nextActions.includeInboxTasks,
          false,
        );

        // Step 2: User opens settings page and changes includeInboxTasks to true
        const updatedNextActions = NextActionsSettings(
          includeInboxTasks: true,
        );

        // Step 3: User saves
        settingsBloc.add(
          SettingsUpdateNextActions(settings: updatedNextActions),
        );

        // Step 4: Wait for the save to complete and the watch stream to emit
        await Future<void>.delayed(const Duration(milliseconds: 200));

        await settingsBloc.stream
            .firstWhere(
              (state) =>
                  state.status == SettingsStatus.loaded &&
                  (state.settings?.nextActions.includeInboxTasks ?? false),
            )
            .timeout(const Duration(seconds: 5));

        // Step 5: Verify the setting is true in the bloc state
        expect(
          settingsBloc.state.settings?.nextActions.includeInboxTasks,
          true,
          reason: 'includeInboxTasks should be true after save',
        );

        // Step 6: Simulate navigating away and back - reload from database
        final loadedFromDb = await settingsRepo.loadAll();
        expect(
          loadedFromDb.nextActions.includeInboxTasks,
          true,
          reason:
              'includeInboxTasks should still be true when loaded from database',
        );

        // Step 7: Wait a bit more to see if any subsequent emissions revert it
        await Future<void>.delayed(const Duration(milliseconds: 500));

        // Step 8: Check the final state
        expect(
          settingsBloc.state.settings?.nextActions.includeInboxTasks,
          true,
          reason: 'includeInboxTasks should remain true after waiting',
        );
      },
    );

    test('Verify watch stream continues to emit correct value', () async {
      // Initial state
      expect(settingsBloc.state.settings?.nextActions.includeInboxTasks, false);

      // Collect emissions
      final emissions = <NextActionsSettings>[];
      final subscription = settingsBloc.stream
          .where((state) => state.settings != null)
          .map((state) => state.settings!.nextActions)
          .listen(emissions.add);

      // Update to true
      const updatedNextActions = NextActionsSettings(
        includeInboxTasks: true,
      );
      settingsBloc.add(
        SettingsUpdateNextActions(settings: updatedNextActions),
      );

      // Wait for emissions
      await Future<void>.delayed(const Duration(milliseconds: 500));

      await subscription.cancel();

      // Verify no emissions have includeInboxTasks: false after the update
      final afterUpdate = emissions
          .skipWhile((s) => !s.includeInboxTasks)
          .toList();

      expect(
        afterUpdate.every((s) => s.includeInboxTasks),
        true,
        reason:
            'All emissions after update should have includeInboxTasks: true',
      );
    });
  });
}
