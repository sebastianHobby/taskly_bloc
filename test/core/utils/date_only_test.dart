import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/core/utils/date_only.dart';

void main() {
  group('dateOnly', () {
    test('strips time-of-day and keeps date', () {
      final input = DateTime(2025, 12, 21, 23, 59, 58);
      expect(dateOnly(input), DateTime.utc(2025, 12, 21));
    });

    test('dateOnlyOrNull returns null for null', () {
      expect(dateOnlyOrNull(null), isNull);
    });

    test('dateOnlyOrNull normalizes non-null value', () {
      final input = DateTime(2025, 12, 21, 1, 2, 3);
      expect(dateOnlyOrNull(input), DateTime.utc(2025, 12, 21));
    });
  });
}
