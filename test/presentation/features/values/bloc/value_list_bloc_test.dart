@Tags(['unit', 'values'])
library;

import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../helpers/test_imports.dart';
import '../../../../mocks/presentation_mocks.dart';
import '../../../../mocks/repository_mocks.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/features/values/bloc/value_list_bloc.dart';
import 'package:taskly_domain/core.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  late MockValueRepositoryContract valueRepository;
  late MockValueWriteService valueWriteService;
  late MockSessionSharedDataService sharedDataService;
  late AppErrorReporter errorReporter;
  late BehaviorSubject<List<Value>> valuesSubject;

  ValueListBloc buildBloc() {
    return ValueListBloc(
      valueRepository: valueRepository,
      valueWriteService: valueWriteService,
      sharedDataService: sharedDataService,
      errorReporter: errorReporter,
    );
  }

  setUp(() {
    valueRepository = MockValueRepositoryContract();
    valueWriteService = MockValueWriteService();
    sharedDataService = MockSessionSharedDataService();
    errorReporter = AppErrorReporter(
      messengerKey: GlobalKey<ScaffoldMessengerState>(),
    );
    valuesSubject = BehaviorSubject<List<Value>>();
    when(() => sharedDataService.watchValues()).thenAnswer(
      (_) => valuesSubject.stream,
    );
    addTearDown(valuesSubject.close);
  });

  blocTestSafe<ValueListBloc, ValueListState>(
    'loads and sorts values on subscription',
    build: () {
      when(() => valueRepository.getAll()).thenAnswer(
        (_) async => [
          TestData.value(id: 'v1', name: 'Bravo'),
          TestData.value(id: 'v2', name: 'Alpha'),
        ],
      );
      return buildBloc();
    },
    act: (bloc) {
      bloc.add(const ValueListEvent.subscriptionRequested());
      valuesSubject.add([
        TestData.value(id: 'v1', name: 'Bravo'),
        TestData.value(id: 'v2', name: 'Alpha'),
      ]);
    },
    expect: () => [
      const ValueListLoading(),
      isA<ValueListLoaded>().having(
        (s) => s.values.first.name,
        'first',
        'Alpha',
      ),
      isA<ValueListLoaded>().having(
        (s) => s.values.first.name,
        'first',
        'Alpha',
      ),
    ],
  );
}
