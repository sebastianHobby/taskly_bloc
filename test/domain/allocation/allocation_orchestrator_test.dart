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
