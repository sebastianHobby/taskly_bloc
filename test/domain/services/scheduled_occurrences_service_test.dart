@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';
import '../../mocks/fake_repositories.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('ScheduledOccurrencesService', () {
    testSafe('combines overdue and scheduled occurrences', () async {
      final taskRepo = FakeTaskRepository();
      final projectRepo = FakeProjectRepository();
      final settingsRepo = FakeSettingsRepository();
      final dayKeyService = HomeDayKeyService(settingsRepository: settingsRepo);

      final occurrenceReadService = OccurrenceReadService(
        taskRepository: taskRepo,
        projectRepository: projectRepo,
        dayKeyService: dayKeyService,
      );

      final service = ScheduledOccurrencesService(
        taskRepository: taskRepo,
        projectRepository: projectRepo,
        occurrenceReadService: occurrenceReadService,
      );

      final today = DateTime(2025, 1, 15);

      final overdueTask = TestData.task(
        id: 't1',
        deadlineDate: DateTime(2025, 1, 10),
      );
      final scheduledTask = TestData.task(
        id: 't2',
        startDate: DateTime(2025, 1, 16),
      );

      taskRepo.pushTasks([overdueTask, scheduledTask]);

      final result = await service
          .watchScheduledOccurrences(
            rangeStartDay: DateTime(2025, 1, 15),
            rangeEndDay: DateTime(2025, 1, 20),
            todayDayKeyUtc: today,
          )
          .first;

      expect(result.overdue, isNotEmpty);
      expect(result.occurrences, isNotEmpty);
    });
  });
}
