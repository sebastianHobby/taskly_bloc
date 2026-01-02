import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/queries/occurrence_expansion.dart';

void main() {
  group('OccurrenceExpansion', () {
    final testRangeStart = DateTime(2025, 1, 1);
    final testRangeEnd = DateTime(2025, 1, 31);

    group('constructor', () {
      test('creates instance with required parameters', () {
        final expansion = OccurrenceExpansion(
          rangeStart: testRangeStart,
          rangeEnd: testRangeEnd,
        );

        expect(expansion.rangeStart, testRangeStart);
        expect(expansion.rangeEnd, testRangeEnd);
      });
    });

    group('copyWith', () {
      test('returns copy with updated rangeStart', () {
        final original = OccurrenceExpansion(
          rangeStart: testRangeStart,
          rangeEnd: testRangeEnd,
        );
        final newStart = DateTime(2025, 2, 1);

        final copy = original.copyWith(rangeStart: newStart);

        expect(copy.rangeStart, newStart);
        expect(copy.rangeEnd, testRangeEnd);
      });

      test('returns copy with updated rangeEnd', () {
        final original = OccurrenceExpansion(
          rangeStart: testRangeStart,
          rangeEnd: testRangeEnd,
        );
        final newEnd = DateTime(2025, 2, 28);

        final copy = original.copyWith(rangeEnd: newEnd);

        expect(copy.rangeStart, testRangeStart);
        expect(copy.rangeEnd, newEnd);
      });

      test('returns copy with both updated when provided', () {
        final original = OccurrenceExpansion(
          rangeStart: testRangeStart,
          rangeEnd: testRangeEnd,
        );
        final newStart = DateTime(2025, 3, 1);
        final newEnd = DateTime(2025, 3, 31);

        final copy = original.copyWith(
          rangeStart: newStart,
          rangeEnd: newEnd,
        );

        expect(copy.rangeStart, newStart);
        expect(copy.rangeEnd, newEnd);
      });

      test('returns equivalent copy when no parameters provided', () {
        final original = OccurrenceExpansion(
          rangeStart: testRangeStart,
          rangeEnd: testRangeEnd,
        );

        final copy = original.copyWith();

        expect(copy, original);
        expect(copy.rangeStart, testRangeStart);
        expect(copy.rangeEnd, testRangeEnd);
      });
    });

    group('equality', () {
      test('equal instances have same hash code', () {
        final a = OccurrenceExpansion(
          rangeStart: testRangeStart,
          rangeEnd: testRangeEnd,
        );
        final b = OccurrenceExpansion(
          rangeStart: testRangeStart,
          rangeEnd: testRangeEnd,
        );

        expect(a, b);
        expect(a.hashCode, b.hashCode);
      });

      test('different rangeStart produces different instance', () {
        final a = OccurrenceExpansion(
          rangeStart: testRangeStart,
          rangeEnd: testRangeEnd,
        );
        final b = OccurrenceExpansion(
          rangeStart: DateTime(2025, 2, 1),
          rangeEnd: testRangeEnd,
        );

        expect(a, isNot(b));
      });

      test('different rangeEnd produces different instance', () {
        final a = OccurrenceExpansion(
          rangeStart: testRangeStart,
          rangeEnd: testRangeEnd,
        );
        final b = OccurrenceExpansion(
          rangeStart: testRangeStart,
          rangeEnd: DateTime(2025, 2, 28),
        );

        expect(a, isNot(b));
      });

      test('identical returns true for same instance', () {
        final a = OccurrenceExpansion(
          rangeStart: testRangeStart,
          rangeEnd: testRangeEnd,
        );

        expect(a == a, isTrue);
      });

      test('equals returns false for different type', () {
        final a = OccurrenceExpansion(
          rangeStart: testRangeStart,
          rangeEnd: testRangeEnd,
        );
        // ignore: unrelated_type_equality_checks
        expect(a == 'not an OccurrenceExpansion', isFalse);
      });
    });

    group('toString', () {
      test('returns string representation', () {
        final expansion = OccurrenceExpansion(
          rangeStart: testRangeStart,
          rangeEnd: testRangeEnd,
        );

        final str = expansion.toString();

        expect(str, contains('OccurrenceExpansion'));
        expect(str, contains('rangeStart'));
        expect(str, contains('rangeEnd'));
      });
    });
  });
}
