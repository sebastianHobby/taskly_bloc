@Tags(['unit', 'repository', 'wellbeing'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/features/wellbeing/repositories/wellbeing_repository_impl.dart';
import 'package:taskly_bloc/domain/models/analytics/date_range.dart';
import 'package:taskly_bloc/domain/models/wellbeing/mood_rating.dart';
import 'package:taskly_bloc/domain/models/wellbeing/tracker.dart';
import 'package:taskly_bloc/domain/models/wellbeing/tracker_response.dart';
import 'package:taskly_bloc/domain/interfaces/wellbeing_repository_contract.dart';

import '../../../../../fixtures/test_data.dart';
import '../../../../../helpers/test_db.dart';

/// Tests for [WellbeingRepositoryImpl] journal entry operations.
///
/// Coverage:
/// - ✅ Save new journal entry
/// - ✅ Update existing entry
/// - ✅ Delete entry
/// - ✅ Query by date
/// - ✅ Query by date range
/// - ✅ Stream watching
void main() {
  late AppDatabase db;
  late WellbeingRepositoryContract repository;

  setUp(() async {
    db = createTestDb();
    repository = WellbeingRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('WellbeingRepositoryContract - Journal Entries', () {
    test('saves new journal entry', () async {
      final entry = TestData.journalEntry(
        id: 'entry-1',
        entryDate: DateTime(2025, 1, 20),
        moodRating: MoodRating.good,
        journalText: 'Today was a good day!',
      );

      await repository.saveJournalEntry(entry);

      final retrieved = await repository.getJournalEntryById('entry-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'entry-1');
      expect(retrieved.moodRating, MoodRating.good);
      expect(retrieved.journalText, 'Today was a good day!');
    });

    test('updates existing journal entry', () async {
      final entry = TestData.journalEntry(
        id: 'entry-1',
        journalText: 'Original text',
      );

      await repository.saveJournalEntry(entry);

      final updated = entry.copyWith(
        journalText: 'Updated text',
        moodRating: MoodRating.excellent,
      );

      await repository.saveJournalEntry(updated);

      final retrieved = await repository.getJournalEntryById('entry-1');
      expect(retrieved!.journalText, 'Updated text');
      expect(retrieved.moodRating, MoodRating.excellent);
    });

    test('getJournalEntryById returns null for non-existent entry', () async {
      final result = await repository.getJournalEntryById('non-existent');
      expect(result, isNull);
    });

    test('getJournalEntryByDate retrieves entry by date', () async {
      final date = DateTime(2025, 1, 20);
      final entry = TestData.journalEntry(
        id: 'entry-1',
        entryDate: date,
        journalText: 'Entry for Jan 20',
      );

      await repository.saveJournalEntry(entry);

      final retrieved = await repository.getJournalEntryByDate(date: date);

      expect(retrieved, isNotNull);
      expect(retrieved!.entryDate, date);
      expect(retrieved.journalText, 'Entry for Jan 20');
    });

    test('getJournalEntryByDate returns null when no entry for date', () async {
      final result = await repository.getJournalEntryByDate(
        date: DateTime(2025, 1, 20),
      );

      expect(result, isNull);
    });

    group('getJournalEntriesByDate (multiple entries per day)', () {
      test('returns all entries for a given date', () async {
        final date = DateTime(2025, 1, 20);
        final entry1 = TestData.journalEntry(
          id: 'entry-1',
          entryDate: date,
          entryTime: DateTime(2025, 1, 20, 9),
          moodRating: MoodRating.good,
        );
        final entry2 = TestData.journalEntry(
          id: 'entry-2',
          entryDate: date,
          entryTime: DateTime(2025, 1, 20, 14, 30),
          moodRating: MoodRating.excellent,
        );
        final entry3 = TestData.journalEntry(
          id: 'entry-3',
          entryDate: date,
          entryTime: DateTime(2025, 1, 20, 20),
          moodRating: MoodRating.neutral,
        );

        await repository.saveJournalEntry(entry1);
        await repository.saveJournalEntry(entry2);
        await repository.saveJournalEntry(entry3);

        final entries = await repository.getJournalEntriesByDate(date: date);

        expect(entries.length, 3);
      });

      test(
        'returns entries ordered by entryTime descending (newest first)',
        () async {
          final date = DateTime(2025, 1, 20);
          await repository.saveJournalEntry(
            TestData.journalEntry(
              id: 'morning',
              entryDate: date,
              entryTime: DateTime(2025, 1, 20, 8),
            ),
          );
          await repository.saveJournalEntry(
            TestData.journalEntry(
              id: 'evening',
              entryDate: date,
              entryTime: DateTime(2025, 1, 20, 20),
            ),
          );
          await repository.saveJournalEntry(
            TestData.journalEntry(
              id: 'afternoon',
              entryDate: date,
              entryTime: DateTime(2025, 1, 20, 14),
            ),
          );

          final entries = await repository.getJournalEntriesByDate(date: date);

          expect(entries[0].id, 'evening');
          expect(entries[1].id, 'afternoon');
          expect(entries[2].id, 'morning');
        },
      );

      test('returns empty list when no entries for date', () async {
        final entries = await repository.getJournalEntriesByDate(
          date: DateTime(2025, 1, 20),
        );

        expect(entries, isEmpty);
      });

      test('only returns entries for specified date', () async {
        await repository.saveJournalEntry(
          TestData.journalEntry(
            id: 'jan-20',
            entryDate: DateTime(2025, 1, 20),
          ),
        );
        await repository.saveJournalEntry(
          TestData.journalEntry(
            id: 'jan-21',
            entryDate: DateTime(2025, 1, 21),
          ),
        );

        final entries = await repository.getJournalEntriesByDate(
          date: DateTime(2025, 1, 20),
        );

        expect(entries.length, 1);
        expect(entries[0].id, 'jan-20');
      });

      test('includes tracker responses for each entry', () async {
        // First save a tracker
        final tracker = TestData.tracker(
          id: 'tracker-1',
          name: 'Exercise',
          responseType: TrackerResponseType.yesNo,
          entryScope: TrackerEntryScope.perEntry,
        );
        await repository.saveTracker(tracker);

        final date = DateTime(2025, 1, 20);
        final response = TrackerResponse(
          id: 'response-1',
          journalEntryId: 'entry-1',
          trackerId: 'tracker-1',
          value: const YesNoValue(value: true),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await repository.saveJournalEntry(
          TestData.journalEntry(
            id: 'entry-1',
            entryDate: date,
            trackerResponses: [response],
          ),
        );

        final entries = await repository.getJournalEntriesByDate(date: date);

        expect(entries.length, 1);
        expect(entries[0].perEntryTrackerResponses.length, 1);
        expect(entries[0].perEntryTrackerResponses[0].trackerId, 'tracker-1');
      });
    });

    test('deletes journal entry', () async {
      final entry = TestData.journalEntry(id: 'entry-1');
      await repository.saveJournalEntry(entry);

      await repository.deleteJournalEntry('entry-1');

      final result = await repository.getJournalEntryById('entry-1');
      expect(result, isNull);
    });

    test('watchJournalEntries returns stream of all entries', () async {
      final entry1 = TestData.journalEntry(
        id: 'entry-1',
        entryDate: DateTime(2025, 1, 20),
      );
      final entry2 = TestData.journalEntry(
        id: 'entry-2',
        entryDate: DateTime(2025, 1, 21),
      );

      await repository.saveJournalEntry(entry1);
      await repository.saveJournalEntry(entry2);

      final stream = repository.watchJournalEntries();
      final entries = await stream.first;

      expect(entries.length, 2);
      // Should be ordered by date descending
      expect(entries[0].entryDate, DateTime(2025, 1, 21));
      expect(entries[1].entryDate, DateTime(2025, 1, 20));
    });

    test('watchJournalEntries filters by date range', () async {
      await repository.saveJournalEntry(
        TestData.journalEntry(
          id: 'entry-1',
          entryDate: DateTime(2025, 1, 15),
        ),
      );
      await repository.saveJournalEntry(
        TestData.journalEntry(
          id: 'entry-2',
          entryDate: DateTime(2025, 1, 20),
        ),
      );
      await repository.saveJournalEntry(
        TestData.journalEntry(
          id: 'entry-3',
          entryDate: DateTime(2025, 1, 25),
        ),
      );

      final range = DateRange(
        start: DateTime(2025, 1, 18),
        end: DateTime(2025, 1, 22),
      );

      final stream = repository.watchJournalEntries(range: range);
      final entries = await stream.first;

      expect(entries.length, 1);
      expect(entries[0].id, 'entry-2');
    });

    test('saves journal entry with all mood ratings', () async {
      for (final mood in MoodRating.values) {
        final entry = TestData.journalEntry(
          id: 'entry-${mood.name}',
          entryDate: DateTime(2025, 1, mood.value),
          moodRating: mood,
        );

        await repository.saveJournalEntry(entry);

        final retrieved = await repository.getJournalEntryById(
          'entry-${mood.name}',
        );
        expect(retrieved!.moodRating, mood);
      }
    });

    test('saves journal entry with null mood rating', () async {
      final entry = TestData.journalEntry(
        id: 'entry-1',
        journalText: 'No mood today',
      );

      await repository.saveJournalEntry(entry);

      final retrieved = await repository.getJournalEntryById('entry-1');
      expect(retrieved!.moodRating, isNull);
      expect(retrieved.journalText, 'No mood today');
    });

    test('saves journal entry with null journal text', () async {
      final entry = TestData.journalEntry(
        id: 'entry-1',
        moodRating: MoodRating.good,
      );

      await repository.saveJournalEntry(entry);

      final retrieved = await repository.getJournalEntryById('entry-1');
      expect(retrieved!.moodRating, MoodRating.good);
      // Repository saves null as empty string in database
      expect(retrieved.journalText, anyOf(isNull, isEmpty));
    });

    test('saves journal entry with entry time', () async {
      final time = DateTime(2025, 1, 20, 14, 30);
      final entry = TestData.journalEntry(
        id: 'entry-1',
        entryTime: time,
      );

      await repository.saveJournalEntry(entry);

      final retrieved = await repository.getJournalEntryById('entry-1');
      expect(retrieved!.entryTime, time);
    });

    test('getDailyMoodAverages calculates averages in range', () async {
      await repository.saveJournalEntry(
        TestData.journalEntry(
          id: 'entry-1',
          entryDate: DateTime(2025, 1, 20),
          moodRating: MoodRating.good, // value: 4
        ),
      );
      await repository.saveJournalEntry(
        TestData.journalEntry(
          id: 'entry-2',
          entryDate: DateTime(2025, 1, 21),
          moodRating: MoodRating.excellent, // value: 5
        ),
      );
      await repository.saveJournalEntry(
        TestData.journalEntry(
          id: 'entry-3',
          entryDate: DateTime(2025, 1, 22),
          moodRating: MoodRating.neutral, // value: 3
        ),
      );

      final range = DateRange(
        start: DateTime(2025, 1, 20),
        end: DateTime(2025, 1, 22),
      );

      final averages = await repository.getDailyMoodAverages(range: range);

      expect(averages.length, 3);
      expect(averages[DateTime(2025, 1, 20)], 4.0);
      expect(averages[DateTime(2025, 1, 21)], 5.0);
      expect(averages[DateTime(2025, 1, 22)], 3.0);
    });

    test('getDailyMoodAverages excludes entries with null mood', () async {
      await repository.saveJournalEntry(
        TestData.journalEntry(
          id: 'entry-1',
          entryDate: DateTime(2025, 1, 20),
          moodRating: MoodRating.good,
        ),
      );
      await repository.saveJournalEntry(
        TestData.journalEntry(
          id: 'entry-2',
          entryDate: DateTime(2025, 1, 21),
        ),
      );

      final range = DateRange(
        start: DateTime(2025, 1, 20),
        end: DateTime(2025, 1, 21),
      );

      final averages = await repository.getDailyMoodAverages(range: range);

      expect(averages.length, 1);
      expect(averages[DateTime(2025, 1, 20)], 4.0);
      expect(averages.containsKey(DateTime(2025, 1, 21)), isFalse);
    });

    test(
      'getDailyMoodAverages returns empty map for range with no entries',
      () async {
        final range = DateRange(
          start: DateTime(2025, 1, 20),
          end: DateTime(2025, 1, 22),
        );

        final averages = await repository.getDailyMoodAverages(range: range);
        expect(averages, isEmpty);
      },
    );

    test(
      'multiple entries can exist for same user on different dates',
      () async {
        await repository.saveJournalEntry(
          TestData.journalEntry(
            id: 'entry-1',
            entryDate: DateTime(2025, 1, 20),
          ),
        );
        await repository.saveJournalEntry(
          TestData.journalEntry(
            id: 'entry-2',
            entryDate: DateTime(2025, 1, 21),
          ),
        );

        final stream = repository.watchJournalEntries();
        final entries = await stream.first;

        expect(entries.length, 2);
      },
    );

    test('saveJournalEntry with empty id generates new id', () async {
      final entry = TestData.journalEntry(
        id: '',
        journalText: 'Auto-generated ID',
      );

      await repository.saveJournalEntry(entry);

      final stream = repository.watchJournalEntries();
      final entries = await stream.first;

      expect(entries.length, 1);
      expect(entries[0].id, isNotEmpty);
      expect(entries[0].journalText, 'Auto-generated ID');
    });

    test('preserves createdAt when updating entry', () async {
      final createdAt = DateTime(2025, 1, 1, 10);
      await repository.saveJournalEntry(
        TestData.journalEntry(
          id: 'entry-1',
          createdAt: createdAt,
          journalText: 'Original',
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      await repository.saveJournalEntry(
        TestData.journalEntry(
          id: 'entry-1',
          createdAt: createdAt,
          journalText: 'Updated',
        ),
      );

      final retrieved = await repository.getJournalEntryById('entry-1');
      expect(retrieved!.createdAt, createdAt);
      expect(retrieved.journalText, 'Updated');
    });
  });
}
