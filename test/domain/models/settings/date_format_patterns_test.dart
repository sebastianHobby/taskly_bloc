import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/presentation/shared/utils/date_format_patterns.dart';

void main() {
  group('DateFormatPatterns', () {
    group('constants', () {
      test('short pattern is defined', () {
        expect(DateFormatPatterns.short, 'yMd');
      });

      test('medium pattern is defined', () {
        expect(DateFormatPatterns.medium, 'yMMMd');
      });

      test('long pattern is defined', () {
        expect(DateFormatPatterns.long, 'yMMMMd');
      });

      test('full pattern is defined', () {
        expect(DateFormatPatterns.full, 'yMMMMEEEEd');
      });

      test('defaultPattern equals medium', () {
        expect(DateFormatPatterns.defaultPattern, DateFormatPatterns.medium);
      });
    });

    group('getFormat', () {
      test('returns DateFormat for valid pattern', () {
        final format = DateFormatPatterns.getFormat('yMd');
        expect(format, isNotNull);
      });

      test('returns DateFormat with locale', () {
        final format = DateFormatPatterns.getFormat('yMd', 'en_US');
        expect(format, isNotNull);
      });

      test('returns fallback for invalid pattern', () {
        // Empty pattern is technically invalid
        final format = DateFormatPatterns.getFormat('invalid!!!');
        expect(format, isNotNull);
      });
    });
  });
}
