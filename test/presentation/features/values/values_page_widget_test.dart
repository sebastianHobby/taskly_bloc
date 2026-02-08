@Tags(['widget', 'values'])
library;

import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';

import '../../../helpers/test_imports.dart';
import 'package:taskly_bloc/presentation/features/values/view/values_page.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/services/streams/session_stream_cache.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_data_provider.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_mode_service.dart';
import 'package:taskly_bloc/presentation/shared/session/session_shared_data_service.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';

import '../../../mocks/repository_mocks.dart';

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockValueRepository extends Mock implements ValueRepositoryContract {}

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

  late MockAnalyticsService analyticsService;
  late MockValueRepository valueRepository;
  late MockProjectRepositoryContract projectRepository;
  late MockTaskRepositoryContract taskRepository;
  late SessionSharedDataService sharedDataService;
  late SessionStreamCacheManager cacheManager;
  late DemoModeService demoModeService;
  late DemoDataProvider demoDataProvider;
  late MockAppLifecycleEvents appLifecycleEvents;
  late BehaviorSubject<List<Value>> valuesSubject;

  setUp(() {
    analyticsService = MockAnalyticsService();
    valueRepository = MockValueRepository();
    projectRepository = MockProjectRepositoryContract();
    taskRepository = MockTaskRepositoryContract();
    appLifecycleEvents = MockAppLifecycleEvents();
    demoModeService = DemoModeService();
    demoDataProvider = DemoDataProvider();
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
    valuesSubject = BehaviorSubject<List<Value>>.seeded(const <Value>[]);

    when(() => appLifecycleEvents.events).thenAnswer(
      (_) => const Stream<AppLifecycleEvent>.empty(),
    );
    when(
      () => analyticsService.getRecentCompletionsByValue(
        days: any(named: 'days'),
      ),
    ).thenAnswer((_) async => <String, int>{});
    when(
      () => analyticsService.getValueActivityStats(),
    ).thenAnswer((_) async => <String, ValueActivityStats>{});
    when(
      () => valueRepository.watchAll(),
    ).thenAnswer((_) => valuesSubject);
  });

  tearDown(() async {
    await valuesSubject.close();
    await cacheManager.dispose();
    await demoModeService.dispose();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/values',
      routes: [
        GoRoute(
          path: '/values',
          builder: (_, __) => MultiRepositoryProvider(
            providers: [
              RepositoryProvider<AnalyticsService>.value(
                value: analyticsService,
              ),
              RepositoryProvider<ValueRepositoryContract>.value(
                value: valueRepository,
              ),
              RepositoryProvider<SessionSharedDataService>.value(
                value: sharedDataService,
              ),
              RepositoryProvider<NowService>.value(
                value: FakeNowService(DateTime(2025, 1, 15, 9)),
              ),
            ],
            child: const ValuesPage(),
          ),
        ),
      ],
    );

    await tester.pumpWidgetWithRouter(router: router);
  }

  testWidgetsSafe('shows loading state while values load', (tester) async {
    final completer = Completer<List<Value>>();
    when(() => valueRepository.getAll()).thenAnswer((_) => completer.future);

    await pumpPage(tester);

    expect(find.byKey(const ValueKey('feed-loading')), findsOneWidget);

    completer.complete(const <Value>[]);
  });

  testWidgetsSafe('shows error state when repository throws', (tester) async {
    when(() => valueRepository.getAll()).thenThrow(Exception('load failed'));

    await pumpPage(tester);
    await tester.pumpForStream();

    expect(
      find.text('Something went wrong. Please try again.'),
      findsOneWidget,
    );
  });

  testWidgetsSafe('renders values content when loaded', (tester) async {
    final value = TestData.value(name: 'Health');
    when(() => valueRepository.getAll()).thenAnswer((_) async => [value]);

    await pumpPage(tester);
    valuesSubject.add([value]);
    await tester.pumpForStream();

    expect(find.text('Health'), findsOneWidget);
  });

  testWidgetsSafe('updates list when values change', (tester) async {
    final valueA = TestData.value(name: 'Work');
    final valueB = TestData.value(name: 'Family');
    when(() => valueRepository.getAll()).thenAnswer((_) async => [valueA]);

    await tester.runAsync(() async {
      final queue = StreamQueue(sharedDataService.watchValues());
      valuesSubject.add([valueA]);
      final first = await queue.next;
      expect(first.map((value) => value.name), contains('Work'));

      valuesSubject.add([valueA, valueB]);
      final deadline = DateTime.now().add(const Duration(seconds: 2));
      List<Value>? updated;
      while (DateTime.now().isBefore(deadline) && updated == null) {
        final nextValues = await queue.next.timeout(const Duration(seconds: 1));
        if (nextValues.any((value) => value.name == 'Family')) {
          updated = nextValues;
        }
      }
      expect(updated, isNotNull);
      await queue.cancel();
    });
  });

  testWidgetsSafe('opens range selector from overflow menu', (tester) async {
    when(() => valueRepository.getAll()).thenAnswer((_) async => const []);

    await pumpPage(tester);
    await tester.pump();

    await tester.tap(find.byTooltip('More'));
    await tester.pump(const Duration(milliseconds: 300));
    final rangeItem = find.text('Range');
    expect(rangeItem, findsOneWidget);
  });
}
