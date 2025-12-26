import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/queries/occurrence_expansion.dart';

void main() {
  group('OccurrenceExpansion', () {
    test('creates instance with required dates', () {
      final start = DateTime(2025);
      final end = DateTime(2025, 1, 31);

      final expansion = OccurrenceExpansion(
        rangeStart: start,
        rangeEnd: end,
      );

      expect(expansion.rangeStart, start);
      expect(expansion.rangeEnd, end);
    });

    test('copyWith preserves unchanged values', () {
      final original = OccurrenceExpansion(
        rangeStart: DateTime(2025),
        rangeEnd: DateTime(2025, 1, 31),
      );

      final newEnd = DateTime(2025, 2, 28);
      final copy = original.copyWith(rangeEnd: newEnd);

      expect(copy.rangeStart, original.rangeStart);
      expect(copy.rangeEnd, newEnd);
    });

    test('copyWith can update rangeStart', () {
      final original = OccurrenceExpansion(
        rangeStart: DateTime(2025),
        rangeEnd: DateTime(2025, 1, 31),
      );

      final newStart = DateTime(2025, 1, 15);
      final copy = original.copyWith(rangeStart: newStart);

      expect(copy.rangeStart, newStart);
      expect(copy.rangeEnd, original.rangeEnd);
    });

    test('copyWith returns new instance when no changes', () {
      final original = OccurrenceExpansion(
        rangeStart: DateTime(2025),
        rangeEnd: DateTime(2025, 1, 31),
      );

      final copy = original.copyWith();

      expect(copy, isNot(same(original)));
      expect(copy.rangeStart, original.rangeStart);
      expect(copy.rangeEnd, original.rangeEnd);
    });

    test('equality compares both dates', () {
      final expansion1 = OccurrenceExpansion(
        rangeStart: DateTime(2025),
        rangeEnd: DateTime(2025, 1, 31),
      );

      final expansion2 = OccurrenceExpansion(
        rangeStart: DateTime(2025),
        rangeEnd: DateTime(2025, 1, 31),
      );

      final expansion3 = OccurrenceExpansion(
        rangeStart: DateTime(2025),
        rangeEnd: DateTime(2025, 2, 28),
      );

      expect(expansion1, equals(expansion2));
      expect(expansion1, isNot(equals(expansion3)));
    });

    test('identical instances are equal', () {
      final expansion = OccurrenceExpansion(
        rangeStart: DateTime(2025),
        rangeEnd: DateTime(2025, 1, 31),
      );

      expect(expansion, equals(expansion));
    });

    test('hashCode is consistent', () {
      final expansion1 = OccurrenceExpansion(
        rangeStart: DateTime(2025),
        rangeEnd: DateTime(2025, 1, 31),
      );

      final expansion2 = OccurrenceExpansion(
        rangeStart: DateTime(2025),
        rangeEnd: DateTime(2025, 1, 31),
      );

      expect(expansion1.hashCode, equals(expansion2.hashCode));
    });

    test('toString provides readable representation', () {
      final expansion = OccurrenceExpansion(
        rangeStart: DateTime(2025),
        rangeEnd: DateTime(2025, 1, 31),
      );

      final string = expansion.toString();

      expect(string, contains('OccurrenceExpansion'));
      expect(string, contains('rangeStart'));
      expect(string, contains('rangeEnd'));
    });

    test('handles same-day range', () {
      final date = DateTime(2025);

      final expansion = OccurrenceExpansion(
        rangeStart: date,
        rangeEnd: date,
      );

      expect(expansion.rangeStart, date);
      expect(expansion.rangeEnd, date);
    });

    test('handles range spanning multiple months', () {
      final expansion = OccurrenceExpansion(
        rangeStart: DateTime(2025),
        rangeEnd: DateTime(2025, 6, 30),
      );

      expect(expansion.rangeStart.month, 1);
      expect(expansion.rangeEnd.month, 6);
    });

    test('handles range spanning year boundary', () {
      final expansion = OccurrenceExpansion(
        rangeStart: DateTime(2025, 12),
        rangeEnd: DateTime(2026, 1, 31),
      );

      expect(expansion.rangeStart.year, 2025);
      expect(expansion.rangeEnd.year, 2026);
    });

    test('handles leap year dates', () {
      final expansion = OccurrenceExpansion(
        rangeStart: DateTime(2024, 2),
        rangeEnd: DateTime(2024, 2, 29),
      );

      expect(expansion.rangeStart.day, 1);
      expect(expansion.rangeEnd.day, 29);
    });

    test('preserves time components', () {
      final expansion = OccurrenceExpansion(
        rangeStart: DateTime(2025, 1, 1, 10, 30, 45),
        rangeEnd: DateTime(2025, 1, 31, 14, 15, 20),
      );

      expect(expansion.rangeStart.hour, 10);
      expect(expansion.rangeStart.minute, 30);
      expect(expansion.rangeStart.second, 45);
      expect(expansion.rangeEnd.hour, 14);
      expect(expansion.rangeEnd.minute, 15);
      expect(expansion.rangeEnd.second, 20);
    });

    test('handles UTC dates', () {
      final expansion = OccurrenceExpansion(
        rangeStart: DateTime.utc(2025),
        rangeEnd: DateTime.utc(2025, 1, 31),
      );

      expect(expansion.rangeStart.isUtc, isTrue);
      expect(expansion.rangeEnd.isUtc, isTrue);
    });

    test('handles local dates', () {
      final expansion = OccurrenceExpansion(
        rangeStart: DateTime(2025),
        rangeEnd: DateTime(2025, 1, 31),
      );

      expect(expansion.rangeStart.isUtc, isFalse);
      expect(expansion.rangeEnd.isUtc, isFalse);
    });

    test('equality handles different time zones correctly', () {
      final localExpansion = OccurrenceExpansion(
        rangeStart: DateTime(2025, 1, 1, 12),
        rangeEnd: DateTime(2025, 1, 31, 12),
      );

      final utcExpansion = OccurrenceExpansion(
        rangeStart: DateTime.utc(2025, 1, 1, 12),
        rangeEnd: DateTime.utc(2025, 1, 31, 12),
      );

      expect(localExpansion, isNot(equals(utcExpansion)));
    });

    test('handles very long ranges', () {
      final expansion = OccurrenceExpansion(
        rangeStart: DateTime(2025),
        rangeEnd: DateTime(2030, 12, 31),
      );

      final daysDifference = expansion.rangeEnd
          .difference(expansion.rangeStart)
          .inDays;

      expect(daysDifference, greaterThan(2000));
    });

    test('handles very short ranges', () {
      final start = DateTime(2025, 1, 1, 10);
      final end = DateTime(2025, 1, 1, 10, 1);

      final expansion = OccurrenceExpansion(
        rangeStart: start,
        rangeEnd: end,
      );

      final difference = expansion.rangeEnd.difference(expansion.rangeStart);

      expect(difference.inMinutes, 1);
    });

    test('supports ranges where end is before start', () {
      // The class doesn't validate, so this is allowed
      final expansion = OccurrenceExpansion(
        rangeStart: DateTime(2025, 1, 31),
        rangeEnd: DateTime(2025),
      );

      expect(
        expansion.rangeEnd.isBefore(expansion.rangeStart),
        isTrue,
      );
    });

    test('copyWith handles null parameters', () {
      final original = OccurrenceExpansion(
        rangeStart: DateTime(2025),
        rangeEnd: DateTime(2025, 1, 31),
      );

      final copy = original.copyWith();

      expect(copy.rangeStart, original.rangeStart);
      expect(copy.rangeEnd, original.rangeEnd);
    });
  });
}
