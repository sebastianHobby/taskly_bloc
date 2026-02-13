@Tags(['widget', 'projects'])
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';

import '../../../helpers/test_imports.dart';
import '../../../mocks/fake_repositories.dart';
import '../../../mocks/feature_mocks.dart';
import '../../../mocks/repository_mocks.dart';
import 'package:taskly_bloc/presentation/features/projects/services/projects_session_query_service.dart';
import 'package:taskly_bloc/presentation/features/projects/view/projects_page.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/shared/services/streams/session_stream_cache.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_data_provider.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_mode_service.dart';
import 'package:taskly_bloc/presentation/shared/session/session_shared_data_service.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/taskly_domain.dart';

class MockEditorLauncher extends Mock implements EditorLauncher {}

class FakeAppLifecycleEvents implements AppLifecycleEvents {
  final _controller = BehaviorSubject<AppLifecycleEvent>.seeded(
    AppLifecycleEvent.resumed,
  );

  @override
  Stream<AppLifecycleEvent> get events => _controller.stream;

  Future<void> dispose() async {
    await _controller.close();
  }
}

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

  late MockProjectRepositoryContract projectRepository;
  late MockTaskRepositoryContract taskRepository;
  late MockValueRepositoryContract valueRepository;
  late MockValueRatingsRepositoryContract valueRatingsRepository;
  late FakeAppLifecycleEvents lifecycleEvents;
  late SessionStreamCacheManager cacheManager;
  late DemoModeService demoModeService;
  late DemoDataProvider demoDataProvider;
  late SessionSharedDataService sharedDataService;
  late ProjectsSessionQueryService queryService;
  late MockEditorLauncher editorLauncher;
  late BehaviorSubject<List<Project>> projectsSubject;
  late BehaviorSubject<int> inboxCountSubject;
  late BehaviorSubject<List<Value>> valuesSubject;
  late BehaviorSubject<List<ValueWeeklyRating>> ratingsSubject;
  const speedDialInitDelay = Duration(milliseconds: 1);

  setUp(() {
    projectRepository = MockProjectRepositoryContract();
    taskRepository = MockTaskRepositoryContract();
    valueRepository = MockValueRepositoryContract();
    valueRatingsRepository = MockValueRatingsRepositoryContract();
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
    queryService = ProjectsSessionQueryService(
      projectRepository: projectRepository,
      valueRatingsRepository: valueRatingsRepository,
      cacheManager: cacheManager,
      sharedDataService: sharedDataService,
      demoModeService: demoModeService,
      demoDataProvider: demoDataProvider,
    );
    editorLauncher = MockEditorLauncher();
    projectsSubject = BehaviorSubject<List<Project>>.seeded(
      const <Project>[],
    );
    inboxCountSubject = BehaviorSubject<int>.seeded(0);
    valuesSubject = BehaviorSubject<List<Value>>.seeded(const <Value>[]);
    ratingsSubject = BehaviorSubject<List<ValueWeeklyRating>>.seeded(
      const <ValueWeeklyRating>[],
    );

    when(() => projectRepository.watchAll()).thenAnswer(
      (_) => projectsSubject,
    );
    when(() => projectRepository.watchAll(any())).thenAnswer(
      (_) => projectsSubject,
    );
    when(() => projectRepository.getAll()).thenAnswer(
      (_) async => const <Project>[],
    );
    when(() => projectRepository.getAll(any())).thenAnswer(
      (_) async => const <Project>[],
    );
    when(
      () => taskRepository.watchAllCount(any()),
    ).thenAnswer((_) => inboxCountSubject);
    when(() => valueRepository.watchAll()).thenAnswer((_) => valuesSubject);
    when(() => valueRepository.watchAll(any())).thenAnswer(
      (_) => valuesSubject,
    );
    when(() => valueRepository.getAll()).thenAnswer(
      (_) async => const <Value>[],
    );
    when(
      () => valueRatingsRepository.watchAll(weeks: any(named: 'weeks')),
    ).thenAnswer((_) => ratingsSubject);
  });

  tearDown(() async {
    await projectsSubject.close();
    await inboxCountSubject.close();
    await valuesSubject.close();
    await ratingsSubject.close();
    await cacheManager.dispose();
    await demoModeService.dispose();
    await lifecycleEvents.dispose();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/projects',
      routes: [
        GoRoute(
          path: '/projects',
          builder: (_, __) => MultiRepositoryProvider(
            providers: [
              RepositoryProvider<ProjectsSessionQueryService>.value(
                value: queryService,
              ),
              RepositoryProvider<EditorLauncher>.value(value: editorLauncher),
              RepositoryProvider<NowService>.value(
                value: FakeNowService(DateTime(2025, 1, 15, 9)),
              ),
              RepositoryProvider<SettingsRepositoryContract>.value(
                value: FakeSettingsRepository(),
              ),
            ],
            child: const ProjectsPage(),
          ),
        ),
      ],
    );

    await tester.pumpWidgetWithRouter(router: router);
    await tester.pump(speedDialInitDelay);
  }

  testWidgetsSafe('shows inbox row when no projects are available', (
    tester,
  ) async {
    await pumpPage(tester);
    projectsSubject.add(const <Project>[]);
    inboxCountSubject.add(0);
    valuesSubject.add(const <Value>[]);
    final foundInbox = await tester.pumpUntilFound(find.text('Inbox'));
    expect(foundInbox, isTrue);

    expect(find.text('Inbox'), findsOneWidget);
  });

  testWidgetsSafe('shows error state when feed stream errors', (tester) async {
    await pumpPage(tester);

    inboxCountSubject.add(0);
    valuesSubject.add(const <Value>[]);
    projectsSubject.addError(Exception('boom'));
    await tester.pumpForStream();

    expect(find.textContaining('boom'), findsOneWidget);
  });

  testWidgetsSafe('renders project content when loaded', (tester) async {
    await pumpPage(tester);

    final value = TestData.value(id: 'value-1', name: 'Health');
    final project = TestData.project(name: 'Project Alpha').copyWith(
      values: [value],
      primaryValueId: value.id,
    );
    projectsSubject.add([project]);
    inboxCountSubject.add(0);
    valuesSubject.add([value]);
    await tester.pumpForStream();

    expect(find.text('Project Alpha'), findsOneWidget);
  });

  testWidgetsSafe('updates list when feed emits new data', (tester) async {
    await pumpPage(tester);

    final value = TestData.value(id: 'value-1', name: 'Health');
    final projectA = TestData.project(name: 'Project A').copyWith(
      values: [value],
      primaryValueId: value.id,
    );
    projectsSubject.add([projectA]);
    inboxCountSubject.add(0);
    valuesSubject.add([value]);
    await tester.pumpForStream();
    expect(find.text('Project A'), findsOneWidget);

    final projectB = TestData.project(name: 'Project B').copyWith(
      values: [value],
      primaryValueId: value.id,
    );
    projectsSubject.add([projectA, projectB]);
    await tester.pumpForStream();

    expect(find.text('Project B'), findsOneWidget);
  });
}
