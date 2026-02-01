@Tags(['unit'])
library;

import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';

import '../../../helpers/test_imports.dart';
import '../../../mocks/repository_mocks.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_gate_bloc.dart';
import 'package:taskly_bloc/presentation/screens/services/my_day_gate_query_service.dart';
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

  late MyDayGateQueryService queryService;
  late MockAppLifecycleEvents appLifecycleEvents;
  late MockValueRepositoryContract valueRepository;
  late MockTaskRepositoryContract taskRepository;
  late MockProjectRepositoryContract projectRepository;
  late SessionStreamCacheManager cacheManager;
  late SessionSharedDataService sharedDataService;
  late DemoModeService demoModeService;
  late DemoDataProvider demoDataProvider;
  late BehaviorSubject<List<Value>> valuesSubject;

  setUp(() {
    appLifecycleEvents = MockAppLifecycleEvents();
    valueRepository = MockValueRepositoryContract();
    taskRepository = MockTaskRepositoryContract();
    projectRepository = MockProjectRepositoryContract();
    demoModeService = DemoModeService();
    demoDataProvider = DemoDataProvider();
    valuesSubject = BehaviorSubject<List<Value>>.seeded(const <Value>[]);

    when(() => appLifecycleEvents.events).thenAnswer(
      (_) => const Stream<AppLifecycleEvent>.empty(),
    );
    when(() => valueRepository.getAll()).thenAnswer(
      (_) async => valuesSubject.valueOrNull ?? const <Value>[],
    );
    when(() => valueRepository.watchAll()).thenAnswer(
      (_) => valuesSubject.stream,
    );
    when(() => projectRepository.getAll()).thenAnswer(
      (_) async => const <Project>[],
    );
    when(() => projectRepository.getAll(any())).thenAnswer(
      (_) async => const <Project>[],
    );
    when(() => projectRepository.watchAll()).thenAnswer(
      (_) => const Stream<List<Project>>.empty(),
    );
    when(() => projectRepository.watchAll(any())).thenAnswer(
      (_) => const Stream<List<Project>>.empty(),
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

    queryService = MyDayGateQueryService(
      valueRepository: valueRepository,
      sharedDataService: sharedDataService,
      demoModeService: demoModeService,
    );

    addTearDown(valuesSubject.close);
    addTearDown(cacheManager.dispose);
    addTearDown(demoModeService.dispose);
  });

  blocTestSafe<MyDayGateBloc, MyDayGateState>(
    'emits loaded state when prerequisites stream emits',
    build: () => MyDayGateBloc(queryService: queryService),
    act: (_) => valuesSubject.add(const <Value>[]),
    expect: () => [
      isA<MyDayGateLoaded>().having(
        (s) => s.needsValuesSetup,
        'needsValuesSetup',
        true,
      ),
    ],
  );

  blocTestSafe<MyDayGateBloc, MyDayGateState>(
    'retry emits loading then loaded',
    build: () {
      valuesSubject.add([TestData.value(id: 'value-1', name: 'Health')]);
      return MyDayGateBloc(queryService: queryService);
    },
    act: (bloc) async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      bloc.add(const MyDayGateRetryRequested());
      valuesSubject.add(const <Value>[]);
    },
    expect: () => [
      isA<MyDayGateLoaded>().having(
        (s) => s.needsValuesSetup,
        'needsValuesSetup',
        false,
      ),
      isA<MyDayGateLoading>(),
      isA<MyDayGateLoaded>().having(
        (s) => s.needsValuesSetup,
        'needsValuesSetup',
        true,
      ),
      isA<MyDayGateLoaded>().having(
        (s) => s.needsValuesSetup,
        'needsValuesSetup',
        true,
      ),
    ],
  );
}
