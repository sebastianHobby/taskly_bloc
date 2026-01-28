@Tags(['unit', 'journal'])
library;

import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_imports.dart';
import '../../../../mocks/feature_mocks.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_today_bloc.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_domain/queries.dart';

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
    registerFallbackValue(
      DateRange(
        start: TestConstants.referenceDate,
        end: TestConstants.referenceDate,
      ),
    );
    registerFallbackValue(JournalQuery());
  });
  setUp(setUpTestEnvironment);

  late MockJournalRepositoryContract repository;
  late TestStreamController<List<TrackerDefinition>> defsController;
  late TestStreamController<List<JournalEntry>> entriesController;
  late TestStreamController<List<TrackerEvent>> eventsController;
  late TestStreamController<List<TrackerEvent>> weekEventsController;
  late TestStreamController<List<TrackerStateDay>> dayStateController;

  final day = DateTime.utc(2025, 1, 14);

  JournalTodayBloc buildBloc() {
    return JournalTodayBloc(repository: repository);
  }

  setUp(() {
    repository = MockJournalRepositoryContract();
    defsController = TestStreamController.seeded(const []);
    entriesController = TestStreamController.seeded(const []);
    eventsController = TestStreamController.seeded(const []);
    weekEventsController = TestStreamController.seeded(const []);
    dayStateController = TestStreamController.seeded(const []);

    when(() => repository.watchTrackerDefinitions()).thenAnswer(
      (_) => defsController.stream,
    );
    when(() => repository.watchJournalEntriesByQuery(any())).thenAnswer(
      (_) => entriesController.stream,
    );
    when(
      () => repository.watchTrackerEvents(
        range: any(named: 'range'),
        anchorType: any(named: 'anchorType'),
      ),
    ).thenAnswer((invocation) {
      final range = invocation.namedArguments[#range] as DateRange;
      if (range.start.isBefore(day)) {
        return weekEventsController.stream;
      }
      return eventsController.stream;
    });
    when(
      () => repository.watchTrackerStateDay(range: any(named: 'range')),
    ).thenAnswer((_) => dayStateController.stream);

    addTearDown(defsController.close);
    addTearDown(entriesController.close);
    addTearDown(eventsController.close);
    addTearDown(weekEventsController.close);
    addTearDown(dayStateController.close);
  });

  blocTestSafe<JournalTodayBloc, JournalTodayState>(
    'loads today data and computes mood summary',
    build: buildBloc,
    act: (bloc) {
      bloc.add(JournalTodayStarted(selectedDay: day));

      defsController.emit([
        TrackerDefinition(
          id: 'mood',
          name: 'Mood',
          scope: 'entry',
          valueType: 'int',
          systemKey: 'mood',
          createdAt: day,
          updatedAt: day,
        ),
      ]);
      entriesController.emit([
        JournalEntry(
          id: 'entry-1',
          entryDate: day,
          entryTime: day,
          occurredAt: day,
          localDate: day,
          createdAt: day,
          updatedAt: day,
          journalText: null,
          deletedAt: null,
        ),
      ]);
      eventsController.emit([
        TrackerEvent(
          id: 'e-1',
          trackerId: 'mood',
          anchorType: 'entry',
          entryId: 'entry-1',
          op: 'set',
          value: 4,
          occurredAt: day,
          recordedAt: day,
        ),
      ]);
      weekEventsController.emit([
        TrackerEvent(
          id: 'e-1',
          trackerId: 'mood',
          anchorType: 'entry',
          entryId: 'entry-1',
          op: 'set',
          value: 4,
          occurredAt: day,
          recordedAt: day,
        ),
      ]);
      dayStateController.emit(const []);
    },
    expect: () => [
      isA<JournalTodayLoaded>()
          .having((s) => s.entries.length, 'entries', 1)
          .having((s) => s.moodTrackerId, 'moodTrackerId', 'mood')
          .having((s) => s.moodAverage, 'moodAverage', 4.0)
          .having((s) => s.moodWeek.length, 'moodWeek', 7),
    ],
  );

  blocTestSafe<JournalTodayBloc, JournalTodayState>(
    'emits error when stream fails',
    build: buildBloc,
    act: (bloc) {
      bloc.add(JournalTodayStarted(selectedDay: day));
      eventsController.emitError(StateError('boom'));
    },
    expect: () => [
      isA<JournalTodayError>()
          .having((s) => s.message, 'message', contains('Failed to load')),
    ],
  );
}
