import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/adapters/next_actions_settings_adapter.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/settings_repository.dart';
import 'package:taskly_bloc/domain/settings.dart';

import '../helpers/test_db.dart';

/// Diagnostic test to trace the data flow from save to load
void main() {
  group('Next Actions Settings Data Flow Diagnosis', () {
    late AppDatabase testDb;
    late SettingsRepository repository;
    late NextActionsSettingsAdapter adapter;

    setUp(() {
      testDb = createTestDb();
      repository = SettingsRepository(driftDb: testDb);
      adapter = NextActionsSettingsAdapter(settingsRepository: repository);
    });

    tearDown(() async {
      await closeTestDb(testDb);
    });

    test(
      'Save settings and verify immediate load returns saved values',
      () async {
        // Step 1: Save settings with includeInbox = true
        const settingsToSave = NextActionsSettings(
          tasksPerProject: 3,
        );

        print(
          'STEP 1: Saving settings: ${{
            'tasksPerProject': settingsToSave.tasksPerProject,
            'includeInboxTasks': settingsToSave.includeInboxTasks,
          }}',
        );

        await adapter.save(settingsToSave);

        // Step 2: Immediately load back
        print('STEP 2: Loading settings back immediately after save');
        final loaded = await adapter.load();

        print(
          'LOADED: ${{
            'tasksPerProject': loaded.tasksPerProject,
            'includeInboxTasks': loaded.includeInboxTasks,
          }}',
        );

        // Verify
        expect(
          loaded.tasksPerProject,
          settingsToSave.tasksPerProject,
          reason: 'tasksPerProject should match',
        );
        expect(
          loaded.includeInboxTasks,
          settingsToSave.includeInboxTasks,
          reason: 'includeInboxTasks should match',
        );
      },
    );

    test('Watch stream emits new value after save', () async {
      // Start watching
      print('STEP 1: Starting watch stream');
      final emissions = <NextActionsSettings>[];
      final subscription = adapter.watch().listen(emissions.add);

      // Wait for initial emission
      await Future<void>.delayed(const Duration(milliseconds: 100));
      print(
        'Initial emission: ${{
          'count': emissions.length,
          'includeInbox': emissions.isEmpty ? null : emissions.last.includeInboxTasks,
        }}',
      );

      // Save new settings
      const newSettings = NextActionsSettings(
        tasksPerProject: 5,
      );

      print('STEP 2: Saving new settings');
      await adapter.save(newSettings);

      // Wait for stream to emit
      await Future<void>.delayed(const Duration(milliseconds: 500));

      print(
        'After save emissions: ${{
          'count': emissions.length,
          'values': emissions.map((s) => {
            'tasksPerProject': s.tasksPerProject,
            'includeInbox': s.includeInboxTasks,
          }).toList(),
        }}',
      );

      await subscription.cancel();

      // Should have at least 2 emissions: initial + after save
      expect(
        emissions.length,
        greaterThanOrEqualTo(2),
        reason: 'Should emit initial value and update after save',
      );

      // Last emission should match saved value
      final last = emissions.last;
      expect(
        last.includeInboxTasks,
        true,
        reason: 'Last emission should have includeInboxTasks = true',
      );
      expect(
        last.tasksPerProject,
        5,
        reason: 'Last emission should have tasksPerProject = 5',
      );
    });

    test('Multiple saves in sequence all persist correctly', () async {
      // Save 1
      await adapter.save(const NextActionsSettings());
      var loaded = await adapter.load();
      expect(loaded.includeInboxTasks, true);

      // Save 2 - explicitly set to false
      await adapter.save(
        const NextActionsSettings(
          includeInboxTasks: false,
        ),
      );
      loaded = await adapter.load();
      expect(loaded.includeInboxTasks, false);

      // Save 3
      await adapter.save(
        const NextActionsSettings(
          tasksPerProject: 10,
        ),
      );
      loaded = await adapter.load();
      expect(loaded.includeInboxTasks, true);
      expect(loaded.tasksPerProject, 10);
    });
  });
}
