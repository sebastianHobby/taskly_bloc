@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:taskly_domain/time.dart';

void main() {
  testSafe('dateOnly normalizes to UTC midnight', () async {
    final dt = DateTime(2026, 1, 18, 15, 45, 12);

    final normalized = dateOnly(dt);

    expect(normalized.isUtc, isTrue);
    expect(normalized.year, 2026);
    expect(normalized.month, 1);
    expect(normalized.day, 18);
    expect(normalized.hour, 0);
    expect(normalized.minute, 0);
  });

  testSafe('dateOnlyOrNull returns null for null input', () async {
    expect(dateOnlyOrNull(null), isNull);
  });

  testSafe('encodeDateOnly encodes as YYYY-MM-DD', () async {
    final dt = DateTime.utc(2026, 1, 8, 23, 59);
    expect(encodeDateOnly(dt), '2026-01-08');
  });

  testSafe('parseDateOnly parses YYYY-MM-DD to UTC midnight', () async {
    final dt = parseDateOnly('2026-01-18');

    expect(dt, DateTime.utc(2026, 1, 18));
    expect(dt.isUtc, isTrue);
  });

  testSafe('parseDateOnly throws for invalid input', () async {
    expect(() => parseDateOnly('2026/01/18'), throwsFormatException);
    expect(() => parseDateOnly(''), throwsFormatException);
  });

  testSafe('tryParseDateOnly handles null/empty', () async {
    expect(tryParseDateOnly(null), isNull);
    expect(tryParseDateOnly(''), isNull);
  });

  testSafe(
    'tryParseDateOnly accepts legacy ISO timestamp and normalizes',
    () async {
      final dt = tryParseDateOnly('2026-01-18T10:20:30Z');
      expect(dt, DateTime.utc(2026, 1, 18));
    },
  );

  testSafe('tryParseDateOnly returns null for unparseable string', () async {
    expect(tryParseDateOnly('not-a-date'), isNull);
  });
}
