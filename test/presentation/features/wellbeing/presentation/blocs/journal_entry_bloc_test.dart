@Tags(['unit', 'wellbeing'])
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/domain/models/wellbeing/daily_tracker_response.dart';
import 'package:taskly_bloc/domain/models/wellbeing/journal_entry.dart';
import 'package:taskly_bloc/domain/models/wellbeing/mood_rating.dart';
import 'package:taskly_bloc/domain/models/wellbeing/tracker_response.dart';
import 'package:taskly_bloc/domain/interfaces/wellbeing_repository_contract.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/bloc/journal_entry/journal_entry_bloc.dart';

import '../../../../../helpers/custom_matchers.dart';
import '../../../../../helpers/fallback_values.dart';

class MockWellbeingRepositoryContract extends Mock implements WellbeingRepositoryContract {}

/// Tests for [JournalEntryBloc] covering journal entry operations.
///
/// Coverage:
/// - ✅ Initial state
/// - ✅ Load by ID
/// - ✅ Load by date
/// - ✅ Save entries
/// - ✅ Delete entries
/// - ✅ Daily tracker responses
/// - ✅ Error handling
void main() {
  late MockWellbeingRepositoryContract repository;
  late JournalEntryBloc bloc;

  setUpAll(registerAllFallbackValues);

  final testDate = DateTime(2025, 12, 27);
  final testEntry = JournalEntry(
    id: 'entry-1',
    entryDate: testDate,
    entryTime: testDate,
    moodRating: MoodRating.excellent,
    journalText: 'Great day!',
    createdAt: testDate,
    updatedAt: testDate,
  );

  setUp(() {
    repository = MockWellbeingRepositoryContract();
    bloc = JournalEntryBloc(repository);
  });

  tearDown(() {
    bloc.close();
  });

  group('JournalEntryBloc', () {
    test('initial state is initial', () {
      expect(bloc.state, isInitialState());
    });

    group('load event', () {
      blocTest<JournalEntryBloc, JournalEntryState>(
        'emits [loading, loaded] when entry is found',
        build: () {
          when(
            () => repository.getJournalEntryById('entry-1'),
          ).thenAnswer((_) async => testEntry);
          return bloc;
        },
        act: (bloc) => bloc.add(const JournalEntryEvent.load('entry-1')),
        expect: () => [
          isLoadingState(),
          JournalEntryState.loaded(testEntry),
        ],
        verify: (_) {
          verify(() => repository.getJournalEntryById('entry-1')).called(1);
        },
      );

      blocTest<JournalEntryBloc, JournalEntryState>(
        'emits [loading, loaded(null)] when entry is not found',
        build: () {
          when(
            () => repository.getJournalEntryById('non-existent'),
          ).thenAnswer((_) async => null);
          return bloc;
        },
        act: (bloc) => bloc.add(const JournalEntryEvent.load('non-existent')),
        expect: () => [
          isLoadingState(),
          const JournalEntryState.loaded(null),
        ],
      );

      blocTest<JournalEntryBloc, JournalEntryState>(
        'emits [loading, error] when repository throws',
        build: () {
          when(
            () => repository.getJournalEntryById(any()),
          ).thenThrow(Exception('Database error'));
          return bloc;
        },
        act: (bloc) => bloc.add(const JournalEntryEvent.load('entry-1')),
        expect: () => [
          isLoadingState(),
          isErrorState(),
        ],
      );
    });

    group('loadByDate event', () {
      blocTest<JournalEntryBloc, JournalEntryState>(
        'emits [loading, loaded] when entry is found for date',
        build: () {
          when(
            () => repository.getJournalEntryByDate(date: testDate),
          ).thenAnswer((_) async => testEntry);
          return bloc;
        },
        act: (bloc) => bloc.add(JournalEntryEvent.loadByDate(date: testDate)),
        expect: () => [
          isLoadingState(),
          JournalEntryState.loaded(testEntry),
        ],
        verify: (_) {
          verify(
            () => repository.getJournalEntryByDate(date: testDate),
          ).called(1);
        },
      );

      blocTest<JournalEntryBloc, JournalEntryState>(
        'emits [loading, loaded(null)] when no entry exists for date',
        build: () {
          when(
            () => repository.getJournalEntryByDate(date: testDate),
          ).thenAnswer((_) async => null);
          return bloc;
        },
        act: (bloc) => bloc.add(JournalEntryEvent.loadByDate(date: testDate)),
        expect: () => [
          isLoadingState(),
          const JournalEntryState.loaded(null),
        ],
      );

      blocTest<JournalEntryBloc, JournalEntryState>(
        'emits [loading, error] when repository throws',
        build: () {
          when(
            () => repository.getJournalEntryByDate(date: any(named: 'date')),
          ).thenThrow(Exception('Query failed'));
          return bloc;
        },
        act: (bloc) => bloc.add(JournalEntryEvent.loadByDate(date: testDate)),
        expect: () => [
          isLoadingState(),
          isErrorState(),
        ],
      );
    });

    group('save event', () {
      blocTest<JournalEntryBloc, JournalEntryState>(
        'emits [loading, saved] when save succeeds',
        build: () {
          when(
            () => repository.saveJournalEntry(testEntry),
          ).thenAnswer((_) async {});
          return bloc;
        },
        act: (bloc) => bloc.add(JournalEntryEvent.save(testEntry)),
        expect: () => [
          isLoadingState(),
          const JournalEntryState.saved(),
        ],
        verify: (_) {
          verify(() => repository.saveJournalEntry(testEntry)).called(1);
        },
      );

      blocTest<JournalEntryBloc, JournalEntryState>(
        'emits [loading, error] when save fails',
        build: () {
          when(
            () => repository.saveJournalEntry(any()),
          ).thenThrow(Exception('Save failed'));
          return bloc;
        },
        act: (bloc) => bloc.add(JournalEntryEvent.save(testEntry)),
        expect: () => [
          isLoadingState(),
          isErrorState(),
        ],
      );
    });

    group('delete event', () {
      blocTest<JournalEntryBloc, JournalEntryState>(
        'emits [loading, saved] when delete succeeds',
        build: () {
          when(
            () => repository.deleteJournalEntry('entry-1'),
          ).thenAnswer((_) async {});
          return bloc;
        },
        act: (bloc) => bloc.add(const JournalEntryEvent.delete('entry-1')),
        expect: () => [
          isLoadingState(),
          const JournalEntryState.saved(),
        ],
        verify: (_) {
          verify(() => repository.deleteJournalEntry('entry-1')).called(1);
        },
      );

      blocTest<JournalEntryBloc, JournalEntryState>(
        'emits [loading, error] when delete fails',
        build: () {
          when(
            () => repository.deleteJournalEntry(any()),
          ).thenThrow(Exception('Delete failed'));
          return bloc;
        },
        act: (bloc) => bloc.add(const JournalEntryEvent.delete('entry-1')),
        expect: () => [
          isLoadingState(),
          isErrorState(),
        ],
      );
    });

    group('state transitions', () {
      blocTest<JournalEntryBloc, JournalEntryState>(
        'can perform multiple operations in sequence',
        build: () {
          when(
            () => repository.getJournalEntryById('entry-1'),
          ).thenAnswer((_) async => testEntry);
          when(
            () => repository.saveJournalEntry(any()),
          ).thenAnswer((_) async {});
          return bloc;
        },
        act: (bloc) async {
          bloc.add(const JournalEntryEvent.load('entry-1'));
          await bloc.stream.first;
          await bloc.stream.first;
          bloc.add(JournalEntryEvent.save(testEntry));
        },
        expect: () => [
          isLoadingState(),
          JournalEntryState.loaded(testEntry),
          isLoadingState(),
          const JournalEntryState.saved(),
        ],
      );
    });

    group('loadEntriesForDate event (multiple entries per day)', () {
      final dailyResponse = DailyTrackerResponse(
        id: 'daily-1',
        responseDate: testDate,
        trackerId: 'tracker-1',
        value: const YesNoValue(value: true),
        createdAt: testDate,
        updatedAt: testDate,
      );

      blocTest<JournalEntryBloc, JournalEntryState>(
        'emits [loading, entriesLoaded] with entries and daily responses',
        build: () {
          when(
            () => repository.getJournalEntriesByDate(date: any(named: 'date')),
          ).thenAnswer((_) async => [testEntry]);
          when(
            () => repository.getDailyTrackerResponses(date: any(named: 'date')),
          ).thenAnswer((_) async => [dailyResponse]);
          return bloc;
        },
        act: (bloc) =>
            bloc.add(JournalEntryEvent.loadEntriesForDate(date: testDate)),
        expect: () => [
          isLoadingState(),
          JournalEntryState.entriesLoaded(
            entries: [testEntry],
            dailyResponses: [dailyResponse],
            date: testDate,
          ),
        ],
        verify: (_) {
          verify(
            () => repository.getJournalEntriesByDate(date: testDate),
          ).called(1);
          verify(
            () => repository.getDailyTrackerResponses(date: testDate),
          ).called(1);
        },
      );

      blocTest<JournalEntryBloc, JournalEntryState>(
        'emits [loading, entriesLoaded] with empty lists when no data',
        build: () {
          when(
            () => repository.getJournalEntriesByDate(date: any(named: 'date')),
          ).thenAnswer((_) async => []);
          when(
            () => repository.getDailyTrackerResponses(date: any(named: 'date')),
          ).thenAnswer((_) async => []);
          return bloc;
        },
        act: (bloc) =>
            bloc.add(JournalEntryEvent.loadEntriesForDate(date: testDate)),
        expect: () => [
          isLoadingState(),
          JournalEntryState.entriesLoaded(
            entries: const [],
            dailyResponses: const [],
            date: testDate,
          ),
        ],
      );

      blocTest<JournalEntryBloc, JournalEntryState>(
        'emits [loading, error] when repository throws',
        build: () {
          when(
            () => repository.getJournalEntriesByDate(date: any(named: 'date')),
          ).thenThrow(Exception('Query failed'));
          when(
            () => repository.getDailyTrackerResponses(date: any(named: 'date')),
          ).thenAnswer((_) async => []);
          return bloc;
        },
        act: (bloc) =>
            bloc.add(JournalEntryEvent.loadEntriesForDate(date: testDate)),
        expect: () => [
          isLoadingState(),
          isErrorState(),
        ],
      );
    });

    group('saveWithDailyResponses event', () {
      final dailyResponse = DailyTrackerResponse(
        id: 'daily-1',
        responseDate: testDate,
        trackerId: 'tracker-1',
        value: const YesNoValue(value: true),
        createdAt: testDate,
        updatedAt: testDate,
      );

      blocTest<JournalEntryBloc, JournalEntryState>(
        'emits [loading, saved] when save succeeds',
        build: () {
          when(
            () => repository.saveJournalEntry(any()),
          ).thenAnswer((_) async {});
          when(
            () => repository.saveDailyTrackerResponse(any()),
          ).thenAnswer((_) async {});
          return bloc;
        },
        act: (bloc) => bloc.add(
          JournalEntryEvent.saveWithDailyResponses(
            entry: testEntry,
            dailyResponses: [dailyResponse],
          ),
        ),
        expect: () => [
          isLoadingState(),
          const JournalEntryState.saved(),
        ],
        verify: (_) {
          verify(() => repository.saveJournalEntry(testEntry)).called(1);
          verify(
            () => repository.saveDailyTrackerResponse(dailyResponse),
          ).called(1);
        },
      );

      blocTest<JournalEntryBloc, JournalEntryState>(
        'saves multiple daily responses',
        build: () {
          when(
            () => repository.saveJournalEntry(any()),
          ).thenAnswer((_) async {});
          when(
            () => repository.saveDailyTrackerResponse(any()),
          ).thenAnswer((_) async {});
          return bloc;
        },
        act: (bloc) => bloc.add(
          JournalEntryEvent.saveWithDailyResponses(
            entry: testEntry,
            dailyResponses: [
              dailyResponse,
              dailyResponse.copyWith(
                id: 'daily-2',
                trackerId: 'tracker-2',
              ),
            ],
          ),
        ),
        expect: () => [
          isLoadingState(),
          const JournalEntryState.saved(),
        ],
        verify: (_) {
          verify(
            () => repository.saveDailyTrackerResponse(any()),
          ).called(2);
        },
      );

      blocTest<JournalEntryBloc, JournalEntryState>(
        'emits [loading, error] when journal entry save fails',
        build: () {
          when(
            () => repository.saveJournalEntry(any()),
          ).thenThrow(Exception('Save failed'));
          return bloc;
        },
        act: (bloc) => bloc.add(
          JournalEntryEvent.saveWithDailyResponses(
            entry: testEntry,
            dailyResponses: [dailyResponse],
          ),
        ),
        expect: () => [
          isLoadingState(),
          isErrorState(),
        ],
      );

      blocTest<JournalEntryBloc, JournalEntryState>(
        'emits [loading, error] when daily response save fails',
        build: () {
          when(
            () => repository.saveJournalEntry(any()),
          ).thenAnswer((_) async {});
          when(
            () => repository.saveDailyTrackerResponse(any()),
          ).thenThrow(Exception('Daily save failed'));
          return bloc;
        },
        act: (bloc) => bloc.add(
          JournalEntryEvent.saveWithDailyResponses(
            entry: testEntry,
            dailyResponses: [dailyResponse],
          ),
        ),
        expect: () => [
          isLoadingState(),
          isErrorState(),
        ],
      );
    });
  });
}
