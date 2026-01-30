@Tags(['widget', 'app'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_imports.dart';
import '../../../mocks/repository_mocks.dart';
import 'package:taskly_bloc/core/startup/authenticated_app_services_coordinator.dart';
import 'package:taskly_bloc/presentation/features/app/bloc/initial_sync_gate_bloc.dart';
import 'package:taskly_bloc/presentation/features/app/view/initial_sync_gate_screen.dart';
import 'package:taskly_bloc/presentation/shared/services/streams/session_stream_cache.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_data_provider.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_mode_service.dart';
import 'package:taskly_bloc/presentation/shared/session/session_shared_data_service.dart';
import 'package:taskly_bloc/presentation/shared/widgets/app_loading_screen.dart';
import 'package:taskly_domain/services.dart';

class MockAuthenticatedAppServicesCoordinator extends Mock
    implements AuthenticatedAppServicesCoordinator {}

class MockInitialSyncService extends Mock implements InitialSyncService {}

class FakeAppLifecycleEvents implements AppLifecycleEvents {
  final _controller = StreamController<AppLifecycleEvent>.broadcast();

  @override
  Stream<AppLifecycleEvent> get events => _controller.stream;

  Future<void> dispose() async {
    await _controller.close();
  }
}

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
  });
  setUp(setUpTestEnvironment);

  late MockAuthenticatedAppServicesCoordinator coordinator;
  late MockInitialSyncService initialSyncService;
  late SessionSharedDataService sharedDataService;
  late DemoModeService demoModeService;
  late DemoDataProvider demoDataProvider;
  late SessionStreamCacheManager cacheManager;
  late FakeAppLifecycleEvents lifecycleEvents;
  late MockValueRepositoryContract valueRepository;
  late MockProjectRepositoryContract projectRepository;
  late MockTaskRepositoryContract taskRepository;

  setUp(() {
    coordinator = MockAuthenticatedAppServicesCoordinator();
    initialSyncService = MockInitialSyncService();
    valueRepository = MockValueRepositoryContract();
    projectRepository = MockProjectRepositoryContract();
    taskRepository = MockTaskRepositoryContract();
    lifecycleEvents = FakeAppLifecycleEvents();
    cacheManager = SessionStreamCacheManager(
      appLifecycleService: lifecycleEvents,
    );
    demoModeService = DemoModeService();
    demoDataProvider = DemoDataProvider();
    sharedDataService = SessionSharedDataService(
      cacheManager: cacheManager,
      valueRepository: valueRepository,
      projectRepository: projectRepository,
      taskRepository: taskRepository,
      demoModeService: demoModeService,
      demoDataProvider: demoDataProvider,
    );

    addTearDown(cacheManager.dispose);
    addTearDown(demoModeService.dispose);
    addTearDown(lifecycleEvents.dispose);
  });

  Future<InitialSyncGateBloc> pumpScreen(WidgetTester tester) async {
    final bloc = InitialSyncGateBloc(
      coordinator: coordinator,
      initialSyncService: initialSyncService,
      sharedDataService: sharedDataService,
    );
    await tester.pumpWidgetWithBloc<InitialSyncGateBloc>(
      bloc: bloc,
      child: const InitialSyncGateScreen(),
    );
    return bloc;
  }

  testWidgetsSafe('shows loading screen during sync', (tester) async {
    final bloc = await pumpScreen(tester);
    addTearDown(bloc.close);

    expect(find.byType(AppLoadingScreen), findsOneWidget);
    expect(find.text('Syncing your data'), findsOneWidget);
  });

  testWidgetsSafe('shows error state with retry button', (tester) async {
    when(() => coordinator.start()).thenThrow(StateError('Failed'));
    final bloc = await pumpScreen(tester);
    addTearDown(bloc.close);

    bloc.add(const InitialSyncGateStarted());
    await tester.pumpForStream();

    expect(find.textContaining('Failed to start sync session'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });
}
