@Tags(['unit'])
library;

import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';

import '../../../helpers/test_imports.dart';
import '../../../mocks/presentation_mocks.dart';
import '../../../mocks/repository_mocks.dart';
import 'package:taskly_bloc/presentation/screens/bloc/plan_my_day_bloc.dart';
import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/my_day.dart' as my_day;
import 'package:taskly_domain/preferences.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/settings.dart' as settings;

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerFallbackValue(TaskQuery.incomplete());
  });
  setUp(setUpTestEnvironment);

  late MockSettingsRepositoryContract settingsRepository;
  late MockMyDayRepositoryContract myDayRepository;
  late MockTaskSuggestionService taskSuggestionService;
  late MockTaskRepositoryContract taskRepository;
  late MockRoutineRepositoryContract routineRepository;
  late MockTaskWriteService taskWriteService;
  late MockRoutineWriteService routineWriteService;
  late MockHomeDayKeyService dayKeyService;
  late MockTemporalTriggerService temporalTriggerService;
  late MockNowService nowService;
  late BehaviorSubject<TemporalTriggerEvent> temporalSubject;

  const dayKey = DateTime.utc(2025, 1, 15);

  setUp(() {
    settingsRepository = MockSettingsRepositoryContract();
    myDayRepository = MockMyDayRepositoryContract();
    taskSuggestionService = MockTaskSuggestionService();
    taskRepository = MockTaskRepositoryContract();
    routineRepository = MockRoutineRepositoryContract();
    taskWriteService = MockTaskWriteService();
    routineWriteService = MockRoutineWriteService();
    dayKeyService = MockHomeDayKeyService();
    temporalTriggerService = MockTemporalTriggerService();
    nowService = MockNowService();
    temporalSubject = BehaviorSubject<TemporalTriggerEvent>();

    when(() => dayKeyService.todayDayKeyUtc()).thenReturn(dayKey);
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
    when(
      () => routineRepository.getAll(includeInactive: true),
    ).thenAnswer((_) async => []);
    when(() => routineRepository.getCompletions()).thenAnswer((_) async => []);
    when(() => routineRepository.getSkips()).thenAnswer((_) async => []);

    when(
      () => taskSuggestionService.getSnapshot(
        dueWindowDays: any(named: 'dueWindowDays'),
        includeDueSoon: any(named: 'includeDueSoon'),
        includeAvailableToStart: any(named: 'includeAvailableToStart'),
        batchCount: any(named: 'batchCount'),
        suggestedTargetCount: any(named: 'suggestedTargetCount'),
        tasksOverride: any(named: 'tasksOverride'),
        routineSelectionsByValue: any(named: 'routineSelectionsByValue'),
        nowUtc: any(named: 'nowUtc'),
      ),
    ).thenAnswer(
      (_) async => TaskSuggestionSnapshot(
        dayKeyUtc: dayKey,
        suggested: const <SuggestedTask>[],
        dueSoonNotSuggested: const <Task>[],
        availableToStartNotSuggested: const <Task>[],
        snoozed: const <Task>[],
        requiresValueSetup: false,
        requiresRatings: false,
        neglectDeficits: const {},
      ),
    );

    addTearDown(temporalSubject.close);
  });

  PlanMyDayBloc buildBloc() {
    return PlanMyDayBloc(
      settingsRepository: settingsRepository,
      myDayRepository: myDayRepository,
      taskSuggestionService: taskSuggestionService,
      taskRepository: taskRepository,
      routineRepository: routineRepository,
      taskWriteService: taskWriteService,
      routineWriteService: routineWriteService,
      dayKeyService: dayKeyService,
      temporalTriggerService: temporalTriggerService,
      nowService: nowService,
    );
  }

  blocTestSafe<PlanMyDayBloc, PlanMyDayState>(
    'emits ready state after initial refresh',
    build: buildBloc,
    expect: () => [const PlanMyDayLoading(), isA<PlanMyDayReady>()],
  );

  blocTestSafe<PlanMyDayBloc, PlanMyDayState>(
    'advances to next step when requested',
    build: () {
      when(
        () => taskSuggestionService.getSnapshot(
          dueWindowDays: any(named: 'dueWindowDays'),
          includeDueSoon: any(named: 'includeDueSoon'),
          includeAvailableToStart: any(named: 'includeAvailableToStart'),
          batchCount: any(named: 'batchCount'),
          suggestedTargetCount: any(named: 'suggestedTargetCount'),
          tasksOverride: any(named: 'tasksOverride'),
          routineSelectionsByValue: any(named: 'routineSelectionsByValue'),
          nowUtc: any(named: 'nowUtc'),
        ),
      ).thenAnswer(
        (_) async => TaskSuggestionSnapshot(
          dayKeyUtc: dayKey,
          suggested: [
            SuggestedTask(
              task: TestData.task(
                id: 'task-1',
                values: [TestData.value(id: 'value-1', name: 'Health')],
              ),
              rank: 1,
              qualifyingValueId: 'value-1',
              reasonCodes: const [],
            ),
          ],
          dueSoonNotSuggested: const <Task>[],
          availableToStartNotSuggested: const <Task>[],
          snoozed: const <Task>[],
          requiresValueSetup: false,
          requiresRatings: false,
          neglectDeficits: const {'value-1': 0.0},
        ),
      );
      return buildBloc();
    },
    act: (bloc) => bloc.add(const PlanMyDayStepNextRequested()),
    expect: () => [
      const PlanMyDayLoading(),
      isA<PlanMyDayReady>(),
      isA<PlanMyDayReady>().having(
        (s) => s.currentStep,
        'currentStep',
        PlanMyDayStep.summary,
      ),
    ],
  );
}
