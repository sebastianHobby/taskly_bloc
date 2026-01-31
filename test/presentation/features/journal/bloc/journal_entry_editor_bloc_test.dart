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

  final nowUtc = DateTime.utc(2025, 1, 15, 12);

  JournalEntryEditorBloc buildBloc({
    String? entryId,
    Set<String>? preselected,
  }) {
    return JournalEntryEditorBloc(
      repository: repository,
      errorReporter: errorReporter,
      entryId: entryId,
      preselectedTrackerIds: preselected ?? const {},
      nowUtc: () => nowUtc,
    );
  }

  setUp(() {
    repository = MockJournalRepositoryContract();
    errorReporter = AppErrorReporter(
      messengerKey: GlobalKey<ScaffoldMessengerState>(),
    );
    defsController = TestStreamController();
    groupsController = TestStreamController();
    dayStateController = TestStreamController();
    eventsController = TestStreamController();

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
      final entryCaptured = verify(
        () => repository.upsertJournalEntry(
          captureAny<JournalEntry>(),
          context: captureAny(named: 'context'),
        ),
      ).captured;
      expect(entryCaptured.length, 2);

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
}
