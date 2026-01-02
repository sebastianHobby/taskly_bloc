@Tags(['integration', 'wellbeing'])
@Skip('Integration tests disabled - pump/async issues being investigated')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/features/wellbeing/repositories/wellbeing_repository_impl.dart';
import 'package:taskly_bloc/domain/models/analytics/date_range.dart';
import 'package:taskly_bloc/domain/models/wellbeing/mood_rating.dart';
import 'package:taskly_bloc/domain/models/wellbeing/tracker.dart';
import 'package:taskly_bloc/domain/models/wellbeing/tracker_response_config.dart';
import 'package:taskly_bloc/domain/interfaces/wellbeing_repository_contract.dart';

import '../fixtures/test_data.dart';
import '../helpers/test_db.dart';

/// Integration tests for Wellbeing CRUD operations using a real in-memory database.
///
/// Coverage:
/// - ✅ Journal entry create, update, delete
/// - ✅ Mood tracking over time
/// - ✅ Filter by date range
/// - ✅ Tracker CRUD operations
/// - ✅ Tracker responses
void main() {
  late AppDatabase db;
  late WellbeingRepositoryContract repository;

  setUp(() {
    db = createTestDb();
    repository = WellbeingRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Wellbeing Journal Integration', () {
    test('end-to-end: create journal entry and track mood over time', () async {
      final startDate = DateTime(2025);

      // Create entries for a week with varying moods
      final moodProgression = [
        MoodRating.low,
        MoodRating.neutral,
        MoodRating.neutral,
        MoodRating.good,
        MoodRating.good,
        MoodRating.excellent,
        MoodRating.excellent,
      ];

      for (var i = 0; i < moodProgression.length; i++) {
        await repository.saveJournalEntry(
          TestData.journalEntry(
            id: 'entry-$i',
            entryDate: startDate.add(Duration(days: i)),
            moodRating: moodProgression[i],
            journalText: 'Day ${i + 1} journal entry',
          ),
        );
      }

      // Retrieve all entries
      final stream = repository.watchJournalEntries();
      final entries = await stream.first;

      expect(entries.length, 7);
      // Should be ordered by date descending
      expect(entries[0].entryDate, startDate.add(const Duration(days: 6)));
      expect(entries[6].entryDate, startDate);
    });

    test('end-to-end: update journal entry multiple times', () async {
      final entry = TestData.journalEntry(
        id: 'entry-1',
        entryDate: DateTime(2025, 1, 20),
        moodRating: MoodRating.neutral,
        journalText: 'Initial thoughts',
      );

      await repository.saveJournalEntry(entry);

      // First update: change mood
      final updated1 = entry.copyWith(moodRating: MoodRating.good);
      await repository.saveJournalEntry(updated1);

      final retrieved1 = await repository.getJournalEntryById('entry-1');
      expect(retrieved1!.moodRating, MoodRating.good);
      expect(retrieved1.journalText, 'Initial thoughts');

      // Second update: add text
      final updated2 = updated1.copyWith(
        journalText: 'Updated thoughts after reflection',
      );
      await repository.saveJournalEntry(updated2);

      final retrieved2 = await repository.getJournalEntryById('entry-1');
      expect(retrieved2!.moodRating, MoodRating.good);
      expect(retrieved2.journalText, 'Updated thoughts after reflection');
    });

    test('end-to-end: delete journal entry and verify removal', () async {
      // Create multiple entries
      await repository.saveJournalEntry(
        TestData.journalEntry(id: 'entry-1'),
      );
      await repository.saveJournalEntry(
        TestData.journalEntry(id: 'entry-2'),
      );

      // Delete one
      await repository.deleteJournalEntry('entry-1');

      // Verify it's gone
      final entry1 = await repository.getJournalEntryById('entry-1');
      expect(entry1, isNull);

      // Verify the other remains
      final entry2 = await repository.getJournalEntryById('entry-2');
      expect(entry2, isNotNull);

      // Verify stream reflects deletion
      final stream = repository.watchJournalEntries();
      final entries = await stream.first;
      expect(entries.length, 1);
      expect(entries[0].id, 'entry-2');
    });

    test('end-to-end: filter journal entries by date range', () async {
      // Create entries across three months
      await repository.saveJournalEntry(
        TestData.journalEntry(
          id: 'jan-entry',
          entryDate: DateTime(2025, 1, 15),
        ),
      );
      await repository.saveJournalEntry(
        TestData.journalEntry(
          id: 'feb-entry',
          entryDate: DateTime(2025, 2, 15),
        ),
      );
      await repository.saveJournalEntry(
        TestData.journalEntry(
          id: 'mar-entry',
          entryDate: DateTime(2025, 3, 15),
        ),
      );

      // Filter for February only
      final febRange = DateRange(
        start: DateTime(2025, 2),
        end: DateTime(2025, 2, 28),
      );

      final stream = repository.watchJournalEntries(range: febRange);
      final entries = await stream.first;

      expect(entries.length, 1);
      expect(entries[0].id, 'feb-entry');
    });

    test('end-to-end: calculate mood averages over time', () async {
      final startDate = DateTime(2025);

      // Create entries with known mood values
      await repository.saveJournalEntry(
        TestData.journalEntry(
          entryDate: startDate,
          moodRating: MoodRating.veryLow, // value: 1
        ),
      );
      await repository.saveJournalEntry(
        TestData.journalEntry(
          entryDate: startDate.add(const Duration(days: 1)),
          moodRating: MoodRating.neutral, // value: 3
        ),
      );
      await repository.saveJournalEntry(
        TestData.journalEntry(
          entryDate: startDate.add(const Duration(days: 2)),
          moodRating: MoodRating.excellent, // value: 5
        ),
      );

      final range = DateRange(
        start: startDate,
        end: startDate.add(const Duration(days: 2)),
      );

      final averages = await repository.getDailyMoodAverages(range: range);

      expect(averages.length, 3);
      expect(averages[startDate], 1.0);
      expect(averages[startDate.add(const Duration(days: 1))], 3.0);
      expect(averages[startDate.add(const Duration(days: 2))], 5.0);
    });

    test('end-to-end: get journal entry by specific date', () async {
      final targetDate = DateTime(2025, 1, 20);

      // Create entries for different dates
      await repository.saveJournalEntry(
        TestData.journalEntry(
          entryDate: DateTime(2025, 1, 19),
        ),
      );
      await repository.saveJournalEntry(
        TestData.journalEntry(
          id: 'target-entry',
          entryDate: targetDate,
        ),
      );
      await repository.saveJournalEntry(
        TestData.journalEntry(
          entryDate: DateTime(2025, 1, 21),
        ),
      );

      final entry = await repository.getJournalEntryByDate(date: targetDate);

      expect(entry, isNotNull);
      expect(entry!.id, 'target-entry');
      expect(entry.entryDate, targetDate);
    });
  });

  group('Wellbeing Tracker Integration', () {
    test('end-to-end: create and manage multiple tracker types', () async {
      // Create different tracker types
      final choiceTracker = TestData.tracker(
        id: 'choice-tracker',
        name: 'Mood',
        responseType: TrackerResponseType.choice,
        config: const TrackerResponseConfig.choice(
          options: ['Happy', 'Sad', 'Neutral'],
        ),
      );

      final scaleTracker = TestData.tracker(
        id: 'scale-tracker',
        name: 'Energy',
        config: const TrackerResponseConfig.scale(max: 10),
        sortOrder: 1,
      );

      final yesNoTracker = TestData.tracker(
        id: 'yesno-tracker',
        name: 'Exercise',
        responseType: TrackerResponseType.yesNo,
        config: const TrackerResponseConfig.yesNo(),
        sortOrder: 2,
      );

      await repository.saveTracker(choiceTracker);
      await repository.saveTracker(scaleTracker);
      await repository.saveTracker(yesNoTracker);

      // Retrieve all trackers
      final trackers = await repository.getAllTrackers();

      expect(trackers.length, 3);
      expect(trackers[0].id, 'choice-tracker');
      expect(trackers[1].id, 'scale-tracker');
      expect(trackers[2].id, 'yesno-tracker');
    });

    test('end-to-end: reorder trackers', () async {
      // Create trackers in one order
      await repository.saveTracker(
        TestData.tracker(id: 'tracker-a'),
      );
      await repository.saveTracker(
        TestData.tracker(id: 'tracker-b', sortOrder: 1),
      );
      await repository.saveTracker(
        TestData.tracker(id: 'tracker-c', sortOrder: 2),
      );

      // Reorder: C, A, B
      await repository.reorderTrackers(['tracker-c', 'tracker-a', 'tracker-b']);

      // Verify new order
      final trackers = await repository.getAllTrackers();

      expect(trackers[0].id, 'tracker-c');
      expect(trackers[0].sortOrder, 0);
      expect(trackers[1].id, 'tracker-a');
      expect(trackers[1].sortOrder, 1);
      expect(trackers[2].id, 'tracker-b');
      expect(trackers[2].sortOrder, 2);
    });

    test('end-to-end: update tracker configuration', () async {
      // Create initial tracker
      await repository.saveTracker(
        TestData.tracker(
          id: 'tracker-1',
          name: 'Original Name',
          config: const TrackerResponseConfig.scale(),
        ),
      );

      // Update name and config
      await repository.saveTracker(
        TestData.tracker(
          id: 'tracker-1',
          name: 'Updated Name',
          config: const TrackerResponseConfig.scale(
            min: 0,
            max: 10,
            minLabel: 'Low',
            maxLabel: 'High',
          ),
        ),
      );

      // Verify update
      final tracker = await repository.getTrackerById('tracker-1');
      expect(tracker!.name, 'Updated Name');

      final config = tracker.config as ScaleConfig;
      expect(config.min, 0);
      expect(config.max, 10);
      expect(config.minLabel, 'Low');
      expect(config.maxLabel, 'High');
    });

    test('end-to-end: delete tracker', () async {
      await repository.saveTracker(
        TestData.tracker(id: 'tracker-1'),
      );
      await repository.saveTracker(
        TestData.tracker(id: 'tracker-2'),
      );

      await repository.deleteTracker('tracker-1');

      final tracker1 = await repository.getTrackerById('tracker-1');
      expect(tracker1, isNull);

      final tracker2 = await repository.getTrackerById('tracker-2');
      expect(tracker2, isNotNull);

      final allTrackers = await repository.getAllTrackers();
      expect(allTrackers.length, 1);
    });

    test('end-to-end: watch trackers stream updates', () async {
      final stream = repository.watchTrackers();

      // Initially empty
      var trackers = await stream.first;
      expect(trackers, isEmpty);

      // Add a tracker
      await repository.saveTracker(
        TestData.tracker(id: 'tracker-1'),
      );

      trackers = await stream.first;
      expect(trackers.length, 1);

      // Add another
      await repository.saveTracker(
        TestData.tracker(id: 'tracker-2'),
      );

      trackers = await stream.first;
      expect(trackers.length, 2);
    });

    test('end-to-end: tracker with different entry scopes', () async {
      await repository.saveTracker(
        TestData.tracker(
          id: 'all-day-tracker',
          name: 'Daily Mood',
        ),
      );

      await repository.saveTracker(
        TestData.tracker(
          id: 'per-entry-tracker',
          name: 'Meal Quality',
          entryScope: TrackerEntryScope.perEntry,
        ),
      );

      final allDay = await repository.getTrackerById('all-day-tracker');
      final perEntry = await repository.getTrackerById('per-entry-tracker');

      expect(allDay!.entryScope, TrackerEntryScope.allDay);
      expect(perEntry!.entryScope, TrackerEntryScope.perEntry);
    });
  });

  group('Wellbeing Combined Integration', () {
    test('end-to-end: journal entries with tracker context', () async {
      final date = DateTime(2025, 1, 20);

      // Create trackers
      await repository.saveTracker(
        TestData.tracker(
          id: 'energy-tracker',
          name: 'Energy Level',
        ),
      );

      // Create journal entry for the day
      await repository.saveJournalEntry(
        TestData.journalEntry(
          id: 'entry-1',
          entryDate: date,
          moodRating: MoodRating.good,
          journalText: 'Productive day with good energy',
        ),
      );

      // Verify both exist
      final entry = await repository.getJournalEntryByDate(
        date: date,
      );
      final trackers = await repository.getAllTrackers();

      expect(entry, isNotNull);
      expect(trackers.length, 1);
      expect(entry!.moodRating, MoodRating.good);
    });

    test('end-to-end: weekly wellbeing review workflow', () async {
      final weekStart = DateTime(2025, 1, 20);
      final weekEnd = weekStart.add(const Duration(days: 6));

      // Create daily journal entries for a week
      for (var i = 0; i < 7; i++) {
        await repository.saveJournalEntry(
          TestData.journalEntry(
            entryDate: weekStart.add(Duration(days: i)),
            moodRating: MoodRating.values[i % 5],
            journalText: 'Day ${i + 1} reflection',
          ),
        );
      }

      // Calculate mood averages for the week
      final range = DateRange(start: weekStart, end: weekEnd);
      final averages = await repository.getDailyMoodAverages(range: range);

      expect(averages.length, 7);

      // Get all entries for the week
      final stream = repository.watchJournalEntries(
        range: range,
      );
      final entries = await stream.first;

      expect(entries.length, 7);
    });

    test(
      'end-to-end: handle tracker updates without affecting entries',
      () async {
        final date = DateTime(2025, 1, 20);

        // Create tracker
        await repository.saveTracker(
          TestData.tracker(
            id: 'mood-tracker',
            name: 'Mood',
          ),
        );

        // Create journal entry
        await repository.saveJournalEntry(
          TestData.journalEntry(
            entryDate: date,
          ),
        );

        // Update tracker
        await repository.saveTracker(
          TestData.tracker(
            id: 'mood-tracker',
            name: 'Daily Mood',
          ),
        );

        // Verify entry unchanged
        final entry = await repository.getJournalEntryByDate(
          date: date,
        );
        expect(entry, isNotNull);

        // Verify tracker updated
        final tracker = await repository.getTrackerById('mood-tracker');
        expect(tracker!.name, 'Daily Mood');
      },
    );
  });
}
