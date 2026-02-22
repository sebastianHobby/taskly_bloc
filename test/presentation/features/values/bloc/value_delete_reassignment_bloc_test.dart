@Tags(['unit', 'values'])
library;

import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_imports.dart';
import '../../../../mocks/repository_mocks.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/features/values/bloc/value_delete_reassignment_bloc.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  late MockValueRepositoryContract valueRepository;
  late MockProjectRepositoryContract projectRepository;
  late ValueWriteService valueWriteService;
  late AppErrorReporter errorReporter;

  ValueDeleteReassignmentBloc buildBloc() {
    return ValueDeleteReassignmentBloc(
      valueRepository: valueRepository,
      projectRepository: projectRepository,
      valueWriteService: valueWriteService,
      errorReporter: errorReporter,
      valueId: 'value-1',
      valueName: 'Health',
    );
  }

  setUp(() {
    valueRepository = MockValueRepositoryContract();
    projectRepository = MockProjectRepositoryContract();
    valueWriteService = ValueWriteService(valueRepository: valueRepository);
    errorReporter = AppErrorReporter(
      messengerKey: GlobalKey<ScaffoldMessengerState>(),
    );
  });

  blocTestSafe<ValueDeleteReassignmentBloc, ValueDeleteReassignmentState>(
    'loads impact and replacement options on start',
    build: () {
      when(() => valueRepository.getById('value-1')).thenAnswer(
        (_) async => TestData.value(id: 'value-1', name: 'Health'),
      );
      when(
        () => projectRepository.getAll(any()),
      ).thenAnswer(
        (_) async => [TestData.project(id: 'project-1', name: 'Plan')],
      );
      when(() => valueRepository.getAll()).thenAnswer(
        (_) async => [
          TestData.value(id: 'value-1', name: 'Health'),
          TestData.value(id: 'value-2', name: 'Career'),
        ],
      );
      return buildBloc();
    },
    act: (bloc) => bloc.add(const ValueDeleteReassignmentStarted()),
    expect: () => [
      isA<ValueDeleteReassignmentState>().having(
        (s) => s.status,
        'status',
        ValueDeleteReassignmentStatus.loading,
      ),
      isA<ValueDeleteReassignmentState>()
          .having(
            (s) => s.status,
            'status',
            ValueDeleteReassignmentStatus.ready,
          )
          .having((s) => s.affectedProjects.length, 'project count', 1)
          .having((s) => s.replacementValues.length, 'replacement count', 1),
    ],
  );

  blocTestSafe<ValueDeleteReassignmentBloc, ValueDeleteReassignmentState>(
    'confirms reassignment delete and emits success',
    build: () {
      when(() => valueRepository.getById('value-1')).thenAnswer(
        (_) async => TestData.value(id: 'value-1', name: 'Health'),
      );
      when(() => projectRepository.getAll(any())).thenAnswer(
        (_) async => [TestData.project(id: 'project-1', name: 'Plan')],
      );
      when(() => valueRepository.getAll()).thenAnswer(
        (_) async => [
          TestData.value(id: 'value-1', name: 'Health'),
          TestData.value(id: 'value-2', name: 'Career'),
        ],
      );
      when(
        () => valueRepository.reassignProjectsAndDelete(
          valueId: 'value-1',
          replacementValueId: 'value-2',
          context: any(named: 'context'),
        ),
      ).thenAnswer((_) async => 1);
      return buildBloc();
    },
    act: (bloc) async {
      bloc.add(const ValueDeleteReassignmentStarted());
      await Future<void>.delayed(const Duration(milliseconds: 1));
      bloc.add(const ValueDeleteReassignmentConfirmPressed());
    },
    expect: () => [
      isA<ValueDeleteReassignmentState>(),
      isA<ValueDeleteReassignmentState>(),
      isA<ValueDeleteReassignmentState>().having(
        (s) => s.status,
        'status',
        ValueDeleteReassignmentStatus.submitting,
      ),
      isA<ValueDeleteReassignmentState>()
          .having(
            (s) => s.status,
            'status',
            ValueDeleteReassignmentStatus.success,
          )
          .having((s) => s.reassignedProjectCount, 'reassigned', 1),
    ],
  );
}
