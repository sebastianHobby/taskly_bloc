@Tags(['unit', 'journal'])
library;

import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_imports.dart';
import '../../../../mocks/feature_mocks.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_entry_editor_bloc.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_domain/taskly_domain.dart' show OperationContext;

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
    registerFallbackValue(
      TrackerDefinition(
        id: 't-1',
        name: 'Tracker',
        scope: 'entry',
        valueType: 'bool',
        createdAt: TestConstants.referenceDate,
        updatedAt: TestConstants.referenceDate,
      ),
    );
    registerFallbackValue(
      TrackerGroup(
        id: 'g-1',
        name: 'Group',
        createdAt: TestConstants.referenceDate,
        updatedAt: TestConstants.referenceDate,
      ),
    );
    registerFallbackValue(
      TrackerEvent(
        id: 'e-1',
        trackerId: 't-1',
        anchorType: 'entry',
        entryId: 'entry-1',
        op: 'set',
        value: true,
        occurredAt: TestConstants.referenceDate,
        recordedAt: TestConstants.referenceDate,
      ),
    );
    registerFallbackValue(
      JournalEntry(
        id: 'entry-1',
        entryDate: TestConstants.referenceDate,
        entryTime: TestConstants.referenceDate,
        occurredAt: TestConstants.referenceDate,
        localDate: TestConstants.referenceDate,
        createdAt: TestConstants.referenceDate,
        updatedAt: TestConstants.referenceDate,
        journalText: 'Note',
        deletedAt: null,
      ),
    );
    registerFallbackValue(
      const OperationContext(
        correlationId: 'corr-1',
        feature: 'journal',
        intent: 'test',
        operation: 'test',
      ),
    );
    registerFallbackValue(
      DateRange(
        start: TestConstants.referenceDate,
        end: TestConstants.referenceDate,
      ),
    );
  });
  setUp(setUpTestEnvironment);

  late MockJournalRepositoryContract repository;
  late AppErrorReporter errorReporter;
  late TestStreamController<List<TrackerDefinition>> defsController;
  late TestStreamController<List<TrackerGroup>> groupsController;
  late TestStreamController<List<TrackerStateDay>> dayStateController;
  late TestStreamController<List<TrackerEvent>> eventsController;

  final nowUtc = DateTime.utc(2025, 1, 15, 12, 30);

  JournalEntryEditorBloc buildBloc({
    String? entryId,
    Set<String>? preselected,
    DateTime? selectedDayLocal,
  }) {
    return JournalEntryEditorBloc(
      repository: repository,
      errorReporter: errorReporter,
      entryId: entryId,
      preselectedTrackerIds: preselected ?? const {},
      nowUtc: () => nowUtc,
      selectedDayLocal: selectedDayLocal,
    );
  }

  setUp(() {
    repository = MockJournalRepositoryContract();
    errorReporter = AppErrorReporter(
      messengerKey: GlobalKey<ScaffoldMessengerState>(),
    );
    defsController = TestStreamController.seeded(const []);
    groupsController = TestStreamController.seeded(const []);
    dayStateController = TestStreamController.seeded(const []);
    eventsController = TestStreamController.seeded(const []);

    when(() => repository.watchTrackerDefinitions()).thenAnswer(
      (_) => defsController.stream,
    );
    when(() => repository.watchTrackerGroups()).thenAnswer(
      (_) => groupsController.stream,
    );
    when(
      () => repository.watchTrackerStateDay(range: any(named: 'range')),
    ).thenAnswer((_) => dayStateController.stream);
    when(
      () => repository.watchTrackerEvents(
        anchorType: any(named: 'anchorType'),
        entryId: any(named: 'entryId'),
      ),
    ).thenAnswer((_) => eventsController.stream);
    when(() => repository.getJournalEntryById(any())).thenAnswer(
      (_) async => null,
    );
    when(
      () => repository.createJournalEntry(
        any(),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async => 'entry-1');
    when(
      () => repository.updateJournalEntry(
        any(),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => repository.appendTrackerEvent(
        any(),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => repository.watchTrackerDefinitionChoices(
        trackerId: any(named: 'trackerId'),
      ),
    ).thenAnswer((_) => Stream.value(const <TrackerDefinitionChoice>[]));

    addTearDown(defsController.close);
    addTearDown(groupsController.close);
    addTearDown(dayStateController.close);
    addTearDown(eventsController.close);
  });

  blocTestSafe<JournalEntryEditorBloc, JournalEntryEditorState>(
    'starts new entry with preselected values',
    build: () => buildBloc(preselected: const {'t-pre'}),
    act: (bloc) => bloc.add(const JournalEntryEditorStarted()),
    expect: () => [
      isA<JournalEntryEditorState>(),
      isA<JournalEntryEditorState>()
          .having((s) => s.status, 'status', isA<JournalEntryEditorIdle>())
          .having(
            (s) => s.entryValues.containsKey('t-pre'),
            'preselected',
            true,
          )
          .having((s) => s.isDirty, 'isDirty', false),
      isA<JournalEntryEditorState>(),
      isA<JournalEntryEditorState>(),
    ],
  );

  blocTestSafe<JournalEntryEditorBloc, JournalEntryEditorState>(
    'loads existing entry data',
    build: () {
      when(() => repository.getJournalEntryById('entry-1')).thenAnswer(
        (_) async => JournalEntry(
          id: 'entry-1',
          entryDate: nowUtc,
          entryTime: nowUtc,
          occurredAt: nowUtc,
          localDate: nowUtc,
          createdAt: nowUtc,
          updatedAt: nowUtc,
          journalText: 'Note',
          deletedAt: null,
        ),
      );
      when(
        () => repository.watchTrackerDefinitions(),
      ).thenAnswer(
        (_) => Stream.value([
          TrackerDefinition(
            id: 'mood',
            name: 'Mood',
            scope: 'entry',
            valueType: 'int',
            systemKey: 'mood',
            createdAt: nowUtc,
            updatedAt: nowUtc,
          ),
        ]),
      );
      when(
        () => repository.watchTrackerEvents(
          anchorType: 'entry',
          entryId: 'entry-1',
        ),
      ).thenAnswer(
        (_) => Stream.value([
          TrackerEvent(
            id: 'e-1',
            trackerId: 'mood',
            anchorType: 'entry',
            entryId: 'entry-1',
            op: 'set',
            value: 4,
            occurredAt: nowUtc,
            recordedAt: nowUtc,
          ),
        ]),
      );
      return buildBloc(entryId: 'entry-1');
    },
    act: (bloc) => bloc.add(const JournalEntryEditorStarted()),
    expect: () => [
      isA<JournalEntryEditorState>(),
      isA<JournalEntryEditorState>()
          .having((s) => s.status, 'status', isA<JournalEntryEditorIdle>())
          .having((s) => s.mood, 'mood', MoodRating.good)
          .having((s) => s.note, 'note', 'Note'),
      isA<JournalEntryEditorState>(),
      isA<JournalEntryEditorState>(),
    ],
  );

  blocTestSafe<JournalEntryEditorBloc, JournalEntryEditorState>(
    'save emits error when mood missing',
    build: () => buildBloc(),
    seed: () => JournalEntryEditorState.initial(entryId: null).copyWith(
      status: const JournalEntryEditorIdle(),
    ),
    act: (bloc) => bloc.add(const JournalEntryEditorSaveRequested()),
    expect: () => [
      isA<JournalEntryEditorState>().having(
        (s) => s.status,
        'status',
        isA<JournalEntryEditorError>().having(
          (s) => s.message,
          'message',
          'Please choose a mood.',
        ),
      ),
    ],
  );

  blocTestSafe<JournalEntryEditorBloc, JournalEntryEditorState>(
    'save persists entry and events with context',
    build: () => buildBloc(),
    seed: () => JournalEntryEditorState.initial(entryId: null).copyWith(
      status: const JournalEntryEditorIdle(),
      moodTrackerId: 'mood',
      mood: MoodRating.good,
      note: 'Hello',
      entryValues: const {'gratitude': true},
      definitionById: {
        'gratitude': TrackerDefinition(
          id: 'gratitude',
          name: 'Gratitude',
          scope: 'entry',
          valueType: 'bool',
          createdAt: TestConstants.referenceDate,
          updatedAt: TestConstants.referenceDate,
        ),
      },
    ),
    act: (bloc) => bloc.add(const JournalEntryEditorSaveRequested()),
    expect: () => [
      isA<JournalEntryEditorState>().having(
        (s) => s.status,
        'status',
        isA<JournalEntryEditorSaving>(),
      ),
      isA<JournalEntryEditorState>().having(
        (s) => s.status,
        'status',
        isA<JournalEntryEditorSaved>(),
      ),
    ],
    verify: (_) {
      final captured = verify(
        () => repository.appendTrackerEvent(
          captureAny<TrackerEvent>(),
          context: captureAny(named: 'context'),
        ),
      ).captured;
      expect(captured.length, 4);
      final ctx =
          captured.firstWhere(
                (item) => item is OperationContext,
              )
              as OperationContext;
      expect(ctx.feature, 'journal');
      expect(ctx.screen, 'journal_entry_editor');
      expect(ctx.intent, 'save');
      expect(ctx.operation, 'journal.entry_editor.save');
      for (final forwarded in captured.whereType<OperationContext>().skip(1)) {
        expect(forwarded.correlationId, ctx.correlationId);
      }
    },
  );

  testSafe(
    'daily value change writes day-anchored event for selected day',
    () async {
      final selectedDay = DateTime(2025, 1, 14);
      final bloc = buildBloc(selectedDayLocal: selectedDay);
      addTearDown(bloc.close);

      bloc.add(const JournalEntryEditorStarted());
      await Future<void>.delayed(const Duration(milliseconds: 30));

      defsController.emit([
        TrackerDefinition(
          id: 'daily-1',
          name: 'Water',
          scope: 'day',
          valueType: 'quantity',
          opKind: 'set',
          createdAt: nowUtc,
          updatedAt: nowUtc,
        ),
      ]);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      bloc.add(
        const JournalEntryEditorDailyValueChanged(
          trackerId: 'daily-1',
          value: 350,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));

      final captured = verify(
        () => repository.appendTrackerEvent(
          captureAny(),
          context: captureAny(named: 'context'),
        ),
      ).captured;

      final event =
          captured.firstWhere((it) => it is TrackerEvent) as TrackerEvent;
      expect(event.anchorType, 'day');
      expect(event.anchorDate, DateTime.utc(2025, 1, 14));
      expect(event.op, 'set');
      expect(event.value, 350);

      final ctx =
          captured.firstWhere((it) => it is OperationContext)
              as OperationContext;
      expect(ctx.intent, 'set_daily_value');
      expect(ctx.operation, 'journal.entry_editor.daily.set');
    },
  );

  testSafe('daily delta add writes add event using selected day', () async {
    final selectedDay = DateTime(2025, 1, 14);
    final bloc = buildBloc(selectedDayLocal: selectedDay);
    addTearDown(bloc.close);

    bloc.add(const JournalEntryEditorStarted());
    await Future<void>.delayed(const Duration(milliseconds: 30));

    defsController.emit([
      TrackerDefinition(
        id: 'steps',
        name: 'Steps',
        scope: 'day',
        valueType: 'quantity',
        createdAt: nowUtc,
        updatedAt: nowUtc,
      ),
    ]);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    bloc.add(
      const JournalEntryEditorDailyDeltaAdded(
        trackerId: 'steps',
        delta: 2,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));

    final captured = verify(
      () => repository.appendTrackerEvent(
        captureAny(),
        context: captureAny(named: 'context'),
      ),
    ).captured;

    final event =
        captured.firstWhere((it) => it is TrackerEvent) as TrackerEvent;
    expect(event.anchorType, 'day');
    expect(event.anchorDate, DateTime.utc(2025, 1, 14));
    expect(event.op, 'add');
    expect(event.value, 2);

    final ctx =
        captured.firstWhere((it) => it is OperationContext) as OperationContext;
    expect(ctx.intent, 'add_daily_delta');
    expect(ctx.operation, 'journal.entry_editor.daily.add');
  });

  testSafe('existing unchanged save short-circuits without writes', () async {
    final bloc = buildBloc(entryId: 'entry-1');
    addTearDown(bloc.close);

    bloc.add(
      const JournalEntryEditorSaveRequested(),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(bloc.state.status, isA<JournalEntryEditorSaved>());
    verifyNever(
      () =>
          repository.createJournalEntry(any(), context: any(named: 'context')),
    );
    verifyNever(
      () =>
          repository.updateJournalEntry(any(), context: any(named: 'context')),
    );
  });

  testSafe(
    'editing existing entry updates journal entry instead of creating',
    () async {
      final existing = JournalEntry(
        id: 'entry-1',
        entryDate: DateTime.utc(2025, 1, 14),
        entryTime: DateTime.utc(2025, 1, 14, 9),
        occurredAt: DateTime.utc(2025, 1, 14, 9),
        localDate: DateTime.utc(2025, 1, 14),
        createdAt: DateTime.utc(2025, 1, 14, 9),
        updatedAt: DateTime.utc(2025, 1, 14, 9),
        journalText: 'Old note',
        deletedAt: null,
      );

      when(
        () => repository.getJournalEntryById('entry-1'),
      ).thenAnswer((_) async => existing);
      when(
        () => repository.watchTrackerDefinitions(),
      ).thenAnswer(
        (_) => Stream.value([
          TrackerDefinition(
            id: 'mood-id',
            name: 'Mood',
            scope: 'entry',
            valueType: 'rating',
            systemKey: 'mood',
            createdAt: nowUtc,
            updatedAt: nowUtc,
          ),
        ]),
      );
      when(
        () => repository.watchTrackerEvents(
          anchorType: 'entry',
          entryId: 'entry-1',
        ),
      ).thenAnswer(
        (_) => Stream.value([
          TrackerEvent(
            id: 'ev-mood',
            trackerId: 'mood-id',
            anchorType: 'entry',
            entryId: 'entry-1',
            op: 'set',
            value: 4,
            occurredAt: existing.occurredAt,
            recordedAt: existing.occurredAt,
          ),
        ]),
      );

      final bloc = buildBloc(entryId: 'entry-1');
      addTearDown(bloc.close);

      bloc.add(const JournalEntryEditorStarted());
      await Future<void>.delayed(const Duration(milliseconds: 30));

      bloc.add(const JournalEntryEditorNoteChanged('Updated note'));
      bloc.add(const JournalEntryEditorSaveRequested());
      await Future<void>.delayed(const Duration(milliseconds: 40));

      verify(
        () => repository.updateJournalEntry(
          any(
            that: isA<JournalEntry>().having(
              (e) => e.journalText,
              'journalText',
              'Updated note',
            ),
          ),
          context: any(named: 'context'),
        ),
      ).called(1);
      verifyNever(
        () => repository.createJournalEntry(
          any(),
          context: any(named: 'context'),
        ),
      );
    },
  );

  testSafe('missing existing entry emits error status', () async {
    when(
      () => repository.getJournalEntryById('missing'),
    ).thenAnswer((_) async => null);

    final bloc = buildBloc(entryId: 'missing');
    addTearDown(bloc.close);
    final seenStatuses = <JournalEntryEditorStatus>[];
    final sub = bloc.stream.listen((state) => seenStatuses.add(state.status));
    addTearDown(sub.cancel);

    bloc.add(const JournalEntryEditorStarted());
    await Future<void>.delayed(const Duration(milliseconds: 30));

    final errorStatus = seenStatuses.whereType<JournalEntryEditorError>().last;
    expect(errorStatus.message, contains('Failed to load log'));
  });
}
