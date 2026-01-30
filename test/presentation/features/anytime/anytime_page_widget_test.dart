@Tags(['widget', 'anytime'])
library;

import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';

import '../../../helpers/test_imports.dart';
import '../../../mocks/repository_mocks.dart';
import 'package:taskly_bloc/presentation/features/anytime/services/anytime_session_query_service.dart';
import 'package:taskly_bloc/presentation/features/anytime/view/anytime_page.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/shared/services/streams/session_stream_cache.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_data_provider.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_mode_service.dart';
import 'package:taskly_bloc/presentation/shared/session/session_shared_data_service.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/taskly_domain.dart';

class MockEditorLauncher extends Mock implements EditorLauncher {}

class FakeAppLifecycleEvents implements AppLifecycleEvents {
  final _controller = BehaviorSubject<AppLifecycleEvent>();

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

  late MockProjectRepositoryContract projectRepository;
  late MockTaskRepositoryContract taskRepository;
  late MockValueRepositoryContract valueRepository;
  late FakeAppLifecycleEvents lifecycleEvents;
  late SessionStreamCacheManager cacheManager;
  late DemoModeService demoModeService;
  late DemoDataProvider demoDataProvider;
  late SessionSharedDataService sharedDataService;
  late AnytimeSessionQueryService queryService;
  late MockEditorLauncher editorLauncher;
  late BehaviorSubject<List<Project>> projectsSubject;
  late BehaviorSubject<int> inboxCountSubject;
  late BehaviorSubject<List<Value>> valuesSubject;

  setUp(() {
    projectRepository = MockProjectRepositoryContract();
    taskRepository = MockTaskRepositoryContract();
    valueRepository = MockValueRepositoryContract();
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
    queryService = AnytimeSessionQueryService(
      projectRepository: projectRepository,
      cacheManager: cacheManager,
      sharedDataService: sharedDataService,
      demoModeService: demoModeService,
      demoDataProvider: demoDataProvider,
    );
    editorLauncher = MockEditorLauncher();
    projectsSubject = BehaviorSubject<List<Project>>();
    inboxCountSubject = BehaviorSubject<int>();
    valuesSubject = BehaviorSubject<List<Value>>();

    when(() => projectRepository.watchAll(any())).thenAnswer(
      (_) => projectsSubject,
    );
    when(
      () => taskRepository.watchAllCount(any()),
    ).thenAnswer((_) => inboxCountSubject);
    when(() => valueRepository.watchAll(any())).thenAnswer(
      (_) => valuesSubject,
    );
  });

  tearDown(() async {
    await projectsSubject.close();
    await inboxCountSubject.close();
    await valuesSubject.close();
    await cacheManager.dispose();
    await demoModeService.dispose();
    await lifecycleEvents.dispose();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpApp(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AnytimeSessionQueryService>.value(
            value: queryService,
          ),
          RepositoryProvider<EditorLauncher>.value(value: editorLauncher),
        ],
        child: const AnytimePage(),
      ),
    );
  }

  testWidgetsSafe('shows loading state before feed emits', (tester) async {
    await pumpPage(tester);

    expect(find.byKey(const ValueKey('feed-loading')), findsOneWidget);
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

    final project = TestData.project(name: 'Project Alpha');
    projectsSubject.add([project]);
    inboxCountSubject.add(0);
    valuesSubject.add(const <Value>[]);
    await tester.pumpForStream();

    expect(find.text('Project Alpha'), findsOneWidget);
  });

  testWidgetsSafe('updates list when feed emits new data', (tester) async {
    await pumpPage(tester);

    final projectA = TestData.project(name: 'Project A');
    projectsSubject.add([projectA]);
    inboxCountSubject.add(0);
    valuesSubject.add(const <Value>[]);
    await tester.pumpForStream();
    expect(find.text('Project A'), findsOneWidget);

    final projectB = TestData.project(name: 'Project B');
    projectsSubject.add([projectA, projectB]);
    await tester.pumpForStream();

    expect(find.text('Project B'), findsOneWidget);
  });
}
