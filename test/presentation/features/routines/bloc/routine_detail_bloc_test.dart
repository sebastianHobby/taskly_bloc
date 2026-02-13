@Tags(['unit', 'routines'])
library;

import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_imports.dart';
import '../../../../mocks/repository_mocks.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/features/routines/bloc/routine_detail_bloc.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/taskly_domain.dart';

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerFallbackValue(
      const CreateRoutineCommand(
        name: 'Routine',
        projectId: 'project-1',
        periodType: RoutinePeriodType.week,
        scheduleMode: RoutineScheduleMode.flexible,
        targetCount: 1,
      ),
    );
  });
  setUp(setUpTestEnvironment);

  late MockRoutineRepositoryContract routineRepository;
  late MockProjectRepositoryContract projectRepository;
  late RoutineWriteService routineWriteService;
  late AppErrorReporter errorReporter;

  RoutineDetailBloc buildBloc() {
    return RoutineDetailBloc(
      routineRepository: routineRepository,
      projectRepository: projectRepository,
      routineWriteService: routineWriteService,
      errorReporter: errorReporter,
      routineId: null,
    );
  }

  setUp(() {
    routineRepository = MockRoutineRepositoryContract();
    projectRepository = MockProjectRepositoryContract();
    routineWriteService = RoutineWriteService(
      routineRepository: routineRepository,
    );
    errorReporter = AppErrorReporter(
      messengerKey: GlobalKey<ScaffoldMessengerState>(),
    );
  });

  blocTestSafe<RoutineDetailBloc, RoutineDetailState>(
    'loads initial data for create',
    build: () {
      when(() => projectRepository.getAll(ProjectQuery.all())).thenAnswer(
        (_) async => [TestData.project(id: 'project-1', name: 'Health')],
      );
      return buildBloc();
    },
    expect: () => [
      const RoutineDetailState.loadInProgress(),
      isA<RoutineDetailInitialDataLoadSuccess>().having(
        (s) => s.availableProjects.length,
        'projects',
        1,
      ),
    ],
  );

  blocTestSafe<RoutineDetailBloc, RoutineDetailState>(
    'emits failure when routine not found',
    build: () {
      when(
        () => projectRepository.getAll(ProjectQuery.all()),
      ).thenAnswer((_) async => []);
      when(() => routineRepository.getById('missing')).thenAnswer(
        (_) async => null,
      );
      return RoutineDetailBloc(
        routineRepository: routineRepository,
        projectRepository: projectRepository,
        routineWriteService: routineWriteService,
        errorReporter: errorReporter,
        routineId: 'missing',
      );
    },
    expect: () => [
      const RoutineDetailState.loadInProgress(),
      isA<RoutineDetailOperationFailure>().having(
        (s) => s.errorDetails.error,
        'error',
        NotFoundEntity.routine,
      ),
    ],
  );
}
