@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';
import '../../mocks/feature_mocks.dart';
import '../../mocks/fake_repositories.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('AllocationOrchestrator', () {
    late FakeTaskRepository taskRepository;
    late FakeValueRepository valueRepository;
    late FakeValueRatingsRepository valueRatingsRepository;
    late FakeSettingsRepository settingsRepository;
    late FakeProjectRepository projectRepository;
    late FakeProjectNextActionsRepository projectNextActionsRepository;
    late FakeProjectAnchorStateRepository projectAnchorStateRepository;
    late MockAnalyticsService analyticsService;
    late HomeDayKeyService dayKeyService;

    setUp(() {
      taskRepository = FakeTaskRepository();
      valueRepository = FakeValueRepository();
      valueRatingsRepository = FakeValueRatingsRepository();
      settingsRepository = FakeSettingsRepository(
        allocation: const AllocationConfig(suggestionsPerBatch: 2),
      );
      projectRepository = FakeProjectRepository();
      projectNextActionsRepository = FakeProjectNextActionsRepository();
      projectAnchorStateRepository = FakeProjectAnchorStateRepository();
      analyticsService = MockAnalyticsService();
      dayKeyService = HomeDayKeyService(settingsRepository: settingsRepository);

      when(
        () => analyticsService.getRecentCompletionsByValue(
          days: any(named: 'days'),
        ),
      ).thenAnswer((_) async => const <String, int>{});
    });

    testSafe('returns requiresValueSetup when no values exist', () async {
      final orchestrator = AllocationOrchestrator(
        taskRepository: taskRepository,
        valueRepository: valueRepository,
        valueRatingsRepository: valueRatingsRepository,
        settingsRepository: settingsRepository,
        analyticsService: analyticsService,
        projectRepository: projectRepository,
        projectNextActionsRepository: projectNextActionsRepository,
        projectAnchorStateRepository: projectAnchorStateRepository,
        dayKeyService: dayKeyService,
      );

      final result = await orchestrator.getAllocationSnapshot(
        nowUtc: TestConstants.referenceDate,
      );

      expect(result.requiresValueSetup, isTrue);
      expect(result.allocatedTasks, isEmpty);
    });

    testSafe('allocates pinned tasks and regular tasks', () async {
      final value = TestData.value(id: 'v1');
      valueRepository.pushValues([value]);
      final project = TestData.project(
        values: [value],
      ).copyWith(primaryValueId: value.id);
      projectRepository.pushProjects([project]);

      final pinnedTask = TestData.task(
        id: 't1',
        isPinned: true,
        values: [value],
        overridePrimaryValueId: value.id,
        projectId: project.id,
      );
      final regularTask = TestData.task(
        id: 't2',
        values: [value],
        overridePrimaryValueId: value.id,
        projectId: project.id,
      );
      taskRepository.pushTasks([pinnedTask, regularTask]);

      final orchestrator = AllocationOrchestrator(
        taskRepository: taskRepository,
        valueRepository: valueRepository,
        valueRatingsRepository: valueRatingsRepository,
        settingsRepository: settingsRepository,
        analyticsService: analyticsService,
        projectRepository: projectRepository,
        projectNextActionsRepository: projectNextActionsRepository,
        projectAnchorStateRepository: projectAnchorStateRepository,
        dayKeyService: dayKeyService,
      );

      final result = await orchestrator.getAllocationSnapshot(
        nowUtc: TestConstants.referenceDate,
      );

      expect(result.allocatedTasks, isNotEmpty);
      expect(
        result.allocatedTasks.any((t) => t.task.id == regularTask.id),
        isTrue,
      );
      expect(
        result.allocatedTasks.any((t) => t.task.id == pinnedTask.id),
        isFalse,
      );
    });

    testSafe('pin and unpin task update repository', () async {
      final value = TestData.value(id: 'v1');
      valueRepository.pushValues([value]);

      final task = TestData.task(id: 't1', values: [value]);
      taskRepository.pushTasks([task]);

      final orchestrator = AllocationOrchestrator(
        taskRepository: taskRepository,
        valueRepository: valueRepository,
        valueRatingsRepository: valueRatingsRepository,
        settingsRepository: settingsRepository,
        analyticsService: analyticsService,
        projectRepository: projectRepository,
        projectNextActionsRepository: projectNextActionsRepository,
        projectAnchorStateRepository: projectAnchorStateRepository,
        dayKeyService: dayKeyService,
      );

      await orchestrator.pinTask('t1');
      final pinned = await taskRepository.getById('t1');
      expect(pinned?.isPinned, isTrue);

      await orchestrator.unpinTask('t1');
      final unpinned = await taskRepository.getById('t1');
      expect(unpinned?.isPinned, isFalse);
    });
  });
}
