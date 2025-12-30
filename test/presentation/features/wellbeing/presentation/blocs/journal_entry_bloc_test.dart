import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/domain/models/wellbeing/journal_entry.dart';
import 'package:taskly_bloc/domain/models/wellbeing/mood_rating.dart';
import 'package:taskly_bloc/domain/repositories/wellbeing_repository.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/bloc/journal_entry/journal_entry_bloc.dart';

class MockWellbeingRepository extends Mock implements WellbeingRepository {}

void main() {
  late MockWellbeingRepository repository;
  late JournalEntryBloc bloc;

  setUpAll(() {
    final fallbackDate = DateTime(2000);
    registerFallbackValue(
      JournalEntry(
        id: 'fallback',
        entryDate: fallbackDate,
        entryTime: fallbackDate,
        createdAt: fallbackDate,
        updatedAt: fallbackDate,
      ),
    );
  });

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
    repository = MockWellbeingRepository();
    bloc = JournalEntryBloc(repository);
  });

  tearDown(() {
    bloc.close();
  });

  group('JournalEntryBloc', () {
    test('initial state is initial', () {
      expect(bloc.state, const JournalEntryState.initial());
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
          const JournalEntryState.loading(),
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
          const JournalEntryState.loading(),
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
          const JournalEntryState.loading(),
          const JournalEntryState.error('Exception: Database error'),
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
          const JournalEntryState.loading(),
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
          const JournalEntryState.loading(),
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
          const JournalEntryState.loading(),
          const JournalEntryState.error('Exception: Query failed'),
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
          const JournalEntryState.loading(),
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
          const JournalEntryState.loading(),
          const JournalEntryState.error('Exception: Save failed'),
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
          const JournalEntryState.loading(),
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
          const JournalEntryState.loading(),
          const JournalEntryState.error('Exception: Delete failed'),
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
          const JournalEntryState.loading(),
          JournalEntryState.loaded(testEntry),
          const JournalEntryState.loading(),
          const JournalEntryState.saved(),
        ],
      );
    });
  });
}
