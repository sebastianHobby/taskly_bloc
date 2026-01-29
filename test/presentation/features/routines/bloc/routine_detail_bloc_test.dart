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
        valueId: 'value-1',
        routineType: RoutineType.weeklyFlexible,
        targetCount: 1,
      ),
    );
  });
  setUp(setUpTestEnvironment);

  late MockRoutineRepositoryContract routineRepository;
  late MockValueRepositoryContract valueRepository;
  late RoutineWriteService routineWriteService;
  late AppErrorReporter errorReporter;

  RoutineDetailBloc buildBloc() {
    return RoutineDetailBloc(
      routineRepository: routineRepository,
      valueRepository: valueRepository,
      routineWriteService: routineWriteService,
      errorReporter: errorReporter,
      routineId: null,
    );
  }

  setUp(() {
    routineRepository = MockRoutineRepositoryContract();
    valueRepository = MockValueRepositoryContract();
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
      when(() => valueRepository.getAll()).thenAnswer(
        (_) async => [TestData.value(id: 'value-1', name: 'Health')],
      );
      return buildBloc();
    },
    expect: () => [
      const RoutineDetailState.loadInProgress(),
      isA<RoutineDetailInitialDataLoadSuccess>().having(
        (s) => s.availableValues.length,
        'values',
        1,
      ),
    ],
  );

  blocTestSafe<RoutineDetailBloc, RoutineDetailState>(
    'emits failure when routine not found',
    build: () {
      when(() => valueRepository.getAll()).thenAnswer((_) async => []);
      when(() => routineRepository.getById('missing')).thenAnswer(
        (_) async => null,
      );
      return RoutineDetailBloc(
        routineRepository: routineRepository,
        valueRepository: valueRepository,
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
