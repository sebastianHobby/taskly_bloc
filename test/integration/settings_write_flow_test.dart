@Tags(['integration'])
library;

import 'package:taskly_data/db.dart';
import 'package:taskly_data/repositories.dart';
import 'package:taskly_domain/taskly_domain.dart';

import '../helpers/test_imports.dart';
import '../helpers/test_db.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  testSafe(
    'settings repository saves global settings with maintenance fields',
    () async {
      final db = createTestDb();
      addTearDown(() => closeTestDb(db));

      final repository = SettingsRepository(driftDb: db);
      final context = TestOperationContextFactory().create(
        feature: 'settings',
        intent: 'test',
        operation: 'settings.save.global',
      );

      const updated = GlobalSettings(
        maintenanceEnabled: false,
        maintenanceDeadlineRiskEnabled: false,
        maintenanceTaskStaleThresholdDays: 10,
        maintenanceProjectIdleThresholdDays: 20,
        maintenanceMissingNextActionsMinOpenTasks: 2,
      );

      await repository.save(SettingsKey.global, updated, context: context);

      final watched = await repository
          .watch(SettingsKey.global)
          .firstWhere((value) => value.maintenanceEnabled == false);
      expect(watched.maintenanceTaskStaleThresholdDays, 10);
      expect(watched.maintenanceProjectIdleThresholdDays, 20);
    },
  );

  testSafe('settings repository saves allocation settings', () async {
    final db = createTestDb();
    addTearDown(() => closeTestDb(db));

    final repository = SettingsRepository(driftDb: db);
    final context = TestOperationContextFactory().create(
      feature: 'settings',
      intent: 'test',
      operation: 'settings.save.allocation',
    );

    const updated = AllocationConfig(
      suggestionsPerBatch: 5,
      hasSelectedFocusMode: true,
      focusMode: FocusMode.intentional,
      strategySettings: StrategySettings(
        urgentTaskBehavior: UrgentTaskBehavior.ignore,
        taskUrgencyThresholdDays: 2,
        projectUrgencyThresholdDays: 5,
        enableNeglectWeighting: false,
      ),
    );

    await repository.save(SettingsKey.allocation, updated, context: context);

    final watched = await repository
        .watch(SettingsKey.allocation)
        .firstWhere((value) => value.suggestionsPerBatch == 5);
    expect(watched.focusMode, FocusMode.intentional);
    expect(watched.strategySettings.taskUrgencyThresholdDays, 2);
  });
}
