// Tests the complete user flow:
// 1. View Next Actions page (settings: includeInbox = false)
// 2. Navigate to settings page
// 3. Change includeInbox to true
// 4. Save and navigate back
// 5. Verify Next Actions shows inbox tasks
// 6. Navigate to settings page again
// 7. Verify includeInbox is still true (persisted)

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/settings_repository.dart';
import 'package:taskly_bloc/domain/settings.dart';
import 'package:taskly_bloc/features/settings/bloc/settings_bloc.dart';

void main() {
  group('Next Actions navigation and settings persistence', () {
    late AppDatabase database;
    late SettingsRepository settingsRepository;

    setUp(() async {
      // In-memory Drift database for testing
      database = AppDatabase(NativeDatabase.memory());
      settingsRepository = SettingsRepository(driftDb: database);
    });

    tearDown(() async {
      await database.close();
    });

    test(
      'settings persist across SettingsBloc instances (navigation simulation)',
      () async {
        // This simulates navigating away and back to pages that read from SettingsBloc

        // Step 1: Initial state - load settings (should be defaults)
        var settings = await settingsRepository.loadAll();
        expect(settings.nextActions.includeInboxTasks, isFalse);

        // Step 2: Create SettingsBloc (as created by the router)
        final bloc1 = SettingsBloc(settingsRepository: settingsRepository);
        bloc1.add(const SettingsSubscriptionRequested());

        // Wait for bloc to receive initial state
        await bloc1.stream.firstWhere((s) => s.status == SettingsStatus.loaded);
        expect(bloc1.state.settings?.nextActions.includeInboxTasks, isFalse);

        // Step 3: Simulate user changing settings
        final updatedNextActions = NextActionsSettings(
          includeInboxTasks: true,
          tasksPerProject: 5,
          bucketRules: NextActionsSettings.defaultBucketRules,
        );

        bloc1.add(SettingsUpdateNextActions(settings: updatedNextActions));

        // Wait for the update to propagate
        await bloc1.stream
            .firstWhere(
              (s) => s.settings?.nextActions.includeInboxTasks ?? false,
            )
            .timeout(const Duration(seconds: 5));

        expect(bloc1.state.settings?.nextActions.includeInboxTasks, isTrue);

        // Step 4: Verify database was updated
        settings = await settingsRepository.loadAll();
        expect(
          settings.nextActions.includeInboxTasks,
          isTrue,
          reason: 'Database should persist includeInboxTasks = true',
        );

        // Step 5: Simulate navigation - create a new SettingsBloc instance
        // (This is what happens when the user navigates)
        await bloc1.close();

        final bloc2 = SettingsBloc(settingsRepository: settingsRepository);
        bloc2.add(const SettingsSubscriptionRequested());

        // Wait for the new bloc to receive state from database
        await bloc2.stream.firstWhere((s) => s.status == SettingsStatus.loaded);

        // Step 6: Verify the new bloc has the persisted settings
        expect(
          bloc2.state.settings?.nextActions.includeInboxTasks,
          isTrue,
          reason:
              'New SettingsBloc should load persisted includeInboxTasks = true',
        );

        await bloc2.close();
      },
    );

    test(
      'settings watch stream emits changes made by another instance',
      () async {
        // This tests that if settings are changed, the watch() stream emits updates

        // Create two listeners to the same repository watch stream
        final emissions = <AppSettings>[];
        final subscription = settingsRepository.watchAll().listen(
          emissions.add,
        );

        // Initial load
        await settingsRepository.loadAll();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(emissions.isNotEmpty, isTrue);
        expect(emissions.last.nextActions.includeInboxTasks, isFalse);

        // Update via save
        const updated = AppSettings(
          nextActions: NextActionsSettings(includeInboxTasks: true),
        );
        await settingsRepository.saveNextActionsSettings(updated.nextActions);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Verify watch emitted the update
        expect(
          emissions.last.nextActions.includeInboxTasks,
          isTrue,
          reason: 'watch() stream should emit after save()',
        );

        await subscription.cancel();
      },
    );

    test('NextActionsSettings equality works correctly', () {
      // Verify equality comparison is correct
      const settings1 = NextActionsSettings(includeInboxTasks: true);
      const settings2 = NextActionsSettings(includeInboxTasks: true);
      const settings3 = NextActionsSettings();

      expect(settings1 == settings2, isTrue);
      expect(settings1 == settings3, isFalse);

      // With bucket rules
      final withRules1 = NextActionsSettings.withDefaults(
        includeInboxTasks: true,
      );
      final withRules2 = NextActionsSettings.withDefaults(
        includeInboxTasks: true,
      );
      expect(withRules1 == withRules2, isTrue);
    });

    test(
      'SettingsBloc.state.settings is not null after subscription',
      () async {
        final bloc = SettingsBloc(settingsRepository: settingsRepository);

        // Before subscription
        expect(bloc.state.settings, isNull);

        bloc.add(const SettingsSubscriptionRequested());

        // After subscription should emit loaded state
        await bloc.stream.firstWhere((s) => s.status == SettingsStatus.loaded);

        expect(bloc.state.settings, isNotNull);
        expect(bloc.state.settings!.nextActions.includeInboxTasks, isFalse);

        await bloc.close();
      },
    );
  });
}
