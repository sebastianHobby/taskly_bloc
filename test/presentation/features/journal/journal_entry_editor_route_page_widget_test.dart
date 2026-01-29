@Tags(['widget', 'journal'])
library;

import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_entry_editor_route_page.dart';
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

class MockErrorReporter extends Mock implements AppErrorReporter {}

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
  });
  setUp(setUpTestEnvironment);

  late MockJournalRepositoryContract repository;
  late MockErrorReporter errorReporter;
  late BehaviorSubject<List<TrackerDefinition>> defsSubject;
  late BehaviorSubject<List<TrackerGroup>> groupsSubject;
  late BehaviorSubject<List<TrackerStateDay>> dayStatesSubject;

  setUp(() {
    repository = MockJournalRepositoryContract();
    errorReporter = MockErrorReporter();
    defsSubject = BehaviorSubject<List<TrackerDefinition>>.seeded(
      const <TrackerDefinition>[],
    );
    groupsSubject = BehaviorSubject<List<TrackerGroup>>.seeded(
      const <TrackerGroup>[],
    );
    dayStatesSubject = BehaviorSubject<List<TrackerStateDay>>.seeded(
      const <TrackerStateDay>[],
    );

    when(() => repository.watchTrackerDefinitions())
        .thenAnswer((_) => defsSubject);
    when(() => repository.watchTrackerGroups())
        .thenAnswer((_) => groupsSubject);
    when(() => repository.watchTrackerStateDay(range: any(named: 'range')))
        .thenAnswer((_) => dayStatesSubject);
    when(
      () => repository.watchTrackerEvents(
        range: any(named: 'range'),
        anchorType: any(named: 'anchorType'),
        entryId: any(named: 'entryId'),
        anchorDate: any(named: 'anchorDate'),
        trackerId: any(named: 'trackerId'),
      ),
    ).thenAnswer((_) => Stream<List<TrackerEvent>>.value(const []));
  });

  tearDown(() async {
    await defsSubject.close();
    await groupsSubject.close();
    await dayStatesSubject.close();
  });

  Future<void> pumpPage(WidgetTester tester, {String? entryId}) async {
    await tester.pumpApp(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<JournalRepositoryContract>.value(value: repository),
          RepositoryProvider<AppErrorReporter>.value(value: errorReporter),
          RepositoryProvider<NowService>.value(
            value: FakeNowService(DateTime(2025, 1, 15, 9)),
          ),
        ],
        child: JournalEntryEditorRoutePage(
          entryId: entryId,
          preselectedTrackerIds: const <String>{},
        ),
      ),
    );
  }

  testWidgetsSafe('shows error snack bar when entry load fails', (tester) async {
    when(() => repository.getJournalEntryById('entry-1'))
        .thenThrow(StateError('missing'));

    await pumpPage(tester, entryId: 'entry-1');
    await tester.pumpForStream();

    expect(find.textContaining('Failed to load log'), findsOneWidget);
  });

  testWidgetsSafe('renders editor content when loaded', (tester) async {
    final moodDef = _trackerDef('mood', 'Mood', systemKey: 'mood');
    final tracker = _trackerDef('tracker-1', 'Energy');

    defsSubject.add([moodDef, tracker]);
    groupsSubject.add([_group('group-1', 'Wellness')]);

    await pumpPage(tester);
    await tester.pumpForStream();

    expect(find.text('Mood'), findsOneWidget);
    expect(find.text('Save log'), findsOneWidget);
    expect(find.text('Energy'), findsOneWidget);
  });

  testWidgetsSafe('requires mood before save', (tester) async {
    final moodDef = _trackerDef('mood', 'Mood', systemKey: 'mood');
    defsSubject.add([moodDef]);

    await pumpPage(tester);
    await tester.pumpForStream();

    await tester.tap(find.text('Save log'));
    await tester.pumpForStream();

    expect(find.textContaining('Please choose a mood'), findsOneWidget);
  });

  testWidgetsSafe('shows error when mood tracker is missing', (tester) async {
    await pumpPage(tester);
    await tester.pumpForStream();

    await tester.tap(find.bySemanticsLabel('Mood: Good'));
    await tester.tap(find.text('Save log'));
    await tester.pumpForStream();

    expect(find.textContaining('Missing system mood tracker'), findsOneWidget);
  });

  testWidgetsSafe('saves new entry and shows success snack', (tester) async {
    final moodDef = _trackerDef('mood', 'Mood', systemKey: 'mood');
    defsSubject.add([moodDef]);
    when(
      () => repository.upsertJournalEntry(
        any(),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async => 'entry-1');
    when(
      () => repository.appendTrackerEvent(
        any(),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async {});

    await pumpPage(tester);
    await tester.pumpForStream();

    await tester.tap(find.bySemanticsLabel('Mood: Good'));
    await tester.pumpForStream();

    await tester.tap(find.text('Save log'));
    await tester.pumpForStream();

    verify(
      () => repository.upsertJournalEntry(
        any(),
        context: any(named: 'context'),
      ),
    ).called(1);
    verify(
      () => repository.appendTrackerEvent(
        any(),
        context: any(named: 'context'),
      ),
    ).called(greaterThanOrEqualTo(1));

    expect(find.textContaining('Saved log'), findsOneWidget);
  });

  testWidgetsSafe('shows error snack when save fails', (tester) async {
    final moodDef = _trackerDef('mood', 'Mood', systemKey: 'mood');
    defsSubject.add([moodDef]);
    when(
      () => repository.upsertJournalEntry(
        any(),
        context: any(named: 'context'),
      ),
    ).thenThrow(Exception('save failed'));

    await pumpPage(tester);
    await tester.pumpForStream();

    await tester.tap(find.bySemanticsLabel('Mood: Good'));
    await tester.tap(find.text('Save log'));
    await tester.pumpForStream();

    expect(find.textContaining('Failed to save log'), findsOneWidget);
  });

  testWidgetsSafe('save button enabled only after edits on existing entry', (
    tester,
  ) async {
    final moodDef = _trackerDef('mood', 'Mood', systemKey: 'mood');
    defsSubject.add([moodDef]);

    final entry = _entry('entry-1', 'Note');
    when(() => repository.getJournalEntryById('entry-1'))
        .thenAnswer((_) async => entry);

    when(
      () => repository.watchTrackerEvents(
        anchorType: any(named: 'anchorType'),
        entryId: 'entry-1',
        range: any(named: 'range'),
        anchorDate: any(named: 'anchorDate'),
        trackerId: any(named: 'trackerId'),
      ),
    ).thenAnswer((_) {
      final now = DateTime(2025, 1, 15, 9);
      return Stream<List<TrackerEvent>>.value(
        [
          TrackerEvent(
            id: 'event-1',
            trackerId: moodDef.id,
            anchorType: 'entry',
            op: 'set',
            occurredAt: now,
            recordedAt: now,
            entryId: entry.id,
            value: 4,
          ),
        ],
      );
    });

    await pumpPage(tester, entryId: 'entry-1');
    await tester.pumpForStream();

    var saveButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Save log'),
    );
    expect(saveButton.onPressed, isNull);

    await tester.enterText(
      _textFieldWithLabel('Note (optional)'),
      'Updated note',
    );
    await tester.pumpForStream();

    saveButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Save log'),
    );
    expect(saveButton.onPressed, isNotNull);
  });

  testWidgetsSafe('updates tracker list when definitions change', (tester) async {
    final moodDef = _trackerDef('mood', 'Mood', systemKey: 'mood');
    final trackerA = _trackerDef('tracker-1', 'Energy');
    final trackerB = _trackerDef('tracker-2', 'Focus');

    defsSubject.add([moodDef, trackerA]);

    await pumpPage(tester);
    await tester.pumpForStream();

    expect(find.text('Energy'), findsOneWidget);

    defsSubject.add([moodDef, trackerA, trackerB]);
    await tester.pumpForStream();

    expect(find.text('Focus'), findsOneWidget);
  });

  testWidgetsSafe('renders choice chips and updates selection', (tester) async {
    final moodDef = _trackerDef('mood', 'Mood', systemKey: 'mood');
    final choiceDef = _trackerDef(
      'choice-1',
      'Location',
      valueType: 'choice',
      valueKind: 'single_choice',
    );
    defsSubject.add([moodDef, choiceDef]);

    when(
      () => repository.watchTrackerDefinitionChoices(trackerId: 'choice-1'),
    ).thenAnswer((_) {
      final now = DateTime(2025, 1, 15, 9);
      return Stream.value([
        TrackerDefinitionChoice(
          id: 'choice-1',
          trackerId: 'choice-1',
          choiceKey: 'home',
          label: 'Home',
          createdAt: now,
          updatedAt: now,
          sortOrder: 0,
          isActive: true,
          userId: null,
        ),
        TrackerDefinitionChoice(
          id: 'choice-2',
          trackerId: 'choice-1',
          choiceKey: 'work',
          label: 'Work',
          createdAt: now,
          updatedAt: now,
          sortOrder: 1,
          isActive: true,
          userId: null,
        ),
      ]);
    });

    await pumpPage(tester);
    await tester.pumpForStream();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Work'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpForStream();

    final chip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Home'),
    );
    expect(chip.selected, isTrue);
  });

  testWidgetsSafe('rating slider uses configured bounds', (tester) async {
    final moodDef = _trackerDef('mood', 'Mood', systemKey: 'mood');
    final ratingDef = _trackerDef(
      'rating-1',
      'Energy',
      valueType: 'rating',
      minInt: 2,
      maxInt: 8,
      stepInt: 2,
    );
    defsSubject.add([moodDef, ratingDef]);

    await pumpPage(tester);
    await tester.pumpForStream();

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.min, 2);
    expect(slider.max, 8);
    expect(slider.divisions, 3);
  });

  testWidgetsSafe('quantity edit sheet clamps values', (tester) async {
    final moodDef = _trackerDef('mood', 'Mood', systemKey: 'mood');
    final quantityDef = _trackerDef(
      'quantity-1',
      'Water',
      valueType: 'quantity',
      valueKind: 'number',
      minInt: 2,
      maxInt: 10,
      stepInt: 2,
    );
    defsSubject.add([moodDef, quantityDef]);

    await pumpPage(tester);
    await tester.pumpForStream();

    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.text('Edit'));
    await tester.pumpForStream();

    await tester.enterText(find.widgetWithText(TextField, 'Value'), '20');
    await tester.tap(find.text('Save'));
    await tester.pumpForStream();

    expect(find.text('10'), findsOneWidget);
  });

  testWidgetsSafe('choice bottom sheet search selects option', (tester) async {
    final moodDef = _trackerDef('mood', 'Mood', systemKey: 'mood');
    final choiceDef = _trackerDef(
      'choice-1',
      'Context',
      valueType: 'choice',
      valueKind: 'single_choice',
    );
    defsSubject.add([moodDef, choiceDef]);

    when(
      () => repository.watchTrackerDefinitionChoices(trackerId: 'choice-1'),
    ).thenAnswer((_) {
      final now = DateTime(2025, 1, 15, 9);
      return Stream.value([
        for (final label in [
          'Home',
          'Work',
          'Travel',
          'Social',
          'Gym',
          'Cafe',
          'Outdoor',
        ])
          TrackerDefinitionChoice(
            id: 'choice-$label',
            trackerId: 'choice-1',
            choiceKey: label.toLowerCase(),
            label: label,
            createdAt: now,
            updatedAt: now,
            sortOrder: 0,
            isActive: true,
            userId: null,
          ),
      ]);
    });

    await pumpPage(tester);
    await tester.pumpForStream();

    await tester.tap(find.text('Choose option'));
    await tester.pumpForStream();

    await tester.enterText(
      find.widgetWithText(TextField, 'Search options'),
      'Work',
    );
    await tester.pumpForStream();

    await tester.tap(find.text('Work'));
    await tester.pumpForStream();

    expect(find.text('Work'), findsOneWidget);
  });
}

Finder _textFieldWithLabel(String label) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is TextField && widget.decoration?.labelText == label,
  );
}

JournalEntry _entry(String id, String note) {
  final when = DateTime(2025, 1, 15, 9);
  return JournalEntry(
    id: id,
    entryDate: when,
    entryTime: when,
    occurredAt: when,
    localDate: when,
    createdAt: when,
    updatedAt: when,
    journalText: note,
  );
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

TrackerDefinition _trackerDef(
  String id,
  String name, {
  String? systemKey,
  String valueType = 'rating',
  String? valueKind,
  int? minInt,
  int? maxInt,
  int? stepInt,
}) {
  final now = DateTime(2025, 1, 15);
  return TrackerDefinition(
    id: id,
    name: name,
    scope: systemKey == 'mood' ? 'day' : 'entry',
    valueType: valueType,
    createdAt: now,
    updatedAt: now,
    systemKey: systemKey,
    isActive: true,
    sortOrder: 0,
    valueKind: valueKind,
    minInt: minInt,
    maxInt: maxInt,
    stepInt: stepInt,
  );
}
