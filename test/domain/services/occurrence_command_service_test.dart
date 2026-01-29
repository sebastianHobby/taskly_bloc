@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';
import '../../mocks/repository_mocks.dart';
import '../../mocks/fake_repositories.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';

class FakeDayKeyService extends HomeDayKeyService {
  FakeDayKeyService({required DateTime today})
    : _today = today,
      super(settingsRepository: FakeSettingsRepository());

  final DateTime _today;

  @override
  DateTime todayDayKeyUtc({DateTime? nowUtc}) => _today;
}

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('OccurrenceCommandService', () {
    late MockTaskRepositoryContract taskRepo;
    late MockProjectRepositoryContract projectRepo;
    late HomeDayKeyService dayKeyService;

    setUp(() {
      taskRepo = MockTaskRepositoryContract();
      projectRepo = MockProjectRepositoryContract();
      dayKeyService = FakeDayKeyService(today: DateTime(2025, 1, 15));
    });

    testSafe('completes explicit task occurrence date', () async {
      final service = OccurrenceCommandService(
        taskRepository: taskRepo,
        projectRepository: projectRepo,
        dayKeyService: dayKeyService,
      );

      when(
        () => taskRepo.completeOccurrence(
          taskId: 't1',
          occurrenceDate: any(named: 'occurrenceDate'),
          originalOccurrenceDate: any(named: 'originalOccurrenceDate'),
          notes: any(named: 'notes'),
          context: any(named: 'context'),
        ),
      ).thenAnswer((_) async {});

      await service.completeTask(
        taskId: 't1',
        occurrenceDate: DateTime(2025, 1, 20),
      );

      verify(
        () => taskRepo.completeOccurrence(
          taskId: 't1',
          occurrenceDate: DateTime(2025, 1, 20),
          originalOccurrenceDate: null,
          notes: null,
          context: null,
        ),
      ).called(1);
    });

    testSafe('resolves next uncompleted task occurrence', () async {
      final service = OccurrenceCommandService(
        taskRepository: taskRepo,
        projectRepository: projectRepo,
        dayKeyService: dayKeyService,
      );

      final baseTask = TestData.task(
        id: 't2',
        repeatIcalRrule: 'FREQ=DAILY',
      );
      final occurrence = TestData.occurrenceData(
        date: DateTime(2025, 1, 16),
      );
      final expandedTask = baseTask.copyWith(occurrence: occurrence);

      when(() => taskRepo.getById('t2')).thenAnswer((_) async => baseTask);
      when(
        () => taskRepo.getOccurrencesForTask(
          taskId: 't2',
          rangeStart: any(named: 'rangeStart'),
          rangeEnd: any(named: 'rangeEnd'),
        ),
      ).thenAnswer((_) async => [expandedTask]);
      when(
        () => taskRepo.completeOccurrence(
          taskId: 't2',
          occurrenceDate: any(named: 'occurrenceDate'),
          originalOccurrenceDate: any(named: 'originalOccurrenceDate'),
          notes: any(named: 'notes'),
          context: any(named: 'context'),
        ),
      ).thenAnswer((_) async {});

      await service.completeTask(taskId: 't2');

      verify(
        () => taskRepo.completeOccurrence(
          taskId: 't2',
          occurrenceDate: DateTime(2025, 1, 16),
          originalOccurrenceDate: DateTime(2025, 1, 16),
          notes: null,
          context: null,
        ),
      ).called(1);
    });

    testSafe('uncompletes most recent completed occurrence', () async {
      final service = OccurrenceCommandService(
        taskRepository: taskRepo,
        projectRepository: projectRepo,
        dayKeyService: dayKeyService,
      );

      final baseTask = TestData.task(
        id: 't3',
        repeatIcalRrule: 'FREQ=DAILY',
      );
      final completedOccurrence = TestData.occurrenceData(
        date: DateTime(2025, 1, 14),
        completionId: 'c1',
        completedAt: DateTime(2025, 1, 14, 8),
      );
      final expandedTask = baseTask.copyWith(occurrence: completedOccurrence);

      when(() => taskRepo.getById('t3')).thenAnswer((_) async => baseTask);
      when(
        () => taskRepo.getOccurrencesForTask(
          taskId: 't3',
          rangeStart: any(named: 'rangeStart'),
          rangeEnd: any(named: 'rangeEnd'),
        ),
      ).thenAnswer((_) async => [expandedTask]);
      when(
        () => taskRepo.uncompleteOccurrence(
          taskId: 't3',
          occurrenceDate: any(named: 'occurrenceDate'),
          context: any(named: 'context'),
        ),
      ).thenAnswer((_) async {});

      await service.uncompleteTask(taskId: 't3');

      verify(
        () => taskRepo.uncompleteOccurrence(
          taskId: 't3',
          occurrenceDate: DateTime(2025, 1, 14),
          context: null,
        ),
      ).called(1);
    });
  });
}
