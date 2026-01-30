@Tags(['unit'])
library;

import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_imports.dart';
import '../../../mocks/feature_mocks.dart';
import '../../../mocks/presentation_mocks.dart';
import '../../../mocks/repository_mocks.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_bloc.dart';
import 'package:taskly_bloc/presentation/screens/services/my_day_query_service.dart';
import 'package:taskly_bloc/presentation/screens/services/my_day_session_query_service.dart';
import 'package:taskly_bloc/presentation/shared/services/streams/session_stream_cache.dart';
import 'package:taskly_bloc/presentation/shared/services/time/session_day_key_service.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_data_provider.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_mode_service.dart';
import 'package:taskly_bloc/presentation/shared/session/session_allocation_cache_service.dart';
import 'package:taskly_bloc/presentation/shared/session/session_shared_data_service.dart';
import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/services.dart';

class MockAppLifecycleEvents extends Mock implements AppLifecycleEvents {}

class MockAllocationOrchestrator extends Mock
    implements AllocationOrchestrator {}

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  late MyDaySessionQueryService queryService;
  late MyDayQueryService myDayQueryService;
  late SessionStreamCacheManager cacheManager;
  late SessionSharedDataService sharedDataService;
  late SessionAllocationCacheService allocationCacheService;
  late SessionDayKeyService sessionDayKeyService;
  late MyDayRitualStatusService ritualStatusService;
  late DemoModeService queryDemoModeService;
  late DemoModeService blocDemoModeService;
  late DemoDataProvider demoDataProvider;
  late MockAppLifecycleEvents appLifecycleEvents;
  late MockHomeDayKeyService dayKeyService;
  late MockTemporalTriggerService temporalTriggerService;
  late MockTaskRepositoryContract taskRepository;
  late MockMyDayRepositoryContract myDayRepository;
  late MockRoutineRepositoryContract routineRepository;
  late MockValueRepositoryContract valueRepository;
  late MockProjectRepositoryContract projectRepository;
  late MockProjectNextActionsRepositoryContract projectNextActionsRepository;
  late MockProjectAnchorStateRepositoryContract projectAnchorStateRepository;
  late MockSettingsRepositoryContract settingsRepository;
  late RoutineWriteService routineWriteService;
  late MockNowService nowService;

  setUp(() {
    appLifecycleEvents = MockAppLifecycleEvents();
    dayKeyService = MockHomeDayKeyService();
    temporalTriggerService = MockTemporalTriggerService();
    taskRepository = MockTaskRepositoryContract();
    myDayRepository = MockMyDayRepositoryContract();
    routineRepository = MockRoutineRepositoryContract();
    valueRepository = MockValueRepositoryContract();
    projectRepository = MockProjectRepositoryContract();
    projectNextActionsRepository = MockProjectNextActionsRepositoryContract();
    projectAnchorStateRepository = MockProjectAnchorStateRepositoryContract();
    settingsRepository = MockSettingsRepositoryContract();
    nowService = MockNowService();

    queryDemoModeService = DemoModeService()..enable();
    blocDemoModeService = DemoModeService();
    demoDataProvider = DemoDataProvider();

    when(() => appLifecycleEvents.events).thenAnswer(
      (_) => const Stream<AppLifecycleEvent>.empty(),
    );
    when(() => temporalTriggerService.events).thenAnswer(
      (_) => const Stream<TemporalTriggerEvent>.empty(),
    );
    when(
      () => dayKeyService.todayDayKeyUtc(),
    ).thenReturn(DateTime.utc(2025, 1, 15));
    when(() => nowService.nowUtc()).thenReturn(DateTime.utc(2025, 1, 15, 12));
    when(() => nowService.nowLocal()).thenReturn(DateTime(2025, 1, 15, 12));

    cacheManager = SessionStreamCacheManager(
      appLifecycleService: appLifecycleEvents,
    );
    sessionDayKeyService = SessionDayKeyService(
      dayKeyService: dayKeyService,
      temporalTriggerService: temporalTriggerService,
    );

    sharedDataService = SessionSharedDataService(
      cacheManager: cacheManager,
      valueRepository: valueRepository,
      projectRepository: projectRepository,
      taskRepository: taskRepository,
      demoModeService: queryDemoModeService,
      demoDataProvider: demoDataProvider,
    );

    allocationCacheService = SessionAllocationCacheService(
      cacheManager: cacheManager,
      sessionDayKeyService: sessionDayKeyService,
      allocationOrchestrator: MockAllocationOrchestrator(),
      taskRepository: taskRepository,
      projectRepository: projectRepository,
      projectNextActionsRepository: projectNextActionsRepository,
      projectAnchorStateRepository: projectAnchorStateRepository,
      settingsRepository: settingsRepository,
      valueRepository: valueRepository,
    );

    ritualStatusService = MyDayRitualStatusService(
      myDayRepository: myDayRepository,
    );

    myDayQueryService = MyDayQueryService(
      taskRepository: taskRepository,
      myDayRepository: myDayRepository,
      ritualStatusService: ritualStatusService,
      routineRepository: routineRepository,
      dayKeyService: dayKeyService,
      temporalTriggerService: temporalTriggerService,
      allocationCacheService: allocationCacheService,
      sharedDataService: sharedDataService,
      demoModeService: queryDemoModeService,
      demoDataProvider: demoDataProvider,
    );

    queryService = MyDaySessionQueryService(
      queryService: myDayQueryService,
      cacheManager: cacheManager,
    );

    routineWriteService = RoutineWriteService(
      routineRepository: routineRepository,
    );

    addTearDown(cacheManager.dispose);
    addTearDown(queryDemoModeService.dispose);
    addTearDown(blocDemoModeService.dispose);
  });

  blocTestSafe<MyDayBloc, MyDayState>(
    'maps view model into loaded state',
    build: () => MyDayBloc(
      queryService: queryService,
      routineWriteService: routineWriteService,
      nowService: nowService,
      demoModeService: blocDemoModeService,
    ),
    expect: () => [isA<MyDayLoaded>()],
  );

  blocTestSafe<MyDayBloc, MyDayState>(
    'records routine completion when toggled to complete',
    build: () {
      when(
        () => routineRepository.recordCompletion(
          routineId: any(named: 'routineId'),
          completedAtUtc: any(named: 'completedAtUtc'),
          context: any(named: 'context'),
        ),
      ).thenAnswer((_) async {});
      return MyDayBloc(
        queryService: queryService,
        routineWriteService: routineWriteService,
        nowService: nowService,
        demoModeService: blocDemoModeService,
      );
    },
    act: (bloc) => bloc.add(
      MyDayRoutineCompletionToggled(
        routineId: 'routine-1',
        completedToday: false,
        dayKeyUtc: DateTime.utc(2025, 1, 15),
      ),
    ),
    verify: (_) {
      verify(
        () => routineRepository.recordCompletion(
          routineId: 'routine-1',
          completedAtUtc: DateTime.utc(2025, 1, 15, 12),
          context: any(named: 'context'),
        ),
      ).called(1);
    },
  );
}
