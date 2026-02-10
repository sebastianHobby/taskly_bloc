@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';
import '../../mocks/fake_repositories.dart';
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
    late FakeProjectAnchorStateRepository projectAnchorStateRepository;
    late HomeDayKeyService dayKeyService;

    setUp(() {
      taskRepository = FakeTaskRepository();
      valueRepository = FakeValueRepository();
      valueRatingsRepository = FakeValueRatingsRepository();
      settingsRepository = FakeSettingsRepository(
        allocation: const AllocationConfig(suggestionsPerBatch: 2),
      );
      projectRepository = FakeProjectRepository();
      projectAnchorStateRepository = FakeProjectAnchorStateRepository();
      dayKeyService = HomeDayKeyService(settingsRepository: settingsRepository);
    });

    testSafe('returns requiresValueSetup when no values exist', () async {
      final orchestrator = AllocationOrchestrator(
        taskRepository: taskRepository,
        valueRepository: valueRepository,
        valueRatingsRepository: valueRatingsRepository,
        settingsRepository: settingsRepository,
        projectRepository: projectRepository,
        projectAnchorStateRepository: projectAnchorStateRepository,
        dayKeyService: dayKeyService,
      );

      final result = await orchestrator.getAllocationSnapshot(
        nowUtc: TestConstants.referenceDate,
      );

      expect(result.requiresValueSetup, isTrue);
      expect(result.allocatedTasks, isEmpty);
    });
  });
}
