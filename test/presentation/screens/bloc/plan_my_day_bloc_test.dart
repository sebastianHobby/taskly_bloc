@Tags(['unit'])
library;

import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';

import '../../../helpers/test_imports.dart';
import '../../../mocks/presentation_mocks.dart';
import '../../../mocks/repository_mocks.dart';
import '../../../mocks/feature_mocks.dart';
import 'package:taskly_bloc/presentation/screens/bloc/plan_my_day_bloc.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_data_provider.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_mode_service.dart';
import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/errors.dart';
import 'package:taskly_domain/my_day.dart' as my_day;
import 'package:taskly_domain/preferences.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/settings.dart' as settings;

class MockAllocationOrchestrator extends Mock
    implements AllocationOrchestrator {}

class MockOccurrenceCommandService extends Mock
    implements OccurrenceCommandService {}

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerFallbackValue(TaskQuery.incomplete());
    registerFallbackValue(DateTime.utc(2000, 1, 1));
  });
  setUp(setUpTestEnvironment);

  late MockSettingsRepositoryContract settingsRepository;
  late MockMyDayRepositoryContract myDayRepository;
  late TaskSuggestionService taskSuggestionService;
  late MockAllocationOrchestrator allocationOrchestrator;
  late MockTaskRepositoryContract taskRepository;
  late MockProjectRepositoryContract projectRepository;
  late MockProjectAnchorStateRepositoryContract projectAnchorStateRepository;
  late MockValueRatingsRepositoryContract valueRatingsRepository;
  late MockRoutineRepositoryContract routineRepository;
  late TaskWriteService taskWriteService;
  late RoutineWriteService routineWriteService;
  late MockOccurrenceCommandService occurrenceCommandService;
  late MockHomeDayKeyService dayKeyService;
  late MockTemporalTriggerService temporalTriggerService;
  late MockNowService nowService;
  late DemoModeService demoModeService;
  late DemoDataProvider demoDataProvider;
  late BehaviorSubject<TemporalTriggerEvent> temporalSubject;

  final dayKey = DateTime.utc(2025, 1, 15);

  setUp(() {
    settingsRepository = MockSettingsRepositoryContract();
    myDayRepository = MockMyDayRepositoryContract();
    allocationOrchestrator = MockAllocationOrchestrator();
    taskRepository = MockTaskRepositoryContract();
    projectRepository = MockProjectRepositoryContract();
    projectAnchorStateRepository = MockProjectAnchorStateRepositoryContract();
    valueRatingsRepository = MockValueRatingsRepositoryContract();
    routineRepository = MockRoutineRepositoryContract();
    occurrenceCommandService = MockOccurrenceCommandService();
    dayKeyService = MockHomeDayKeyService();
    temporalTriggerService = MockTemporalTriggerService();
    nowService = MockNowService();
    demoModeService = DemoModeService();
    demoDataProvider = DemoDataProvider();
    temporalSubject = BehaviorSubject<TemporalTriggerEvent>.seeded(
      const AppResumed(),
    );

    when(() => dayKeyService.todayDayKeyUtc()).thenReturn(dayKey);
    when(
      () => dayKeyService.todayDayKeyUtc(nowUtc: any(named: 'nowUtc')),
    ).thenReturn(dayKey);
    when(() => temporalTriggerService.events).thenAnswer(
      (_) => temporalSubject.stream,
    );
    when(() => nowService.nowUtc()).thenReturn(DateTime.utc(2025, 1, 15, 12));

    when(() => settingsRepository.load(SettingsKey.global)).thenAnswer(
      (_) async => const settings.GlobalSettings(),
    );
    when(() => settingsRepository.load(SettingsKey.allocation)).thenAnswer(
      (_) async => const AllocationConfig(),
    );

    when(() => myDayRepository.loadDay(any())).thenAnswer(
      (_) async => my_day.MyDayDayPicks(
        dayKeyUtc: dayKey,
        ritualCompletedAtUtc: null,
        picks: const <my_day.MyDayPick>[],
      ),
    );

    when(() => taskRepository.getAll(any())).thenAnswer((_) async => []);
    when(() => taskRepository.getByIds(any())).thenAnswer((_) async => []);
    when(() => taskRepository.watchAll(any())).thenAnswer(
      (_) => Stream.value(const <Task>[]),
    );
    when(
      () => routineRepository.getAll(includeInactive: true),
    ).thenAnswer((_) async => []);
    when(() => routineRepository.getCompletions()).thenAnswer((_) async => []);
    when(() => routineRepository.getSkips()).thenAnswer((_) async => []);
    when(
      () => valueRatingsRepository.watchAll(
        weeks: any(named: 'weeks'),
      ),
    ).thenAnswer((_) => Stream.value(const <ValueWeeklyRating>[]));
    when(
      () => valueRatingsRepository.getAll(
        weeks: any(named: 'weeks'),
      ),
    ).thenAnswer((_) async => const <ValueWeeklyRating>[]);

    final defaultAllocation = AllocationResult(
      allocatedTasks: const <AllocatedTask>[],
      reasoning: const AllocationReasoning(
        strategyUsed: 'none',
        categoryAllocations: {},
        categoryWeights: {},
        explanation: 'test',
      ),
      excludedTasks: const <ExcludedTask>[],
    );
    when(
      () => allocationOrchestrator.getSuggestedSnapshot(
        batchCount: any(named: 'batchCount'),
        nowUtc: any(named: 'nowUtc'),
        routineSelectionsByValue: any(named: 'routineSelectionsByValue'),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async => defaultAllocation);
    when(
      () => allocationOrchestrator.getSuggestedSnapshotForTargetCount(
        suggestedTaskTarget: any(named: 'suggestedTaskTarget'),
        nowUtc: any(named: 'nowUtc'),
        routineSelectionsByValue: any(named: 'routineSelectionsByValue'),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async => defaultAllocation);

    taskSuggestionService = TaskSuggestionService(
      allocationOrchestrator: allocationOrchestrator,
      taskRepository: taskRepository,
      dayKeyService: dayKeyService,
      valueRatingsRepository: valueRatingsRepository,
    );

    taskWriteService = TaskWriteService(
      taskRepository: taskRepository,
      projectRepository: projectRepository,
      occurrenceCommandService: occurrenceCommandService,
    );

    routineWriteService = RoutineWriteService(
      routineRepository: routineRepository,
    );

    addTearDown(temporalSubject.close);
    addTearDown(demoModeService.dispose);
  });

  PlanMyDayBloc buildBloc() {
    return PlanMyDayBloc(
      settingsRepository: settingsRepository,
      myDayRepository: myDayRepository,
      taskSuggestionService: taskSuggestionService,
      taskRepository: taskRepository,
      routineRepository: routineRepository,
      projectAnchorStateRepository: projectAnchorStateRepository,
      taskWriteService: taskWriteService,
      routineWriteService: routineWriteService,
      dayKeyService: dayKeyService,
      temporalTriggerService: temporalTriggerService,
      nowService: nowService,
      valueRatingsRepository: valueRatingsRepository,
      demoModeService: demoModeService,
      demoDataProvider: demoDataProvider,
    );
  }

  blocTestSafe<PlanMyDayBloc, PlanMyDayState>(
    'emits ready state after initial refresh',
    build: buildBloc,
    expect: () => [
      const PlanMyDayLoading(),
      isA<PlanMyDayReady>(),
      isA<PlanMyDayReady>(),
      isA<PlanMyDayReady>(),
    ],
  );

  late Task dueTask;
  late Task plannedTask;
  String? swapFromId;
  String? swapToId;

  blocTestSafe<PlanMyDayBloc, PlanMyDayState>(
    'auto-includes due and planned (start <= today) tasks in selection',
    build: () {
      final value = TestData.value(id: 'value-1', name: 'Health');
      dueTask = TestData.task(
        id: 'task-due',
        name: 'Due Today',
        deadlineDate: dayKey,
        values: [value],
      );
      plannedTask = TestData.task(
        id: 'task-planned',
        name: 'Planned For Today',
        startDate: dayKey,
        values: [value],
      );
      final suggestedTask = TestData.task(
        id: 'task-suggested',
        name: 'Suggested',
        values: [value],
      );

      when(() => myDayRepository.loadDay(dayKey)).thenAnswer(
        (_) async => my_day.MyDayDayPicks(
          dayKeyUtc: dayKey,
          ritualCompletedAtUtc: null,
          picks: const <my_day.MyDayPick>[],
        ),
      );
      when(() => taskRepository.getAll(any())).thenAnswer(
        (_) async => [dueTask, plannedTask, suggestedTask],
      );
      when(() => taskRepository.watchAll(any())).thenAnswer(
        (_) => Stream.value([dueTask, plannedTask, suggestedTask]),
      );

      final allocation = AllocationResult(
        allocatedTasks: [
          AllocatedTask(
            task: suggestedTask,
            qualifyingValueId: value.id,
            allocationScore: 0.9,
            reasonCodes: const [],
          ),
        ],
        reasoning: AllocationReasoning(
          strategyUsed: 'test',
          categoryAllocations: const {},
          categoryWeights: const {},
          explanation: 'test',
          neglectDeficits: {value.id: 0.0},
        ),
        excludedTasks: const <ExcludedTask>[],
      );
      when(
        () => allocationOrchestrator.getSuggestedSnapshot(
          batchCount: any(named: 'batchCount'),
          nowUtc: any(named: 'nowUtc'),
          routineSelectionsByValue: any(named: 'routineSelectionsByValue'),
          context: any(named: 'context'),
        ),
      ).thenAnswer((_) async => allocation);
      when(
        () => allocationOrchestrator.getSuggestedSnapshotForTargetCount(
          suggestedTaskTarget: any(named: 'suggestedTaskTarget'),
          nowUtc: any(named: 'nowUtc'),
          routineSelectionsByValue: any(named: 'routineSelectionsByValue'),
          context: any(named: 'context'),
        ),
      ).thenAnswer((_) async => allocation);

      return buildBloc();
    },
    expect: () => [
      const PlanMyDayLoading(),
      isA<PlanMyDayReady>(),
      isA<PlanMyDayReady>(),
      isA<PlanMyDayReady>()
          .having(
            (s) => s.dueTodayTasks.map((t) => t.id).toList(),
            'dueTodayTasks',
            contains(dueTask.id),
          )
          .having(
            (s) => s.plannedTasks.map((t) => t.id).toList(),
            'plannedTasks',
            contains(plannedTask.id),
          )
          .having(
            (s) => s.selectedTaskIds,
            'selectedTaskIds',
            containsAll([dueTask.id, plannedTask.id]),
          ),
    ],
  );

  blocTestSafe<PlanMyDayBloc, PlanMyDayState>(
    'swaps a selected suggestion for another option',
    build: () {
      demoModeService.enable();
      return buildBloc();
    },
    act: (bloc) async {
      if (bloc.state is! PlanMyDayReady) {
        await bloc.stream.firstWhere((state) => state is PlanMyDayReady);
      }
      final ready = bloc.state as PlanMyDayReady;
      final group = ready.valueSuggestionGroups.first;
      final fromTaskId = group.tasks
          .firstWhere((task) => ready.selectedTaskIds.contains(task.id))
          .id;
      final toTaskId = group.tasks
          .firstWhere((task) => !ready.selectedTaskIds.contains(task.id))
          .id;
      swapFromId = fromTaskId;
      swapToId = toTaskId;
      bloc.add(
        PlanMyDaySwapSuggestionRequested(
          fromTaskId: fromTaskId,
          toTaskId: toTaskId,
        ),
      );
    },
    verify: (bloc) {
      final ready = bloc.state as PlanMyDayReady;
      expect(ready.selectedTaskIds, contains(swapToId));
      expect(ready.selectedTaskIds, isNot(contains(swapFromId)));
    },
  );

  blocTestSafe<PlanMyDayBloc, PlanMyDayState>(
    'sorts value groups by lowest average rating first',
    build: () {
      final lowValue = TestData.value(
        id: 'value-low',
        name: 'Family',
      );
      final highValue = TestData.value(
        id: 'value-high',
        name: 'Health',
      );
      final lowTask = TestData.task(
        id: 'task-low',
        name: 'Call parents',
        projectId: 'project-low',
        project: TestData.project(
          id: 'project-low',
          name: 'Family Project',
          values: [lowValue],
        ).copyWith(primaryValueId: lowValue.id),
      );
      final highTask = TestData.task(
        id: 'task-high',
        name: 'Morning walk',
        projectId: 'project-high',
        project: TestData.project(
          id: 'project-high',
          name: 'Health Project',
          values: [highValue],
        ).copyWith(primaryValueId: highValue.id),
      );

      when(() => taskRepository.getAll(any())).thenAnswer(
        (_) async => [lowTask, highTask],
      );
      when(() => taskRepository.watchAll(any())).thenAnswer(
        (_) => Stream.value([lowTask, highTask]),
      );

      final weekStart = DateTime.utc(2025, 1, 13);
      final ratings = <ValueWeeklyRating>[
        ValueWeeklyRating(
          id: 'rating-low',
          valueId: lowValue.id,
          weekStartUtc: weekStart,
          rating: 3,
          createdAtUtc: weekStart,
          updatedAtUtc: weekStart,
        ),
        ValueWeeklyRating(
          id: 'rating-high',
          valueId: highValue.id,
          weekStartUtc: weekStart,
          rating: 8,
          createdAtUtc: weekStart,
          updatedAtUtc: weekStart,
        ),
      ];
      when(
        () => valueRatingsRepository.getAll(weeks: any(named: 'weeks')),
      ).thenAnswer((_) async => ratings);
      when(
        () => valueRatingsRepository.watchAll(weeks: any(named: 'weeks')),
      ).thenAnswer((_) => Stream.value(ratings));

      final allocation = AllocationResult(
        allocatedTasks: [
          AllocatedTask(
            task: lowTask,
            qualifyingValueId: lowValue.id,
            allocationScore: 0.9,
            reasonCodes: const [],
          ),
          AllocatedTask(
            task: highTask,
            qualifyingValueId: highValue.id,
            allocationScore: 0.8,
            reasonCodes: const [],
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
        () => allocationOrchestrator.getSuggestedSnapshot(
          batchCount: any(named: 'batchCount'),
          nowUtc: any(named: 'nowUtc'),
          routineSelectionsByValue: any(named: 'routineSelectionsByValue'),
          context: any(named: 'context'),
        ),
      ).thenAnswer((_) async => allocation);
      when(
        () => allocationOrchestrator.getSuggestedSnapshotForTargetCount(
          suggestedTaskTarget: any(named: 'suggestedTaskTarget'),
          nowUtc: any(named: 'nowUtc'),
          routineSelectionsByValue: any(named: 'routineSelectionsByValue'),
          context: any(named: 'context'),
        ),
      ).thenAnswer((_) async => allocation);

      return buildBloc();
    },
    act: (bloc) async {
      if (bloc.state is! PlanMyDayReady) {
        await bloc.stream.firstWhere((state) => state is PlanMyDayReady);
      }
    },
    verify: (bloc) {
      final ready = bloc.state as PlanMyDayReady;
      expect(ready.valueSuggestionGroups.first.valueId, 'value-low');
    },
  );

  blocTestSafe<PlanMyDayBloc, PlanMyDayState>(
    'switches from demo data to live data when demo mode disables',
    build: () {
      demoModeService.enable();
      return buildBloc();
    },
    act: (bloc) async {
      await Future<void>.delayed(Duration.zero);
      demoModeService.disable();
    },
    expect: () => [
      isA<PlanMyDayReady>(),
      const PlanMyDayLoading(),
      isA<PlanMyDayReady>(),
    ],
  );

  blocTestSafe<PlanMyDayBloc, PlanMyDayState>(
    'shows a toast when bulk reschedule due fails',
    build: () {
      final value = TestData.value(id: 'value-1', name: 'Health');
      dueTask = TestData.task(
        id: 'task-due',
        name: 'Due Today',
        deadlineDate: dayKey,
        values: [value],
      );

      when(() => taskRepository.getAll(any())).thenAnswer(
        (_) async => [dueTask],
      );
      when(() => taskRepository.watchAll(any())).thenAnswer(
        (_) => Stream.value([dueTask]),
      );
      when(
        () => taskRepository.bulkRescheduleDeadlines(
          taskIds: any(named: 'taskIds'),
          deadlineDate: any(named: 'deadlineDate'),
          context: any(named: 'context'),
        ),
      ).thenThrow(const StorageFailure(message: 'write failed'));

      return buildBloc();
    },
    act: (bloc) async {
      if (bloc.state is! PlanMyDayReady) {
        await bloc.stream.firstWhere((state) => state is PlanMyDayReady);
      }

      bloc.add(
        PlanMyDayBulkRescheduleDueRequested(
          newDayUtc: dayKey.add(const Duration(days: 1)),
        ),
      );

      await bloc.stream.firstWhere(
        (state) => state is PlanMyDayReady && state.toast != null,
      );
    },
    verify: (bloc) {
      final state = bloc.state as PlanMyDayReady;
      expect(state.toast?.kind, PlanMyDayToastKind.error);
      expect(state.toast?.error, isNotNull);
    },
  );
}
