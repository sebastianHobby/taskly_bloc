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
/// may be filtering out legitimate updates due to equality sues with
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
        // Simulate initial state: user starts with includeInboxTasks=false
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
        await Future<void>.delayed(const Duration(milliseconds: 200));

        final initialEmissionCount = emissions.length;
        expect(initialEmissionCount, greaterThanOrEqualTo(1));
        expect(emissions.last.includeInboxTasks, false);

        // Simulate user saving with includeInboxTasks=true
        const updatedSettings = NextActionsSettings(
          tasksPerProject: 5,
        );
        await adapter.save(updatedSettings);

        // Wait for update to propagate through Drift's watch stream
        await Future<void>.delayed(const Duration(milliseconds: 500));

        await subscription.cancel();

        // Verify load returns the updated value (primary persistence check)
        final loaded = await adapter.load();
        expect(
          loaded.includeInboxTasks,
          true,
          reason: 'Loaded settings should have includeInboxTasks=true',
        );

        // Check if watch stream emitted the update
        expect(
          emissions.last.includeInboxTasks,
          true,
          reason:
              'Latest emission should have includeInboxTasks=true. '
              'Got: ${emissions.map((e) => 'inbox=${e.includeInboxTasks}').toList()}',
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
        final subscription = adapter.watch().listen(emissions.add);

        // Wait for initial emission
        await Future<void>.delayed(const Duration(milliseconds: 200));

        // Save with ONLY includeInboxTasks changed
        final updatedSettings = initialSettings.copyWith(
          includeInboxTasks: true,
        );
        await adapter.save(updatedSettings);

        // Wait for update to propagate
        await Future<void>.delayed(const Duration(milliseconds: 500));

        await subscription.cancel();

        // Find emission with includeInboxTasks=true
        final hasUpdatedEmission = emissions.any(
          (s) => s.includeInboxTasks,
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
        );

        expect(
          settings1 == settings2,
          false,
          reason:
              'Settings with different includeInboxTasks should not be equal',
        );
        expect(
          settings1.hashCode == settings2.hashCode,
          false,
          reason:
              'Settings with different includeInboxTasks should have different hashCodes',
        );
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

        expect(
          settings1 == settings2,
          false,
          reason:
              'Settings with same buckets but different includeInboxTasks should not be equal',
        );
      },
    );

    test(
      'round-trip JSON serialization preserves includeInboxTasks',
      () {
        const original = NextActionsSettings(
          tasksPerProject: 5,
        );

        final json = original.toJson();
        final restored = NextActionsSettings.fromJson(json);

        expect(
          restored.includeInboxTasks,
          true,
          reason: 'includeInboxTasks should survive JSON round-trip',
        );
        expect(
          restored,
          original,
          reason: 'Restored settings should equal original',
        );
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

        expect(
          restored.includeInboxTasks,
          true,
          reason:
              'includeInboxTasks should survive JSON round-trip with bucket rules',
        );
      },
    );

    test(
      'navigation simulation: save then create new stream subscription',
      () async {
        // This simulates the actual navigation flow:
        // 1. User is on NextActionsView with a bloc subscribed to settings
        // 2. User navigates to settings, changes includeInbox to true, saves
        // 3. User returns to NextActionsView - new bloc created, new subscription

        // Step 1: Initial state - settings exist with includeInbox=false
        const initialSettings = NextActionsSettings(
          tasksPerProject: 5,
          includeInboxTasks: false,
        );
        await adapter.save(initialSettings);

        // Step 2: First subscription (simulates first visit to NextActionsView)
        final firstEmissions = <NextActionsSettings>[];
        final firstSub = adapter.watch().listen(firstEmissions.add);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(firstEmissions.isNotEmpty, true);
        expect(firstEmissions.last.includeInboxTasks, false);

        await firstSub.cancel();

        // Step 3: User saves new settings (simulates settings page save)
        const updatedSettings = NextActionsSettings(
          tasksPerProject: 5,
        );
        await adapter.save(updatedSettings);

        // Step 4: User returns to NextActionsView - NEW subscription created
        // This is the critical test - the new subscription should get the updated value
        final secondEmissions = <NextActionsSettings>[];
        final secondSub = adapter.watch().listen(secondEmissions.add);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        await secondSub.cancel();

        // BUG: The new subscription should immediately emit includeInboxTasks=true
        expect(
          secondEmissions.isNotEmpty,
          true,
          reason: 'Second subscription should emit',
        );
        expect(
          secondEmissions.first.includeInboxTasks,
          true,
          reason:
              'First emission after re-navigation should have includeInboxTasks=true. '
              'Got: ${secondEmissions.map((e) => 'inbox=${e.includeInboxTasks}').toList()}',
        );
      },
    );

    test(
      'effectiveBucketRules preserves includeInboxTasks when buckets are empty',
      () async {
        // This tests the bug path where:
        // 1. Settings are saved with empty bucketRules
        // 2. effectiveBucketRules returns defaults
        // 3. When re-saving, the defaults are saved as actual buckets
        // 4. This could affect equality comparisons

        // Save with empty bucket rules (uses defaults via effectiveBucketRules)
        const settingsWithEmptyBuckets = NextActionsSettings(
          tasksPerProject: 5,
        );
        await adapter.save(settingsWithEmptyBuckets);

        // Load and check
        final loaded = await adapter.load();
        expect(
          loaded.includeInboxTasks,
          true,
          reason: 'includeInboxTasks should be true even with empty buckets',
        );
        expect(
          loaded.bucketRules,
          isEmpty,
          reason:
              'bucketRules should remain empty (not replaced with defaults)',
        );
      },
    );
  });
}
