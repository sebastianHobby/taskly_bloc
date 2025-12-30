import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/wellbeing/tracker_response.dart';

void main() {
  group('TrackerResponse', () {
    final now = DateTime(2025, 12, 27);

    group('construction', () {
      test('creates instance with choice value', () {
        final response = TrackerResponse(
          id: 'tr-1',
          journalEntryId: 'je-1',
          trackerId: 't-1',
          value: const TrackerResponseValue.choice(selected: 'Morning'),
          createdAt: now,
          updatedAt: now,
        );

        expect(response.id, equals('tr-1'));
        expect(response.journalEntryId, equals('je-1'));
        expect(response.trackerId, equals('t-1'));
        expect(response.value, isA<ChoiceValue>());
      });

      test('creates instance with scale value', () {
        final response = TrackerResponse(
          id: 'tr-2',
          journalEntryId: 'je-1',
          trackerId: 't-2',
          value: const TrackerResponseValue.scale(value: 7),
          createdAt: now,
          updatedAt: now,
        );

        expect(response.value, isA<ScaleValue>());
        final scaleValue = response.value as ScaleValue;
        expect(scaleValue.value, equals(7));
      });

      test('creates instance with yesNo value', () {
        final response = TrackerResponse(
          id: 'tr-3',
          journalEntryId: 'je-1',
          trackerId: 't-3',
          value: const TrackerResponseValue.yesNo(value: true),
          createdAt: now,
          updatedAt: now,
        );

        expect(response.value, isA<YesNoValue>());
        final yesNoValue = response.value as YesNoValue;
        expect(yesNoValue.value, isTrue);
      });
    });

    group('copyWith', () {
      test('creates copy with updated value', () {
        final original = TrackerResponse(
          id: 'tr-1',
          journalEntryId: 'je-1',
          trackerId: 't-1',
          value: const TrackerResponseValue.scale(value: 5),
          createdAt: now,
          updatedAt: now,
        );

        final copy = original.copyWith(
          value: const TrackerResponseValue.scale(value: 8),
        );

        expect(copy.id, equals(original.id));
        expect((copy.value as ScaleValue).value, equals(8));
        expect((original.value as ScaleValue).value, equals(5));
      });

      test('preserves unchanged fields', () {
        final original = TrackerResponse(
          id: 'tr-1',
          journalEntryId: 'je-1',
          trackerId: 't-1',
          value: const TrackerResponseValue.yesNo(value: false),
          createdAt: now,
          updatedAt: now,
        );

        final copy = original.copyWith(
          value: const TrackerResponseValue.yesNo(value: true),
        );

        expect(copy.journalEntryId, equals(original.journalEntryId));
        expect(copy.trackerId, equals(original.trackerId));
      });
    });

    group('equality', () {
      test('two instances with same values are equal', () {
        final response1 = TrackerResponse(
          id: 'tr-1',
          journalEntryId: 'je-1',
          trackerId: 't-1',
          value: const TrackerResponseValue.choice(selected: 'A'),
          createdAt: now,
          updatedAt: now,
        );

        final response2 = TrackerResponse(
          id: 'tr-1',
          journalEntryId: 'je-1',
          trackerId: 't-1',
          value: const TrackerResponseValue.choice(selected: 'A'),
          createdAt: now,
          updatedAt: now,
        );

        expect(response1, equals(response2));
        expect(response1.hashCode, equals(response2.hashCode));
      });

      test('two instances with different values are not equal', () {
        final response1 = TrackerResponse(
          id: 'tr-1',
          journalEntryId: 'je-1',
          trackerId: 't-1',
          value: const TrackerResponseValue.scale(value: 5),
          createdAt: now,
          updatedAt: now,
        );

        final response2 = TrackerResponse(
          id: 'tr-1',
          journalEntryId: 'je-1',
          trackerId: 't-1',
          value: const TrackerResponseValue.scale(value: 8),
          createdAt: now,
          updatedAt: now,
        );

        expect(response1, isNot(equals(response2)));
      });
    });

    group('JSON serialization', () {
      test('toJson serializes choice value correctly', () {
        final response = TrackerResponse(
          id: 'tr-1',
          journalEntryId: 'je-1',
          trackerId: 't-1',
          value: const TrackerResponseValue.choice(selected: 'Option A'),
          createdAt: now,
          updatedAt: now,
        );

        final json = response.toJson();

        expect(json['id'], equals('tr-1'));
        expect(json['journal_entry_id'], equals('je-1'));
        expect(json['tracker_id'], equals('t-1'));
        expect(json.containsKey('value'), isTrue);
      });

      test('fromJson deserializes correctly', () {
        final json = {
          'id': 'tr-1',
          'journal_entry_id': 'je-1',
          'tracker_id': 't-1',
          'value': {
            'runtimeType': 'scale',
            'value': 7,
          },
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        };

        final response = TrackerResponse.fromJson(json);

        expect(response.id, equals('tr-1'));
        expect(response.value, isA<ScaleValue>());
      });

      test('roundtrip serialization preserves data', () {
        final original = TrackerResponse(
          id: 'tr-1',
          journalEntryId: 'je-1',
          trackerId: 't-1',
          value: const TrackerResponseValue.yesNo(value: true),
          createdAt: now,
          updatedAt: now,
        );

        final json = original.toJson();
        final deserialized = TrackerResponse.fromJson(json);

        expect(deserialized.id, equals(original.id));
        expect(deserialized.value, equals(original.value));
      });
    });
  });

  group('TrackerResponseValue', () {
    group('ChoiceValue', () {
      test('creates choice value', () {
        const value = TrackerResponseValue.choice(selected: 'Option A');

        expect(value, isA<ChoiceValue>());
        expect((value as ChoiceValue).selected, equals('Option A'));
      });

      test('two choice values with same selection are equal', () {
        const value1 = TrackerResponseValue.choice(selected: 'A');
        const value2 = TrackerResponseValue.choice(selected: 'A');

        expect(value1, equals(value2));
        expect(value1.hashCode, equals(value2.hashCode));
      });

      test('supports pattern matching', () {
        const value = TrackerResponseValue.choice(selected: 'Test');

        final result = switch (value) {
          ChoiceValue(:final selected) => 'Choice: $selected',
          ScaleValue() => 'Scale',
          YesNoValue() => 'YesNo',
          _ => 'Unknown',
        };

        expect(result, equals('Choice: Test'));
      });
    });

    group('ScaleValue', () {
      test('creates scale value', () {
        const value = TrackerResponseValue.scale(value: 8);

        expect(value, isA<ScaleValue>());
        expect((value as ScaleValue).value, equals(8));
      });

      test('accepts minimum value', () {
        const value = TrackerResponseValue.scale(value: 1);
        expect((value as ScaleValue).value, equals(1));
      });

      test('accepts maximum value', () {
        const value = TrackerResponseValue.scale(value: 10);
        expect((value as ScaleValue).value, equals(10));
      });

      test('two scale values with same number are equal', () {
        const value1 = TrackerResponseValue.scale(value: 5);
        const value2 = TrackerResponseValue.scale(value: 5);

        expect(value1, equals(value2));
        expect(value1.hashCode, equals(value2.hashCode));
      });

      test('supports pattern matching', () {
        const value = TrackerResponseValue.scale(value: 7);

        final result = switch (value) {
          ChoiceValue() => 'Choice',
          ScaleValue(:final value) => 'Scale: $value',
          YesNoValue() => 'YesNo',
          _ => 'Unknown',
        };

        expect(result, equals('Scale: 7'));
      });
    });

    group('YesNoValue', () {
      test('creates yesNo value with true', () {
        const value = TrackerResponseValue.yesNo(value: true);

        expect(value, isA<YesNoValue>());
        expect((value as YesNoValue).value, isTrue);
      });

      test('creates yesNo value with false', () {
        const value = TrackerResponseValue.yesNo(value: false);

        expect(value, isA<YesNoValue>());
        expect((value as YesNoValue).value, isFalse);
      });

      test('two yesNo values with same boolean are equal', () {
        const value1 = TrackerResponseValue.yesNo(value: true);
        const value2 = TrackerResponseValue.yesNo(value: true);

        expect(value1, equals(value2));
        expect(value1.hashCode, equals(value2.hashCode));
      });

      test('supports pattern matching', () {
        const value = TrackerResponseValue.yesNo(value: false);

        final result = switch (value) {
          ChoiceValue() => 'Choice',
          ScaleValue() => 'Scale',
          YesNoValue(:final value) => 'YesNo: $value',
          _ => 'Unknown',
        };

        expect(result, equals('YesNo: false'));
      });
    });

    group('type discrimination', () {
      test('distinguishes between different value types', () {
        const choice = TrackerResponseValue.choice(selected: 'A');
        const scale = TrackerResponseValue.scale(value: 5);
        const yesNo = TrackerResponseValue.yesNo(value: true);

        expect(choice, isNot(equals(scale)));
        expect(choice, isNot(equals(yesNo)));
        expect(scale, isNot(equals(yesNo)));
      });
    });
  });
}
