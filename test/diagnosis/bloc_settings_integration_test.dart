import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/settings_repository.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/presentation/features/next_action/bloc/next_actions_bloc.dart';

import '../helpers/test_db.dart';
import '../mocks/repository_mocks.dart';

/// Full integration test from settings save to bloc state update
void main() {
  group('NextActionsBloc Settings Integration', () {
    late AppDatabase testDb;
    late SettingsRepository settingsRepo;
    late TaskRepository taskRepo;

    setUp(() {
      testDb = createTestDb();
      settingsRepo = SettingsRepository(driftDb: testDb);
      taskRepo = TaskRepository(
        driftDb: testDb,
        occurrenceExpander: MockOccurrenceStreamExpander(),
        occurrenceWriteHelper: MockOccurrenceWriteHelper(),
      );
    });

    tearDown(() async {
      await closeTestDb(testDb);
    });

    test('Bloc receives settings changes and updates state', () async {
      // Create bloc
      final bloc = NextActionsBloc(
        taskRepository: taskRepo,
        settingsRepository: settingsRepo,
      );

      // Start subscription
      bloc.add(const NextActionsSubscriptionRequested());

      // Wait for initial state
      await Future<void>.delayed(const Duration(milliseconds: 200));

      print('Initial bloc state: ${bloc.state.status}');

      // Save new settings
      print('Saving settings with includeInboxTasks=true');
      await settingsRepo.saveNextActionsSettings(
        const NextActionsSettings(
          tasksPerProject: 10,
        ),
      );

      // Wait for bloc to process
      await Future<void>.delayed(const Duration(milliseconds: 500));

      print('Bloc state after save: ${bloc.state.status}');

      // The bloc should have processed the update
      expect(
        bloc.state.status,
        NextActionsStatus.success,
        reason: 'Bloc should have processed the settings update',
      );

      await bloc.close();
    });

    test('Settings stream emits multiple updates to bloc', () async {
      final bloc = NextActionsBloc(
        taskRepository: taskRepo,
        settingsRepository: settingsRepo,
      );

      final stateChanges = <NextActionsState>[];
      final subscription = bloc.stream.listen(stateChanges.add);

      // Start subscription
      bloc.add(const NextActionsSubscriptionRequested());
      await Future<void>.delayed(const Duration(milliseconds: 200));

      print('Initial states count: ${stateChanges.length}');

      // Save settings change 1
      await settingsRepo.saveNextActionsSettings(const NextActionsSettings());
      await Future<void>.delayed(const Duration(milliseconds: 300));

      print('After change 1, states count: ${stateChanges.length}');

      // Save settings change 2
      await settingsRepo.saveNextActionsSettings(
        const NextActionsSettings(tasksPerProject: 15),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));

      print('After change 2, states count: ${stateChanges.length}');

      // Should have received multiple state emissions
      expect(
        stateChanges.length,
        greaterThan(2),
        reason: 'Bloc should emit state for each settings change',
      );

      await subscription.cancel();
      await bloc.close();
    });

    test('Direct watch of settings stream', () async {
      print('=== Direct Settings Watch Test ===');

      final emissions = <NextActionsSettings>[];
      final subscription = settingsRepo.watchNextActionsSettings().listen((
        settings,
      ) {
        print(
          'Settings emitted: includeInbox=${settings.includeInboxTasks}, tasksPerProject=${settings.tasksPerProject}',
        );
        emissions.add(settings);
      });

      // Wait for initial emission
      await Future<void>.delayed(const Duration(milliseconds: 100));
      print('Initial emissions: ${emissions.length}');

      // Save change 1
      print('Saving change 1...');
      await settingsRepo.saveNextActionsSettings(
        const NextActionsSettings(tasksPerProject: 3),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
      print('After save 1, emissions: ${emissions.length}');

      // Save change 2
      print('Saving change 2...');
      await settingsRepo.saveNextActionsSettings(
        const NextActionsSettings(tasksPerProject: 7),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
      print('After save 2, emissions: ${emissions.length}');

      await subscription.cancel();

      expect(
        emissions.length,
        greaterThanOrEqualTo(3),
        reason: 'Should have initial + 2 updates',
      );
    });
  });
}
