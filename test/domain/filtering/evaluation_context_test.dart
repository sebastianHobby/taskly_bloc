import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/filtering/evaluation_context.dart';

import '../../fixtures/test_data.dart';
import '../../helpers/fallback_values.dart';

void main() {
  setUpAll(registerAllFallbackValues);

  group('EvaluationContext', () {
    group('construction', () {
      test('creates with explicit today date (not normalized)', () {
        // Constructor does NOT normalize explicit dates
        final date = DateTime(2025, 6, 15, 14, 30, 45);
        final context = EvaluationContext(today: date);

        // Preserves the exact time provided
        expect(context.today, date);
      });

      test(
        'creates with current date normalized to UTC midnight when none provided',
        () {
          final before = DateTime.now();
          final context = EvaluationContext();

          // The context's today should be between before and after (same day)
          expect(context.today.year, before.year);
          expect(context.today.month, before.month);
          expect(context.today.day, before.day);
          // Should be normalized to UTC midnight
          expect(context.today.isUtc, isTrue);
          expect(context.today.hour, 0);
          expect(context.today.minute, 0);
          expect(context.today.second, 0);
        },
      );
    });

    group('forDate factory', () {
      test('creates context for specific date normalized to UTC midnight', () {
        final context = EvaluationContext.forDate(
          DateTime(2025, 12, 25, 14, 30),
        );

        expect(context.today, DateTime.utc(2025, 12, 25));
        expect(context.today.isUtc, isTrue);
      });

      test('normalizes the date to midnight', () {
        final context = EvaluationContext.forDate(
          DateTime(2025, 1, 1, 12, 30, 45),
        );

        expect(context.today.hour, 0);
        expect(context.today.minute, 0);
        expect(context.today.second, 0);
      });
    });

    group('TestData builder', () {
      test('creates context with default date', () {
        final context = TestData.evaluationContext();

        expect(context.today, DateTime(2025, 6, 15));
      });

      test('creates context with custom date', () {
        final context = TestData.evaluationContext(
          today: DateTime(2025, 12, 31),
        );

        expect(context.today, DateTime(2025, 12, 31));
      });
    });

    group('usage in rules', () {
      test('provides consistent date for multiple evaluations', () {
        final context = EvaluationContext.forDate(DateTime(2025, 6, 15));

        // Access today multiple times
        final first = context.today;
        final second = context.today;
        final third = context.today;

        expect(first, equals(second));
        expect(second, equals(third));
      });
    });
  });
}
