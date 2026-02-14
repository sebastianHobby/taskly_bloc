@Tags(['unit', 'scheduled'])
library;

import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/presentation/features/scheduled/services/scheduled_session_query_service.dart';
import 'package:taskly_bloc/presentation/shared/services/streams/session_stream_cache.dart';
import 'package:taskly_bloc/presentation/shared/services/time/session_day_key_service.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_data_provider.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_mode_service.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';

import '../../../../helpers/test_imports.dart';
import '../../../../mocks/presentation_mocks.dart';
import '../../../../mocks/repository_mocks.dart';

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
  });
  setUp(setUpTestEnvironment);

  late ScheduledOccurrencesService occurrencesService;
  late ScheduledSessionQueryService queryService;
  late SessionStreamCacheManager cacheManager;
  late SessionDayKeyService sessionDayKeyService;
  late OccurrenceReadService occurrenceReadService;
  late OccurrenceStreamExpanderContract occurrenceExpander;
  late MockTaskRepositoryContract taskRepository;
  late MockProjectRepositoryContract projectRepository;
  late MockHomeDayKeyService dayKeyService;
  late MockTemporalTriggerService temporalTriggerService;
  late TestStreamController<TemporalTriggerEvent> temporalController;
  late DemoModeService demoModeService;
  late DemoDataProvider demoDataProvider;

  setUp(() {
    taskRepository = MockTaskRepositoryContract();
    projectRepository = MockProjectRepositoryContract();
    dayKeyService = MockHomeDayKeyService();
    temporalTriggerService = MockTemporalTriggerService();
    temporalController = TestStreamController.seeded(const AppResumed());
    occurrenceExpander = _NoopOccurrenceExpander();
    demoModeService = DemoModeService();
    demoDataProvider = DemoDataProvider();

    when(() => temporalTriggerService.events).thenAnswer(
      (_) => temporalController.stream,
    );
    when(
      () => dayKeyService.todayDayKeyUtc(),
    ).thenReturn(DateTime.utc(2025, 1, 15));
    when(() => taskRepository.watchAll(any())).thenAnswer(
      (_) => Stream.value(const <Task>[]),
    );
    when(() => projectRepository.watchAll(any())).thenAnswer(
      (_) => Stream.value(const <Project>[]),
    );
    when(() => taskRepository.watchCompletionHistory()).thenAnswer(
      (_) => Stream.value(const <CompletionHistoryData>[]),
    );
    when(() => taskRepository.watchRecurrenceExceptions()).thenAnswer(
      (_) => Stream.value(const <RecurrenceExceptionData>[]),
    );
    when(() => projectRepository.watchCompletionHistory()).thenAnswer(
      (_) => Stream.value(const <CompletionHistoryData>[]),
    );
    when(() => projectRepository.watchRecurrenceExceptions()).thenAnswer(
      (_) => Stream.value(const <RecurrenceExceptionData>[]),
    );

    occurrenceReadService = OccurrenceReadService(
      taskRepository: taskRepository,
      projectRepository: projectRepository,
      dayKeyService: dayKeyService,
      occurrenceExpander: occurrenceExpander,
    );

    occurrencesService = ScheduledOccurrencesService(
      taskRepository: taskRepository,
      projectRepository: projectRepository,
      occurrenceReadService: occurrenceReadService,
    );

    cacheManager = SessionStreamCacheManager(
      appLifecycleService: const _StaticLifecycleEvents(),
    )..start();

    sessionDayKeyService = SessionDayKeyService(
      dayKeyService: dayKeyService,
      temporalTriggerService: temporalTriggerService,
    )..start();

    queryService = ScheduledSessionQueryService(
      scheduledOccurrencesService: occurrencesService,
      sessionDayKeyService: sessionDayKeyService,
      cacheManager: cacheManager,
      demoModeService: demoModeService,
      demoDataProvider: demoDataProvider,
    );

    addTearDown(temporalController.close);
    addTearDown(cacheManager.dispose);
    addTearDown(sessionDayKeyService.dispose);
    addTearDown(demoModeService.dispose);
  });

  testSafe('reuses cache for identical scope+range key', () async {
    final streamA = queryService.watchScheduledOccurrences(
      scope: const GlobalScheduledScope(),
      rangeStartDay: DateTime.utc(2025, 1, 15),
      rangeEndDay: DateTime.utc(2025, 2, 15),
    );
    final streamB = queryService.watchScheduledOccurrences(
      scope: const GlobalScheduledScope(),
      rangeStartDay: DateTime.utc(2025, 1, 15),
      rangeEndDay: DateTime.utc(2025, 2, 15),
    );

    await streamA.first;
    await streamB.first;

    verify(() => taskRepository.watchAll(any())).called(3);
    verify(() => projectRepository.watchAll(any())).called(3);
  });

  testSafe('creates distinct subscriptions for different ranges', () async {
    await queryService
        .watchScheduledOccurrences(
          scope: const GlobalScheduledScope(),
          rangeStartDay: DateTime.utc(2025, 1, 15),
          rangeEndDay: DateTime.utc(2025, 2, 15),
        )
        .first;

    await queryService
        .watchScheduledOccurrences(
          scope: const GlobalScheduledScope(),
          rangeStartDay: DateTime.utc(2025, 1, 15),
          rangeEndDay: DateTime.utc(2025, 3, 31),
        )
        .first;

    verify(() => taskRepository.watchAll(any())).called(6);
    verify(() => projectRepository.watchAll(any())).called(6);
  });
}

final class _StaticLifecycleEvents implements AppLifecycleEvents {
  const _StaticLifecycleEvents();

  @override
  Stream<AppLifecycleEvent> get events =>
      const Stream<AppLifecycleEvent>.empty();
}

class _NoopOccurrenceExpander implements OccurrenceStreamExpanderContract {
  @override
  Stream<List<Task>> expandTaskOccurrences({
    required Stream<List<Task>> tasksStream,
    required Stream<List<CompletionHistoryData>> completionsStream,
    required Stream<List<RecurrenceExceptionData>> exceptionsStream,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    bool Function(Task)? postExpansionFilter,
  }) {
    return tasksStream;
  }

  @override
  Stream<List<Project>> expandProjectOccurrences({
    required Stream<List<Project>> projectsStream,
    required Stream<List<CompletionHistoryData>> completionsStream,
    required Stream<List<RecurrenceExceptionData>> exceptionsStream,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    bool Function(Project)? postExpansionFilter,
  }) {
    return projectsStream;
  }

  @override
  List<Task> expandTaskOccurrencesSync({
    required List<Task> tasks,
    required List<CompletionHistoryData> completions,
    required List<RecurrenceExceptionData> exceptions,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    bool Function(Task)? postExpansionFilter,
  }) {
    return tasks;
  }

  @override
  List<Project> expandProjectOccurrencesSync({
    required List<Project> projects,
    required List<CompletionHistoryData> completions,
    required List<RecurrenceExceptionData> exceptions,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    bool Function(Project)? postExpansionFilter,
  }) {
    return projects;
  }
}
