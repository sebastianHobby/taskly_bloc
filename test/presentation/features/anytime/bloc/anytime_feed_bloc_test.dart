@Tags(['unit', 'anytime'])
library;

import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../helpers/test_imports.dart';
import 'package:taskly_bloc/presentation/features/anytime/bloc/anytime_feed_bloc.dart';
import 'package:taskly_bloc/presentation/features/anytime/services/anytime_session_query_service.dart';
import 'package:taskly_bloc/presentation/shared/services/streams/session_stream_cache.dart';
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
  late AnytimeSessionQueryService queryService;
  late PublishSubject<List<Project>> projects;
  late PublishSubject<int> inboxCounts;
  late PublishSubject<List<Value>> values;

  setUp(() {
    projectRepository = MockProjectRepositoryContract();
    taskRepository = MockTaskRepositoryContract();
    valueRepository = MockValueRepositoryContract();
    lifecycleEvents = FakeAppLifecycleEvents();
    cacheManager = SessionStreamCacheManager(appLifecycleService: lifecycleEvents);
    sharedDataService = SessionSharedDataService(
      cacheManager: cacheManager,
      valueRepository: valueRepository,
      projectRepository: projectRepository,
      taskRepository: taskRepository,
    );
    queryService = AnytimeSessionQueryService(
      projectRepository: projectRepository,
      cacheManager: cacheManager,
      sharedDataService: sharedDataService,
    );

    projects = PublishSubject<List<Project>>();
    inboxCounts = PublishSubject<int>();
    values = PublishSubject<List<Value>>();

    when(() => projectRepository.watchAll(any())).thenAnswer((_) => projects);
    when(() => taskRepository.watchAllCount(any())).thenAnswer((_) => inboxCounts);
    when(() => valueRepository.watchAll(any())).thenAnswer((_) => values);
  });

  tearDown(() async {
    await projects.close();
    await inboxCounts.close();
    await values.close();
    await cacheManager.dispose();
    await lifecycleEvents.dispose();
  });

  blocTestSafe<AnytimeFeedBloc, AnytimeFeedState>(
    'emits loaded state when snapshot arrives',
    build: () => AnytimeFeedBloc(queryService: queryService),
    act: (_) {
      projects.add([TestData.project(name: 'Inbox')]);
      inboxCounts.add(3);
      values.add(const <Value>[]);
    },
    expect: () => [
      isA<AnytimeFeedLoaded>()
          .having((s) => s.rows.length, 'rows.length', 2)
          .having((s) => s.inboxTaskCount, 'inboxTaskCount', 3),
    ],
  );

  blocTestSafe<AnytimeFeedBloc, AnytimeFeedState>(
    'filters rows when search query changes',
    build: () => AnytimeFeedBloc(queryService: queryService),
    act: (bloc) async {
      projects.add([
        TestData.project(name: 'Alpha Project'),
        TestData.project(name: 'Beta'),
      ]);
      inboxCounts.add(0);
      values.add(const <Value>[]);
      await Future<void>.delayed(TestConstants.defaultWait);
      bloc.add(const AnytimeFeedSearchQueryChanged(query: 'beta'));
    },
    expect: () => [
      isA<AnytimeFeedLoaded>().having((s) => s.rows.length, 'rows.length', 2),
      isA<AnytimeFeedLoaded>().having((s) => s.rows.length, 'rows.length', 1),
    ],
  );

  blocTestSafe<AnytimeFeedBloc, AnytimeFeedState>(
    'emits error when the query stream fails',
    build: () => AnytimeFeedBloc(queryService: queryService),
    act: (_) {
      projects.addError(StateError('boom'));
    },
    expect: () => [
      isA<AnytimeFeedError>().having(
        (s) => s.message,
        'message',
        contains('boom'),
      ),
    ],
  );
}
