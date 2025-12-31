@Tags(['unit', 'repository', 'wellbeing'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/features/wellbeing/repositories/wellbeing_repository_impl.dart';
import 'package:taskly_bloc/domain/models/wellbeing/tracker.dart';
import 'package:taskly_bloc/domain/models/wellbeing/tracker_response.dart';
import 'package:taskly_bloc/domain/models/wellbeing/tracker_response_config.dart';
import 'package:taskly_bloc/domain/interfaces/wellbeing_repository_contract.dart';

import '../../../../../fixtures/test_data.dart';
import '../../../../../helpers/test_db.dart';

/// Tests for [WellbeingRepositoryImpl] tracker operations.
///
/// Coverage:
/// - ✅ Save/update trackers
/// - ✅ Delete trackers
/// - ✅ Tracker response types (choice, scale, yes/no, text)
/// - ✅ Tracker ordering
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

  group('WellbeingRepositoryContract - Trackers', () {
    test('saves new tracker with choice config', () async {
      final tracker = TestData.tracker(
        id: 'tracker-1',
        name: 'Mood Tracker',
        responseType: TrackerResponseType.choice,
        config: const TrackerResponseConfig.choice(
          options: ['Happy', 'Sad', 'Neutral'],
        ),
      );

      await repository.saveTracker(tracker);

      final retrieved = await repository.getTrackerById('tracker-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Mood Tracker');
      expect(retrieved.responseType, TrackerResponseType.choice);

      final config = retrieved.config as ChoiceConfig;
      expect(config.options, ['Happy', 'Sad', 'Neutral']);
    });

    test('saves new tracker with scale config', () async {
      final tracker = TestData.tracker(
        id: 'tracker-1',
        name: 'Energy Level',
        config: const TrackerResponseConfig.scale(
          max: 10,
          minLabel: 'Low',
          maxLabel: 'High',
        ),
      );

      await repository.saveTracker(tracker);

      final retrieved = await repository.getTrackerById('tracker-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.responseType, TrackerResponseType.scale);

      final config = retrieved.config as ScaleConfig;
      expect(config.min, 1);
      expect(config.max, 10);
      expect(config.minLabel, 'Low');
      expect(config.maxLabel, 'High');
    });

    test('saves new tracker with yesNo config', () async {
      final tracker = TestData.tracker(
        id: 'tracker-1',
        name: 'Exercise Today?',
        responseType: TrackerResponseType.yesNo,
        config: const TrackerResponseConfig.yesNo(),
      );

      await repository.saveTracker(tracker);

      final retrieved = await repository.getTrackerById('tracker-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.responseType, TrackerResponseType.yesNo);
      expect(retrieved.config, isA<YesNoConfig>());
    });

    test('updates existing tracker', () async {
      final tracker = TestData.tracker(
        id: 'tracker-1',
        name: 'Original Name',
      );

      await repository.saveTracker(tracker);

      final updated = tracker.copyWith(
        name: 'Updated Name',
        description: 'New description',
      );

      await repository.saveTracker(updated);

      final retrieved = await repository.getTrackerById('tracker-1');
      expect(retrieved!.name, 'Updated Name');
      expect(retrieved.description, 'New description');
    });

    test('getTrackerById returns null for non-existent tracker', () async {
      final result = await repository.getTrackerById('non-existent');
      expect(result, isNull);
    });

    test('deletes tracker', () async {
      final tracker = TestData.tracker(id: 'tracker-1');
      await repository.saveTracker(tracker);

      await repository.deleteTracker('tracker-1');

      final result = await repository.getTrackerById('tracker-1');
      expect(result, isNull);
    });

    test('getAllTrackers returns all trackers ordered by sortOrder', () async {
      await repository.saveTracker(
        TestData.tracker(id: 'tracker-3', sortOrder: 2),
      );
      await repository.saveTracker(
        TestData.tracker(id: 'tracker-1'),
      );
      await repository.saveTracker(
        TestData.tracker(id: 'tracker-2', sortOrder: 1),
      );

      final trackers = await repository.getAllTrackers();

      expect(trackers.length, 3);
      expect(trackers[0].id, 'tracker-1');
      expect(trackers[1].id, 'tracker-2');
      expect(trackers[2].id, 'tracker-3');
    });

    test('watchTrackers returns stream of trackers', () async {
      await repository.saveTracker(
        TestData.tracker(id: 'tracker-1'),
      );
      await repository.saveTracker(
        TestData.tracker(id: 'tracker-2', sortOrder: 1),
      );

      final stream = repository.watchTrackers();
      final trackers = await stream.first;

      expect(trackers.length, 2);
      expect(trackers[0].sortOrder, 0);
      expect(trackers[1].sortOrder, 1);
    });

    test('reorderTrackers updates sort order', () async {
      await repository.saveTracker(
        TestData.tracker(id: 'tracker-1'),
      );
      await repository.saveTracker(
        TestData.tracker(id: 'tracker-2', sortOrder: 1),
      );
      await repository.saveTracker(
        TestData.tracker(id: 'tracker-3', sortOrder: 2),
      );

      // Reorder: 3, 1, 2
      await repository.reorderTrackers(['tracker-3', 'tracker-1', 'tracker-2']);

      final trackers = await repository.getAllTrackers();

      expect(trackers[0].id, 'tracker-3');
      expect(trackers[0].sortOrder, 0);
      expect(trackers[1].id, 'tracker-1');
      expect(trackers[1].sortOrder, 1);
      expect(trackers[2].id, 'tracker-2');
      expect(trackers[2].sortOrder, 2);
    });

    test('saves tracker with allDay entry scope', () async {
      final tracker = TestData.tracker(
        id: 'tracker-1',
      );

      await repository.saveTracker(tracker);

      final retrieved = await repository.getTrackerById('tracker-1');
      expect(retrieved!.entryScope, TrackerEntryScope.allDay);
    });

    test('saves tracker with perEntry entry scope', () async {
      final tracker = TestData.tracker(
        id: 'tracker-1',
        entryScope: TrackerEntryScope.perEntry,
      );

      await repository.saveTracker(tracker);

      final retrieved = await repository.getTrackerById('tracker-1');
      expect(retrieved!.entryScope, TrackerEntryScope.perEntry);
    });

    test('saves tracker with null description', () async {
      final tracker = TestData.tracker(
        id: 'tracker-1',
      );

      await repository.saveTracker(tracker);

      final retrieved = await repository.getTrackerById('tracker-1');
      expect(retrieved!.description, isNull);
    });

    test('saves scale tracker with null labels', () async {
      final tracker = TestData.tracker(
        id: 'tracker-1',
        config: const TrackerResponseConfig.scale(),
      );

      await repository.saveTracker(tracker);

      final retrieved = await repository.getTrackerById('tracker-1');
      final config = retrieved!.config as ScaleConfig;
      expect(config.minLabel, isNull);
      expect(config.maxLabel, isNull);
    });

    test('handles scale tracker with various min/max values', () async {
      final testCases = [
        (min: 0, max: 1),
        (min: 1, max: 5),
        (min: 1, max: 10),
        (min: 0, max: 100),
      ];

      for (final (index, testCase) in testCases.indexed) {
        final tracker = TestData.tracker(
          id: 'tracker-$index',
          config: TrackerResponseConfig.scale(
            min: testCase.min,
            max: testCase.max,
          ),
        );

        await repository.saveTracker(tracker);

        final retrieved = await repository.getTrackerById('tracker-$index');
        final config = retrieved!.config as ScaleConfig;
        expect(config.min, testCase.min);
        expect(config.max, testCase.max);
      }
    });

    test('handles choice tracker with various option counts', () async {
      final testCases = [
        ['Yes', 'No'],
        ['Low', 'Medium', 'High'],
        ['1', '2', '3', '4', '5'],
      ];

      for (final (index, options) in testCases.indexed) {
        final tracker = TestData.tracker(
          id: 'tracker-$index',
          config: TrackerResponseConfig.choice(options: options),
        );

        await repository.saveTracker(tracker);

        final retrieved = await repository.getTrackerById('tracker-$index');
        final config = retrieved!.config as ChoiceConfig;
        expect(config.options, options);
      }
    });

    test('saveTracker with empty id generates new id', () async {
      final tracker = TestData.tracker(
        id: '',
        name: 'Auto-generated ID',
      );

      await repository.saveTracker(tracker);

      final trackers = await repository.getAllTrackers();

      expect(trackers.length, 1);
      expect(trackers[0].id, isNotEmpty);
      expect(trackers[0].name, 'Auto-generated ID');
    });

    test('preserves createdAt when updating tracker', () async {
      final createdAt = DateTime(2025, 1, 1, 10);
      await repository.saveTracker(
        TestData.tracker(
          id: 'tracker-1',
          name: 'Original',
          createdAt: createdAt,
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      await repository.saveTracker(
        TestData.tracker(
          id: 'tracker-1',
          name: 'Updated',
          createdAt: createdAt,
        ),
      );

      final retrieved = await repository.getTrackerById('tracker-1');
      expect(retrieved!.createdAt, createdAt);
      expect(retrieved.name, 'Updated');
    });

    test('handles tracker with special characters in name', () async {
      final tracker = TestData.tracker(
        id: 'tracker-1',
        name: "Tracker with 'quotes' and \"double quotes\" and \$pecial ch@rs!",
      );

      await repository.saveTracker(tracker);

      final retrieved = await repository.getTrackerById('tracker-1');
      expect(retrieved!.name, tracker.name);
    });

    test('handles tracker with very long name', () async {
      // Database has 100 character limit on tracker names
      final longName = 'A' * 100;
      final tracker = TestData.tracker(
        id: 'tracker-1',
        name: longName,
      );

      await repository.saveTracker(tracker);

      final retrieved = await repository.getTrackerById('tracker-1');
      expect(retrieved!.name, longName);
    });

    test('handles tracker with very long description', () async {
      final longDescription = 'B' * 2000;
      final tracker = TestData.tracker(
        id: 'tracker-1',
        description: longDescription,
      );

      await repository.saveTracker(tracker);

      final retrieved = await repository.getTrackerById('tracker-1');
      expect(retrieved!.description, longDescription);
    });

    test('handles choice tracker with many options', () async {
      final manyOptions = List.generate(50, (i) => 'Option $i');
      final tracker = TestData.tracker(
        id: 'tracker-1',
        config: TrackerResponseConfig.choice(options: manyOptions),
      );

      await repository.saveTracker(tracker);

      final retrieved = await repository.getTrackerById('tracker-1');
      final config = retrieved!.config as ChoiceConfig;
      expect(config.options.length, 50);
      expect(config.options, manyOptions);
    });

    test('handles many trackers efficiently', () async {
      // Create 100 trackers
      for (var i = 0; i < 100; i++) {
        await repository.saveTracker(
          TestData.tracker(
            id: 'tracker-$i',
            name: 'Tracker $i',
            sortOrder: i,
          ),
        );
      }

      final trackers = await repository.getAllTrackers();
      expect(trackers.length, 100);

      // Should be ordered by sortOrder
      for (var i = 0; i < trackers.length; i++) {
        expect(trackers[i].sortOrder, i);
      }
    });

    test('deleting non-existent tracker does not throw', () async {
      expect(
        () => repository.deleteTracker('non-existent'),
        returnsNormally,
      );
    });

    test('handles concurrent tracker operations', () async {
      await repository.saveTracker(
        TestData.tracker(id: 'tracker-1', name: 'Original'),
      );

      // Simulate concurrent operations
      await Future.wait([
        repository.saveTracker(
          TestData.tracker(id: 'tracker-1', name: 'Concurrent Update 1'),
        ),
        repository.saveTracker(
          TestData.tracker(id: 'tracker-1', name: 'Concurrent Update 2'),
        ),
        repository.getTrackerById('tracker-1'),
      ]);

      // Should not throw error and tracker should exist
      final tracker = await repository.getTrackerById('tracker-1');
      expect(tracker, isNotNull);
    });
  });

  group('WellbeingRepositoryContract - Daily Tracker Responses', () {
    test('saves and retrieves daily tracker response', () async {
      final tracker = TestData.tracker(
        id: 'tracker-1',
        name: 'Exercise',
        responseType: TrackerResponseType.yesNo,
      );
      await repository.saveTracker(tracker);

      final response = TestData.dailyTrackerResponse(
        id: 'response-1',
        trackerId: 'tracker-1',
        responseDate: DateTime(2025, 1, 20),
        value: const YesNoValue(value: true),
      );

      await repository.saveDailyTrackerResponse(response);

      final responses = await repository.getDailyTrackerResponses(
        date: DateTime(2025, 1, 20),
      );

      expect(responses.length, 1);
      expect(responses[0].trackerId, 'tracker-1');
      expect(responses[0].value, isA<YesNoValue>());
      expect((responses[0].value as YesNoValue).value, true);
    });

    test('updates existing daily tracker response', () async {
      final tracker = TestData.tracker(
        id: 'tracker-1',
      );
      await repository.saveTracker(tracker);

      final response = TestData.dailyTrackerResponse(
        id: 'response-1',
        trackerId: 'tracker-1',
        responseDate: DateTime(2025, 1, 20),
        value: const ScaleValue(value: 3),
      );

      await repository.saveDailyTrackerResponse(response);

      // Update the response
      final updated = response.copyWith(value: const ScaleValue(value: 5));
      await repository.saveDailyTrackerResponse(updated);

      final responses = await repository.getDailyTrackerResponses(
        date: DateTime(2025, 1, 20),
      );

      expect(responses.length, 1);
      expect((responses[0].value as ScaleValue).value, 5);
    });

    test('returns empty list when no responses for date', () async {
      final responses = await repository.getDailyTrackerResponses(
        date: DateTime(2025, 1, 20),
      );

      expect(responses, isEmpty);
    });

    test('only returns responses for specified date', () async {
      final tracker = TestData.tracker(
        id: 'tracker-1',
        responseType: TrackerResponseType.yesNo,
      );
      await repository.saveTracker(tracker);

      await repository.saveDailyTrackerResponse(
        TestData.dailyTrackerResponse(
          id: 'response-jan-20',
          trackerId: 'tracker-1',
          responseDate: DateTime(2025, 1, 20),
          value: const YesNoValue(value: true),
        ),
      );
      await repository.saveDailyTrackerResponse(
        TestData.dailyTrackerResponse(
          id: 'response-jan-21',
          trackerId: 'tracker-1',
          responseDate: DateTime(2025, 1, 21),
          value: const YesNoValue(value: false),
        ),
      );

      final responses = await repository.getDailyTrackerResponses(
        date: DateTime(2025, 1, 20),
      );

      expect(responses.length, 1);
      expect(responses[0].id, 'response-jan-20');
    });

    test('watchDailyTrackerResponses emits updates', () async {
      final tracker = TestData.tracker(
        id: 'tracker-1',
        responseType: TrackerResponseType.yesNo,
      );
      await repository.saveTracker(tracker);

      final date = DateTime(2025, 1, 20);
      final stream = repository.watchDailyTrackerResponses(date: date);

      // Initial empty state
      var responses = await stream.first;
      expect(responses, isEmpty);

      // Save a response
      await repository.saveDailyTrackerResponse(
        TestData.dailyTrackerResponse(
          id: 'response-1',
          trackerId: 'tracker-1',
          responseDate: date,
          value: const YesNoValue(value: true),
        ),
      );

      // Should now have the response
      responses = await stream.first;
      expect(responses.length, 1);
    });

    test('deletes daily tracker response', () async {
      final tracker = TestData.tracker(
        id: 'tracker-1',
        responseType: TrackerResponseType.yesNo,
      );
      await repository.saveTracker(tracker);

      await repository.saveDailyTrackerResponse(
        TestData.dailyTrackerResponse(
          id: 'response-1',
          trackerId: 'tracker-1',
          responseDate: DateTime(2025, 1, 20),
          value: const YesNoValue(value: true),
        ),
      );

      await repository.deleteDailyTrackerResponse('response-1');

      final responses = await repository.getDailyTrackerResponses(
        date: DateTime(2025, 1, 20),
      );
      expect(responses, isEmpty);
    });

    test('supports multiple trackers for same date', () async {
      await repository.saveTracker(
        TestData.tracker(
          id: 'exercise',
          responseType: TrackerResponseType.yesNo,
        ),
      );
      await repository.saveTracker(
        TestData.tracker(
          id: 'sleep',
        ),
      );

      final date = DateTime(2025, 1, 20);
      await repository.saveDailyTrackerResponse(
        TestData.dailyTrackerResponse(
          id: 'response-exercise',
          trackerId: 'exercise',
          responseDate: date,
          value: const YesNoValue(value: true),
        ),
      );
      await repository.saveDailyTrackerResponse(
        TestData.dailyTrackerResponse(
          id: 'response-sleep',
          trackerId: 'sleep',
          responseDate: date,
          value: const ScaleValue(value: 8),
        ),
      );

      final responses = await repository.getDailyTrackerResponses(date: date);

      expect(responses.length, 2);
      final trackerIds = responses.map((r) => r.trackerId).toSet();
      expect(trackerIds, containsAll(['exercise', 'sleep']));
    });
  });
}
