@Tags(['widget', 'journal'])
library;

import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
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
      () => repository.saveTrackerDefinitionChoice(
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
        child: const JournalTrackerWizardPage(),
      ),
    );
  }

  testWidgetsSafe('shows error snack bar when groups stream fails', (
    tester,
  ) async {
    when(
      () => repository.watchTrackerGroups(),
    ).thenAnswer((_) => Stream<List<TrackerGroup>>.error('boom'));

    await pumpPage(tester);
    await tester.pumpForStream();

    expect(find.textContaining('Failed to load groups'), findsOneWidget);
  });

  testWidgetsSafe('renders stepper with group options', (tester) async {
    final group = _group('group-1', 'Health');
    groupsSubject.add([group]);

    await pumpPage(tester);
    await tester.pumpForStream();

    expect(find.text('New tracker'), findsOneWidget);
    expect(find.text('Name'), findsWidgets);

    await tester.tap(find.text('Ungrouped'));
    await tester.pumpForStream();

    expect(find.text('Health'), findsOneWidget);
  });

  testWidgetsSafe('requires name and scope before continuing', (tester) async {
    await pumpPage(tester);
    await tester.pumpForStream();

    await tester.tap(find.text('Next'));
    await tester.pumpForStream();
    expect(find.text('Daily total'), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'Daily check-in');
    await tester.tap(find.text('Next'));
    await tester.pumpForStream();
    expect(find.text('Daily total'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpForStream();
    expect(find.text('Toggle'), findsNothing);
  });

  testWidgetsSafe('validates measurement selection before create', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.pumpForStream();

    await _goToMeasurementStep(tester, name: 'Tracker');

    final createButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Create'),
    );
    expect(createButton.onPressed, isNull);
  });

  testWidgetsSafe('shows error for invalid rating range', (tester) async {
    await pumpPage(tester);
    await tester.pumpForStream();

    await _goToMeasurementStep(tester, name: 'Energy');
    await tester.tap(find.text('Rating'));
    await tester.pumpForStream();

    await tester.enterText(find.widgetWithText(TextField, 'Min'), '5');
    await tester.enterText(find.widgetWithText(TextField, 'Max'), '3');
    await tester.enterText(find.widgetWithText(TextField, 'Step'), '1');

    await tester.tap(find.text('Create'));
    await tester.pumpForStream();

    expect(find.textContaining('Check rating range'), findsOneWidget);
  });

  testWidgetsSafe('shows error for invalid quantity step', (tester) async {
    await pumpPage(tester);
    await tester.pumpForStream();

    await _goToMeasurementStep(tester, name: 'Steps');
    await tester.tap(find.text('Quantity'));
    await tester.pumpForStream();

    await tester.enterText(find.widgetWithText(TextField, 'Step'), '0');

    await tester.tap(find.text('Create'));
    await tester.pumpForStream();

    expect(find.textContaining('Step must be > 0'), findsOneWidget);
  });

  testWidgetsSafe('shows error when choice has no options', (tester) async {
    await pumpPage(tester);
    await tester.pumpForStream();

    await _goToMeasurementStep(tester, name: 'Context');
    await tester.tap(find.text('Choice'));
    await tester.pumpForStream();

    await tester.tap(find.text('Create'));
    await tester.pumpForStream();

    expect(find.textContaining('Add at least one option'), findsOneWidget);
  });

  testWidgetsSafe('choice UI adds and removes options', (tester) async {
    await pumpPage(tester);
    await tester.pumpForStream();

    await _goToMeasurementStep(tester, name: 'Location');
    await tester.tap(find.text('Choice'));
    await tester.pumpForStream();

    await tester.enterText(find.widgetWithText(TextField, 'Option'), 'Home');
    await tester.tap(find.text('Add'));
    await tester.pumpForStream();

    expect(find.byType(TextFormField), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpForStream();

    expect(find.textContaining('Add at least one option'), findsOneWidget);
  });

  testWidgetsSafe('creates tracker and pops on success', (tester) async {
    await pumpPage(tester);
    await tester.pumpForStream();

    await _goToMeasurementStep(tester, name: 'Mood');
    await tester.tap(find.text('Toggle'));
    await tester.pumpForStream();

    await tester.tap(find.text('Create'));
    await tester.pumpForStream();

    verify(
      () => repository.saveTrackerDefinition(
        any(),
        context: any(named: 'context'),
      ),
    ).called(1);
    expect(find.text('New tracker'), findsNothing);
  });

  testWidgetsSafe('shows error snack when save fails', (tester) async {
    when(
      () => repository.saveTrackerDefinition(
        any(),
        context: any(named: 'context'),
      ),
    ).thenThrow(Exception('save failed'));

    await pumpPage(tester);
    await tester.pumpForStream();

    await _goToMeasurementStep(tester, name: 'Mood');
    await tester.tap(find.text('Toggle'));
    await tester.pumpForStream();

    await tester.tap(find.text('Create'));
    await tester.pumpForStream();

    expect(
      find.textContaining('Failed to create tracker'),
      findsOneWidget,
    );
  });

  testWidgetsSafe('shows rating config fields when rating selected', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.pumpForStream();

    await _goToMeasurementStep(tester, name: 'Energy');
    await tester.tap(find.text('Rating'));
    await tester.pumpForStream();

    expect(find.widgetWithText(TextField, 'Min'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Max'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Step'), findsOneWidget);
  });

  testWidgetsSafe('shows quantity config fields when quantity selected', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.pumpForStream();

    await _goToMeasurementStep(tester, name: 'Water');
    await tester.tap(find.text('Quantity'));
    await tester.pumpForStream();

    expect(find.widgetWithText(TextField, 'Unit (optional)'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Min (optional)'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Max (optional)'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Step'), findsOneWidget);
  });
}

Future<void> _goToMeasurementStep(
  WidgetTester tester, {
  required String name,
}) async {
  await tester.enterText(find.byType(TextField).first, name);
  await tester.tap(find.text('Next'));
  await tester.pumpForStream();

  await tester.tap(find.text('Daily total'));
  await tester.pumpForStream();

  await tester.tap(find.text('Next'));
  await tester.pumpForStream();
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
