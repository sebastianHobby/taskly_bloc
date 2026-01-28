@Tags(['unit', 'journal'])
library;

import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_imports.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_history_bloc.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/time.dart';

class MockJournalRepository extends Mock implements JournalRepositoryContract {}

class MockHomeDayKeyService extends Mock implements HomeDayKeyService {}

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  late MockJournalRepository repository;
  late MockHomeDayKeyService dayKeyService;
  late TestStreamController<List<TrackerDefinition>> defsController;
  late TestStreamController<List<JournalEntry>> entriesController;
  late TestStreamController<List<TrackerStateDay>> dayStateController;
  late TestStreamController<List<TrackerEvent>> eventsController;

  setUp(() {
    repository = MockJournalRepository();
    dayKeyService = MockHomeDayKeyService();

    defsController = TestStreamController.seeded(<TrackerDefinition>[]);
    entriesController = TestStreamController.seeded(<JournalEntry>[]);
    dayStateController = TestStreamController.seeded(<TrackerStateDay>[]);
    eventsController = TestStreamController.seeded(<TrackerEvent>[]);

    when(
      () => repository.watchTrackerDefinitions(),
    ).thenAnswer((_) => defsController.stream);
    when(
      () => repository.watchJournalEntriesByQuery(any()),
    ).thenAnswer((_) => entriesController.stream);
    when(
      () => repository.watchTrackerStateDay(range: any(named: 'range')),
    ).thenAnswer((_) => dayStateController.stream);
    when(
      () => repository.watchTrackerEvents(
        range: any(named: 'range'),
        anchorType: any(named: 'anchorType'),
      ),
    ).thenAnswer((_) => eventsController.stream);

    when(
      () => dayKeyService.todayDayKeyUtc(),
    ).thenReturn(DateTime.utc(2026, 1, 28));
  });

  tearDown(() async {
    await defsController.close();
    await entriesController.close();
    await dayStateController.close();
    await eventsController.close();
  });

  blocTestSafe<JournalHistoryBloc, JournalHistoryState>(
    'filters days by mood minimum',
    build: () => JournalHistoryBloc(
      repository: repository,
      dayKeyService: dayKeyService,
    ),
    act: (bloc) {
      final moodTracker = TrackerDefinition(
        id: 'mood-1',
        name: 'Mood',
        scope: 'entry',
        valueType: 'rating',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
        valueKind: 'rating',
        opKind: 'set',
        isActive: true,
        isOutcome: true,
        systemKey: 'mood',
      );

      defsController.emit([moodTracker]);

      final day1 = DateTime.utc(2026, 1, 10);
      final day2 = DateTime.utc(2026, 1, 11);

      entriesController.emit([
        JournalEntry(
          id: 'e1',
          entryDate: day1,
          entryTime: day1,
          occurredAt: day1,
          localDate: day1,
          createdAt: day1,
          updatedAt: day1,
        ),
        JournalEntry(
          id: 'e2',
          entryDate: day2,
          entryTime: day2,
          occurredAt: day2,
          localDate: day2,
          createdAt: day2,
          updatedAt: day2,
        ),
      ]);

      eventsController.emit([
        TrackerEvent(
          id: 'ev1',
          trackerId: 'mood-1',
          anchorType: 'entry',
          entryId: 'e1',
          op: 'set',
          value: 2,
          occurredAt: day1,
          recordedAt: day1,
        ),
        TrackerEvent(
          id: 'ev2',
          trackerId: 'mood-1',
          anchorType: 'entry',
          entryId: 'e2',
          op: 'set',
          value: 5,
          occurredAt: day2,
          recordedAt: day2,
        ),
      ]);

      bloc.add(
        JournalHistoryFiltersChanged(
          JournalHistoryFilters.initial().copyWith(moodMinValue: 4),
        ),
      );
    },
    verify: (bloc) {
      expect(
        bloc.state,
        isA<JournalHistoryLoaded>()
            .having((s) => s.days.length, 'days.length', 1)
            .having(
              (s) => s.filters.moodMinValue,
              'filters.moodMinValue',
              4,
            ),
      );
    },
  );
}
