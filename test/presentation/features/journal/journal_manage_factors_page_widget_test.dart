@Tags(['widget', 'journal'])
library;

import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_manage_factors_page.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/journal.dart';

import '../../../helpers/test_imports.dart';
import '../../../mocks/feature_mocks.dart';

class _FakeNowService implements NowService {
  @override
  DateTime nowLocal() => DateTime(2025, 1, 15, 9);

  @override
  DateTime nowUtc() => DateTime.utc(2025, 1, 15, 9);
}

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
    registerFallbackValue(
      TrackerGroup(
        id: 'g-fallback',
        name: 'Fallback group',
        createdAt: TestConstants.referenceDate,
        updatedAt: TestConstants.referenceDate,
      ),
    );
    registerFallbackValue(
      TrackerDefinition(
        id: 't-fallback',
        name: 'Fallback tracker',
        scope: 'entry',
        valueType: 'rating',
        createdAt: TestConstants.referenceDate,
        updatedAt: TestConstants.referenceDate,
      ),
    );
  });
  setUp(setUpTestEnvironment);

  late MockJournalRepositoryContract repository;
  late BehaviorSubject<List<TrackerGroup>> groupsSubject;
  late BehaviorSubject<List<TrackerDefinition>> defsSubject;
  late BehaviorSubject<List<TrackerPreference>> prefsSubject;

  setUp(() {
    repository = MockJournalRepositoryContract();
    groupsSubject = BehaviorSubject.seeded(const <TrackerGroup>[]);
    defsSubject = BehaviorSubject.seeded(const <TrackerDefinition>[]);
    prefsSubject = BehaviorSubject.seeded(const <TrackerPreference>[]);

    when(
      () => repository.watchTrackerGroups(),
    ).thenAnswer((_) => groupsSubject);
    when(
      () => repository.watchTrackerDefinitions(),
    ).thenAnswer((_) => defsSubject);
    when(
      () => repository.watchTrackerPreferences(),
    ).thenAnswer((_) => prefsSubject);
    when(
      () => repository.saveTrackerGroup(any(), context: any(named: 'context')),
    ).thenAnswer((_) async {});
    when(
      () => repository.saveTrackerDefinition(
        any(),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => repository.deleteTrackerGroup(
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
    await prefsSubject.close();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await pumpLocalizedApp(
      tester,
      home: MultiRepositoryProvider(
        providers: [
          RepositoryProvider<JournalRepositoryContract>.value(
            value: repository,
          ),
          RepositoryProvider<AppErrorReporter>.value(
            value: AppErrorReporter(
              messengerKey: GlobalKey<ScaffoldMessengerState>(),
            ),
          ),
          RepositoryProvider<NowService>.value(value: _FakeNowService()),
        ],
        child: const JournalManageFactorsPage(),
      ),
    );
  }

  testWidgetsSafe('renders group section and tracker actions', (tester) async {
    final now = DateTime.utc(2025, 1, 15);
    groupsSubject.add([
      TrackerGroup(
        id: 'g-1',
        name: 'Mindset',
        createdAt: now,
        updatedAt: now,
        isActive: true,
        sortOrder: 0,
        userId: null,
      ),
    ]);
    defsSubject.add([
      TrackerDefinition(
        id: 't-1',
        name: 'Energy',
        scope: 'entry',
        valueType: 'rating',
        createdAt: now,
        updatedAt: now,
        groupId: 'g-1',
      ),
    ]);

    await pumpPage(tester);
    await tester.pumpForStream();

    expect(find.text('Trackers'), findsOneWidget);
    expect(find.text('Groups'), findsOneWidget);
    expect(find.text('Mindset'), findsWidgets);
    expect(find.text('Energy'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_horiz).first);
    await tester.pumpForStream();

    expect(find.text('Group'), findsOneWidget);
    expect(find.text('Move up'), findsNothing);
  });
}
