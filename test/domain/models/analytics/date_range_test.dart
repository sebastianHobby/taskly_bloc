import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/analytics/date_range.dart';

import '../../../helpers/fallback_values.dart';

void main() {
  setUpAll(registerAllFallbackValues);

  group('DateRange', () {
    group('construction', () {
      test('creates with required start and end', () {
        final start = DateTime(2025);
        final end = DateTime(2025, 1, 31);
        final range = DateRange(start: start, end: end);

        expect(range.start, start);
        expect(range.end, end);
      });

      test('allows same start and end date', () {
        final date = DateTime(2025, 1, 15);
        final range = DateRange(start: date, end: date);

        expect(range.start, date);
        expect(range.end, date);
      });
    });

    group('DateRange.last30Days', () {
      test('creates range ending now', () {
        final before = DateTime.now();
        final range = DateRange.last30Days();
        final after = DateTime.now();

        expect(
          range.end.isAfter(before.subtract(const Duration(seconds: 1))),
          true,
        );
        expect(range.end.isBefore(after.add(const Duration(seconds: 1))), true);
      });

      test('creates range starting 30 days ago', () {
        final range = DateRange.last30Days();
        final daysDiff = range.end.difference(range.start).inDays;

        expect(daysDiff, 30);
      });
    });

    group('daysDifference', () {
      test('returns correct number of days', () {
        final range = DateRange(
          start: DateTime(2025),
          end: DateTime(2025, 1, 31),
        );

        expect(range.daysDifference, 30);
      });

      test('returns 0 for same day', () {
        final date = DateTime(2025, 1, 15);
        final range = DateRange(start: date, end: date);

        expect(range.daysDifference, 0);
      });

      test('returns 1 for consecutive days', () {
        final range = DateRange(
          start: DateTime(2025),
          end: DateTime(2025, 1, 2),
        );

        expect(range.daysDifference, 1);
      });

      test('handles year boundaries', () {
        final range = DateRange(
          start: DateTime(2024, 12, 31),
          end: DateTime(2025),
        );

        expect(range.daysDifference, 1);
      });
    });

    group('contains', () {
      test('returns true for date within range', () {
        final range = DateRange(
          start: DateTime(2025),
          end: DateTime(2025, 1, 31),
        );

        expect(range.contains(DateTime(2025, 1, 15)), true);
      });

      test('returns true for start date', () {
        final range = DateRange(
          start: DateTime(2025),
          end: DateTime(2025, 1, 31),
        );

        expect(range.contains(DateTime(2025)), true);
      });

      test('returns true for end date', () {
        final range = DateRange(
          start: DateTime(2025),
          end: DateTime(2025, 1, 31),
        );

        expect(range.contains(DateTime(2025, 1, 31)), true);
      });

      test('returns false for date before range', () {
        final range = DateRange(
          start: DateTime(2025, 1, 10),
          end: DateTime(2025, 1, 20),
        );

        expect(range.contains(DateTime(2025, 1, 5)), false);
      });

      test('returns false for date after range', () {
        final range = DateRange(
          start: DateTime(2025, 1, 10),
          end: DateTime(2025, 1, 20),
        );

        expect(range.contains(DateTime(2025, 1, 25)), false);
      });
    });

    group('equality', () {
      test('equal when start and end match', () {
        final range1 = DateRange(
          start: DateTime(2025),
          end: DateTime(2025, 1, 31),
        );
        final range2 = DateRange(
          start: DateTime(2025),
          end: DateTime(2025, 1, 31),
        );

        expect(range1, equals(range2));
        expect(range1.hashCode, equals(range2.hashCode));
      });

      test('not equal when start differs', () {
        final range1 = DateRange(
          start: DateTime(2025),
          end: DateTime(2025, 1, 31),
        );
        final range2 = DateRange(
          start: DateTime(2025, 1, 2),
          end: DateTime(2025, 1, 31),
        );

        expect(range1, isNot(equals(range2)));
      });

      test('not equal when end differs', () {
        final range1 = DateRange(
          start: DateTime(2025),
          end: DateTime(2025, 1, 31),
        );
        final range2 = DateRange(
          start: DateTime(2025),
          end: DateTime(2025, 1, 30),
        );

        expect(range1, isNot(equals(range2)));
      });
    });

    group('copyWith', () {
      test('copies with new start', () {
        final range = DateRange(
          start: DateTime(2025),
          end: DateTime(2025, 1, 31),
        );
        final newStart = DateTime(2025, 1, 5);
        final copied = range.copyWith(start: newStart);

        expect(copied.start, newStart);
        expect(copied.end, range.end);
      });

      test('copies with new end', () {
        final range = DateRange(
          start: DateTime(2025),
          end: DateTime(2025, 1, 31),
        );
        final newEnd = DateTime(2025, 2, 15);
        final copied = range.copyWith(end: newEnd);

        expect(copied.end, newEnd);
        expect(copied.start, range.start);
      });
    });
  });
}
