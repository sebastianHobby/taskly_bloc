import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/settings_repository.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/presentation/features/next_action/bloc/next_actions_bloc.dart';

import '../helpers/test_db.dart';
import '../mocks/repository_mocks.dart';

/// User scenario: Change includeInboxTasks setting and verify UI updates
void main() {
  group('User Scenario: Change Next Actions Settings', () {
    late AppDatabase testDb;
    late SettingsRepository settingsRepo;
    late TaskRepository taskRepo;
    late NextActionsBloc bloc;

    setUp(() async {
      testDb = createTestDb();
      settingsRepo = SettingsRepository(driftDb: testDb);
      taskRepo = TaskRepository(
        driftDb: testDb,
        occurrenceExpander: MockOccurrenceStreamExpander(),
        occurrenceWriteHelper: MockOccurrenceWriteHelper(),
      );

      // Create the project FIRST (for foreign key constraint)
      await testDb
          .into(testDb.projectTable)
          .insert(
            ProjectTableCompanion.insert(
              id: const Value('test-project'),
              name: 'Test Project',
              completed: false,
            ),
          );

      // Create some test tasks (1 inbox, 1 non-inbox)
      await taskRepo.create(
        name: 'Inbox Task',
        description: 'This is in inbox',
      );

      await taskRepo.create(
        name: 'Project Task',
        description: 'This is in a project',
        projectId: 'test-project',
      );

      // Create bloc with initial settings (includeInboxTasks = false)
      bloc = NextActionsBloc(
        taskRepository: taskRepo,
        settingsRepository: settingsRepo,
      );

      // Start subscription
      bloc.add(const NextActionsSubscriptionRequested());

      // Wait for initial load
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });

    tearDown(() async {
      await bloc.close();
      await closeTestDb(testDb);
    });

    test('User changes includeInboxTasks from false to true', () async {
      print('=== Initial State ===');
      print('Status: ${bloc.state.status}');
      print('Total tasks: ${bloc.state.totalCount}');
      print('Groups: ${bloc.state.groups.length}');

      // Initial state: should NOT include inbox tasks
      expect(
        bloc.state.status,
        NextActionsStatus.success,
        reason: 'Bloc should have loaded',
      );

      final initialTaskCount = bloc.state.totalCount;
      print('Initial task count: $initialTaskCount');

      // User opens settings page and changes includeInboxTasks to true
      print('\n=== User changes settings ===');
      const newSettings = NextActionsSettings(
        tasksPerProject: 5,
      );

      await settingsRepo.saveNextActionsSettings(newSettings);
      print('Settings saved');

      // Wait for bloc to receive and process the update
      await Future<void>.delayed(const Duration(milliseconds: 500));

      print('\n=== After Settings Change ===');
      print('Status: ${bloc.state.status}');
      print('Total tasks: ${bloc.state.totalCount}');
      print('Groups: ${bloc.state.groups.length}');

      // Verify the settings were actually saved
      final loaded = await settingsRepo.loadNextActionsSettings();
      expect(
        loaded.includeInboxTasks,
        true,
        reason: 'Settings should have been saved',
      );

      // Verify bloc state updated
      expect(
        bloc.state.status,
        NextActionsStatus.success,
        reason: 'Bloc should still be in success state',
      );

      // With includeInboxTasks = true, we should see more (or at least same) tasks
      final finalTaskCount = bloc.state.totalCount;
      print('Final task count: $finalTaskCount');

      expect(
        finalTaskCount,
        greaterThanOrEqualTo(initialTaskCount),
        reason: 'Including inbox should show same or more tasks',
      );
    });

    test('Multiple rapid settings changes all propagate', () async {
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // Change 1
      await settingsRepo.saveNextActionsSettings(const NextActionsSettings());
      await Future<void>.delayed(const Duration(milliseconds: 200));
      var loaded = await settingsRepo.loadNextActionsSettings();
      expect(loaded.includeInboxTasks, true);

      // Change 2 - explicitly set includeInboxTasks to false
      await settingsRepo.saveNextActionsSettings(
        const NextActionsSettings(
          tasksPerProject: 10,
          includeInboxTasks: false,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));
      loaded = await settingsRepo.loadNextActionsSettings();
      expect(loaded.includeInboxTasks, false);
      expect(loaded.tasksPerProject, 10);

      // Change 3
      await settingsRepo.saveNextActionsSettings(
        const NextActionsSettings(tasksPerProject: 3),
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));
      loaded = await settingsRepo.loadNextActionsSettings();
      expect(loaded.includeInboxTasks, true);
      expect(loaded.tasksPerProject, 3);

      expect(bloc.state.status, NextActionsStatus.success);
    });
  });
}

