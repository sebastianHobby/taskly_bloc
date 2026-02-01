@Tags(['unit', 'projects'])
library;

import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../helpers/test_imports.dart';
import 'package:taskly_bloc/presentation/features/projects/bloc/projects_feed_bloc.dart';
import 'package:taskly_bloc/presentation/features/projects/services/projects_session_query_service.dart';
import 'package:taskly_bloc/presentation/features/scope_context/model/projects_scope.dart';
import 'package:taskly_bloc/presentation/shared/services/streams/session_stream_cache.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_data_provider.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_mode_service.dart';
import 'package:taskly_bloc/presentation/shared/session/session_shared_data_service.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/taskly_domain.dart';

import '../../../../mocks/repository_mocks.dart';

class FakeAppLifecycleEvents implements AppLifecycleEvents {
  final _controller = BehaviorSubject<AppLifecycleEvent>();

  @override
  Stream<AppLifecycleEvent> get events => _controller.stream;

  Future<void> dispose() async {
    await _controller.close();
  }
}

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  late MockProjectRepositoryContract projectRepository;
  late MockTaskRepositoryContract taskRepository;
  late MockValueRepositoryContract valueRepository;
  late FakeAppLifecycleEvents lifecycleEvents;
  late SessionStreamCacheManager cacheManager;
  late SessionSharedDataService sharedDataService;
  late DemoModeService demoModeService;
  late DemoDataProvider demoDataProvider;
  late ProjectsSessionQueryService queryService;
  late PublishSubject<List<Project>> projects;
  late PublishSubject<int> inboxCounts;
  late PublishSubject<List<Value>> values;

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
    queryService = ProjectsSessionQueryService(
      projectRepository: projectRepository,
      cacheManager: cacheManager,
      sharedDataService: sharedDataService,
      demoModeService: demoModeService,
      demoDataProvider: demoDataProvider,
    );

    projects = PublishSubject<List<Project>>();
    inboxCounts = PublishSubject<int>();
    values = PublishSubject<List<Value>>();

    when(() => projectRepository.watchAll()).thenAnswer((_) => projects);
    when(() => projectRepository.watchAll(any())).thenAnswer((_) => projects);
    when(() => projectRepository.getAll()).thenAnswer(
      (_) async => const <Project>[],
    );
    when(() => projectRepository.getAll(any())).thenAnswer(
      (_) async => const <Project>[],
    );
    when(
      () => taskRepository.watchAllCount(any()),
    ).thenAnswer((_) => inboxCounts);
    when(() => valueRepository.watchAll()).thenAnswer((_) => values);
    when(() => valueRepository.watchAll(any())).thenAnswer((_) => values);
    when(() => valueRepository.getAll()).thenAnswer(
      (_) async => const <Value>[],
    );
  });

  tearDown(() async {
    await projects.close();
    await inboxCounts.close();
    await values.close();
    await cacheManager.dispose();
    await demoModeService.dispose();
    await lifecycleEvents.dispose();
  });

  blocTestSafe<ProjectsFeedBloc, ProjectsFeedState>(
    'emits loaded state when snapshot arrives',
    build: () => ProjectsFeedBloc(queryService: queryService),
    act: (_) {
      projects.add([TestData.project(name: 'Inbox')]);
      inboxCounts.add(3);
      values.add(const <Value>[]);
    },
    skip: 1,
    expect: () => [
      isA<ProjectsFeedLoaded>()
          .having((s) => s.rows.length, 'rows.length', 1)
          .having((s) => s.inboxTaskCount, 'inboxTaskCount', 0),
      isA<ProjectsFeedLoaded>()
          .having((s) => s.rows.length, 'rows.length', 1)
          .having((s) => s.inboxTaskCount, 'inboxTaskCount', 3),
      isA<ProjectsFeedLoaded>()
          .having((s) => s.rows.length, 'rows.length', 1)
          .having((s) => s.inboxTaskCount, 'inboxTaskCount', 3),
    ],
  );

  blocTestSafe<ProjectsFeedBloc, ProjectsFeedState>(
    'filters rows when search query changes',
    build: () => ProjectsFeedBloc(queryService: queryService),
    act: (bloc) async {
      projects.add([
        TestData.project(name: 'Alpha Project'),
        TestData.project(name: 'Beta'),
      ]);
      inboxCounts.add(0);
      values.add(const <Value>[]);
      await Future<void>.delayed(TestConstants.defaultWait);
      bloc.add(const ProjectsFeedSearchQueryChanged(query: 'beta'));
    },
    skip: 1,
    expect: () => [
      isA<ProjectsFeedLoaded>().having((s) => s.rows.length, 'rows.length', 2),
      isA<ProjectsFeedLoaded>().having((s) => s.rows.length, 'rows.length', 2),
      isA<ProjectsFeedLoaded>().having((s) => s.rows.length, 'rows.length', 2),
      isA<ProjectsFeedLoaded>().having((s) => s.rows.length, 'rows.length', 1),
    ],
  );

  blocTestSafe<ProjectsFeedBloc, ProjectsFeedState>(
    'emits error when the query stream fails',
    build: () => ProjectsFeedBloc(queryService: queryService),
    act: (_) {
      inboxCounts.add(0);
      values.add(const <Value>[]);
      projects.addError(StateError('boom'));
    },
    skip: 1,
    expect: () => [
      isA<ProjectsFeedLoaded>(),
      isA<ProjectsFeedLoaded>(),
      isA<ProjectsFeedError>().having(
        (s) => s.message,
        'message',
        contains('boom'),
      ),
    ],
  );

  blocTestSafe<ProjectsFeedBloc, ProjectsFeedState>(
    'repro: global scope should render projects before inbox count emits',
    build: () => ProjectsFeedBloc(queryService: queryService),
    act: (_) {
      final value = TestData.value(id: 'value-1', name: 'Purpose');
      final project = Project(
        id: 'project-1',
        createdAt: TestConstants.referenceDate,
        updatedAt: TestConstants.referenceDate,
        name: 'First Project',
        completed: false,
        values: [value],
        primaryValueId: value.id,
      );

      projects.add([project]);
      values.add([value]);
    },
    skip: 1,
    expect: () => [
      isA<ProjectsFeedLoaded>().having((s) => s.rows.length, 'rows.length', 1),
      isA<ProjectsFeedLoaded>().having((s) => s.rows.length, 'rows.length', 1),
    ],
  );

  blocTestSafe<ProjectsFeedBloc, ProjectsFeedState>(
    'value scope still renders project without inbox count',
    build: () => ProjectsFeedBloc(
      queryService: queryService,
      scope: const ProjectsValueScope(valueId: 'value-1'),
    ),
    act: (_) {
      final value = TestData.value(id: 'value-1', name: 'Purpose');
      final project = Project(
        id: 'project-1',
        createdAt: TestConstants.referenceDate,
        updatedAt: TestConstants.referenceDate,
        name: 'First Project',
        completed: false,
        values: [value],
        primaryValueId: value.id,
      );

      projects.add([project]);
      values.add([value]);
    },
    skip: 1,
    expect: () => [
      isA<ProjectsFeedLoaded>().having((s) => s.rows.length, 'rows.length', 1),
    ],
  );

  blocTestSafe<ProjectsFeedBloc, ProjectsFeedState>(
    'repro: inbox count present should not block new projects',
    build: () => ProjectsFeedBloc(queryService: queryService),
    act: (_) async {
      final value = TestData.value(id: 'value-1', name: 'Purpose');
      final project = Project(
        id: 'project-1',
        createdAt: TestConstants.referenceDate,
        updatedAt: TestConstants.referenceDate,
        name: 'Second Project',
        completed: false,
        values: [value],
        primaryValueId: value.id,
      );

      values.add([value]);
      await Future<void>.delayed(TestConstants.defaultWait);
      inboxCounts.add(1);
      projects.add([project]);
    },
    skip: 1,
    expect: () => [
      isA<ProjectsFeedLoaded>().having((s) => s.rows.length, 'rows.length', 0),
      isA<ProjectsFeedLoaded>().having((s) => s.rows.length, 'rows.length', 0),
      isA<ProjectsFeedLoaded>().having((s) => s.rows.length, 'rows.length', 1),
    ],
  );
}
