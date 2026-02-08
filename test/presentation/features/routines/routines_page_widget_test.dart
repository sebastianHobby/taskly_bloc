@Tags(['widget', 'routines'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';

import '../../../helpers/test_imports.dart';
import '../../../mocks/presentation_mocks.dart';
import '../../../mocks/fake_repositories.dart';
import '../../../mocks/repository_mocks.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/features/guided_tour/bloc/guided_tour_bloc.dart';
import 'package:taskly_bloc/presentation/features/routines/view/routines_page.dart';
import 'package:taskly_bloc/presentation/shared/services/streams/session_stream_cache.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/services/time/session_day_key_service.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_data_provider.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_mode_service.dart';
import 'package:taskly_bloc/presentation/shared/session/session_shared_data_service.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/settings.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/preferences.dart';

class MockRoutineRepository extends Mock implements RoutineRepositoryContract {}

class MockAppLifecycleEvents extends Mock implements AppLifecycleEvents {}

class FakeNowService implements NowService {
  FakeNowService(this.now);

  final DateTime now;

  @override
  DateTime nowLocal() => now;

  @override
  DateTime nowUtc() => now.toUtc();
}

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
  });
  setUp(setUpTestEnvironment);

  late MockRoutineRepository routineRepository;
  late SessionDayKeyService sessionDayKeyService;
  late AppErrorReporter errorReporter;
  late SessionSharedDataService sharedDataService;
  late RoutineWriteService routineWriteService;
  late SessionStreamCacheManager cacheManager;
  late DemoModeService demoModeService;
  late DemoDataProvider demoDataProvider;
  late GuidedTourBloc guidedTourBloc;
  late FakeSettingsRepository settingsRepository;
  late MockAppLifecycleEvents appLifecycleEvents;
  late MockHomeDayKeyService dayKeyService;
  late MockTemporalTriggerService temporalTriggerService;
  late MockValueRepositoryContract valueRepository;
  late MockProjectRepositoryContract projectRepository;
  late MockTaskRepositoryContract taskRepository;

  late TestStreamController<TemporalTriggerEvent> temporalController;
  late BehaviorSubject<List<Routine>> routinesSubject;
  late BehaviorSubject<List<RoutineCompletion>> completionsSubject;
  late BehaviorSubject<List<RoutineSkip>> skipsSubject;
  late BehaviorSubject<List<Value>> valuesSubject;
  const speedDialInitDelay = Duration(milliseconds: 1);

  setUp(() {
    routineRepository = MockRoutineRepository();
    appLifecycleEvents = MockAppLifecycleEvents();
    dayKeyService = MockHomeDayKeyService();
    temporalTriggerService = MockTemporalTriggerService();
    valueRepository = MockValueRepositoryContract();
    projectRepository = MockProjectRepositoryContract();
    taskRepository = MockTaskRepositoryContract();
    demoModeService = DemoModeService();
    demoDataProvider = DemoDataProvider();
    settingsRepository = FakeSettingsRepository();
    cacheManager = SessionStreamCacheManager(
      appLifecycleService: appLifecycleEvents,
    );
    sessionDayKeyService = SessionDayKeyService(
      dayKeyService: dayKeyService,
      temporalTriggerService: temporalTriggerService,
    );
    routineWriteService = RoutineWriteService(
      routineRepository: routineRepository,
    );
    errorReporter = AppErrorReporter(
      messengerKey: GlobalKey<ScaffoldMessengerState>(),
    );
    guidedTourBloc = GuidedTourBloc(
      settingsRepository: settingsRepository,
      demoModeService: demoModeService,
    );

    temporalController = TestStreamController.seeded(const AppResumed());
    routinesSubject = BehaviorSubject<List<Routine>>.seeded(const <Routine>[]);
    completionsSubject = BehaviorSubject<List<RoutineCompletion>>.seeded(
      const <RoutineCompletion>[],
    );
    skipsSubject = BehaviorSubject<List<RoutineSkip>>.seeded(
      const <RoutineSkip>[],
    );
    valuesSubject = BehaviorSubject<List<Value>>.seeded(const <Value>[]);

    when(() => appLifecycleEvents.events).thenAnswer(
      (_) => const Stream<AppLifecycleEvent>.empty(),
    );
    when(() => temporalTriggerService.events).thenAnswer(
      (_) => temporalController.stream,
    );
    when(
      () => dayKeyService.todayDayKeyUtc(),
    ).thenReturn(DateTime.utc(2025, 1, 15));

    when(
      () => routineRepository.watchAll(includeInactive: true),
    ).thenAnswer((_) => routinesSubject.stream);
    when(
      () => routineRepository.watchCompletions(),
    ).thenAnswer((_) => completionsSubject.stream);
    when(
      () => routineRepository.watchSkips(),
    ).thenAnswer((_) => skipsSubject.stream);

    when(
      () => valueRepository.watchAll(),
    ).thenAnswer((_) => valuesSubject.stream);
    when(() => valueRepository.getAll()).thenAnswer(
      (_) async => valuesSubject.valueOrNull ?? const <Value>[],
    );
    sharedDataService = SessionSharedDataService(
      cacheManager: cacheManager,
      valueRepository: valueRepository,
      projectRepository: projectRepository,
      taskRepository: taskRepository,
      demoModeService: demoModeService,
      demoDataProvider: demoDataProvider,
    );
    sessionDayKeyService.start();
  });

  tearDown(() async {
    await temporalController.close();
    await routinesSubject.close();
    await completionsSubject.close();
    await skipsSubject.close();
    await valuesSubject.close();
    await sessionDayKeyService.dispose();
    await cacheManager.dispose();
    await guidedTourBloc.close();
    await demoModeService.dispose();
  });

  Routine buildRoutine({
    required String id,
    required String name,
    required Value value,
  }) {
    return Routine(
      id: id,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
      name: name,
      valueId: value.id,
      routineType: RoutineType.weeklyFixed,
      targetCount: 1,
      scheduleDays: const [1],
      value: value,
    );
  }

  Future<void> pumpPage(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/routines',
      routes: [
        GoRoute(
          path: '/routines',
          builder: (_, __) => MultiRepositoryProvider(
            providers: [
              RepositoryProvider<RoutineRepositoryContract>.value(
                value: routineRepository,
              ),
              RepositoryProvider<SessionDayKeyService>.value(
                value: sessionDayKeyService,
              ),
              RepositoryProvider<AppErrorReporter>.value(value: errorReporter),
              RepositoryProvider<SessionSharedDataService>.value(
                value: sharedDataService,
              ),
              RepositoryProvider<RoutineWriteService>.value(
                value: routineWriteService,
              ),
              RepositoryProvider<NowService>.value(
                value: FakeNowService(DateTime(2025, 1, 15, 9)),
              ),
              RepositoryProvider<DemoModeService>.value(
                value: demoModeService,
              ),
              RepositoryProvider<SettingsRepositoryContract>.value(
                value: settingsRepository,
              ),
            ],
            child: MultiBlocProvider(
              providers: [
                BlocProvider<GuidedTourBloc>.value(value: guidedTourBloc),
              ],
              child: const RoutinesPage(),
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidgetWithRouter(router: router);
    await tester.pump(speedDialInitDelay);
  }

  testWidgetsSafe('shows loading state while routines load', (tester) async {
    final completer = Completer<List<Routine>>();
    when(
      () => routineRepository.getAll(includeInactive: true),
    ).thenAnswer((_) => completer.future);
    when(
      () => routineRepository.getCompletions(),
    ).thenAnswer((_) async => const <RoutineCompletion>[]);
    when(
      () => routineRepository.getSkips(),
    ).thenAnswer((_) async => const <RoutineSkip>[]);

    await pumpPage(tester);

    expect(find.byKey(const ValueKey('feed-loading')), findsOneWidget);

    completer.complete(const <Routine>[]);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgetsSafe('shows error state when repository throws', (tester) async {
    when(
      () => routineRepository.getAll(includeInactive: true),
    ).thenThrow(Exception('routine load failed'));
    when(
      () => routineRepository.getCompletions(),
    ).thenAnswer((_) async => const <RoutineCompletion>[]);
    when(
      () => routineRepository.getSkips(),
    ).thenAnswer((_) async => const <RoutineSkip>[]);

    await pumpPage(tester);
    await tester.pumpForStream();

    expect(
      find.text('Something went wrong. Please try again.'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgetsSafe('renders routine list content when loaded', (tester) async {
    final value = TestData.value(name: 'Health');
    final routine = buildRoutine(
      id: 'routine-1',
      name: 'Morning Walk',
      value: value,
    );

    when(
      () => routineRepository.getAll(includeInactive: true),
    ).thenAnswer((_) async => [routine]);
    when(
      () => routineRepository.getCompletions(),
    ).thenAnswer((_) async => const <RoutineCompletion>[]);
    when(
      () => routineRepository.getSkips(),
    ).thenAnswer((_) async => const <RoutineSkip>[]);

    await pumpPage(tester);
    routinesSubject.add([routine]);
    valuesSubject.add([value]);
    await tester.pumpForStream();

    expect(find.text('Morning Walk'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgetsSafe(
    'shows log today by default and swaps to selection in multi-select mode',
    (tester) async {
      final value = TestData.value(name: 'Health');
      final routine = buildRoutine(
        id: 'routine-1',
        name: 'Morning Walk',
        value: value,
      );

      when(
        () => routineRepository.getAll(includeInactive: true),
      ).thenAnswer((_) async => [routine]);
      when(
        () => routineRepository.getCompletions(),
      ).thenAnswer((_) async => const <RoutineCompletion>[]);
      when(
        () => routineRepository.getSkips(),
      ).thenAnswer((_) async => const <RoutineSkip>[]);

      await pumpPage(tester);
      routinesSubject.add([routine]);
      valuesSubject.add([value]);
      await tester.pumpForStream();

      expect(find.text('Log today'), findsOneWidget);
      expect(find.byTooltip('Select'), findsNothing);
      expect(find.byTooltip('Deselect'), findsNothing);

      await tester.longPress(find.text('Morning Walk'));
      await tester.pump();

      expect(find.text('Log today'), findsNothing);
      expect(find.byTooltip('Deselect'), findsOneWidget);
    },
  );

  testWidgetsSafe('updates list when routines change', (tester) async {
    final value = TestData.value(name: 'Focus');
    final routineA = buildRoutine(
      id: 'routine-a',
      name: 'Stretch',
      value: value,
    );
    final routineB = buildRoutine(id: 'routine-b', name: 'Read', value: value);

    when(
      () => routineRepository.getAll(includeInactive: true),
    ).thenAnswer((_) async => [routineA]);
    when(
      () => routineRepository.getCompletions(),
    ).thenAnswer((_) async => const <RoutineCompletion>[]);
    when(
      () => routineRepository.getSkips(),
    ).thenAnswer((_) async => const <RoutineSkip>[]);

    await pumpPage(tester);
    routinesSubject.add([routineA]);
    valuesSubject.add([value]);
    await tester.pumpForStream();

    expect(find.text('Stretch'), findsOneWidget);

    routinesSubject.add([routineA, routineB]);
    await tester.pumpForStream();

    expect(find.text('Read'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
  });
}
