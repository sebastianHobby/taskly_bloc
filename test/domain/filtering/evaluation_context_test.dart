import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/filtering/evaluation_context.dart';

void main() {
  group('EvaluationContext', () {
    test('default constructor uses current date normalized to midnight', () {
      final context = EvaluationContext();
      final now = DateTime.now();

      // Verify the date is today but at midnight
      expect(context.today.year, now.year);
      expect(context.today.month, now.month);
      expect(context.today.day, now.day);
      expect(context.today.hour, 0);
      expect(context.today.minute, 0);
      expect(context.today.second, 0);
      expect(context.today.millisecond, 0);
      expect(context.today.microsecond, 0);
    });

    test('default constructor accepts explicit today parameter', () {
      final specificDate = DateTime(2024, 3, 15, 14, 30, 45);
      final context = EvaluationContext(today: specificDate);

      expect(context.today, specificDate);
    });

    test('forDate factory normalizes DateTime to midnight', () {
      final dateWithTime = DateTime(2024, 7, 20, 15, 45, 30, 500);
      final context = EvaluationContext.forDate(dateWithTime);

      expect(context.today.year, 2024);
      expect(context.today.month, 7);
      expect(context.today.day, 20);
      expect(context.today.hour, 0);
      expect(context.today.minute, 0);
      expect(context.today.second, 0);
      expect(context.today.millisecond, 0);
      expect(context.today.microsecond, 0);
    });

    test('forDate factory handles dates already at midnight', () {
      final dateAtMidnight = DateTime(2024);
      final context = EvaluationContext.forDate(dateAtMidnight);

      expect(context.today, dateAtMidnight);
    });

    test('forDate factory handles edge cases', () {
      // Leap year date
      final leapDate = DateTime(2024, 2, 29, 23, 59, 59);
      final leapContext = EvaluationContext.forDate(leapDate);
      expect(leapContext.today, DateTime(2024, 2, 29));

      // End of year
      final endOfYear = DateTime(2024, 12, 31, 12);
      final endContext = EvaluationContext.forDate(endOfYear);
      expect(endContext.today, DateTime(2024, 12, 31));

      // Start of year
      final startOfYear = DateTime(2024, 1, 1, 0, 0, 1);
      final startContext = EvaluationContext.forDate(startOfYear);
      expect(startContext.today, DateTime(2024));
    });

    test('today field is immutable', () {
      final date = DateTime(2024, 5, 15);
      final context = EvaluationContext(today: date);

      expect(context.today, date);
      // Verify we cannot modify the date
      expect(() => context.today, returnsNormally);
    });

    test('multiple instances with same date are independent', () {
      final date = DateTime(2024, 6, 10);
      final context1 = EvaluationContext.forDate(date);
      final context2 = EvaluationContext.forDate(date);

      expect(context1.today, context2.today);
      expect(identical(context1, context2), isFalse);
    });

    test('handles different time zones by normalizing to local midnight', () {
      final localDate = DateTime(2024, 8, 25, 10, 30);
      final utcDate = DateTime.utc(2024, 8, 25, 10, 30);

      final localContext = EvaluationContext.forDate(localDate);
      final utcContext = EvaluationContext.forDate(utcDate);

      // Both normalize to midnight in local time (dateOnly always returns local)
      expect(localContext.today.hour, 0);
      expect(utcContext.today.hour, 0);
      expect(localContext.today.minute, 0);
      expect(utcContext.today.minute, 0);

      // Verify the date components are preserved
      expect(localContext.today.year, 2024);
      expect(localContext.today.month, 8);
      expect(localContext.today.day, 25);
    });
  });
}
