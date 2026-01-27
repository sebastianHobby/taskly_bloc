@Tags(['unit', 'anytime'])
library;

import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';

import '../../../../helpers/test_imports.dart';
import 'package:taskly_bloc/presentation/features/anytime/bloc/anytime_feed_bloc.dart';
import 'package:taskly_bloc/presentation/features/anytime/services/anytime_session_query_service.dart';
import 'package:taskly_domain/core.dart';

class MockAnytimeSessionQueryService extends Mock
    implements AnytimeSessionQueryService {}

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  late MockAnytimeSessionQueryService queryService;
  late BehaviorSubject<AnytimeProjectsSnapshot> snapshots;

  setUp(() {
    queryService = MockAnytimeSessionQueryService();
    snapshots = BehaviorSubject<AnytimeProjectsSnapshot>();
    when(
      () => queryService.watchProjects(scope: null),
    ).thenAnswer((_) => snapshots);
  });

  tearDown(() async {
    await snapshots.close();
  });

  blocTestSafe<AnytimeFeedBloc, AnytimeFeedState>(
    'emits loaded state when snapshot arrives',
    build: () => AnytimeFeedBloc(queryService: queryService),
    act: (_) {
      snapshots.add(
        AnytimeProjectsSnapshot(
          projects: [TestData.project(name: 'Inbox')],
          inboxTaskCount: 3,
          values: const <Value>[],
        ),
      );
    },
    expect: () => [
      isA<AnytimeFeedLoaded>()
          .having((s) => s.rows.length, 'rows.length', 1)
          .having((s) => s.inboxTaskCount, 'inboxTaskCount', 3),
    ],
  );

  blocTestSafe<AnytimeFeedBloc, AnytimeFeedState>(
    'filters rows when search query changes',
    build: () => AnytimeFeedBloc(queryService: queryService),
    act: (bloc) async {
      snapshots.add(
        AnytimeProjectsSnapshot(
          projects: [
            TestData.project(name: 'Alpha Project'),
            TestData.project(name: 'Beta'),
          ],
          inboxTaskCount: 0,
          values: const <Value>[],
        ),
      );
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
      snapshots.addError(StateError('boom'));
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
