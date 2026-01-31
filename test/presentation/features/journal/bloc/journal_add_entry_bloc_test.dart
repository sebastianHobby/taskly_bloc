@Tags(['unit', 'journal'])
library;

import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_imports.dart';
import '../../../../mocks/feature_mocks.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_add_entry_bloc.dart';
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
        op: 'set',
        value: true,
        occurredAt: TestConstants.referenceDate,
        recordedAt: TestConstants.referenceDate,
      ),
    );
    registerFallbackValue(
      JournalEntry(
        id: 'j-1',
        entryDate: TestConstants.referenceDate,
        entryTime: TestConstants.referenceDate,
        occurredAt: TestConstants.referenceDate,
        localDate: TestConstants.referenceDate,
        createdAt: TestConstants.referenceDate,
        updatedAt: TestConstants.referenceDate,
        journalText: null,
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
  });
  setUp(setUpTestEnvironment);

  late MockJournalRepositoryContract repository;
  late AppErrorReporter errorReporter;
  late TestStreamController<List<TrackerDefinition>> defsController;
  late TestStreamController<List<TrackerGroup>> groupsController;

  final nowUtc = DateTime.utc(2025, 1, 15, 12);

  JournalAddEntryBloc buildBloc() {
    return JournalAddEntryBloc(
      repository: repository,
      errorReporter: errorReporter,
      nowUtc: () => nowUtc,
    );
  }

  setUp(() {
    repository = MockJournalRepositoryContract();
    errorReporter = AppErrorReporter(
      messengerKey: GlobalKey<ScaffoldMessengerState>(),
    );
    defsController = TestStreamController.seeded(const []);
    groupsController = TestStreamController.seeded(const []);

    when(() => repository.watchTrackerDefinitions()).thenAnswer(
      (_) => defsController.stream,
    );
    when(() => repository.watchTrackerGroups()).thenAnswer(
      (_) => groupsController.stream,
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
  });

  testSafe('initial state is loading', () async {
    final bloc = buildBloc();
    addTearDown(bloc.close);

    expect(bloc.state.status, isA<JournalAddEntryLoading>());
  });

  blocTestSafe<JournalAddEntryBloc, JournalAddEntryState>(
    'started loads active groups and trackers',
    build: buildBloc,
    act: (bloc) {
      bloc.add(
        JournalAddEntryStarted(
          selectedDayLocal: DateTime(2025, 1, 14),
        ),
      );

      defsController.emit([
        TrackerDefinition(
          id: 'mood',
          name: 'Mood',
          scope: 'entry',
          valueType: 'int',
          systemKey: 'mood',
          createdAt: nowUtc,
          updatedAt: nowUtc,
        ),
        TrackerDefinition(
          id: 'daily',
          name: 'Sleep',
          scope: 'daily',
          valueType: 'int',
          createdAt: nowUtc,
          updatedAt: nowUtc,
        ),
        TrackerDefinition(
          id: 'gratitude',
          name: 'Gratitude',
          scope: 'entry',
          valueType: 'bool',
          createdAt: nowUtc,
          updatedAt: nowUtc,
          sortOrder: 2,
        ),
      ]);

      groupsController.emit([
        TrackerGroup(
          id: 'g-1',
          name: 'Active',
          createdAt: nowUtc,
          updatedAt: nowUtc,
          isActive: true,
          sortOrder: 1,
        ),
        TrackerGroup(
          id: 'g-2',
          name: 'Inactive',
          createdAt: nowUtc,
          updatedAt: nowUtc,
          isActive: false,
          sortOrder: 2,
        ),
      ]);
    },
    expect: () => [
      isA<JournalAddEntryState>().having(
        (s) => s.selectedDayLocal.day,
        'day',
        14,
      ),
      isA<JournalAddEntryState>().having(
        (s) => s.status,
        'status',
        isA<JournalAddEntryIdle>(),
      ),
      isA<JournalAddEntryState>()
          .having((s) => s.groups.length, 'groups', 1)
          .having((s) => s.trackers.length, 'trackers', 1)
          .having((s) => s.moodTrackerId, 'moodTrackerId', 'mood'),
    ],
  );

  blocTestSafe<JournalAddEntryBloc, JournalAddEntryState>(
    'save emits error when nothing to save',
    build: buildBloc,
    seed: () => JournalAddEntryState.initial().copyWith(
      status: const JournalAddEntryIdle(),
      selectedDayLocal: DateTime(2025, 1, 14),
    ),
    act: (bloc) => bloc.add(const JournalAddEntrySaveRequested()),
    expect: () => [
      isA<JournalAddEntryState>().having(
        (s) => s.status,
        'status',
        isA<JournalAddEntryError>().having(
          (s) => s.message,
          'message',
          'Nothing to save.',
        ),
      ),
    ],
    verify: (_) {
      verifyNever(
        () => repository.upsertJournalEntry(
          any(),
          context: any(named: 'context'),
        ),
      );
    },
  );

  blocTestSafe<JournalAddEntryBloc, JournalAddEntryState>(
    'save emits error when mood missing',
    build: buildBloc,
    seed: () => JournalAddEntryState.initial().copyWith(
      status: const JournalAddEntryIdle(),
      selectedDayLocal: DateTime(2025, 1, 14),
      note: 'Note',
    ),
    act: (bloc) => bloc.add(const JournalAddEntrySaveRequested()),
    expect: () => [
      isA<JournalAddEntryState>().having(
        (s) => s.status,
        'status',
        isA<JournalAddEntryError>().having(
          (s) => s.message,
          'message',
          'Please choose a mood.',
        ),
      ),
    ],
  );

  blocTestSafe<JournalAddEntryBloc, JournalAddEntryState>(
    'save persists entry and tracker events with context',
    build: buildBloc,
    seed: () => JournalAddEntryState.initial().copyWith(
      status: const JournalAddEntryIdle(),
      selectedDayLocal: DateTime(2025, 1, 14),
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
    act: (bloc) => bloc.add(const JournalAddEntrySaveRequested()),
    expect: () => [
      isA<JournalAddEntryState>().having(
        (s) => s.status,
        'status',
        isA<JournalAddEntrySaving>(),
      ),
      isA<JournalAddEntryState>().having(
        (s) => s.status,
        'status',
        isA<JournalAddEntrySaved>(),
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
      expect(ctx.screen, 'add_entry_sheet');
      expect(ctx.intent, 'save');
      expect(ctx.operation, 'journal.add_entry.save');
      expect(ctx.correlationId, isNotEmpty);
      for (final forwarded in captured.whereType<OperationContext>().skip(1)) {
        expect(forwarded.correlationId, ctx.correlationId);
      }
    },
  );
}
