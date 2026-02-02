@Tags(['unit', 'app'])
library;

import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_imports.dart';
import '../../../../mocks/repository_mocks.dart';
import 'package:taskly_bloc/core/startup/authenticated_app_services_coordinator.dart';
import 'package:taskly_bloc/core/startup/app_restart_service.dart';
import 'package:taskly_bloc/presentation/features/app/bloc/initial_sync_gate_bloc.dart';
import 'package:taskly_bloc/presentation/shared/services/streams/session_stream_cache.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_data_provider.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_mode_service.dart';
import 'package:taskly_bloc/presentation/shared/session/session_shared_data_service.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';

class MockAuthenticatedAppServicesCoordinator extends Mock
    implements AuthenticatedAppServicesCoordinator {}

class MockInitialSyncService extends Mock implements InitialSyncService {}

class MockAppLifecycleEvents extends Mock implements AppLifecycleEvents {}

class MockAppRestartService extends Mock implements AppRestartService {}

InitialSyncProgress _progress({
  bool hasSynced = false,
  DateTime? lastSyncedAt,
}) {
  return InitialSyncProgress(
    connected: false,
    connecting: false,
    downloading: false,
    uploading: false,
    hasSynced: hasSynced,
    lastSyncedAt: lastSyncedAt,
  );
}

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
  });
  setUp(setUpTestEnvironment);

  late MockAuthenticatedAppServicesCoordinator coordinator;
  late MockInitialSyncService initialSyncService;
  late MockAppRestartService appRestartService;
  late SessionSharedDataService sharedDataService;
  late SessionStreamCacheManager cacheManager;
  late DemoModeService demoModeService;
  late DemoDataProvider demoDataProvider;
  late MockAppLifecycleEvents appLifecycleEvents;
  late MockValueRepositoryContract valueRepository;
  late MockTaskRepositoryContract taskRepository;
  late MockProjectRepositoryContract projectRepository;
  late TestStreamController<InitialSyncProgress> progressController;
  late TestStreamController<int> taskCountController;
  late TestStreamController<List<Value>> valuesController;

  InitialSyncGateBloc buildBloc() {
    return InitialSyncGateBloc(
      coordinator: coordinator,
      initialSyncService: initialSyncService,
      sharedDataService: sharedDataService,
      appRestartService: appRestartService,
    );
  }

  setUp(() {
    coordinator = MockAuthenticatedAppServicesCoordinator();
    initialSyncService = MockInitialSyncService();
    appRestartService = MockAppRestartService();
    appLifecycleEvents = MockAppLifecycleEvents();
    valueRepository = MockValueRepositoryContract();
    taskRepository = MockTaskRepositoryContract();
    projectRepository = MockProjectRepositoryContract();
    demoModeService = DemoModeService();
    demoDataProvider = DemoDataProvider();
    progressController = TestStreamController.seeded(_progress());
    taskCountController = TestStreamController.seeded(0);
    valuesController = TestStreamController.seeded(const <Value>[]);

    when(() => coordinator.start()).thenAnswer((_) async {});
    when(() => initialSyncService.progress).thenAnswer(
      (_) => progressController.stream,
    );
    when(
      () => appRestartService.restart(reason: any(named: 'reason')),
    ).thenAnswer((_) async => true);
    when(() => appLifecycleEvents.events).thenAnswer(
      (_) => const Stream<AppLifecycleEvent>.empty(),
    );
    when(() => taskRepository.watchAllCount()).thenAnswer(
      (_) => taskCountController.stream,
    );
    when(() => valueRepository.watchAll()).thenAnswer(
      (_) => valuesController.stream,
    );
    when(() => valueRepository.getAll()).thenAnswer(
      (_) async => const <Value>[],
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

    addTearDown(progressController.close);
    addTearDown(taskCountController.close);
    addTearDown(valuesController.close);
    addTearDown(cacheManager.dispose);
    addTearDown(demoModeService.dispose);
  });

  blocTestSafe<InitialSyncGateBloc, InitialSyncGateState>(
    'emits ready immediately when local data exists',
    build: () {
      taskCountController.emit(2);
      return buildBloc();
    },
    act: (bloc) => bloc.add(const InitialSyncGateStarted()),
    expect: () => [
      isA<InitialSyncGateInProgress>(),
      isA<InitialSyncGateReady>(),
    ],
  );

  blocTestSafe<InitialSyncGateBloc, InitialSyncGateState>(
    'emits ready when sync completes without blocking',
    build: buildBloc,
    act: (bloc) async {
      bloc.add(const InitialSyncGateStarted());
      progressController.emit(_progress(hasSynced: false));
      progressController.emit(_progress(hasSynced: true));
    },
    expect: () => [
      isA<InitialSyncGateInProgress>(),
      isA<InitialSyncGateReady>(),
    ],
  );

  blocTestSafe<InitialSyncGateBloc, InitialSyncGateState>(
    'retry exits failure state',
    build: () {
      when(() => coordinator.start()).thenThrow(StateError('boom'));
      return buildBloc();
    },
    act: (bloc) async {
      bloc.add(const InitialSyncGateStarted());
      await Future<void>.delayed(TestConstants.defaultWait);
      when(() => coordinator.start()).thenAnswer((_) async {});
      bloc.add(const InitialSyncGateRetryRequested());
      progressController.emit(_progress(hasSynced: true));
    },
    expect: () => [
      isA<InitialSyncGateInProgress>(),
      isA<InitialSyncGateFailure>(),
      isA<InitialSyncGateInProgress>(),
      isA<InitialSyncGateReady>(),
    ],
  );

  blocTestSafe<InitialSyncGateBloc, InitialSyncGateState>(
    'triggers app restart on stream already listened error',
    build: () {
      when(
        () => coordinator.start(),
      ).thenThrow(StateError('Stream has already been listened to.'));
      return buildBloc();
    },
    act: (bloc) => bloc.add(const InitialSyncGateStarted()),
    expect: () => [
      isA<InitialSyncGateInProgress>(),
    ],
    verify: (_) {
      verify(
        () => appRestartService.restart(
          reason: 'powersync-stream-already-listened',
        ),
      ).called(1);
    },
  );
}
