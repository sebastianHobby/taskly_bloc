@Tags(['unit'])
library;

import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/presentation/screens/services/my_day_query_service.dart';
import 'package:taskly_bloc/presentation/shared/services/streams/session_stream_cache.dart';
import 'package:taskly_bloc/presentation/shared/services/time/session_day_key_service.dart';
import 'package:taskly_bloc/presentation/shared/session/session_allocation_cache_service.dart';
import 'package:taskly_bloc/presentation/shared/session/session_shared_data_service.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_data_provider.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_mode_service.dart';
import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/my_day.dart' as my_day;
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/taskly_domain.dart';

import '../../../fixtures/test_data.dart';
import '../../../helpers/test_imports.dart';
import '../../../mocks/feature_mocks.dart';
import '../../../mocks/repository_mocks.dart';

class MockAppLifecycleEvents extends Mock implements AppLifecycleEvents {}

class MockHomeDayKeyService extends Mock implements HomeDayKeyService {}

class MockTemporalTriggerService extends Mock
    implements TemporalTriggerService {}

class MockProjectAnchorStateRepositoryContract extends Mock
    implements ProjectAnchorStateRepositoryContract {}

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  late MockTaskRepositoryContract taskRepository;
  late MockMyDayRepositoryContract myDayRepository;
  late MockRoutineRepositoryContract routineRepository;
  late MockValueRepositoryContract valueRepository;
  late MockProjectRepositoryContract projectRepository;
  late MockProjectAnchorStateRepositoryContract projectAnchorStateRepository;
  late MockSettingsRepositoryContract settingsRepository;
  late MockAllocationOrchestrator allocationOrchestrator;
  late MockHomeDayKeyService dayKeyService;
  late MockTemporalTriggerService temporalTriggerService;
  late MockAppLifecycleEvents appLifecycleEvents;

  late SessionStreamCacheManager cacheManager;
  late SessionSharedDataService sharedDataService;
  late SessionAllocationCacheService allocationCacheService;
  late MyDayRitualStatusService ritualStatusService;
  late MyDayQueryService queryService;
  late DemoModeService demoModeService;
  late DemoDataProvider demoDataProvider;

  late TestStreamController<TemporalTriggerEvent> triggerController;
  late TestStreamController<AppLifecycleEvent> lifecycleController;
  late TestStreamController<List<Value>> valuesController;
  late TestStreamController<List<Task>> tasksController;
  late TestStreamController<List<Project>> projectsController;
  late TestStreamController<List<ProjectAnchorState>>
  projectAnchorStateController;
  late TestStreamController<List<Routine>> routinesController;
  late TestStreamController<List<RoutineCompletion>> completionsController;
  late TestStreamController<List<RoutineSkip>> skipsController;
  late TestStreamController<List<CompletionHistoryData>>
  completionHistoryController;
  late TestStreamController<AllocationConfig> allocationConfigController;

  setUp(() {
    taskRepository = MockTaskRepositoryContract();
    myDayRepository = MockMyDayRepositoryContract();
    routineRepository = MockRoutineRepositoryContract();
    valueRepository = MockValueRepositoryContract();
    projectRepository = MockProjectRepositoryContract();
    projectAnchorStateRepository = MockProjectAnchorStateRepositoryContract();
    settingsRepository = MockSettingsRepositoryContract();
    allocationOrchestrator = MockAllocationOrchestrator();
    dayKeyService = MockHomeDayKeyService();
    temporalTriggerService = MockTemporalTriggerService();
    appLifecycleEvents = MockAppLifecycleEvents();
    demoModeService = DemoModeService();
    demoDataProvider = DemoDataProvider();

    triggerController = TestStreamController.seeded(const AppResumed());
    lifecycleController = TestStreamController.seeded(
      AppLifecycleEvent.resumed,
    );
    valuesController = TestStreamController.seeded(const <Value>[]);
    tasksController = TestStreamController.seeded(const <Task>[]);
    projectsController = TestStreamController.seeded(const <Project>[]);
    projectAnchorStateController = TestStreamController.seeded(
      const <ProjectAnchorState>[],
    );
    routinesController = TestStreamController.seeded(const <Routine>[]);
    completionsController = TestStreamController.seeded(
      const <RoutineCompletion>[],
    );
    skipsController = TestStreamController.seeded(const <RoutineSkip>[]);
    completionHistoryController = TestStreamController.seeded(
      const <CompletionHistoryData>[],
    );
    allocationConfigController = TestStreamController.seeded(
      const AllocationConfig(),
    );

    when(
      () => temporalTriggerService.events,
    ).thenAnswer((_) => triggerController.stream);
    when(
      () => appLifecycleEvents.events,
    ).thenAnswer((_) => lifecycleController.stream);

    cacheManager = SessionStreamCacheManager(
      appLifecycleService: appLifecycleEvents,
    );

    sharedDataService = SessionSharedDataService(
      cacheManager: cacheManager,
      valueRepository: valueRepository,
      projectRepository: projectRepository,
      taskRepository: taskRepository,
      demoModeService: demoModeService,
      demoDataProvider: demoDataProvider,
    );

    allocationCacheService = SessionAllocationCacheService(
      cacheManager: cacheManager,
      sessionDayKeyService: SessionDayKeyService(
        dayKeyService: dayKeyService,
        temporalTriggerService: temporalTriggerService,
      ),
      allocationOrchestrator: allocationOrchestrator,
      taskRepository: taskRepository,
      projectRepository: projectRepository,
      projectAnchorStateRepository: projectAnchorStateRepository,
      settingsRepository: settingsRepository,
      valueRepository: valueRepository,
    );

    ritualStatusService = MyDayRitualStatusService(
      myDayRepository: myDayRepository,
    );

    queryService = MyDayQueryService(
      taskRepository: taskRepository,
      myDayRepository: myDayRepository,
      ritualStatusService: ritualStatusService,
      routineRepository: routineRepository,
      dayKeyService: dayKeyService,
      temporalTriggerService: temporalTriggerService,
      allocationCacheService: allocationCacheService,
      sharedDataService: sharedDataService,
      demoModeService: demoModeService,
      demoDataProvider: demoDataProvider,
    );

    when(
      () => valueRepository.watchAll(),
    ).thenAnswer((_) => valuesController.stream);
    when(() => valueRepository.getAll()).thenAnswer(
      (_) async => valuesController.value ?? const <Value>[],
    );
    when(
      () => taskRepository.watchAll(any()),
    ).thenAnswer((_) => tasksController.stream);
    when(
      () => taskRepository.getAll(any()),
    ).thenAnswer((_) async => const <Task>[]);
    when(
      () => projectRepository.watchAll(),
    ).thenAnswer((_) => projectsController.stream);
    when(() => projectRepository.getAll()).thenAnswer(
      (_) async => projectsController.value ?? const <Project>[],
    );
    when(() => projectRepository.getAll(any())).thenAnswer(
      (_) async => projectsController.value ?? const <Project>[],
    );
    when(
      () => projectAnchorStateRepository.watchAll(),
    ).thenAnswer((_) => projectAnchorStateController.stream);
    when(
      () => routineRepository.watchAll(includeInactive: true),
    ).thenAnswer((_) => routinesController.stream);
    when(
      () => routineRepository.getAll(includeInactive: true),
    ).thenAnswer((_) async => const <Routine>[]);
    when(
      () => routineRepository.watchCompletions(),
    ).thenAnswer((_) => completionsController.stream);
    when(
      () => routineRepository.getCompletions(),
    ).thenAnswer((_) async => const <RoutineCompletion>[]);
    when(
      () => routineRepository.watchSkips(),
    ).thenAnswer((_) => skipsController.stream);
    when(
      () => routineRepository.getSkips(),
    ).thenAnswer((_) async => const <RoutineSkip>[]);
    when(
      () => taskRepository.watchCompletionHistory(),
    ).thenAnswer((_) => completionHistoryController.stream);
    when(
      () => settingsRepository.watch(SettingsKey.allocation),
    ).thenAnswer((_) => allocationConfigController.stream);
    when(
      () => allocationOrchestrator.getAllocationSnapshot(
        context: any(named: 'context'),
      ),
    ).thenAnswer(
      (_) async => const AllocationResult(
        allocatedTasks: <AllocatedTask>[],
        reasoning: AllocationReasoning(
          strategyUsed: 'test',
          categoryAllocations: <String, int>{},
          categoryWeights: <String, double>{},
        ),
        excludedTasks: <ExcludedTask>[],
      ),
    );

    addTearDown(() async {
      await triggerController.close();
      await lifecycleController.close();
      await valuesController.close();
      await tasksController.close();
      await projectsController.close();
      await projectAnchorStateController.close();
      await routinesController.close();
      await completionsController.close();
      await skipsController.close();
      await completionHistoryController.close();
      await allocationConfigController.close();
      await cacheManager.dispose();
      await demoModeService.dispose();
    });
  });

  testSafe('uses allocation snapshot when ritual is not completed', () async {
    final dayKey = DateTime.utc(2025, 1, 15);
    var currentDayKey = dayKey;

    when(() => dayKeyService.todayDayKeyUtc()).thenAnswer((_) => currentDayKey);

    final value = TestData.value(id: 'value-1', name: 'Health');
    final task = TestData.task(id: 'task-1', name: 'Allocated Task');

    valuesController.emit([value]);
    tasksController.emit([task]);

    final allocation = AllocationResult(
      allocatedTasks: [
        AllocatedTask(
          task: task,
          qualifyingValueId: value.id,
          allocationScore: 0.9,
        ),
      ],
      reasoning: const AllocationReasoning(
        strategyUsed: 'test',
        categoryAllocations: {},
        categoryWeights: {},
        explanation: 'test',
      ),
      excludedTasks: const <ExcludedTask>[],
    );

    when(
      () => allocationOrchestrator.getAllocationSnapshot(
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async => allocation);

    final picks = my_day.MyDayDayPicks(
      dayKeyUtc: dayKey,
      ritualCompletedAtUtc: null,
      picks: const <my_day.MyDayPick>[],
    );

    when(() => myDayRepository.loadDay(dayKey)).thenAnswer((_) async => picks);
    when(
      () => myDayRepository.watchDay(dayKey),
    ).thenAnswer((_) => Stream.value(picks));

    final model = await queryService.watchMyDayViewModel().first;

    expect(model.plannedItems, isEmpty);
    expect(model.tasks.single.id, task.id);
  });

  testSafe('uses day picks when ritual is completed', () async {
    final dayKey = DateTime.utc(2025, 1, 16);
    when(() => dayKeyService.todayDayKeyUtc()).thenReturn(dayKey);

    final value = TestData.value(id: 'value-2', name: 'Focus');
    final task = TestData.task(id: 'task-2', name: 'Selected Task');

    valuesController.emit([value]);
    tasksController.emit([task]);

    final pick = my_day.MyDayPick.task(
      taskId: task.id,
      bucket: my_day.MyDayPickBucket.manual,
      sortIndex: 1,
      pickedAtUtc: dayKey,
    );

    final picks = my_day.MyDayDayPicks(
      dayKeyUtc: dayKey,
      ritualCompletedAtUtc: dayKey,
      picks: [pick],
    );

    when(() => myDayRepository.loadDay(dayKey)).thenAnswer((_) async => picks);
    when(
      () => myDayRepository.watchDay(dayKey),
    ).thenAnswer((_) => Stream.value(picks));

    when(
      () => taskRepository.getAll(TaskQuery.all()),
    ).thenAnswer((_) async => [task]);
    when(
      () => routineRepository.getAll(includeInactive: true),
    ).thenAnswer((_) async => const <Routine>[]);
    when(
      () => routineRepository.getCompletions(),
    ).thenAnswer((_) async => const <RoutineCompletion>[]);
    when(
      () => routineRepository.getSkips(),
    ).thenAnswer((_) async => const <RoutineSkip>[]);

    final model = await queryService.watchMyDayViewModel().first;

    expect(model.plannedItems.single.id, task.id);
    expect(model.selectedTotalCount, 1);
  });

  testSafe('emits new view model on day boundary trigger', () async {
    final dayKey1 = DateTime.utc(2025, 1, 15);
    final dayKey2 = DateTime.utc(2025, 1, 16);
    var currentDayKey = dayKey1;

    when(() => dayKeyService.todayDayKeyUtc()).thenAnswer((_) => currentDayKey);

    final picks1 = my_day.MyDayDayPicks(
      dayKeyUtc: dayKey1,
      ritualCompletedAtUtc: null,
      picks: const <my_day.MyDayPick>[],
    );
    final picks2 = my_day.MyDayDayPicks(
      dayKeyUtc: dayKey2,
      ritualCompletedAtUtc: dayKey2,
      picks: const <my_day.MyDayPick>[],
    );

    when(() => myDayRepository.loadDay(any())).thenAnswer((invocation) async {
      final key = invocation.positionalArguments.first as DateTime;
      return key.isAtSameMomentAs(dayKey1) ? picks1 : picks2;
    });
    when(() => myDayRepository.watchDay(any())).thenAnswer((invocation) {
      final key = invocation.positionalArguments.first as DateTime;
      return Stream.value(key.isAtSameMomentAs(dayKey1) ? picks1 : picks2);
    });

    final iterator = StreamIterator(queryService.watchMyDayViewModel());
    addTearDown(iterator.cancel);

    expect(await iterator.moveNext(), isTrue);
    final first = iterator.current;
    expect(first.ritualStatus.ritualCompletedAtUtc, isNull);

    currentDayKey = dayKey2;
    triggerController.emit(HomeDayBoundaryCrossed(newDayKeyUtc: dayKey2));

    expect(await iterator.moveNext(), isTrue);
    final second = iterator.current;
    expect(second.ritualStatus.ritualCompletedAtUtc, dayKey2);

    verify(() => myDayRepository.loadDay(dayKey2)).called(greaterThan(0));
  });
}
