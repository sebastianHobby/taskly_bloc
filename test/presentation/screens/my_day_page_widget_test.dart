@Tags(['widget', 'my_day'])
library;

import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';

import '../../helpers/test_imports.dart';
import '../../mocks/repository_mocks.dart';
import 'package:taskly_bloc/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/features/guided_tour/bloc/guided_tour_bloc.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_bloc/presentation/screens/services/my_day_gate_query_service.dart';
import 'package:taskly_bloc/presentation/screens/services/my_day_query_service.dart';
import 'package:taskly_bloc/presentation/screens/services/my_day_session_query_service.dart';
import 'package:taskly_bloc/presentation/screens/view/my_day_page.dart';
import 'package:taskly_bloc/presentation/shared/services/streams/session_stream_cache.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/services/time/home_day_service.dart';
import 'package:taskly_bloc/presentation/shared/services/time/session_day_key_service.dart';
import 'package:taskly_bloc/presentation/shared/session/session_allocation_cache_service.dart';
import 'package:taskly_bloc/presentation/shared/session/session_shared_data_service.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_data_provider.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_mode_service.dart';
import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/my_day.dart' as my_day;
import 'package:taskly_domain/preferences.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/settings.dart' as settings;

class MockGlobalSettingsBloc
    extends MockBloc<GlobalSettingsEvent, GlobalSettingsState>
    implements GlobalSettingsBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AppAuthState>
    implements AuthBloc {}

class MockEditorLauncher extends Mock implements EditorLauncher {}

class MockAppLifecycleEvents extends Mock implements AppLifecycleEvents {}

class MockGuidedTourBloc extends MockBloc<GuidedTourEvent, GuidedTourState>
    implements GuidedTourBloc {}

class MockHomeDayKeyService extends Mock implements HomeDayKeyService {}

class MockTemporalTriggerService extends Mock
    implements TemporalTriggerService {}

class MockNowService extends Mock implements NowService {}

class MockProjectAnchorStateRepositoryContract extends Mock
    implements ProjectAnchorStateRepositoryContract {}

class MockAllocationOrchestrator extends Mock
    implements AllocationOrchestrator {}

class MockOccurrenceCommandService extends Mock
    implements OccurrenceCommandService {}

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    debugPrint('[my_day_test] setUpAll');
  });
  setUp(setUpTestEnvironment);

  late MyDaySessionQueryService myDaySessionQueryService;
  late MyDayGateQueryService myDayGateQueryService;
  late RoutineWriteService routineWriteService;
  late TaskWriteService taskWriteService;
  late TaskSuggestionService taskSuggestionService;
  late SessionStreamCacheManager sessionStreamCacheManager;
  late SessionSharedDataService sessionSharedDataService;
  late SessionAllocationCacheService sessionAllocationCacheService;
  late SessionDayKeyService sessionDayKeyService;
  late MyDayQueryService myDayQueryService;
  late MyDayRitualStatusService myDayRitualStatusService;
  late DemoModeService demoModeService;
  late DemoDataProvider demoDataProvider;
  late MockAllocationOrchestrator allocationOrchestrator;
  late MockOccurrenceCommandService occurrenceCommandService;
  late MockNowService nowService;
  late MockHomeDayKeyService dayKeyService;
  late MockTemporalTriggerService temporalTriggerService;
  late MockAppLifecycleEvents appLifecycleEvents;
  late MockValueRepositoryContract valueRepository;
  late MockTaskRepositoryContract taskRepository;
  late MockProjectRepositoryContract projectRepository;
  late MockRoutineRepositoryContract routineRepository;
  late MockProjectAnchorStateRepositoryContract projectAnchorStateRepository;
  late MockMyDayRepositoryContract myDayRepository;
  late MockSettingsRepositoryContract settingsRepository;
  late MockEditorLauncher editorLauncher;
  late MockGlobalSettingsBloc globalSettingsBloc;
  late MockGuidedTourBloc guidedTourBloc;
  late MockAuthBloc authBloc;

  late BehaviorSubject<List<Value>> valuesSubject;
  late BehaviorSubject<List<Task>> tasksSubject;
  late BehaviorSubject<List<Routine>> routinesSubject;
  late BehaviorSubject<List<RoutineCompletion>> completionsSubject;
  late BehaviorSubject<List<RoutineSkip>> skipsSubject;
  late BehaviorSubject<my_day.MyDayDayPicks> dayPicksSubject;
  late StreamController<TemporalTriggerEvent> temporalTriggerController;
  late StreamController<AppLifecycleEvent> appLifecycleController;

  final dayKeyUtc = DateTime.utc(2025, 1, 15);
  final nowUtc = DateTime.utc(2025, 1, 15, 12);
  final defaultValues = [
    TestData.value(id: 'value-1', name: 'Health'),
  ];
  const speedDialInitDelay = Duration(milliseconds: 1);

  setUp(() {
    debugPrint('[my_day_test] setUp');
    nowService = MockNowService();
    dayKeyService = MockHomeDayKeyService();
    temporalTriggerService = MockTemporalTriggerService();
    appLifecycleEvents = MockAppLifecycleEvents();
    valueRepository = MockValueRepositoryContract();
    taskRepository = MockTaskRepositoryContract();
    projectRepository = MockProjectRepositoryContract();
    routineRepository = MockRoutineRepositoryContract();
    projectAnchorStateRepository = MockProjectAnchorStateRepositoryContract();
    allocationOrchestrator = MockAllocationOrchestrator();
    occurrenceCommandService = MockOccurrenceCommandService();
    myDayRepository = MockMyDayRepositoryContract();
    settingsRepository = MockSettingsRepositoryContract();
    editorLauncher = MockEditorLauncher();
    globalSettingsBloc = MockGlobalSettingsBloc();
    guidedTourBloc = MockGuidedTourBloc();
    authBloc = MockAuthBloc();
    demoModeService = DemoModeService();
    demoDataProvider = DemoDataProvider();

    valuesSubject = BehaviorSubject<List<Value>>.seeded(defaultValues);
    tasksSubject = BehaviorSubject<List<Task>>.seeded(const <Task>[]);
    routinesSubject = BehaviorSubject<List<Routine>>.seeded(const <Routine>[]);
    completionsSubject = BehaviorSubject<List<RoutineCompletion>>.seeded(
      const <RoutineCompletion>[],
    );
    skipsSubject = BehaviorSubject<List<RoutineSkip>>.seeded(
      const <RoutineSkip>[],
    );
    dayPicksSubject = BehaviorSubject<my_day.MyDayDayPicks>.seeded(
      my_day.MyDayDayPicks(
        dayKeyUtc: dayKeyUtc,
        ritualCompletedAtUtc: null,
        picks: const <my_day.MyDayPick>[],
      ),
    );
    temporalTriggerController =
        StreamController<TemporalTriggerEvent>.broadcast();
    appLifecycleController = StreamController<AppLifecycleEvent>.broadcast();

    when(() => nowService.nowUtc()).thenReturn(nowUtc);
    when(() => nowService.nowLocal()).thenReturn(DateTime(2025, 1, 15, 12));

    when(() => dayKeyService.todayDayKeyUtc()).thenReturn(dayKeyUtc);
    when(
      () => dayKeyService.todayDayKeyUtc(nowUtc: any(named: 'nowUtc')),
    ).thenReturn(dayKeyUtc);
    when(
      () => dayKeyService.nextHomeDayBoundaryUtc(nowUtc: any(named: 'nowUtc')),
    ).thenReturn(dayKeyUtc.add(const Duration(days: 1)));

    when(() => temporalTriggerService.events).thenAnswer(
      (_) => temporalTriggerController.stream,
    );
    when(() => appLifecycleEvents.events).thenAnswer(
      (_) => appLifecycleController.stream,
    );

    when(() => settingsRepository.load(SettingsKey.global)).thenAnswer(
      (_) async => const settings.GlobalSettings(),
    );
    when(() => settingsRepository.load(SettingsKey.allocation)).thenAnswer(
      (_) async => const AllocationConfig(),
    );
    when(
      () => settingsRepository.load(
        SettingsKey.pageDisplay(PageKey.myDay),
      ),
    ).thenAnswer((_) async => null);

    when(() => settingsRepository.watch(SettingsKey.allocation)).thenAnswer(
      (_) => Stream.value(const AllocationConfig()),
    );
    when(() => settingsRepository.watch(SettingsKey.global)).thenAnswer(
      (_) => Stream.value(const settings.GlobalSettings()),
    );

    when(() => valueRepository.getAll()).thenAnswer(
      (_) async => defaultValues,
    );
    when(() => valueRepository.watchAll()).thenAnswer(
      (_) => valuesSubject.stream,
    );

    when(() => taskRepository.getAll(any())).thenAnswer(
      (_) async => tasksSubject.valueOrNull ?? <Task>[],
    );
    when(() => taskRepository.getAll()).thenAnswer(
      (_) async => tasksSubject.valueOrNull ?? <Task>[],
    );
    when(() => taskRepository.watchAll(any())).thenAnswer(
      (_) => tasksSubject.stream,
    );
    when(() => taskRepository.watchAll()).thenAnswer(
      (_) => tasksSubject.stream,
    );
    when(() => taskRepository.watchAllCount(any())).thenAnswer(
      (_) => Stream.value(0),
    );
    when(() => taskRepository.watchAllCount()).thenAnswer(
      (_) => Stream.value(0),
    );
    when(() => taskRepository.watchCompletionHistory()).thenAnswer(
      (_) => Stream.value(const <CompletionHistoryData>[]),
    );
    when(() => taskRepository.watchRecurrenceExceptions()).thenAnswer(
      (_) => Stream.value(const <RecurrenceExceptionData>[]),
    );
    when(() => taskRepository.getByIds(any())).thenAnswer((_) async => []);

    when(() => routineRepository.getAll(includeInactive: true)).thenAnswer(
      (_) async => routinesSubject.valueOrNull ?? <Routine>[],
    );
    when(() => routineRepository.watchAll(includeInactive: true)).thenAnswer(
      (_) => routinesSubject.stream,
    );
    when(() => routineRepository.getCompletions()).thenAnswer(
      (_) async => completionsSubject.valueOrNull ?? <RoutineCompletion>[],
    );
    when(() => routineRepository.watchCompletions()).thenAnswer(
      (_) => completionsSubject.stream,
    );
    when(() => routineRepository.getSkips()).thenAnswer(
      (_) async => skipsSubject.valueOrNull ?? <RoutineSkip>[],
    );
    when(() => routineRepository.watchSkips()).thenAnswer(
      (_) => skipsSubject.stream,
    );

    when(() => projectRepository.getAll()).thenAnswer((_) async => []);
    when(() => projectRepository.getAll(any())).thenAnswer((_) async => []);
    when(() => projectRepository.watchAll()).thenAnswer(
      (_) => Stream.value(const <Project>[]),
    );
    when(() => projectRepository.watchAll(any())).thenAnswer(
      (_) => Stream.value(const <Project>[]),
    );
    when(() => projectAnchorStateRepository.getAll()).thenAnswer(
      (_) async => [],
    );
    when(() => projectAnchorStateRepository.watchAll()).thenAnswer(
      (_) => Stream.value(const <ProjectAnchorState>[]),
    );
    when(() => myDayRepository.loadDay(any())).thenAnswer(
      (_) async => my_day.MyDayDayPicks(
        dayKeyUtc: dayKeyUtc,
        ritualCompletedAtUtc: nowUtc,
        picks: const <my_day.MyDayPick>[],
      ),
    );
    when(() => myDayRepository.watchDay(any())).thenAnswer(
      (_) => dayPicksSubject.stream,
    );

    when(
      () => allocationOrchestrator.getSuggestedSnapshot(
        batchCount: any(named: 'batchCount'),
        nowUtc: any(named: 'nowUtc'),
        routineSelectionsByValue: any(named: 'routineSelectionsByValue'),
      ),
    ).thenAnswer(
      (_) async => AllocationResult(
        allocatedTasks: const <AllocatedTask>[],
        reasoning: const AllocationReasoning(
          strategyUsed: 'none',
          categoryAllocations: {},
          categoryWeights: {},
          explanation: 'test',
        ),
        excludedTasks: const <ExcludedTask>[],
      ),
    );
    when(
      () => allocationOrchestrator.getSuggestedSnapshotForTargetCount(
        suggestedTaskTarget: any(named: 'suggestedTaskTarget'),
        nowUtc: any(named: 'nowUtc'),
        routineSelectionsByValue: any(named: 'routineSelectionsByValue'),
      ),
    ).thenAnswer(
      (_) async => AllocationResult(
        allocatedTasks: const <AllocatedTask>[],
        reasoning: const AllocationReasoning(
          strategyUsed: 'none',
          categoryAllocations: {},
          categoryWeights: {},
          explanation: 'test',
        ),
        excludedTasks: const <ExcludedTask>[],
      ),
    );
    when(() => allocationOrchestrator.getAllocationSnapshot()).thenAnswer(
      (_) async => const AllocationResult(
        allocatedTasks: <AllocatedTask>[],
        reasoning: AllocationReasoning(
          strategyUsed: 'none',
          categoryAllocations: <String, int>{},
          categoryWeights: <String, double>{},
          explanation: 'test',
        ),
        excludedTasks: <ExcludedTask>[],
      ),
    );

    taskWriteService = TaskWriteService(
      taskRepository: taskRepository,
      projectRepository: projectRepository,
      occurrenceCommandService: occurrenceCommandService,
    );

    routineWriteService = RoutineWriteService(
      routineRepository: routineRepository,
    );

    taskSuggestionService = TaskSuggestionService(
      allocationOrchestrator: allocationOrchestrator,
      taskRepository: taskRepository,
      dayKeyService: dayKeyService,
    );

    sessionStreamCacheManager = SessionStreamCacheManager(
      appLifecycleService: appLifecycleEvents,
    );
    sessionDayKeyService = SessionDayKeyService(
      dayKeyService: dayKeyService,
      temporalTriggerService: temporalTriggerService,
    );
    sessionDayKeyService.start();

    sessionSharedDataService = SessionSharedDataService(
      cacheManager: sessionStreamCacheManager,
      valueRepository: valueRepository,
      projectRepository: projectRepository,
      taskRepository: taskRepository,
      demoModeService: demoModeService,
      demoDataProvider: demoDataProvider,
    );

    sessionAllocationCacheService = SessionAllocationCacheService(
      cacheManager: sessionStreamCacheManager,
      sessionDayKeyService: sessionDayKeyService,
      allocationOrchestrator: allocationOrchestrator,
      taskRepository: taskRepository,
      projectRepository: projectRepository,
      projectAnchorStateRepository: projectAnchorStateRepository,
      settingsRepository: settingsRepository,
      valueRepository: valueRepository,
    );

    myDayRitualStatusService = MyDayRitualStatusService(
      myDayRepository: myDayRepository,
    );

    myDayQueryService = MyDayQueryService(
      taskRepository: taskRepository,
      myDayRepository: myDayRepository,
      ritualStatusService: myDayRitualStatusService,
      routineRepository: routineRepository,
      dayKeyService: dayKeyService,
      temporalTriggerService: temporalTriggerService,
      allocationCacheService: sessionAllocationCacheService,
      sharedDataService: sessionSharedDataService,
      demoModeService: demoModeService,
      demoDataProvider: demoDataProvider,
    );

    myDaySessionQueryService = MyDaySessionQueryService(
      queryService: myDayQueryService,
      cacheManager: sessionStreamCacheManager,
    );

    myDayGateQueryService = MyDayGateQueryService(
      valueRepository: valueRepository,
      sharedDataService: sessionSharedDataService,
      demoModeService: demoModeService,
    );

    const globalState = GlobalSettingsState(
      isLoading: false,
      settings: settings.GlobalSettings(),
    );
    when(() => globalSettingsBloc.state).thenReturn(globalState);
    whenListen(
      globalSettingsBloc,
      Stream.value(globalState),
      initialState: globalState,
    );
    final guidedTourState = GuidedTourState.initial();
    when(() => guidedTourBloc.state).thenReturn(guidedTourState);
    whenListen(
      guidedTourBloc,
      Stream.value(guidedTourState),
      initialState: guidedTourState,
    );
    const authState = AppAuthState();
    when(() => authBloc.state).thenReturn(authState);
    whenListen(
      authBloc,
      Stream.value(authState),
      initialState: authState,
    );

    addTearDown(valuesSubject.close);
    addTearDown(tasksSubject.close);
    addTearDown(routinesSubject.close);
    addTearDown(completionsSubject.close);
    addTearDown(skipsSubject.close);
    addTearDown(dayPicksSubject.close);
    addTearDown(() async => temporalTriggerController.close());
    addTearDown(() async => appLifecycleController.close());
    addTearDown(sessionDayKeyService.dispose);
    addTearDown(sessionStreamCacheManager.dispose);
    addTearDown(demoModeService.dispose);
    addTearDown(globalSettingsBloc.close);
    addTearDown(guidedTourBloc.close);
    addTearDown(authBloc.close);
  });

  Widget buildSubject() {
    final homeDayService = HomeDayService(
      dayKeyService: dayKeyService,
      nowService: nowService,
    );

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<MyDayGateQueryService>.value(
          value: myDayGateQueryService,
        ),
        RepositoryProvider<MyDaySessionQueryService>.value(
          value: myDaySessionQueryService,
        ),
        RepositoryProvider<RoutineWriteService>.value(
          value: routineWriteService,
        ),
        RepositoryProvider<NowService>.value(value: nowService),
        RepositoryProvider<HomeDayKeyService>.value(value: dayKeyService),
        RepositoryProvider<HomeDayService>.value(value: homeDayService),
        RepositoryProvider<SettingsRepositoryContract>.value(
          value: settingsRepository,
        ),
        RepositoryProvider<MyDayRepositoryContract>.value(
          value: myDayRepository,
        ),
        RepositoryProvider<TaskSuggestionService>.value(
          value: taskSuggestionService,
        ),
        RepositoryProvider<TaskRepositoryContract>.value(
          value: taskRepository,
        ),
        RepositoryProvider<RoutineRepositoryContract>.value(
          value: routineRepository,
        ),
        RepositoryProvider<TaskWriteService>.value(value: taskWriteService),
        RepositoryProvider<DemoModeService>.value(value: demoModeService),
        RepositoryProvider<DemoDataProvider>.value(value: demoDataProvider),
        RepositoryProvider<TemporalTriggerService>.value(
          value: temporalTriggerService,
        ),
        RepositoryProvider<EditorLauncher>.value(value: editorLauncher),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<GlobalSettingsBloc>.value(value: globalSettingsBloc),
          BlocProvider<GuidedTourBloc>.value(value: guidedTourBloc),
          BlocProvider<AuthBloc>.value(value: authBloc),
        ],
        child: const MyDayPage(),
      ),
    );
  }

  void seedDailyStreams({List<Value>? values}) {
    valuesSubject.add(values ?? defaultValues);
    routinesSubject.add(const <Routine>[]);
    completionsSubject.add(const <RoutineCompletion>[]);
    skipsSubject.add(const <RoutineSkip>[]);
  }

  Future<void> pumpMyDay(WidgetTester tester) async {
    debugPrint('[my_day_test] pumpMyDay start');
    myDaySessionQueryService.start();
    appLifecycleController.add(AppLifecycleEvent.resumed);
    await tester.pumpApp(buildSubject());
    debugPrint('[my_day_test] pumpMyDay after pumpApp');
    await tester.pumpForStream();
    debugPrint('[my_day_test] pumpMyDay after pumpForStream');
    await tester.pump(speedDialInitDelay);
    debugPrint('[my_day_test] pumpMyDay after speedDial');
  }

  testWidgetsSafe('my day shows loading state while waiting for data', (
    tester,
  ) async {
    debugPrint('[my_day_test] loading state test start');
    final completer = Completer<my_day.MyDayDayPicks>();
    when(() => myDayRepository.loadDay(any())).thenAnswer(
      (_) => completer.future,
    );
    addTearDown(() {
      if (!completer.isCompleted) {
        completer.complete(
          my_day.MyDayDayPicks(
            dayKeyUtc: dayKeyUtc,
            ritualCompletedAtUtc: nowUtc,
            picks: const <my_day.MyDayPick>[],
          ),
        );
      }
    });

    await pumpMyDay(tester);

    expect(
      find.text('Preparing a calm list for today...'),
      findsOneWidget,
    );

    completer.complete(
      my_day.MyDayDayPicks(
        dayKeyUtc: dayKeyUtc,
        ritualCompletedAtUtc: nowUtc,
        picks: const <my_day.MyDayPick>[],
      ),
    );
    await tester.pumpForStream();
  });

  testWidgetsSafe(
    'my day keeps content when watch stream errors after load',
    (tester) async {
      debugPrint('[my_day_test] watch error test start');
      final task = TestData.task(id: 'task-err-1', name: 'Still Here');
      seedDailyStreams();
      tasksSubject.add([task]);

      final picks = my_day.MyDayDayPicks(
        dayKeyUtc: dayKeyUtc,
        ritualCompletedAtUtc: nowUtc,
        picks: [
          my_day.MyDayPick.task(
            taskId: task.id,
            bucket: my_day.MyDayPickBucket.manual,
            sortIndex: 0,
            pickedAtUtc: nowUtc,
            qualifyingValueId: task.effectivePrimaryValueId,
          ),
        ],
      );

      when(() => myDayRepository.loadDay(any())).thenAnswer((_) async => picks);
      when(() => myDayRepository.watchDay(any())).thenAnswer(
        (_) => Stream<my_day.MyDayDayPicks>.error(Exception('boom')),
      );

      await pumpMyDay(tester);
      await tester.pumpForStream();

      expect(find.byKey(ValueKey('myday-accepted-${task.id}')), findsOneWidget);
      expect(find.text("Couldn't load your list."), findsNothing);
    },
  );

  testWidgetsSafe('my day renders and updates planned tasks', (tester) async {
    debugPrint('[my_day_test] renders/updates test start');
    final task = TestData.task(id: 'task-1', name: 'Plan Something');
    final task2 = TestData.task(
      id: 'task-2',
      name: 'Follow Up',
    );

    seedDailyStreams();
    tasksSubject.add([task]);
    final firstPicks = my_day.MyDayDayPicks(
      dayKeyUtc: dayKeyUtc,
      ritualCompletedAtUtc: nowUtc,
      picks: [
        my_day.MyDayPick.task(
          taskId: task.id,
          bucket: my_day.MyDayPickBucket.manual,
          sortIndex: 0,
          pickedAtUtc: nowUtc,
          qualifyingValueId: task.effectivePrimaryValueId,
        ),
      ],
    );
    dayPicksSubject.add(firstPicks);
    when(() => myDayRepository.loadDay(any())).thenAnswer(
      (_) async => firstPicks,
    );
    when(() => myDayRepository.watchDay(any())).thenAnswer(
      (_) => dayPicksSubject.stream,
    );

    await tester.runAsync(() async {
      final queue = StreamQueue(myDayQueryService.watchMyDayViewModel());
      final firstVm = await queue.next;
      expect(
        firstVm.plannedItems.map((item) => item.id),
        contains(task.id),
      );

      tasksSubject.add([task2]);
      dayPicksSubject.add(
        my_day.MyDayDayPicks(
          dayKeyUtc: dayKeyUtc,
          ritualCompletedAtUtc: nowUtc,
          picks: [
            my_day.MyDayPick.task(
              taskId: task2.id,
              bucket: my_day.MyDayPickBucket.manual,
              sortIndex: 0,
              pickedAtUtc: nowUtc,
              qualifyingValueId: task2.effectivePrimaryValueId,
            ),
          ],
        ),
      );

      final deadline = DateTime.now().add(const Duration(seconds: 2));
      dynamic updatedVm;
      while (DateTime.now().isBefore(deadline) && updatedVm == null) {
        final nextVm = await queue.next.timeout(const Duration(seconds: 1));
        if (nextVm.plannedItems.any((item) => item.id == task2.id)) {
          updatedVm = nextVm;
        }
      }
      expect(updatedVm, isNotNull);
      await queue.cancel();
    });
  });
}
