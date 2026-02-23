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

  testSafe(
    'CorrelationCalculator uses non-early non-significant insight for larger samples',
    () async {
      final calculator = CorrelationCalculator();

      final sourceDays = <DateTime>[for (int i = 1; i <= 40; i += 2) day(i)];
      final targetData = <DateTime, double>{
        for (int i = 1; i <= 40; i++) day(i): 5,
      };

      final result = calculator.calculate(
        sourceLabel: 'Sleep',
        targetLabel: 'Mood',
        sourceDays: sourceDays,
        targetData: targetData,
      );

      expect(result.sampleSize, 40);
      expect(result.statisticalSignificance?.isSignificant, isFalse);
      expect(
        result.insight,
        contains('No statistically significant correlation'),
      );
    },
  );

  testSafe(
    'CorrelationCalculator detects strong negative correlation with significance',
    () async {
      final calculator = CorrelationCalculator();

      final sourceDays = <DateTime>[];
      final targetData = <DateTime, double>{};
      for (int i = 1; i <= 24; i++) {
        final d = day(i);
        final sourceOn = i.isEven;
        if (sourceOn) sourceDays.add(d);
        targetData[d] = sourceOn ? 1 : 10;
      }

      final result = calculator.calculate(
        sourceLabel: 'Late caffeine',
        targetLabel: 'Sleep quality',
        sourceDays: sourceDays,
        targetData: targetData,
      );

      expect(result.coefficient, lessThan(-0.9));
      expect(result.strength, CorrelationStrength.strongNegative);
      expect(result.statisticalSignificance?.isSignificant, isTrue);
      expect(result.insight, contains('lower'));
    },
  );

  testSafe(
    'CorrelationCalculator can produce moderate positive strength',
    () async {
      final calculator = CorrelationCalculator();

      final sourceDays = <DateTime>[];
      final targetData = <DateTime, double>{};
      for (int i = 1; i <= 120; i++) {
        final d = day(i);
        final sourceOn = i.isEven;
        if (sourceOn) sourceDays.add(d);
        final base = (i % 10).toDouble();
        targetData[d] = sourceOn ? base + 3 : base;
      }

      final result = calculator.calculate(
        sourceLabel: 'Planning',
        targetLabel: 'Productivity',
        sourceDays: sourceDays,
        targetData: targetData,
      );

      expect(result.sampleSize, 120);
      expect(result.statisticalSignificance?.isSignificant, isTrue);
      expect(
        result.strength,
        anyOf(
          CorrelationStrength.moderatePositive,
          CorrelationStrength.strongPositive,
        ),
      );
    },
  );
}
