import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/presentation/shared/utils/sort_utils.dart';

void main() {
  group('compareAsciiLowerCase', () {
    test('compares equal strings as equal', () {
      expect(compareAsciiLowerCase('abc', 'abc'), 0);
    });

    test('compares case-insensitively', () {
      expect(compareAsciiLowerCase('ABC', 'abc'), 0);
      expect(compareAsciiLowerCase('abc', 'ABC'), 0);
    });

    test('returns negative when first is less', () {
      expect(compareAsciiLowerCase('aaa', 'bbb'), lessThan(0));
    });

    test('returns positive when first is greater', () {
      expect(compareAsciiLowerCase('zzz', 'aaa'), greaterThan(0));
    });
  });

  group('compareNullableDate', () {
    final earlier = DateTime(2024, 1, 1);
    final later = DateTime(2024, 12, 31);

    test('returns 0 when both are null', () {
      expect(compareNullableDate(null, null), 0);
    });

    test('returns 1 when first is null', () {
      expect(compareNullableDate(null, later), 1);
    });

    test('returns -1 when second is null', () {
      expect(compareNullableDate(earlier, null), -1);
    });

    test('returns negative when first is earlier', () {
      expect(compareNullableDate(earlier, later), lessThan(0));
    });

    test('returns positive when first is later', () {
      expect(compareNullableDate(later, earlier), greaterThan(0));
    });

    test('returns 0 when dates are equal', () {
      final date1 = DateTime(2024, 6, 15);
      final date2 = DateTime(2024, 6, 15);
      expect(compareNullableDate(date1, date2), 0);
    });
  });
}
