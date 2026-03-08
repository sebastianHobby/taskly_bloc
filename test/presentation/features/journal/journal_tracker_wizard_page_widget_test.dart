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
    registerFallbackValue(
      TrackerGroup(
        id: 'fallback-group',
        name: 'Fallback',
        sortOrder: 0,
        isActive: true,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      ),
    );
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
    when(
      () => repository.saveTrackerGroup(
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
    JournalTrackerScopeOption? forcedScope,
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
        child: JournalTrackerWizardPage(mode: mode, forcedScope: forcedScope),
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

    _requestSave(tester);
    await tester.pumpForStream();
    await tester.pumpForStream();
  });

  testWidgetsSafe('renders daily wizard copy and saves', (tester) async {
    await pumpPage(tester, mode: JournalTrackerWizardMode.dailyCheckin);
    await tester.pumpForStream();

    expect(find.text('Configure tracker'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Water');
    await tester.pumpForStream();

    _requestSave(tester);
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

  testWidgetsSafe('entry tracker configure shows preview and saves', (
    tester,
  ) async {
    final now = DateTime(2025, 1, 15);
    groupsSubject.add([
      TrackerGroup(
        id: 'group-1',
        name: 'Sport',
        sortOrder: 10,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      TrackerGroup(
        id: 'group-2',
        name: 'Health',
        sortOrder: 20,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
    ]);

    await pumpPage(
      tester,
      forcedScope: JournalTrackerScopeOption.entry,
    );
    await tester.pumpForStream();

    expect(find.text('New tracker'), findsOneWidget);
    expect(find.text('New group'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Running');
    await tester.pumpForStream();

    _requestSave(tester);
    await tester.pumpForStream();
    await tester.pumpForStream();

    final captured =
        verify(
              () => repository.saveTrackerDefinition(
                captureAny(),
                context: any(named: 'context'),
              ),
            ).captured.last
            as TrackerDefinition;
    expect(captured.scope, 'entry');
    expect(captured.groupId, 'group-1');
  });

  testWidgetsSafe('day tracker flow supports quantity averages', (
    tester,
  ) async {
    await pumpPage(
      tester,
      forcedScope: JournalTrackerScopeOption.day,
    );
    await tester.pumpForStream();

    await tester.enterText(find.byType(TextField).first, 'Water');
    await tester.pumpForStream();

    final context = tester.element(find.byType(Scaffold).first);
    context.read<JournalTrackerWizardBloc>().add(
      const JournalTrackerWizardMeasurementChanged(
        JournalTrackerMeasurementType.quantity,
      ),
    );
    context.read<JournalTrackerWizardBloc>().add(
      const JournalTrackerWizardAggregationKindChanged('avg'),
    );
    context.read<JournalTrackerWizardBloc>().add(
      const JournalTrackerWizardQuantityConfigChanged(
        unit: 'ml',
        min: null,
        max: null,
        step: 1,
      ),
    );
    await tester.pumpForStream();

    _requestSave(tester);
    await tester.pumpForStream();
    await tester.pumpForStream();

    final captured =
        verify(
              () => repository.saveTrackerDefinition(
                captureAny(),
                context: any(named: 'context'),
              ),
            ).captured.last
            as TrackerDefinition;
    expect(captured.scope, 'day');
    expect(captured.valueType, 'quantity');
    expect(captured.opKind, 'add');
    expect(captured.aggregationKind, 'avg');
  });
}

void _requestSave(WidgetTester tester) {
  final context = tester.element(find.byType(Scaffold).first);
  context.read<JournalTrackerWizardBloc>().add(
    const JournalTrackerWizardSaveRequested(),
  );
}
