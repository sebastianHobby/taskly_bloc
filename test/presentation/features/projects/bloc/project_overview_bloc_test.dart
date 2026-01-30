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
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/telemetry.dart';
import 'package:taskly_domain/time.dart';

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
    registerFallbackValue(
      const OperationContext(
        correlationId: 'corr-1',
        feature: 'projects',
        intent: 'test',
        operation: 'test',
      ),
    );
  });
  setUp(setUpTestEnvironment);

  late MockProjectRepositoryContract projectRepository;
  late MockTaskRepositoryContract taskRepository;
  late MockSettingsRepositoryContract settingsRepository;
  late OccurrenceReadService occurrenceReadService;
  late MockProjectNextActionsRepositoryContract nextActionsRepository;
  late SessionDayKeyService sessionDayKeyService;
  late MockHomeDayKeyService dayKeyService;
  late MockTemporalTriggerService temporalTriggerService;

  late TestStreamController<TemporalTriggerEvent> temporalController;
  late BehaviorSubject<Project?> projectSubject;
  late BehaviorSubject<List<Task>> tasksSubject;
  late BehaviorSubject<List<ProjectNextAction>> nextActionsSubject;
  late BehaviorSubject<List<CompletionHistoryData>> completionsSubject;
  late BehaviorSubject<List<RecurrenceExceptionData>> exceptionsSubject;

  ProjectOverviewBloc buildBloc(String projectId) {
    return ProjectOverviewBloc(
      projectId: projectId,
      projectRepository: projectRepository,
      occurrenceReadService: occurrenceReadService,
      projectNextActionsRepository: nextActionsRepository,
      sessionDayKeyService: sessionDayKeyService,
    );
  }

  setUp(() {
    projectRepository = MockProjectRepositoryContract();
    taskRepository = MockTaskRepositoryContract();
    settingsRepository = MockSettingsRepositoryContract();
    occurrenceReadService = OccurrenceReadService(
      taskRepository: taskRepository,
      projectRepository: projectRepository,
      dayKeyService: HomeDayKeyService(
        settingsRepository: settingsRepository,
        clock: FakeClock(DateTime.utc(2025, 1, 15)),
      ),
    );
    nextActionsRepository = MockProjectNextActionsRepositoryContract();
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
    nextActionsSubject = BehaviorSubject.seeded(<ProjectNextAction>[]);
    completionsSubject = BehaviorSubject.seeded(
      const <CompletionHistoryData>[],
    );
    exceptionsSubject = BehaviorSubject.seeded(
      const <RecurrenceExceptionData>[],
    );

    when(() => taskRepository.watchAll(any())).thenAnswer(
      (_) => tasksSubject.stream,
    );
    when(() => taskRepository.watchCompletionHistory()).thenAnswer(
      (_) => completionsSubject.stream,
    );
    when(() => taskRepository.watchRecurrenceExceptions()).thenAnswer(
      (_) => exceptionsSubject.stream,
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
    when(() => nextActionsRepository.watchForProject('p-1')).thenAnswer(
      (_) => nextActionsSubject.stream,
    );
    when(
      () => nextActionsRepository.setForProject(
        projectId: any(named: 'projectId'),
        actions: any(named: 'actions'),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async {});

    addTearDown(temporalController.close);
    addTearDown(sessionDayKeyService.dispose);
    addTearDown(projectSubject.close);
    addTearDown(tasksSubject.close);
    addTearDown(nextActionsSubject.close);
    addTearDown(completionsSubject.close);
    addTearDown(exceptionsSubject.close);
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
    'next actions update forwards context',
    build: () => buildBloc('p-1'),
    act: (bloc) => bloc.add(
      const ProjectOverviewNextActionsUpdated(
        actions: [],
        intent: 'next_actions_updated',
      ),
    ),
    skip: 2,
    expect: () => [],
    verify: (_) {
      final captured = verify(
        () => nextActionsRepository.setForProject(
          projectId: 'p-1',
          actions: any(named: 'actions'),
          context: captureAny(named: 'context'),
        ),
      ).captured;
      final ctx = captured.single as OperationContext;
      expect(ctx.feature, 'projects');
      expect(ctx.screen, 'project_detail');
      expect(ctx.intent, 'next_actions_updated');
      expect(ctx.operation, 'project_next_actions.set');
    },
  );

  blocTestSafe<ProjectOverviewBloc, ProjectOverviewState>(
    'inbox project uses synthetic project and ignores next actions',
    build: () => buildBloc(ProjectGroupingRef.inbox().stableKey),
    act: (bloc) {
      bloc.add(
        const ProjectOverviewNextActionsUpdated(
          actions: [],
          intent: 'next_actions_updated',
        ),
      );
    },
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
      verifyNever(
        () => nextActionsRepository.setForProject(
          projectId: any(named: 'projectId'),
          actions: any(named: 'actions'),
          context: any(named: 'context'),
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
