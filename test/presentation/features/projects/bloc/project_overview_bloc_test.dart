@Tags(['unit', 'projects'])
library;

import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../helpers/test_imports.dart';
import '../../../../mocks/feature_mocks.dart';
import '../../../../mocks/presentation_mocks.dart';
import '../../../../mocks/repository_mocks.dart';
import 'package:taskly_bloc/presentation/features/projects/bloc/project_overview_bloc.dart';
import 'package:taskly_bloc/presentation/shared/services/time/session_day_key_service.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/telemetry.dart';
import 'package:taskly_domain/time.dart';

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
  });
  setUp(setUpTestEnvironment);

  late MockProjectRepositoryContract projectRepository;
  late MockTaskRepositoryContract taskRepository;
  late MockRoutineRepositoryContract routineRepository;
  late MockSettingsRepositoryContract settingsRepository;
  late OccurrenceReadService occurrenceReadService;
  late SessionDayKeyService sessionDayKeyService;
  late MockHomeDayKeyService dayKeyService;
  late MockTemporalTriggerService temporalTriggerService;

  late TestStreamController<TemporalTriggerEvent> temporalController;
  late BehaviorSubject<Project?> projectSubject;
  late BehaviorSubject<List<Task>> tasksSubject;
  late BehaviorSubject<List<CompletionHistoryData>> completionsSubject;
  late BehaviorSubject<List<RecurrenceExceptionData>> exceptionsSubject;
  late BehaviorSubject<List<Routine>> routinesSubject;
  late BehaviorSubject<List<RoutineCompletion>> routineCompletionsSubject;
  late BehaviorSubject<List<RoutineSkip>> routineSkipsSubject;

  ProjectOverviewBloc buildBloc(String projectId) {
    return ProjectOverviewBloc(
      projectId: projectId,
      projectRepository: projectRepository,
      occurrenceReadService: occurrenceReadService,
      sessionDayKeyService: sessionDayKeyService,
      routineRepository: routineRepository,
    );
  }

  setUp(() {
    projectRepository = MockProjectRepositoryContract();
    taskRepository = MockTaskRepositoryContract();
    routineRepository = MockRoutineRepositoryContract();
    settingsRepository = MockSettingsRepositoryContract();
    occurrenceReadService = OccurrenceReadService(
      taskRepository: taskRepository,
      projectRepository: projectRepository,
      dayKeyService: HomeDayKeyService(
        settingsRepository: settingsRepository,
        clock: FakeClock(DateTime.utc(2025, 1, 15)),
      ),
    );
    dayKeyService = MockHomeDayKeyService();
    temporalTriggerService = MockTemporalTriggerService();
    sessionDayKeyService = SessionDayKeyService(
      dayKeyService: dayKeyService,
      temporalTriggerService: temporalTriggerService,
    );

    temporalController = TestStreamController.seeded(const AppResumed());
    projectSubject = BehaviorSubject<Project?>.seeded(
      TestData.project(id: 'p-1'),
    );
    tasksSubject = BehaviorSubject.seeded(<Task>[]);
    completionsSubject = BehaviorSubject.seeded(
      const <CompletionHistoryData>[],
    );
    exceptionsSubject = BehaviorSubject.seeded(
      const <RecurrenceExceptionData>[],
    );
    routinesSubject = BehaviorSubject.seeded(<Routine>[]);
    routineCompletionsSubject = BehaviorSubject.seeded(
      const <RoutineCompletion>[],
    );
    routineSkipsSubject = BehaviorSubject.seeded(const <RoutineSkip>[]);

    when(() => taskRepository.watchAll(any())).thenAnswer(
      (_) => tasksSubject.stream,
    );
    when(() => taskRepository.watchCompletionHistory()).thenAnswer(
      (_) => completionsSubject.stream,
    );
    when(() => taskRepository.watchRecurrenceExceptions()).thenAnswer(
      (_) => exceptionsSubject.stream,
    );
    when(() => routineRepository.watchAll(includeInactive: true)).thenAnswer(
      (_) => routinesSubject.stream,
    );
    when(() => routineRepository.watchCompletions()).thenAnswer(
      (_) => routineCompletionsSubject.stream,
    );
    when(() => routineRepository.watchSkips()).thenAnswer(
      (_) => routineSkipsSubject.stream,
    );
    when(() => temporalTriggerService.events).thenAnswer(
      (_) => temporalController.stream,
    );
    when(
      () => dayKeyService.todayDayKeyUtc(),
    ).thenReturn(DateTime.utc(2025, 1, 15));
    sessionDayKeyService.start();
    when(() => projectRepository.watchById('p-1')).thenAnswer(
      (_) => projectSubject.stream,
    );

    addTearDown(temporalController.close);
    addTearDown(sessionDayKeyService.dispose);
    addTearDown(projectSubject.close);
    addTearDown(tasksSubject.close);
    addTearDown(completionsSubject.close);
    addTearDown(exceptionsSubject.close);
    addTearDown(routinesSubject.close);
    addTearDown(routineCompletionsSubject.close);
    addTearDown(routineSkipsSubject.close);
  });

  blocTestSafe<ProjectOverviewBloc, ProjectOverviewState>(
    'loads overview with project and tasks',
    build: () => buildBloc('p-1'),
    act: (_) {
      tasksSubject.add([TestData.task(id: 't-1')]);
    },
    skip: 2,
    expect: () => [
      isA<ProjectOverviewLoaded>().having((s) => s.tasks.length, 'tasks', 1),
    ],
  );

  blocTestSafe<ProjectOverviewBloc, ProjectOverviewState>(
    'inbox project uses synthetic project',
    build: () => buildBloc(ProjectGroupingRef.inbox().stableKey),
    skip: 2,
    expect: () => [],
    verify: (bloc) {
      expect(
        bloc.state,
        isA<ProjectOverviewLoaded>().having(
          (s) => s.project.id,
          'projectId',
          ProjectGroupingRef.inbox().stableKey,
        ),
      );
    },
  );
}

class FakeClock implements Clock {
  FakeClock(this.now);

  DateTime now;

  @override
  DateTime nowLocal() => now;

  @override
  DateTime nowUtc() => now.toUtc();
}
