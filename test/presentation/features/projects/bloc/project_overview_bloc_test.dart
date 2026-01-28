@Tags(['unit', 'projects'])
library;

import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../helpers/test_imports.dart';
import '../../../../mocks/feature_mocks.dart';
import '../../../../mocks/presentation_mocks.dart';
import '../../../../mocks/repository_mocks.dart';
import 'package:taskly_bloc/presentation/features/projects/bloc/project_overview_bloc.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/queries.dart';

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
  late MockOccurrenceReadService occurrenceReadService;
  late MockProjectNextActionsRepositoryContract nextActionsRepository;
  late MockSessionDayKeyService sessionDayKeyService;

  late BehaviorSubject<DateTime> dayKeySubject;
  late BehaviorSubject<Project?> projectSubject;
  late BehaviorSubject<List<Task>> tasksSubject;
  late BehaviorSubject<List<ProjectNextAction>> nextActionsSubject;

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
    occurrenceReadService = MockOccurrenceReadService();
    nextActionsRepository = MockProjectNextActionsRepositoryContract();
    sessionDayKeyService = MockSessionDayKeyService();

    dayKeySubject = BehaviorSubject.seeded(DateTime.utc(2025, 1, 15));
    projectSubject = BehaviorSubject<Project?>.seeded(
      TestData.project(id: 'p-1'),
    );
    tasksSubject = BehaviorSubject.seeded(<Task>[]);
    nextActionsSubject = BehaviorSubject.seeded(<ProjectNextAction>[]);

    when(() => sessionDayKeyService.todayDayKeyUtc).thenAnswer(
      (_) => dayKeySubject.stream,
    );
    when(() => projectRepository.watchById('p-1')).thenAnswer(
      (_) => projectSubject.stream,
    );
    when(
      () => occurrenceReadService.watchTasksWithOccurrencePreview(
        query: any(named: 'query'),
        preview: any(named: 'preview'),
      ),
    ).thenAnswer((_) => tasksSubject.stream);
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

    addTearDown(dayKeySubject.close);
    addTearDown(projectSubject.close);
    addTearDown(tasksSubject.close);
    addTearDown(nextActionsSubject.close);
  });

  blocTestSafe<ProjectOverviewBloc, ProjectOverviewState>(
    'loads overview with project and tasks',
    build: () => buildBloc('p-1'),
    act: (_) {
      tasksSubject.add([TestData.task(id: 't-1')]);
    },
    expect: () => [
      isA<ProjectOverviewLoaded>()
          .having((s) => s.project.id, 'projectId', 'p-1')
          .having((s) => s.tasks.length, 'tasks', 0),
      isA<ProjectOverviewLoaded>()
          .having((s) => s.tasks.length, 'tasks', 1),
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
    expect: () => [
      isA<ProjectOverviewLoaded>()
          .having((s) => s.project.id, 'projectId', ProjectGroupingRef.inbox().stableKey),
    ],
    verify: (_) {
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
