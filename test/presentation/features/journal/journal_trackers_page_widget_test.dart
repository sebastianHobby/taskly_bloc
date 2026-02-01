@Tags(['widget', 'journal'])
library;

import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_trackers_page.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/journal.dart';

import '../../../helpers/test_imports.dart';
import '../../../mocks/feature_mocks.dart';

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

  late MockJournalRepositoryContract repository;
  late AppErrorReporter errorReporter;
  late BehaviorSubject<List<TrackerGroup>> groupsSubject;
  late BehaviorSubject<List<TrackerDefinition>> defsSubject;

  setUp(() {
    repository = MockJournalRepositoryContract();
    errorReporter = AppErrorReporter(
      messengerKey: GlobalKey<ScaffoldMessengerState>(),
    );
    groupsSubject = BehaviorSubject<List<TrackerGroup>>.seeded(
      const <TrackerGroup>[],
    );
    defsSubject = BehaviorSubject<List<TrackerDefinition>>.seeded(
      const <TrackerDefinition>[],
    );

    when(
      () => repository.watchTrackerGroups(),
    ).thenAnswer((_) => groupsSubject);
    when(
      () => repository.watchTrackerDefinitions(),
    ).thenAnswer((_) => defsSubject);
  });

  tearDown(() async {
    await groupsSubject.close();
    await defsSubject.close();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpApp(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<JournalRepositoryContract>.value(
            value: repository,
          ),
          RepositoryProvider<AppErrorReporter>.value(value: errorReporter),
          RepositoryProvider<NowService>.value(
            value: FakeNowService(DateTime(2025, 1, 15, 9)),
          ),
        ],
        child: const JournalTrackersPage(),
      ),
    );
  }

  testWidgetsSafe('shows error state when streams fail', (tester) async {
    final errorSubject = BehaviorSubject<List<TrackerGroup>>.seeded(
      const <TrackerGroup>[],
    );
    addTearDown(errorSubject.close);

    when(
      () => repository.watchTrackerGroups(),
    ).thenAnswer((_) => errorSubject);

    await pumpPage(tester);
    errorSubject.addError('boom');
    await tester.pumpForStream();
    final found = await tester.pumpUntilFound(
      find.textContaining('Failed to load trackers'),
    );
    expect(found, isTrue);
  });

  testWidgetsSafe('renders groups and trackers when loaded', (tester) async {
    final group = _group('group-1', 'Health');
    final tracker = _tracker('tracker-1', 'Mood', groupId: group.id);

    groupsSubject.add([group]);
    defsSubject.add([tracker]);

    await pumpPage(tester);
    await tester.pumpForStream();

    expect(find.text('Groups'), findsOneWidget);
    expect(find.text('Health'), findsWidgets);
    expect(find.text('Mood'), findsOneWidget);
  });

  testWidgetsSafe('updates list when trackers change', (tester) async {
    final group = _group('group-1', 'Health');
    final trackerA = _tracker('tracker-1', 'Mood', groupId: group.id);
    final trackerB = _tracker('tracker-2', 'Sleep', groupId: group.id);

    groupsSubject.add([group]);
    defsSubject.add([trackerA]);

    await pumpPage(tester);
    await tester.pumpForStream();

    expect(find.text('Mood'), findsOneWidget);

    defsSubject.add([trackerA, trackerB]);
    await tester.pumpForStream();

    expect(find.text('Sleep'), findsOneWidget);
  });
}

TrackerGroup _group(String id, String name) {
  final now = DateTime(2025, 1, 15);
  return TrackerGroup(
    id: id,
    name: name,
    createdAt: now,
    updatedAt: now,
    isActive: true,
    sortOrder: 0,
    userId: null,
  );
}

TrackerDefinition _tracker(
  String id,
  String name, {
  String? groupId,
}) {
  final now = DateTime(2025, 1, 15);
  return TrackerDefinition(
    id: id,
    name: name,
    scope: 'entry',
    valueType: 'rating',
    createdAt: now,
    updatedAt: now,
    groupId: groupId,
    isActive: true,
    sortOrder: 0,
  );
}
