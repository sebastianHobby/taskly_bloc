import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/wellbeing/journal_entry.dart';
import 'package:taskly_bloc/domain/models/wellbeing/mood_rating.dart';
import 'package:taskly_bloc/domain/models/wellbeing/tracker_response.dart';

void main() {
  group('JournalEntry', () {
    final now = DateTime(2025, 12, 27, 14, 30);
    final trackerResponse = TrackerResponse(
      id: 'tr-1',
      journalEntryId: 'je-1',
      trackerId: 't-1',
      value: const TrackerResponseValue.yesNo(value: true),
      createdAt: now,
      updatedAt: now,
    );

    group('construction', () {
      test('creates instance with required fields', () {
        final entry = JournalEntry(
          id: 'je-1',
          entryDate: now,
          entryTime: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(entry.id, equals('je-1'));
        expect(entry.entryDate, equals(now));
        expect(entry.entryTime, equals(now));
        expect(entry.createdAt, equals(now));
        expect(entry.updatedAt, equals(now));
        expect(entry.moodRating, isNull);
        expect(entry.journalText, isNull);
        expect(entry.perEntryTrackerResponses, isEmpty);
      });

      test('creates instance with all fields', () {
        final entry = JournalEntry(
          id: 'je-1',
          entryDate: now,
          entryTime: now,
          createdAt: now,
          updatedAt: now,
          moodRating: MoodRating.excellent,
          journalText: 'Had a great day!',
          perEntryTrackerResponses: [trackerResponse],
        );

        expect(entry.id, equals('je-1'));
        expect(entry.moodRating, equals(MoodRating.excellent));
        expect(entry.journalText, equals('Had a great day!'));
        expect(entry.perEntryTrackerResponses.length, equals(1));
        expect(entry.perEntryTrackerResponses.first, equals(trackerResponse));
      });

      test('trackerResponses defaults to empty list', () {
        final entry = JournalEntry(
          id: 'je-1',
          entryDate: now,
          entryTime: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(entry.perEntryTrackerResponses, isEmpty);
        expect(entry.perEntryTrackerResponses, isA<List<TrackerResponse>>());
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        final original = JournalEntry(
          id: 'je-1',
          entryDate: now,
          entryTime: now,
          createdAt: now,
          updatedAt: now,
          moodRating: MoodRating.neutral,
          journalText: 'Original text',
        );

        final copy = original.copyWith(
          moodRating: MoodRating.excellent,
          journalText: 'Updated text',
        );

        expect(copy.id, equals(original.id));
        expect(copy.moodRating, equals(MoodRating.excellent));
        expect(copy.journalText, equals('Updated text'));
        expect(copy.entryDate, equals(original.entryDate));
      });

      test('preserves unchanged fields', () {
        final original = JournalEntry(
          id: 'je-1',
          entryDate: now,
          entryTime: now,
          createdAt: now,
          updatedAt: now,
          journalText: 'My journal',
        );

        final copy = original.copyWith(moodRating: MoodRating.good);

        expect(copy.journalText, equals('My journal'));
        expect(copy.id, equals(original.id));
      });

      test('can update tracker responses', () {
        final original = JournalEntry(
          id: 'je-1',
          entryDate: now,
          entryTime: now,
          createdAt: now,
          updatedAt: now,
        );

        final copy = original.copyWith(
          perEntryTrackerResponses: [trackerResponse],
        );

        expect(copy.perEntryTrackerResponses.length, equals(1));
        expect(original.perEntryTrackerResponses, isEmpty);
      });
    });

    group('equality', () {
      test('two instances with same values are equal', () {
        final entry1 = JournalEntry(
          id: 'je-1',
          entryDate: now,
          entryTime: now,
          createdAt: now,
          updatedAt: now,
          moodRating: MoodRating.good,
          journalText: 'Test',
        );

        final entry2 = JournalEntry(
          id: 'je-1',
          entryDate: now,
          entryTime: now,
          createdAt: now,
          updatedAt: now,
          moodRating: MoodRating.good,
          journalText: 'Test',
        );

        expect(entry1, equals(entry2));
        expect(entry1.hashCode, equals(entry2.hashCode));
      });

      test('two instances with different ids are not equal', () {
        final entry1 = JournalEntry(
          id: 'je-1',
          entryDate: now,
          entryTime: now,
          createdAt: now,
          updatedAt: now,
        );

        final entry2 = JournalEntry(
          id: 'je-2',
          entryDate: now,
          entryTime: now,
          createdAt: now,
          updatedAt: now,
        );

        expect(entry1, isNot(equals(entry2)));
      });

      test('two instances with different mood ratings are not equal', () {
        final entry1 = JournalEntry(
          id: 'je-1',
          entryDate: now,
          entryTime: now,
          createdAt: now,
          updatedAt: now,
          moodRating: MoodRating.good,
        );

        final entry2 = JournalEntry(
          id: 'je-1',
          entryDate: now,
          entryTime: now,
          createdAt: now,
          updatedAt: now,
          moodRating: MoodRating.excellent,
        );

        expect(entry1, isNot(equals(entry2)));
      });
    });

    group('JSON serialization', () {
      test('toJson serializes correctly', () {
        final entry = JournalEntry(
          id: 'je-1',
          entryDate: now,
          entryTime: now,
          createdAt: now,
          updatedAt: now,
          moodRating: MoodRating.excellent,
          journalText: 'Great day!',
        );

        final json = entry.toJson();

        expect(json['id'], equals('je-1'));
        expect(json['journal_text'], equals('Great day!'));
        expect(json.containsKey('entry_date'), isTrue);
        expect(json.containsKey('created_at'), isTrue);
      });

      test('fromJson deserializes correctly', () {
        final json = {
          'id': 'je-1',
          'entry_date': now.toIso8601String(),
          'entry_time': now.toIso8601String(),
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
          'journal_text': 'Test entry',
          'tracker_responses': <Map<String, dynamic>>[],
        };

        final entry = JournalEntry.fromJson(json);

        expect(entry.id, equals('je-1'));
        expect(entry.journalText, equals('Test entry'));
        expect(entry.perEntryTrackerResponses, isEmpty);
      });

      test('roundtrip serialization preserves data', () {
        final original = JournalEntry(
          id: 'je-1',
          entryDate: now,
          entryTime: now,
          createdAt: now,
          updatedAt: now,
          moodRating: MoodRating.good,
          journalText: 'Test',
        );

        final json = original.toJson();
        final deserialized = JournalEntry.fromJson(json);

        expect(deserialized.id, equals(original.id));
        expect(deserialized.journalText, equals(original.journalText));
        expect(deserialized.moodRating, equals(original.moodRating));
      });
    });
  });
}
