@Tags(['unit', 'routines'])
library;

import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../helpers/test_imports.dart';
import '../../../../mocks/presentation_mocks.dart';
import '../../../../mocks/repository_mocks.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/features/routines/bloc/routine_list_bloc.dart';
import 'package:taskly_bloc/presentation/shared/services/streams/session_stream_cache.dart';
import 'package:taskly_bloc/presentation/shared/services/time/session_day_key_service.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_data_provider.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_mode_service.dart';
import 'package:taskly_bloc/presentation/shared/session/session_shared_data_service.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/services.dart';

class MockAppLifecycleEvents extends Mock implements AppLifecycleEvents {}

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  late MockRoutineRepositoryContract routineRepository;
  late SessionDayKeyService sessionDayKeyService;
  late SessionSharedDataService sharedDataService;
  late RoutineWriteService routineWriteService;
  late SessionStreamCacheManager cacheManager;
  late DemoModeService demoModeService;
  late DemoDataProvider demoDataProvider;
  late MockAppLifecycleEvents appLifecycleEvents;
  late MockHomeDayKeyService dayKeyService;
  late MockTemporalTriggerService temporalTriggerService;
  late MockValueRepositoryContract valueRepository;
  late MockTaskRepositoryContract taskRepository;
  late MockProjectRepositoryContract projectRepository;
  late MockNowService nowService;
  late AppErrorReporter errorReporter;

  late BehaviorSubject<List<Routine>> routinesSubject;
  late BehaviorSubject<List<RoutineCompletion>> completionsSubject;
  late BehaviorSubject<List<RoutineSkip>> skipsSubject;
  late BehaviorSubject<List<Value>> valuesSubject;
  late TestStreamController<TemporalTriggerEvent> temporalController;

  RoutineListBloc buildBloc() {
    return RoutineListBloc(
      routineRepository: routineRepository,
      sessionDayKeyService: sessionDayKeyService,
      errorReporter: errorReporter,
      sharedDataService: sharedDataService,
      routineWriteService: routineWriteService,
      nowService: nowService,
    );
  }

  setUp(() {
    routineRepository = MockRoutineRepositoryContract();
    dayKeyService = MockHomeDayKeyService();
    temporalTriggerService = MockTemporalTriggerService();
    valueRepository = MockValueRepositoryContract();
    taskRepository = MockTaskRepositoryContract();
    projectRepository = MockProjectRepositoryContract();
    appLifecycleEvents = MockAppLifecycleEvents();
    demoModeService = DemoModeService();
    demoDataProvider = DemoDataProvider();
    cacheManager = SessionStreamCacheManager(
      appLifecycleService: appLifecycleEvents,
    );
    sessionDayKeyService = SessionDayKeyService(
      dayKeyService: dayKeyService,
      temporalTriggerService: temporalTriggerService,
    );
    routineWriteService = RoutineWriteService(
      routineRepository: routineRepository,
    );
    nowService = MockNowService();
    errorReporter = AppErrorReporter(
      messengerKey: GlobalKey<ScaffoldMessengerState>(),
    );

    routinesSubject = BehaviorSubject<List<Routine>>();
    completionsSubject = BehaviorSubject<List<RoutineCompletion>>();
    skipsSubject = BehaviorSubject<List<RoutineSkip>>();
    valuesSubject = BehaviorSubject<List<Value>>();
    temporalController = TestStreamController.seeded(const AppResumed());

    when(() => appLifecycleEvents.events).thenAnswer(
      (_) => const Stream<AppLifecycleEvent>.empty(),
    );
    when(() => temporalTriggerService.events).thenAnswer(
      (_) => temporalController.stream,
    );
    when(
      () => dayKeyService.todayDayKeyUtc(),
    ).thenReturn(DateTime.utc(2025, 1, 15));

    when(
      () => routineRepository.getAll(includeInactive: true),
    ).thenAnswer((_) async => _sampleRoutines());
    when(() => routineRepository.getCompletions()).thenAnswer((_) async => []);
    when(() => routineRepository.getSkips()).thenAnswer((_) async => []);

    when(
      () => routineRepository.watchAll(includeInactive: true),
    ).thenAnswer((_) => routinesSubject.stream);
    when(() => routineRepository.watchCompletions()).thenAnswer(
      (_) => completionsSubject.stream,
    );
    when(() => routineRepository.watchSkips()).thenAnswer(
      (_) => skipsSubject.stream,
    );
    when(() => valueRepository.watchAll()).thenAnswer(
      (_) => valuesSubject.stream,
    );
    when(() => valueRepository.getAll()).thenAnswer(
      (_) async => valuesSubject.valueOrNull ?? const <Value>[],
    );

    when(() => nowService.nowUtc()).thenReturn(DateTime.utc(2025, 1, 15, 12));

    sharedDataService = SessionSharedDataService(
      cacheManager: cacheManager,
      valueRepository: valueRepository,
      projectRepository: projectRepository,
      taskRepository: taskRepository,
      demoModeService: demoModeService,
      demoDataProvider: demoDataProvider,
    );
    sessionDayKeyService.start();

    addTearDown(routinesSubject.close);
    addTearDown(completionsSubject.close);
    addTearDown(skipsSubject.close);
    addTearDown(valuesSubject.close);
    addTearDown(temporalController.close);
    addTearDown(sessionDayKeyService.dispose);
    addTearDown(cacheManager.dispose);
    addTearDown(demoModeService.dispose);
  });

  blocTestSafe<RoutineListBloc, RoutineListState>(
    'loads routines and emits loaded state',
    build: buildBloc,
    act: (bloc) {
      bloc.add(const RoutineListEvent.subscriptionRequested());
      routinesSubject.add(_sampleRoutines());
      completionsSubject.add(const []);
      skipsSubject.add(const []);
      valuesSubject.add([TestData.value(id: 'value-1', name: 'Health')]);
    },
    expect: () => [
      const RoutineListLoading(),
      isA<RoutineListLoaded>().having((s) => s.routines.length, 'count', 1),
      isA<RoutineListLoaded>().having((s) => s.routines.length, 'count', 1),
    ],
  );
}

List<Routine> _sampleRoutines() {
  return [
    Routine(
      id: 'routine-1',
      createdAt: DateTime.utc(2025, 1, 1),
      updatedAt: DateTime.utc(2025, 1, 1),
      name: 'Hydrate',
      valueId: 'value-1',
      routineType: RoutineType.weeklyFlexible,
      targetCount: 3,
      scheduleDays: const [1, 3, 5],
      value: TestData.value(id: 'value-1', name: 'Health'),
    ),
  ];
}
