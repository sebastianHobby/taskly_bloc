@Tags(['unit', 'projects'])
library;

import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_imports.dart';
import '../../../../mocks/feature_mocks.dart';
import '../../../../mocks/repository_mocks.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/features/projects/bloc/project_detail_bloc.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/taskly_domain.dart';

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
  late MockValueRepositoryContract valueRepository;
  late MockProjectWriteService projectWriteService;
  late AppErrorReporter errorReporter;

  ProjectDetailBloc buildBloc() {
    return ProjectDetailBloc(
      projectRepository: projectRepository,
      valueRepository: valueRepository,
      projectWriteService: projectWriteService,
      errorReporter: errorReporter,
    );
  }

  setUp(() {
    projectRepository = MockProjectRepositoryContract();
    valueRepository = MockValueRepositoryContract();
    projectWriteService = MockProjectWriteService();
    errorReporter = AppErrorReporter(
      messengerKey: GlobalKey<ScaffoldMessengerState>(),
    );

    when(() => valueRepository.getAll()).thenAnswer((_) async => []);
    when(() => projectRepository.getById(any())).thenAnswer(
      (_) async => TestData.project(id: 'p-1'),
    );
    when(
      () => projectWriteService.create(
        any(),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async => const CommandSuccess());
    when(
      () => projectWriteService.update(
        any(),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async => const CommandSuccess());
    when(
      () => projectWriteService.setPinned(
        any(),
        isPinned: any(named: 'isPinned'),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async {});
  });

  blocTestSafe<ProjectDetailBloc, ProjectDetailState>(
    'loadById emits load success',
    build: buildBloc,
    act: (bloc) => bloc.add(
      const ProjectDetailEvent.loadById(projectId: 'p-1'),
    ),
    expect: () => [
      const ProjectDetailState.loadInProgress(),
      isA<ProjectDetailLoadSuccess>()
          .having((s) => s.project.id, 'projectId', 'p-1'),
    ],
  );

  blocTestSafe<ProjectDetailBloc, ProjectDetailState>(
    'loadById emits not found failure',
    build: () {
      when(() => projectRepository.getById(any())).thenAnswer((_) async => null);
      return buildBloc();
    },
    act: (bloc) => bloc.add(
      const ProjectDetailEvent.loadById(projectId: 'p-404'),
    ),
    expect: () => [
      const ProjectDetailState.loadInProgress(),
      const ProjectDetailState.operationFailure(
        errorDetails: DetailBlocError<Project>(error: NotFoundEntity.project),
      ),
    ],
  );

  blocTestSafe<ProjectDetailBloc, ProjectDetailState>(
    'create forwards context and emits success',
    build: buildBloc,
    act: (bloc) => bloc.add(
      const ProjectDetailEvent.create(
        command: CreateProjectCommand(name: 'New', completed: false),
      ),
    ),
    expect: () => [
      isA<ProjectDetailOperationSuccess>(),
    ],
    verify: (_) {
      final captured = verify(
        () => projectWriteService.create(
          any(),
          context: captureAny(named: 'context'),
        ),
      ).captured;
      final ctx = captured.single as OperationContext;
      expect(ctx.feature, 'projects');
      expect(ctx.screen, 'project_detail');
      expect(ctx.intent, 'project_create_requested');
      expect(ctx.operation, 'projects.create');
    },
  );

  blocTestSafe<ProjectDetailBloc, ProjectDetailState>(
    'update emits validation failure',
    build: () {
      when(
        () => projectWriteService.update(
          any(),
          context: any(named: 'context'),
        ),
      ).thenAnswer(
        (_) async => const CommandValidationFailure(
          ValidationFailure(),
        ),
      );
      return buildBloc();
    },
    act: (bloc) => bloc.add(
      const ProjectDetailEvent.update(
        command: UpdateProjectCommand(
          id: 'p-1',
          name: 'Updated',
          completed: false,
        ),
      ),
    ),
    expect: () => [
      isA<ProjectDetailValidationFailure>(),
    ],
  );

  blocTestSafe<ProjectDetailBloc, ProjectDetailState>(
    'setPinned emits inline success then reloads project',
    build: buildBloc,
    act: (bloc) => bloc.add(
      const ProjectDetailEvent.setPinned(id: 'p-1', isPinned: true),
    ),
    expect: () => [
      isA<ProjectDetailInlineActionSuccess>()
          .having((s) => s.message, 'message', 'Pinned'),
      isA<ProjectDetailLoadSuccess>(),
    ],
    verify: (_) {
      verify(
        () => projectWriteService.setPinned(
          'p-1',
          isPinned: true,
          context: any(named: 'context'),
        ),
      ).called(1);
    },
  );
}
