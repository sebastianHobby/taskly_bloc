import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/domain/models/mood_rating.dart';

void main() {
  group('MoodRating', () {
    group('enum values', () {
      test('has all expected ratings', () {
        expect(MoodRating.values, hasLength(5));
        expect(MoodRating.values, contains(MoodRating.veryLow));
        expect(MoodRating.values, contains(MoodRating.low));
        expect(MoodRating.values, contains(MoodRating.neutral));
        expect(MoodRating.values, contains(MoodRating.good));
        expect(MoodRating.values, contains(MoodRating.excellent));
      });

      test('veryLow has correct properties', () {
        expect(MoodRating.veryLow.value, equals(1));
        expect(MoodRating.veryLow.label, equals('Very Low'));
        expect(MoodRating.veryLow.emoji, equals('😢'));
      });

      test('low has correct properties', () {
        expect(MoodRating.low.value, equals(2));
        expect(MoodRating.low.label, equals('Low'));
        expect(MoodRating.low.emoji, equals('😕'));
      });

      test('neutral has correct properties', () {
        expect(MoodRating.neutral.value, equals(3));
        expect(MoodRating.neutral.label, equals('Neutral'));
        expect(MoodRating.neutral.emoji, equals('😐'));
      });

      test('good has correct properties', () {
        expect(MoodRating.good.value, equals(4));
        expect(MoodRating.good.label, equals('Good'));
        expect(MoodRating.good.emoji, equals('🙂'));
      });

      test('excellent has correct properties', () {
        expect(MoodRating.excellent.value, equals(5));
        expect(MoodRating.excellent.label, equals('Excellent'));
        expect(MoodRating.excellent.emoji, equals('😄'));
      });
    });

    group('fromValue', () {
      test('returns correct rating for value 1', () {
        expect(MoodRating.fromValue(1), equals(MoodRating.veryLow));
      });

      test('returns correct rating for value 2', () {
        expect(MoodRating.fromValue(2), equals(MoodRating.low));
      });

      test('returns correct rating for value 3', () {
        expect(MoodRating.fromValue(3), equals(MoodRating.neutral));
      });

      test('returns correct rating for value 4', () {
        expect(MoodRating.fromValue(4), equals(MoodRating.good));
      });

      test('returns correct rating for value 5', () {
        expect(MoodRating.fromValue(5), equals(MoodRating.excellent));
      });

      test('returns neutral for invalid value (0)', () {
        expect(MoodRating.fromValue(0), equals(MoodRating.neutral));
      });

      test('returns neutral for invalid value (6)', () {
        expect(MoodRating.fromValue(6), equals(MoodRating.neutral));
      });

      test('returns neutral for negative value', () {
        expect(MoodRating.fromValue(-1), equals(MoodRating.neutral));
      });

      test('returns neutral for very large value', () {
        expect(MoodRating.fromValue(999), equals(MoodRating.neutral));
      });
    });

    group('value ordering', () {
      test('values are ordered from lowest to highest', () {
        expect(MoodRating.veryLow.value < MoodRating.low.value, isTrue);
        expect(MoodRating.low.value < MoodRating.neutral.value, isTrue);
        expect(MoodRating.neutral.value < MoodRating.good.value, isTrue);
        expect(MoodRating.good.value < MoodRating.excellent.value, isTrue);
      });

      test('values are sequential', () {
        expect(MoodRating.veryLow.value, equals(1));
        expect(MoodRating.low.value, equals(2));
        expect(MoodRating.neutral.value, equals(3));
        expect(MoodRating.good.value, equals(4));
        expect(MoodRating.excellent.value, equals(5));
      });
    });

    group('enum usage', () {
      test('can be used in switch statements', () {
        String getMessage(MoodRating rating) {
          return switch (rating) {
            MoodRating.veryLow => 'feeling down',
            MoodRating.low => 'not great',
            MoodRating.neutral => 'okay',
            MoodRating.good => 'good',
            MoodRating.excellent => 'amazing',
          };
        }

        expect(getMessage(MoodRating.veryLow), equals('feeling down'));
        expect(getMessage(MoodRating.excellent), equals('amazing'));
      });

      test('supports equality comparison', () {
        expect(MoodRating.good == MoodRating.good, isTrue);
        expect(MoodRating.good == MoodRating.excellent, isFalse);
      });

      test('can be compared by value', () {
        const rating1 = MoodRating.good;
        final rating2 = MoodRating.fromValue(4);
        expect(rating1, equals(rating2));
      });
    });
  });
}
