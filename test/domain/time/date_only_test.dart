@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';
import 'package:taskly_domain/time.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('dateOnly', () {
    testSafe('normalizes to UTC midnight', () async {
      final input = DateTime(2025, 2, 3, 14, 45);

      final result = dateOnly(input);

      expect(result, DateTime.utc(2025, 2, 3));
      expect(result.isUtc, isTrue);
    });

    testSafe('returns null when input is null', () async {
      expect(dateOnlyOrNull(null), isNull);
    });
  });

  group('encode/parse date-only', () {
    testSafe('encodes to YYYY-MM-DD', () async {
      final input = DateTime(2025, 2, 3, 6, 10);

      expect(encodeDateOnly(input), '2025-02-03');
      expect(encodeDateOnlyOrNull(null), isNull);
    });

    testSafe('parses valid date-only string', () async {
      final result = parseDateOnly('2025-02-03');

      expect(result, DateTime.utc(2025, 2, 3));
      expect(result.isUtc, isTrue);
    });

    testSafe('throws on invalid date-only string', () async {
      expect(
        () => parseDateOnly('2025/02/03'),
        throwsA(isA<FormatException>()),
      );
    });

    testSafe('tryParseDateOnly handles legacy timestamps', () async {
      expect(tryParseDateOnly(null), isNull);
      expect(tryParseDateOnly(''), isNull);
      expect(tryParseDateOnly('2025-02-03'), DateTime.utc(2025, 2, 3));
      expect(
        tryParseDateOnly('2025-02-03T10:15:00Z'),
        DateTime.utc(2025, 2, 3),
      );
    });
  });
}
