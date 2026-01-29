@Tags(['unit', 'values'])
library;

import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_imports.dart';
import '../../../../mocks/presentation_mocks.dart';
import '../../../../mocks/repository_mocks.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/features/values/bloc/value_detail_bloc.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/taskly_domain.dart';

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerFallbackValue(
      const CreateValueCommand(name: 'Test', color: '#000000'),
    );
  });
  setUp(setUpTestEnvironment);

  late MockValueRepositoryContract valueRepository;
  late MockValueWriteService valueWriteService;
  late AppErrorReporter errorReporter;

  ValueDetailBloc buildBloc() {
    return ValueDetailBloc(
      valueRepository: valueRepository,
      valueWriteService: valueWriteService,
      errorReporter: errorReporter,
    );
  }

  setUp(() {
    valueRepository = MockValueRepositoryContract();
    valueWriteService = MockValueWriteService();
    errorReporter = AppErrorReporter(
      messengerKey: GlobalKey<ScaffoldMessengerState>(),
    );
  });

  blocTestSafe<ValueDetailBloc, ValueDetailState>(
    'loads value by id',
    build: () {
      when(() => valueRepository.getById('value-1')).thenAnswer(
        (_) async => TestData.value(id: 'value-1', name: 'Focus'),
      );
      return buildBloc();
    },
    act: (bloc) => bloc.add(
      const ValueDetailEvent.loadById(valueId: 'value-1'),
    ),
    expect: () => [
      const ValueDetailState.loadInProgress(),
      isA<ValueDetailLoadSuccess>().having((s) => s.value.id, 'id', 'value-1'),
    ],
  );

  blocTestSafe<ValueDetailBloc, ValueDetailState>(
    'emits validation failure on create',
    build: () {
      when(
        () => valueWriteService.create(
          any(),
          context: any(named: 'context'),
        ),
      ).thenAnswer(
        (_) async => CommandValidationFailure(
          failure: const ValidationFailure(
            formErrors: [
              ValidationError(code: 'invalid', messageKey: 'invalid'),
            ],
          ),
        ),
      );
      return buildBloc();
    },
    act: (bloc) => bloc.add(
      const ValueDetailEvent.create(
        command: CreateValueCommand(name: '', color: '#000000'),
      ),
    ),
    expect: () => [isA<ValueDetailValidationFailure>()],
  );
}
