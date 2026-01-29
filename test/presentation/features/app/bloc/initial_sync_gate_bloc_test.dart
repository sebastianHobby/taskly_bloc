@Tags(['unit', 'app'])
library;

import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_imports.dart';
import '../../../../mocks/presentation_mocks.dart';
import 'package:taskly_bloc/core/startup/authenticated_app_services_coordinator.dart';
import 'package:taskly_bloc/presentation/features/app/bloc/initial_sync_gate_bloc.dart';
import 'package:taskly_domain/services.dart';

class MockAuthenticatedAppServicesCoordinator extends Mock
    implements AuthenticatedAppServicesCoordinator {}

class MockInitialSyncService extends Mock implements InitialSyncService {}

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
  late MockSessionSharedDataService sharedDataService;
  late TestStreamController<InitialSyncProgress> progressController;

  InitialSyncGateBloc buildBloc() {
    return InitialSyncGateBloc(
      coordinator: coordinator,
      initialSyncService: initialSyncService,
      sharedDataService: sharedDataService,
    );
  }

  setUp(() {
    coordinator = MockAuthenticatedAppServicesCoordinator();
    initialSyncService = MockInitialSyncService();
    sharedDataService = MockSessionSharedDataService();
    progressController = TestStreamController.seeded(_progress());

    when(() => coordinator.start()).thenAnswer((_) async {});
    when(() => initialSyncService.progress).thenAnswer(
      (_) => progressController.stream,
    );
    when(() => sharedDataService.watchAllTaskCount()).thenAnswer(
      (_) => Stream.value(0),
    );
    when(() => sharedDataService.watchValues()).thenAnswer(
      (_) => Stream.value(const []),
    );

    addTearDown(progressController.close);
  });

  blocTestSafe<InitialSyncGateBloc, InitialSyncGateState>(
    'emits ready immediately when local data exists',
    build: () {
      when(() => sharedDataService.watchAllTaskCount()).thenAnswer(
        (_) => Stream.value(2),
      );
      return buildBloc();
    },
    act: (bloc) => bloc.add(const InitialSyncGateStarted()),
    expect: () => [
      isA<InitialSyncGateReady>(),
    ],
  );

  blocTestSafe<InitialSyncGateBloc, InitialSyncGateState>(
    'emits in progress then ready when sync completes',
    build: buildBloc,
    act: (bloc) async {
      bloc.add(const InitialSyncGateStarted());
      progressController.emit(_progress(hasSynced: false));
      progressController.emit(_progress(hasSynced: true));
    },
    expect: () => [
      isA<InitialSyncGateInProgress>(),
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
      isA<InitialSyncGateFailure>(),
      isA<InitialSyncGateReady>(),
    ],
  );
}
