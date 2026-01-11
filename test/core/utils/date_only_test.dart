import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/time/date_only.dart';

void main() {
  group('dateOnly', () {
    test('converts local datetime to UTC midnight', () {
      final local = DateTime(2024, 6, 15, 10, 30, 45);
      final result = dateOnly(local);

      expect(result.isUtc, true);
      expect(result.year, 2024);
      expect(result.month, 6);
      expect(result.day, 15);
      expect(result.hour, 0);
      expect(result.minute, 0);
      expect(result.second, 0);
    });

    test('converts UTC datetime to UTC midnight', () {
      final utc = DateTime.utc(2024, 6, 15, 10, 30, 45);
      final result = dateOnly(utc);

      expect(result.isUtc, true);
      expect(result.hour, 0);
      expect(result.minute, 0);
      expect(result.second, 0);
    });

    test('preserves date components', () {
      final result = dateOnly(DateTime(2024, 12, 25, 23, 59, 59));

      expect(result.year, 2024);
      expect(result.month, 12);
      expect(result.day, 25);
    });
  });

  group('dateOnlyOrNull', () {
    test('returns null for null input', () {
      expect(dateOnlyOrNull(null), isNull);
    });

    test('converts non-null datetime to UTC midnight', () {
      final result = dateOnlyOrNull(DateTime(2024, 6, 15, 10, 30));

      expect(result, isNotNull);
      expect(result!.isUtc, true);
      expect(result.hour, 0);
    });
  });

  group('encodeDateOnly', () {
    test('formats date as YYYY-MM-DD', () {
      final date = DateTime(2024, 6, 15);
      expect(encodeDateOnly(date), '2024-06-15');
    });

    test('pads month and day with zeros', () {
      final date = DateTime(2024, 1, 5);
      expect(encodeDateOnly(date), '2024-01-05');
    });

    test('ignores time components', () {
      final date = DateTime(2024, 6, 15, 23, 59, 59);
      expect(encodeDateOnly(date), '2024-06-15');
    });

    test('handles year 0000', () {
      final date = DateTime(0);
      expect(encodeDateOnly(date), '0000-01-01');
    });

    test('pads year to 4 digits', () {
      final date = DateTime(24, 6, 15);
      expect(encodeDateOnly(date), '0024-06-15');
    });
  });

  group('encodeDateOnlyOrNull', () {
    test('returns null for null input', () {
      expect(encodeDateOnlyOrNull(null), isNull);
    });

    test('encodes non-null datetime', () {
      expect(encodeDateOnlyOrNull(DateTime(2024, 6, 15)), '2024-06-15');
    });
  });

  group('parseDateOnly', () {
    test('parses valid YYYY-MM-DD string', () {
      final result = parseDateOnly('2024-03-15');

      expect(result.year, 2024);
      expect(result.month, 3);
      expect(result.day, 15);
      expect(result.hour, 0);
      expect(result.minute, 0);
      expect(result.second, 0);
      expect(result.isUtc, true);
    });

    test('parses date with single digit month and day (padded)', () {
      final result = parseDateOnly('2024-01-05');

      expect(result.year, 2024);
      expect(result.month, 1);
      expect(result.day, 5);
    });

    test('parses year 0000', () {
      final result = parseDateOnly('0000-01-01');

      expect(result.year, 0);
      expect(result.month, 1);
      expect(result.day, 1);
    });

    test('throws FormatException for invalid format with slashes', () {
      expect(
        () => parseDateOnly('2024/03/15'),
        throwsFormatException,
      );
    });

    test('throws FormatException for empty string', () {
      expect(
        () => parseDateOnly(''),
        throwsFormatException,
      );
    });

    test('throws FormatException for ISO timestamp format', () {
      expect(
        () => parseDateOnly('2024-03-15T10:30:00Z'),
        throwsFormatException,
      );
    });

    test('throws FormatException for partial date', () {
      expect(
        () => parseDateOnly('2024-03'),
        throwsFormatException,
      );
    });

    test('throws FormatException for unparseable string', () {
      expect(
        () => parseDateOnly('not a date'),
        throwsFormatException,
      );
    });
  });

  group('tryParseDateOnly', () {
    test('parses valid YYYY-MM-DD string directly', () {
      final result = tryParseDateOnly('2024-03-15');

      expect(result, isNotNull);
      expect(result!.year, 2024);
      expect(result.month, 3);
      expect(result.day, 15);
      expect(result.hour, 0);
      expect(result.isUtc, true);
    });

    test('parses ISO timestamp and normalizes to date', () {
      final result = tryParseDateOnly('2024-03-15T10:30:00Z');

      expect(result, isNotNull);
      expect(result!.year, 2024);
      expect(result.month, 3);
      expect(result.day, 15);
      expect(result.hour, 0);
      expect(result.isUtc, true);
    });

    test('returns null for null value', () {
      final result = tryParseDateOnly(null);

      expect(result, isNull);
    });

    test('returns null for empty string', () {
      final result = tryParseDateOnly('');

      expect(result, isNull);
    });

    test('returns null for unparseable string', () {
      final result = tryParseDateOnly('not a date');

      expect(result, isNull);
    });

    test('normalizes ISO timestamp to date', () {
      final result = tryParseDateOnly('2024-06-15T23:59:59');

      expect(result, isNotNull);
      expect(result!.year, 2024);
      expect(result.month, 6);
      expect(result.day, 15);
      expect(result.isUtc, true);
    });

    test('parses date with timezone offset', () {
      final result = tryParseDateOnly('2024-06-15T10:30:00+05:00');

      expect(result, isNotNull);
      expect(result!.year, 2024);
      expect(result.month, 6);
      expect(result.day, 15);
    });
  });
}
