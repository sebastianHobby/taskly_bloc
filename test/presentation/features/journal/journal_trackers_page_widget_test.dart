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
    when(
      () => repository.saveTrackerDefinition(
        any(),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => repository.deleteTrackerAndData(
        any(),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async {});
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

  testWidgetsSafe('renders entry trackers and hides daily trackers', (
    tester,
  ) async {
    final group = _group('group-1', 'Health');
    final entryTracker = _tracker(
      'tracker-1',
      'Mood',
      scope: 'entry',
      groupId: group.id,
    );
    final dailyTracker = _tracker('tracker-2', 'Water', scope: 'day');

    groupsSubject.add([group]);
    defsSubject.add([entryTracker, dailyTracker]);

    await pumpPage(tester);
    await tester.pumpForStream();

    expect(find.text('Mood'), findsOneWidget);
    expect(find.text('Water'), findsNothing);
  });

  testWidgetsSafe('shows empty label when no entry trackers', (tester) async {
    defsSubject.add([_tracker('tracker-2', 'Water', scope: 'day')]);

    await pumpPage(tester);
    await tester.pumpForStream();

    expect(find.text('No trackers yet'), findsOneWidget);
  });

  testWidgetsSafe('rename popup action saves tracker definition', (
    tester,
  ) async {
    final def = _tracker('tracker-1', 'Mood', scope: 'entry');
    defsSubject.add([def]);

    await pumpPage(tester);
    await tester.pumpForStream();

    await _tapPopupAction(tester, 'Rename');
    await tester.pumpForStream();

    await tester.enterText(find.byType(TextField).last, 'Renamed mood');
    await _tapText(tester, find.text('Save').last);
    await tester.pumpForStream();

    verify(
      () => repository.saveTrackerDefinition(
        any(
          that: isA<TrackerDefinition>().having(
            (d) => d.name,
            'name',
            'Renamed mood',
          ),
        ),
        context: any(named: 'context'),
      ),
    ).called(1);
  });

  testWidgetsSafe('archive popup action deactivates tracker', (tester) async {
    final def = _tracker('tracker-1', 'Mood', scope: 'entry');
    defsSubject.add([def]);

    await pumpPage(tester);
    await tester.pumpForStream();

    await _tapPopupAction(tester, 'Archive');
    await tester.pumpForStream();

    verify(
      () => repository.saveTrackerDefinition(
        any(
          that: isA<TrackerDefinition>().having(
            (d) => d.isActive,
            'isActive',
            false,
          ),
        ),
        context: any(named: 'context'),
      ),
    ).called(1);
  });

  testWidgetsSafe('delete popup action can hard delete tracker', (
    tester,
  ) async {
    final def = _tracker('tracker-1', 'Mood', scope: 'entry');
    defsSubject.add([def]);

    await pumpPage(tester);
    await tester.pumpForStream();

    await _tapPopupAction(tester, 'Delete');
    await tester.pumpForStream();

    await _tapText(tester, find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpForStream();

    verify(
      () => repository.deleteTrackerAndData(
        'tracker-1',
        context: any(named: 'context'),
      ),
    ).called(1);
  });
}

Future<void> _tapPopupAction(WidgetTester tester, String text) async {
  final menuButton = find.byType(PopupMenuButton<String>).first;
  await tester.ensureVisible(menuButton);
  await tester.tap(menuButton, warnIfMissed: false);
  await tester.pumpForStream();

  final action = find.text(text).last;
  await _tapText(tester, action);
}

Future<void> _tapText(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpUntilCondition(
    () => finder.hitTestable().evaluate().isNotEmpty,
  );
  await tester.tap(finder.hitTestable().first, warnIfMissed: false);
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
  required String scope,
  String? groupId,
}) {
  final now = DateTime(2025, 1, 15);
  return TrackerDefinition(
    id: id,
    name: name,
    scope: scope,
    valueType: 'rating',
    createdAt: now,
    updatedAt: now,
    groupId: groupId,
    isActive: true,
    sortOrder: 0,
  );
}
