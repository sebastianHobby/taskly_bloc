import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/adapters/next_actions_settings_adapter.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/settings_repository.dart';
import 'package:taskly_bloc/domain/settings.dart';
import '../helpers/test_db.dart';

/// Bug reproduction test:
/// User navigates to next action settings, changes includeInboxTasks from
/// false to true, then returns to the next actions view. Tasks from inbox
/// briefly show, then disappear. Returning to settings page shows
/// includeInboxTasks as false again - the change was not persisted.
///
/// Root cause hypothesis: The `.distinct()` call on watchNextActionsSettings()
/// may be filtering out legitimate updates due to equality issues with
/// complex nested objects (bucket rules, rule sets, etc.).
void main() {
  group('Include Inbox Persistence Bug', () {
    late AppDatabase testDb;
    late SettingsRepository repo;
    late NextActionsSettingsAdapter adapter;

    setUp(() {
      testDb = createTestDb();
      repo = SettingsRepository(driftDb: testDb);
      adapter = NextActionsSettingsAdapter(settingsRepository: repo);
    });

    tearDown(() async {
      await closeTestDb(testDb);
    });

    test(
      'includeInboxTasks change from false to true persists through save/load cycle',
      () async {
        // Simulate initial state: user has default settings (includeInbox=false)
        const initialSettings = NextActionsSettings(
          tasksPerProject: 5,
          includeInboxTasks: false,
        );
        await adapter.save(initialSettings);

        // Verify initial state
        var loaded = await adapter.load();
        expect(loaded.includeInboxTasks, false);

        // Simulate user changing includeInboxTasks to true and saving
        const updatedSettings = NextActionsSettings(
          tasksPerProject: 5,
          includeInboxTasks: true,
        );
        await adapter.save(updatedSettings);

        // Simulate navigating away and returning (new load)
        loaded = await adapter.load();
        expect(
          loaded.includeInboxTasks,
          true,
          reason: 'includeInboxTasks should persist as true after save',
        );
      },
    );

    test(
      'watch stream emits updated includeInboxTasks value after save',
      () async {
        // Set up initial settings
        const initialSettings = NextActionsSettings(
          tasksPerProject: 5,
          includeInboxTasks: false,
        );
        await adapter.save(initialSettings);

        // Set up stream listener to capture emissions
        final emissions = <NextActionsSettings>[];
        final subscription = adapter.watch().listen(emissions.add);

        // Wait for initial emission
        await Future<void>.delayed(const Duration(milliseconds: 100));

        final initialEmissionCount = emissions.length;
        expect(initialEmissionCount, greaterThanOrEqualTo(1));
        expect(emissions.last.includeInboxTasks, false);

        // Simulate user saving with includeInboxTasks=true
        const updatedSettings = NextActionsSettings(
          tasksPerProject: 5,
          includeInboxTasks: true,
        );
        await adapter.save(updatedSettings);

        // Wait for update to propagate
        await Future<void>.delayed(const Duration(milliseconds: 100));

        await subscription.cancel();

        // BUG: If distinct() incorrectly filters the update, we won't see
        // the new emission with includeInboxTasks=true
        expect(
          emissions.length,
          greaterThan(initialEmissionCount),
          reason: 'Stream should emit after save with changed includeInboxTasks',
        );
        expect(
          emissions.last.includeInboxTasks,
          true,
          reason: 'Latest emission should have includeInboxTasks=true',
        );
      },
    );

    test(
      'watch stream emits when only includeInboxTasks changes (distinct bug)',
      () async {
        // This test specifically targets the distinct() issue
        // The hypothesis is that distinct() may be incorrectly comparing
        // NextActionsSettings objects

        // Start with default bucket rules
        final initialSettings = NextActionsSettings.withDefaults(
          tasksPerProject: 5,
          includeInboxTasks: false,
        );
        await adapter.save(initialSettings);

        // Set up stream listener
        final emissions = <NextActionsSettings>[];
        final completer = Completer<void>();

        final subscription = adapter.watch().listen((settings) {
          emissions.add(settings);
          // Complete when we get a settings with includeInbox=true
          if (settings.includeInboxTasks && !completer.isCompleted) {
            completer.complete();
          }
        });

        // Wait for initial emission
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Save with ONLY includeInboxTasks changed
        final updatedSettings = initialSettings.copyWith(
          includeInboxTasks: true,
        );
        await adapter.save(updatedSettings);

        // Wait for the update with timeout
        try {
          await completer.future.timeout(const Duration(seconds: 2));
        } on TimeoutException {
          // Test will fail in assertions below
        }

        await subscription.cancel();

        // Find emission with includeInboxTasks=true
        final hasUpdatedEmission = emissions.any(
          (s) => s.includeInboxTasks == true,
        );

        expect(
          hasUpdatedEmission,
          true,
          reason:
              'Stream should emit settings with includeInboxTasks=true. '
              'Got emissions: ${emissions.map((e) => 'inbox=${e.includeInboxTasks}').toList()}',
        );
      },
    );

    test(
      'NextActionsSettings equality correctly detects includeInboxTasks change',
      () {
        // Unit test to verify equality implementation
        const settings1 = NextActionsSettings(
          tasksPerProject: 5,
          includeInboxTasks: false,
        );
        const settings2 = NextActionsSettings(
          tasksPerProject: 5,
          includeInboxTasks: true,
        );

        expect(settings1 == settings2, false,
            reason: 'Settings with different includeInboxTasks should not be equal');
        expect(settings1.hashCode == settings2.hashCode, false,
            reason: 'Settings with different includeInboxTasks should have different hashCodes');
      },
    );

    test(
      'NextActionsSettings with bucket rules equality works correctly',
      () {
        // Test equality with default bucket rules
        final settings1 = NextActionsSettings.withDefaults(
          tasksPerProject: 5,
          includeInboxTasks: false,
        );
        final settings2 = NextActionsSettings.withDefaults(
          tasksPerProject: 5,
          includeInboxTasks: true,
        );

        expect(settings1 == settings2, false,
            reason: 'Settings with same buckets but different includeInboxTasks should not be equal');
      },
    );

    test(
      'round-trip JSON serialization preserves includeInboxTasks',
      () {
        const original = NextActionsSettings(
          tasksPerProject: 5,
          includeInboxTasks: true,
        );

        final json = original.toJson();
        final restored = NextActionsSettings.fromJson(json);

        expect(restored.includeInboxTasks, true,
            reason: 'includeInboxTasks should survive JSON round-trip');
        expect(restored, original,
            reason: 'Restored settings should equal original');
      },
    );

    test(
      'round-trip JSON with bucket rules preserves includeInboxTasks',
      () {
        final original = NextActionsSettings.withDefaults(
          tasksPerProject: 5,
          includeInboxTasks: true,
        );

        final json = original.toJson();
        final restored = NextActionsSettings.fromJson(json);

        expect(restored.includeInboxTasks, true,
            reason: 'includeInboxTasks should survive JSON round-trip with bucket rules');
      },
    );
  });
}
