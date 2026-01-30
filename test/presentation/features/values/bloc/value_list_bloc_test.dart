@Tags(['unit', 'values'])
library;

import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../helpers/test_imports.dart';
import '../../../../mocks/repository_mocks.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/features/values/bloc/value_list_bloc.dart';
import 'package:taskly_bloc/presentation/shared/services/streams/session_stream_cache.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_data_provider.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_mode_service.dart';
import 'package:taskly_bloc/presentation/shared/session/session_shared_data_service.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';

class MockAppLifecycleEvents extends Mock implements AppLifecycleEvents {}

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  late MockValueRepositoryContract valueRepository;
  late ValueWriteService valueWriteService;
  late SessionSharedDataService sharedDataService;
  late SessionStreamCacheManager cacheManager;
  late DemoModeService demoModeService;
  late DemoDataProvider demoDataProvider;
  late MockAppLifecycleEvents appLifecycleEvents;
  late MockTaskRepositoryContract taskRepository;
  late MockProjectRepositoryContract projectRepository;
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
    taskRepository = MockTaskRepositoryContract();
    projectRepository = MockProjectRepositoryContract();
    appLifecycleEvents = MockAppLifecycleEvents();
    demoModeService = DemoModeService();
    demoDataProvider = DemoDataProvider();
    valueWriteService = ValueWriteService(valueRepository: valueRepository);
    errorReporter = AppErrorReporter(
      messengerKey: GlobalKey<ScaffoldMessengerState>(),
    );
    valuesSubject = BehaviorSubject<List<Value>>();
    when(() => appLifecycleEvents.events).thenAnswer(
      (_) => const Stream<AppLifecycleEvent>.empty(),
    );
    when(() => valueRepository.watchAll()).thenAnswer(
      (_) => valuesSubject.stream,
    );

    cacheManager = SessionStreamCacheManager(
      appLifecycleService: appLifecycleEvents,
    );
    sharedDataService = SessionSharedDataService(
      cacheManager: cacheManager,
      valueRepository: valueRepository,
      projectRepository: projectRepository,
      taskRepository: taskRepository,
      demoModeService: demoModeService,
      demoDataProvider: demoDataProvider,
    );
    addTearDown(valuesSubject.close);
    addTearDown(cacheManager.dispose);
    addTearDown(demoModeService.dispose);
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
    ],
  );
}
