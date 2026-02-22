@Tags(['unit'])
library;

import '../../../helpers/test_imports.dart';

import 'package:taskly_domain/analytics.dart';

void main() {
  DateTime day(int i) => DateTime.utc(2026, 1, i);

  testSafe(
    'CorrelationCalculator returns insufficient-data result for empty input',
    () async {
      final calculator = CorrelationCalculator();

      final result = calculator.calculate(
        sourceLabel: 'A',
        targetLabel: 'B',
        sourceDays: const [],
        targetData: const {},
      );

      expect(result.coefficient, 0);
      expect(result.strength, CorrelationStrength.negligible);
      expect(result.insight, contains('insufficient data'));
    },
  );

  testSafe(
    'CorrelationCalculator excludes outlier and enforces min sample size',
    () async {
      final calculator = CorrelationCalculator();

      // 10 target points, but one extreme value gets excluded as an outlier,
      // leaving 9 which is below minSampleSize.
      final targetData = <DateTime, double>{
        for (int i = 1; i <= 9; i++) day(i): i.toDouble(),
        day(10): 10_000,
      };

      final result = calculator.calculate(
        sourceLabel: 'Source',
        targetLabel: 'Target',
        sourceDays: [day(1), day(3), day(5), day(7), day(9)],
        targetData: targetData,
      );

      expect(result.sampleSize, 9);
      expect(
        result.insight,
        contains(
          'Need at least ${CorrelationCalculator.minSampleSize} data points',
        ),
      );
    },
  );

  testSafe(
    'CorrelationCalculator detects significant strong positive correlation',
    () async {
      final calculator = CorrelationCalculator();

      // Perfect relationship: y = 5 + 5x (affine transform still yields r=1)
      final sourceDays = <DateTime>[];
      final targetData = <DateTime, double>{};

      for (int i = 1; i <= 20; i++) {
        final d = day(i);
        final isSource = i.isEven;
        if (isSource) sourceDays.add(d);
        targetData[d] = isSource ? 10 : 5;
      }

      final result = calculator.calculate(
        sourceLabel: 'Exercise',
        targetLabel: 'Energy',
        sourceDays: sourceDays,
        targetData: targetData,
      );

      expect(result.coefficient, closeTo(1, 1e-12));
      expect(result.strength, CorrelationStrength.strongPositive);
      expect(result.statisticalSignificance?.isSignificant, isTrue);
      expect(result.insight, contains('statistically significant'));
      expect(result.valueWithSource, 10);
      expect(result.valueWithoutSource, 5);
    },
  );

  testSafe(
    'CorrelationCalculator produces early-pattern insight when not significant',
    () async {
      final calculator = CorrelationCalculator();

      // Constant target value produces r=0 and p=1.
      final sourceDays = <DateTime>[for (int i = 1; i <= 12; i += 2) day(i)];
      final targetData = <DateTime, double>{
        for (int i = 1; i <= 12; i++) day(i): 5,
      };

      final result = calculator.calculate(
        sourceLabel: 'A',
        targetLabel: 'B',
        sourceDays: sourceDays,
        targetData: targetData,
      );

      expect(result.coefficient, 0);
      expect(result.strength, CorrelationStrength.negligible);
      expect(result.statisticalSignificance?.isSignificant, isFalse);
      expect(result.insight, contains('Early pattern detected'));
      expect(result.insight, contains('n=12'));
    },
  );
}
