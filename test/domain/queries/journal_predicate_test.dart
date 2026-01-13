import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/journal/model/mood_rating.dart';
import 'package:taskly_bloc/domain/queries/journal_predicate.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart'
    show DateOperator, RelativeComparison;

void main() {
  group('JournalPredicate', () {
    group('JournalIdPredicate', () {
      test('creates with id', () {
        const predicate = JournalIdPredicate(id: 'entry-123');

        expect(predicate.id, 'entry-123');
      });

      test('toJson creates valid JSON', () {
        const predicate = JournalIdPredicate(id: 'entry-123');
        final json = predicate.toJson();

        expect(json['type'], 'id');
        expect(json['id'], 'entry-123');
      });

      test('fromJson restores predicate', () {
        const predicate = JournalIdPredicate(id: 'entry-123');
        final json = predicate.toJson();
        final restored = JournalPredicate.fromJson(json) as JournalIdPredicate;

        expect(restored.id, predicate.id);
      });

      test('equality works correctly', () {
        const p1 = JournalIdPredicate(id: 'test');
        const p2 = JournalIdPredicate(id: 'test');
        const p3 = JournalIdPredicate(id: 'other');

        expect(p1, equals(p2));
        expect(p1, isNot(equals(p3)));
        expect(p1.hashCode, equals(p2.hashCode));
      });
    });

    group('JournalDatePredicate', () {
      test('creates with date', () {
        final predicate = JournalDatePredicate(
          operator: DateOperator.on,
          date: DateTime(2026, 1, 3),
        );

        expect(predicate.operator, DateOperator.on);
        expect(predicate.date, DateTime(2026, 1, 3));
      });

      test('creates with date range', () {
        final predicate = JournalDatePredicate(
          operator: DateOperator.between,
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 31),
        );

        expect(predicate.operator, DateOperator.between);
        expect(predicate.startDate, isNotNull);
        expect(predicate.endDate, isNotNull);
      });

      test('creates with relative date', () {
        const predicate = JournalDatePredicate(
          operator: DateOperator.relative,
          relativeComparison: RelativeComparison.onOrAfter,
          relativeDays: -7,
        );

        expect(predicate.operator, DateOperator.relative);
        expect(predicate.relativeComparison, RelativeComparison.onOrAfter);
        expect(predicate.relativeDays, -7);
      });

      test('toJson creates valid JSON', () {
        final predicate = JournalDatePredicate(
          operator: DateOperator.on,
          date: DateTime(2026, 1, 3),
        );
        final json = predicate.toJson();

        expect(json['type'], 'date');
        expect(json['operator'], 'on');
        expect(json['date'], isNotNull);
      });

      test('fromJson restores predicate', () {
        final predicate = JournalDatePredicate(
          operator: DateOperator.on,
          date: DateTime(2026, 1, 3),
        );
        final json = predicate.toJson();
        final restored =
            JournalPredicate.fromJson(json) as JournalDatePredicate;

        expect(restored.operator, predicate.operator);
        expect(restored.date, isNotNull);
      });

      test('equality works correctly', () {
        final p1 = JournalDatePredicate(
          operator: DateOperator.on,
          date: DateTime(2026, 1, 3),
        );
        final p2 = JournalDatePredicate(
          operator: DateOperator.on,
          date: DateTime(2026, 1, 3),
        );
        final p3 = JournalDatePredicate(
          operator: DateOperator.on,
          date: DateTime(2026, 1, 4),
        );

        expect(p1, equals(p2));
        expect(p1, isNot(equals(p3)));
      });
    });

    group('JournalMoodPredicate', () {
      test('creates with equals operator', () {
        const predicate = JournalMoodPredicate(
          operator: MoodOperator.equals,
          value: MoodRating.good,
        );

        expect(predicate.operator, MoodOperator.equals);
        expect(predicate.value, MoodRating.good);
      });

      test('creates with greaterThanOrEqual operator', () {
        const predicate = JournalMoodPredicate(
          operator: MoodOperator.greaterThanOrEqual,
          value: MoodRating.neutral,
        );

        expect(predicate.operator, MoodOperator.greaterThanOrEqual);
        expect(predicate.value, MoodRating.neutral);
      });

      test('creates with isNull operator', () {
        const predicate = JournalMoodPredicate(
          operator: MoodOperator.isNull,
        );

        expect(predicate.operator, MoodOperator.isNull);
        expect(predicate.value, isNull);
      });

      test('toJson creates valid JSON', () {
        const predicate = JournalMoodPredicate(
          operator: MoodOperator.equals,
          value: MoodRating.good,
        );
        final json = predicate.toJson();

        expect(json['type'], 'mood');
        expect(json['operator'], 'equals');
        expect(json['value'], 4); // MoodRating.good.value
      });

      test('fromJson restores predicate', () {
        const predicate = JournalMoodPredicate(
          operator: MoodOperator.greaterThanOrEqual,
          value: MoodRating.good,
        );
        final json = predicate.toJson();
        final restored =
            JournalPredicate.fromJson(json) as JournalMoodPredicate;

        expect(restored.operator, predicate.operator);
        expect(restored.value, predicate.value);
      });

      test('equality works correctly', () {
        const p1 = JournalMoodPredicate(
          operator: MoodOperator.equals,
          value: MoodRating.good,
        );
        const p2 = JournalMoodPredicate(
          operator: MoodOperator.equals,
          value: MoodRating.good,
        );
        const p3 = JournalMoodPredicate(
          operator: MoodOperator.equals,
          value: MoodRating.excellent,
        );

        expect(p1, equals(p2));
        expect(p1, isNot(equals(p3)));
      });
    });

    group('JournalTextPredicate', () {
      test('creates with contains operator', () {
        const predicate = JournalTextPredicate(
          operator: TextOperator.contains,
          value: 'grateful',
        );

        expect(predicate.operator, TextOperator.contains);
        expect(predicate.value, 'grateful');
      });

      test('creates with isEmpty operator', () {
        const predicate = JournalTextPredicate(
          operator: TextOperator.isEmpty,
        );

        expect(predicate.operator, TextOperator.isEmpty);
        expect(predicate.value, isNull);
      });

      test('toJson creates valid JSON', () {
        const predicate = JournalTextPredicate(
          operator: TextOperator.contains,
          value: 'grateful',
        );
        final json = predicate.toJson();

        expect(json['type'], 'text');
        expect(json['operator'], 'contains');
        expect(json['value'], 'grateful');
      });

      test('fromJson restores predicate', () {
        const predicate = JournalTextPredicate(
          operator: TextOperator.contains,
          value: 'grateful',
        );
        final json = predicate.toJson();
        final restored =
            JournalPredicate.fromJson(json) as JournalTextPredicate;

        expect(restored.operator, predicate.operator);
        expect(restored.value, predicate.value);
      });

      test('equality works correctly', () {
        const p1 = JournalTextPredicate(
          operator: TextOperator.contains,
          value: 'test',
        );
        const p2 = JournalTextPredicate(
          operator: TextOperator.contains,
          value: 'test',
        );
        const p3 = JournalTextPredicate(
          operator: TextOperator.contains,
          value: 'other',
        );

        expect(p1, equals(p2));
        expect(p1, isNot(equals(p3)));
      });
    });

    group('fromJson error handling', () {
      test('throws for unknown predicate type', () {
        expect(
          () => JournalPredicate.fromJson({'type': 'unknown'}),
          throwsArgumentError,
        );
      });
    });
  });

  group('MoodOperator', () {
    test('has expected values', () {
      expect(MoodOperator.values, hasLength(5));
      expect(MoodOperator.values, contains(MoodOperator.equals));
      expect(MoodOperator.values, contains(MoodOperator.greaterThanOrEqual));
      expect(MoodOperator.values, contains(MoodOperator.lessThanOrEqual));
      expect(MoodOperator.values, contains(MoodOperator.isNull));
      expect(MoodOperator.values, contains(MoodOperator.isNotNull));
    });
  });

  group('TextOperator', () {
    test('has expected values', () {
      expect(TextOperator.values, hasLength(4));
      expect(TextOperator.values, contains(TextOperator.contains));
      expect(TextOperator.values, contains(TextOperator.equals));
      expect(TextOperator.values, contains(TextOperator.isEmpty));
      expect(TextOperator.values, contains(TextOperator.isNotEmpty));
    });
  });
}
