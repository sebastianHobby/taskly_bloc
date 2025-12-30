import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/wellbeing/tracker.dart';
import 'package:taskly_bloc/domain/models/wellbeing/tracker_response_config.dart';

void main() {
  group('Tracker', () {
    final now = DateTime(2025, 12, 27);

    group('construction', () {
      test('creates instance with required fields', () {
        final tracker = Tracker(
          id: 't-1',
          name: 'Exercise',
          responseType: TrackerResponseType.yesNo,
          config: const TrackerResponseConfig.yesNo(),
          entryScope: TrackerEntryScope.allDay,
          createdAt: now,
          updatedAt: now,
        );

        expect(tracker.id, equals('t-1'));
        expect(tracker.name, equals('Exercise'));
        expect(tracker.responseType, equals(TrackerResponseType.yesNo));
        expect(tracker.entryScope, equals(TrackerEntryScope.allDay));
        expect(tracker.description, isNull);
        expect(tracker.sortOrder, equals(0));
      });

      test('creates instance with all fields', () {
        final tracker = Tracker(
          id: 't-1',
          name: 'Water Intake',
          responseType: TrackerResponseType.scale,
          config: const TrackerResponseConfig.scale(min: 0, max: 10),
          entryScope: TrackerEntryScope.perEntry,
          createdAt: now,
          updatedAt: now,
          description: 'Track daily water consumption',
          sortOrder: 5,
        );

        expect(tracker.description, equals('Track daily water consumption'));
        expect(tracker.sortOrder, equals(5));
      });

      test('sortOrder defaults to 0', () {
        final tracker = Tracker(
          id: 't-1',
          name: 'Test',
          responseType: TrackerResponseType.choice,
          config: const TrackerResponseConfig.choice(options: ['A', 'B']),
          entryScope: TrackerEntryScope.allDay,
          createdAt: now,
          updatedAt: now,
        );

        expect(tracker.sortOrder, equals(0));
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        final original = Tracker(
          id: 't-1',
          name: 'Exercise',
          responseType: TrackerResponseType.yesNo,
          config: const TrackerResponseConfig.yesNo(),
          entryScope: TrackerEntryScope.allDay,
          createdAt: now,
          updatedAt: now,
          sortOrder: 1,
        );

        final copy = original.copyWith(
          name: 'Workout',
          sortOrder: 10,
        );

        expect(copy.name, equals('Workout'));
        expect(copy.sortOrder, equals(10));
        expect(copy.id, equals(original.id));
        expect(copy.responseType, equals(original.responseType));
      });

      test('preserves unchanged fields', () {
        final original = Tracker(
          id: 't-1',
          name: 'Mood',
          responseType: TrackerResponseType.scale,
          config: const TrackerResponseConfig.scale(),
          entryScope: TrackerEntryScope.perEntry,
          createdAt: now,
          updatedAt: now,
          description: 'Track mood',
        );

        final copy = original.copyWith(sortOrder: 5);

        expect(copy.description, equals('Track mood'));
        expect(copy.name, equals('Mood'));
      });
    });

    group('equality', () {
      test('two instances with same values are equal', () {
        final tracker1 = Tracker(
          id: 't-1',
          name: 'Sleep',
          responseType: TrackerResponseType.scale,
          config: const TrackerResponseConfig.scale(max: 10),
          entryScope: TrackerEntryScope.allDay,
          createdAt: now,
          updatedAt: now,
        );

        final tracker2 = Tracker(
          id: 't-1',
          name: 'Sleep',
          responseType: TrackerResponseType.scale,
          config: const TrackerResponseConfig.scale(max: 10),
          entryScope: TrackerEntryScope.allDay,
          createdAt: now,
          updatedAt: now,
        );

        expect(tracker1, equals(tracker2));
        expect(tracker1.hashCode, equals(tracker2.hashCode));
      });

      test('two instances with different ids are not equal', () {
        final tracker1 = Tracker(
          id: 't-1',
          name: 'Test',
          responseType: TrackerResponseType.yesNo,
          config: const TrackerResponseConfig.yesNo(),
          entryScope: TrackerEntryScope.allDay,
          createdAt: now,
          updatedAt: now,
        );

        final tracker2 = Tracker(
          id: 't-2',
          name: 'Test',
          responseType: TrackerResponseType.yesNo,
          config: const TrackerResponseConfig.yesNo(),
          entryScope: TrackerEntryScope.allDay,
          createdAt: now,
          updatedAt: now,
        );

        expect(tracker1, isNot(equals(tracker2)));
      });
    });

    group('JSON serialization', () {
      test('toJson serializes correctly', () {
        final tracker = Tracker(
          id: 't-1',
          name: 'Exercise',
          responseType: TrackerResponseType.yesNo,
          config: const TrackerResponseConfig.yesNo(),
          entryScope: TrackerEntryScope.allDay,
          createdAt: now,
          updatedAt: now,
          description: 'Daily exercise',
          sortOrder: 3,
        );

        final json = tracker.toJson();

        expect(json['id'], equals('t-1'));
        expect(json['name'], equals('Exercise'));
        expect(json['description'], equals('Daily exercise'));
        expect(json['sort_order'], equals(3));
      });

      test('fromJson deserializes correctly', () {
        final json = {
          'id': 't-1',
          'name': 'Water',
          'response_type': 'scale',
          'config': {
            'runtimeType': 'scale',
            'min': 1,
            'max': 10,
          },
          'entry_scope': 'allDay',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
          'sort_order': 2,
        };

        final tracker = Tracker.fromJson(json);

        expect(tracker.id, equals('t-1'));
        expect(tracker.name, equals('Water'));
        expect(tracker.sortOrder, equals(2));
      });

      test('roundtrip serialization preserves data', () {
        final original = Tracker(
          id: 't-1',
          name: 'Meditation',
          responseType: TrackerResponseType.choice,
          config: const TrackerResponseConfig.choice(
            options: ['Morning', 'Evening', 'Both'],
          ),
          entryScope: TrackerEntryScope.perEntry,
          createdAt: now,
          updatedAt: now,
          description: 'Meditation practice',
          sortOrder: 1,
        );

        final json = original.toJson();
        final deserialized = Tracker.fromJson(json);

        expect(deserialized.id, equals(original.id));
        expect(deserialized.name, equals(original.name));
        expect(deserialized.description, equals(original.description));
        expect(deserialized.sortOrder, equals(original.sortOrder));
      });
    });
  });

  group('TrackerResponseType', () {
    test('has three values', () {
      expect(TrackerResponseType.values.length, equals(3));
    });

    test('contains choice type', () {
      expect(
        TrackerResponseType.values,
        contains(TrackerResponseType.choice),
      );
    });

    test('contains scale type', () {
      expect(TrackerResponseType.values, contains(TrackerResponseType.scale));
    });

    test('contains yesNo type', () {
      expect(TrackerResponseType.values, contains(TrackerResponseType.yesNo));
    });

    test('supports switch statements exhaustively', () {
      String getDescription(TrackerResponseType type) {
        return switch (type) {
          TrackerResponseType.choice => 'Multiple choice',
          TrackerResponseType.scale => 'Numeric scale',
          TrackerResponseType.yesNo => 'Yes or no',
        };
      }

      expect(getDescription(TrackerResponseType.choice), isNotEmpty);
      expect(getDescription(TrackerResponseType.scale), isNotEmpty);
      expect(getDescription(TrackerResponseType.yesNo), isNotEmpty);
    });
  });

  group('TrackerEntryScope', () {
    test('has two values', () {
      expect(TrackerEntryScope.values.length, equals(2));
    });

    test('contains allDay scope', () {
      expect(TrackerEntryScope.values, contains(TrackerEntryScope.allDay));
    });

    test('contains perEntry scope', () {
      expect(TrackerEntryScope.values, contains(TrackerEntryScope.perEntry));
    });

    test('supports switch statements exhaustively', () {
      String getDescription(TrackerEntryScope scope) {
        return switch (scope) {
          TrackerEntryScope.allDay => 'Once per day',
          TrackerEntryScope.perEntry => 'Multiple per day',
        };
      }

      expect(getDescription(TrackerEntryScope.allDay), isNotEmpty);
      expect(getDescription(TrackerEntryScope.perEntry), isNotEmpty);
    });
  });
}
