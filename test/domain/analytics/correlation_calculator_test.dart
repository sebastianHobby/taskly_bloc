@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';
import 'package:taskly_domain/analytics.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('CorrelationCalculator', () {
    testSafe('returns insufficient data result when inputs are empty', () async {
      final calculator = CorrelationCalculator();

      final result = calculator.calculate(
        sourceLabel: 'Source',
        targetLabel: 'Target',
        sourceDays: const [],
        targetData: const {},
      );

      expect(result.strength, CorrelationStrength.negligible);
      expect(result.insight, contains('Insufficient data'));
    });

    testSafe('calculates correlation with adequate sample size', () async {
      final calculator = CorrelationCalculator();

      final days = List.generate(
        12,
        (i) => DateTime(2025, 1, 1).add(Duration(days: i)),
      );

      final targetData = <DateTime, double>{
        for (var i = 0; i < days.length; i++) days[i]: (i + 1).toDouble(),
      };

      final result = calculator.calculate(
        sourceLabel: 'Workout',
        targetLabel: 'Mood',
        sourceDays: days.where((d) => d.day.isEven).toList(growable: false),
        targetData: targetData,
      );

      expect(result.sampleSize, greaterThanOrEqualTo(10));
      expect(result.performanceMetrics, isNotNull);
      expect(result.statisticalSignificance, isNotNull);
    });

    testSafe('filters outliers and still computes result', () async {
      final calculator = CorrelationCalculator();

      final days = List.generate(
        12,
        (i) => DateTime(2025, 2, 1).add(Duration(days: i)),
      );

      final targetData = <DateTime, double>{
        for (var i = 0; i < days.length; i++) days[i]: 10.0,
      };
      targetData[days[5]] = 1000.0;

      final result = calculator.calculate(
        sourceLabel: 'Sleep',
        targetLabel: 'Focus',
        sourceDays: days.take(6).toList(growable: false),
        targetData: targetData,
      );

      expect(result.sampleSize, greaterThan(0));
      expect(result.insight, isNotEmpty);
    });
  });
}
