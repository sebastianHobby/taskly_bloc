@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';
import '../../mocks/fake_repositories.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/services.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('OccurrenceReadService', () {
    testSafe('adds next occurrence preview for repeating tasks', () async {
      final taskRepo = FakeTaskRepository();
      final projectRepo = FakeProjectRepository();
      final settingsRepo = FakeSettingsRepository();
      final dayKeyService = HomeDayKeyService(settingsRepository: settingsRepo);

      final service = OccurrenceReadService(
        taskRepository: taskRepo,
        projectRepository: projectRepo,
        dayKeyService: dayKeyService,
      );

      final task = TestData.task(
        id: 't1',
        startDate: DateTime(2025, 1, 10),
        repeatIcalRrule: 'FREQ=DAILY;COUNT=3',
      );

      taskRepo.pushTasks([task]);

      final preview = OccurrencePreview(
        asOfDayKey: DateTime(2025, 1, 10),
        pastDays: 2,
        futureDays: 10,
      );

      final tasks = await service
          .watchTasksWithOccurrencePreview(
            query: TaskQuery.all(),
            preview: preview,
          )
          .firstWhere((tasks) => tasks.any((t) => t.occurrence != null));

      expect(tasks.first.occurrence, isNotNull);
    });

    testSafe('expands task occurrences for range', () async {
      final taskRepo = FakeTaskRepository();
      final projectRepo = FakeProjectRepository();
      final settingsRepo = FakeSettingsRepository();
      final dayKeyService = HomeDayKeyService(settingsRepository: settingsRepo);

      final service = OccurrenceReadService(
        taskRepository: taskRepo,
        projectRepository: projectRepo,
        dayKeyService: dayKeyService,
      );

      final task = TestData.task(
        id: 't2',
        startDate: DateTime(2025, 1, 10),
        repeatIcalRrule: 'FREQ=DAILY;COUNT=2',
      );
      taskRepo.pushTasks([task]);

      final tasks = await service
          .watchTaskOccurrences(
            query: TaskQuery.schedule(
              rangeStart: DateTime(2025, 1, 10),
              rangeEnd: DateTime(2025, 1, 12),
            ),
            rangeStartDay: DateTime(2025, 1, 10),
            rangeEndDay: DateTime(2025, 1, 12),
            todayDayKeyUtc: DateTime(2025, 1, 10),
          )
          .first;

      expect(tasks, isNotEmpty);
      expect(tasks.first.occurrence, isNotNull);
    });
  });
}
