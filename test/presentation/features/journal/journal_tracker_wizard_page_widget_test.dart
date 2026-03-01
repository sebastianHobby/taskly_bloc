@Tags(['widget', 'journal'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_tracker_wizard_bloc.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_tracker_wizard_page.dart';
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

  setUp(() {
    repository = MockJournalRepositoryContract();
    errorReporter = AppErrorReporter(
      messengerKey: GlobalKey<ScaffoldMessengerState>(),
    );
    groupsSubject = BehaviorSubject<List<TrackerGroup>>.seeded(
      const <TrackerGroup>[],
    );

    when(
      () => repository.watchTrackerGroups(),
    ).thenAnswer((_) => groupsSubject);
    when(
      () => repository.watchTrackerDefinitions(),
    ).thenAnswer((_) => Stream.value(const <TrackerDefinition>[]));
    when(
      () => repository.saveTrackerDefinition(
        any(),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => repository.saveTrackerDefinitionChoice(
        any(),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async {});
  });

  tearDown(() async {
    await groupsSubject.close();
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    JournalTrackerWizardMode mode = JournalTrackerWizardMode.tracker,
  }) async {
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
        child: JournalTrackerWizardPage(mode: mode),
      ),
    );
  }

  testWidgetsSafe('renders tracker wizard without scope step', (tester) async {
    final now = DateTime(2025, 1, 15);
    groupsSubject.add([
      TrackerGroup(
        id: 'group-1',
        name: 'General',
        sortOrder: 10,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
    ]);
    await pumpPage(tester);
    await tester.pumpForStream();

    expect(find.text('Configure tracker'), findsOneWidget);
    expect(find.byType(Stepper), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'Mood');
    await tester.pumpForStream();

    await tester.tap(find.widgetWithText(FilledButton, 'Next step'));
    await tester.pumpForStream();
    await tester.pumpForStream();
  });

  testWidgetsSafe('renders daily wizard copy and saves', (tester) async {
    await pumpPage(tester, mode: JournalTrackerWizardMode.dailyCheckin);
    await tester.pumpForStream();

    expect(find.text('Configure tracker'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Water');
    await tester.pumpForStream();

    await tester.tap(find.widgetWithText(FilledButton, 'Next step'));
    await tester.pumpForStream();
    await tester.pumpForStream();

    final captured =
        verify(
              () => repository.saveTrackerDefinition(
                captureAny(),
                context: any(named: 'context'),
              ),
            ).captured.single
            as TrackerDefinition;
    expect(captured.scope, 'day');
  });
}
