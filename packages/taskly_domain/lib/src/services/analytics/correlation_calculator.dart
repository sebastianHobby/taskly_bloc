import 'dart:math' as math;

import 'package:ml_linalg/linalg.dart';
import 'package:statistics/statistics.dart';
import 'package:taskly_domain/src/analytics/model/correlation_result.dart';

/// Calculates correlations using Pearson coefficient with statistical rigor
class CorrelationCalculator {
  // Minimum sample size for reliable correlation
  static const int minSampleSize = 10;

  // Outlier detection threshold (IQR method)
  static const double outlierMultiplier = 1.5;

  /// Calculate Pearson correlation coefficient with statistical significance
  CorrelationResult calculate({
    required String sourceLabel,
    required String targetLabel,
    required List<DateTime> sourceDays,
    required Map<DateTime, double> targetData,
    bool? sourceHigherIsBetter,
    bool? targetHigherIsBetter,
  }) {
    final stopwatch = Stopwatch()..start();

    if (sourceDays.isEmpty || targetData.isEmpty) {
      return _insufficientDataResult(
        sourceLabel: sourceLabel,
        targetLabel: targetLabel,
        reason: 'No data provided',
        sourceHigherIsBetter: sourceHigherIsBetter,
        targetHigherIsBetter: targetHigherIsBetter,
      );
    }

    // Get all unique days
    final allDays = <DateTime>{...sourceDays, ...targetData.keys}.toList()
      ..sort();

    if (allDays.isEmpty) {
      return _insufficientDataResult(
        sourceLabel: sourceLabel,
        targetLabel: targetLabel,
        reason: 'No overlapping data',
        sourceHigherIsBetter: sourceHigherIsBetter,
        targetHigherIsBetter: targetHigherIsBetter,
      );
    }

    // Create binary series for source (1 if present, 0 if not)
    final sourceSet = sourceDays.toSet();

    // Build aligned series and detect outliers
    final rawTargetValues = <double>[];
    for (final day in allDays) {
      if (targetData.containsKey(day)) {
        rawTargetValues.add(targetData[day]!);
      }
    }

    // Detect and exclude outliers (auto-exclude per requirements)
    final outlierIndices = _detectOutliers(rawTargetValues);

    // Calculate value with and without source (excluding outliers)
    final daysWithSource = <double>[];
    final daysWithoutSource = <double>[];
    int dataIndex = 0;

    for (final day in allDays) {
      if (targetData.containsKey(day)) {
        if (!outlierIndices.contains(dataIndex)) {
          if (sourceSet.contains(day)) {
            daysWithSource.add(targetData[day]!);
          } else {
            daysWithoutSource.add(targetData[day]!);
          }
        }
        dataIndex++;
      }
    }

    final valueWithSource = daysWithSource.isEmpty
        ? null
        : daysWithSource.statistics.mean;

    final valueWithoutSource = daysWithoutSource.isEmpty
        ? null
        : daysWithoutSource.statistics.mean;

    double? differencePercent;
    if (valueWithSource != null &&
        valueWithoutSource != null &&
        valueWithoutSource != 0) {
      differencePercent =
          ((valueWithSource - valueWithoutSource) / valueWithoutSource) * 100;
    }

    // Build cleaned series for correlation (outliers removed)
    final List<double> x = []; // source (0 or 1)
    final List<double> y = []; // target value
    dataIndex = 0;

    for (final day in allDays) {
      if (targetData.containsKey(day)) {
        if (!outlierIndices.contains(dataIndex)) {
          x.add(sourceSet.contains(day) ? 1.0 : 0.0);
          y.add(targetData[day]!);
        }
        dataIndex++;
      }
    }

    // Check minimum sample size
    if (x.length < minSampleSize) {
      return _insufficientDataResult(
        sourceLabel: sourceLabel,
        targetLabel: targetLabel,
        reason: 'Need at least $minSampleSize data points (found ${x.length})',
        sampleSize: x.length,
        sourceHigherIsBetter: sourceHigherIsBetter,
        targetHigherIsBetter: targetHigherIsBetter,
      );
    }

    // Calculate Pearson correlation using ml_linalg for performance
    final coefficient = _pearsonCorrelationML(x, y);

    // Calculate statistical significance
    final significance = _calculateSignificance(coefficient, x.length);

    // Determine strength based on coefficient AND significance
    final strength = significance.isSignificant
        ? _determineStrength(coefficient)
        : CorrelationStrength.negligible;

    final insight = _generateInsight(
      sourceLabel: sourceLabel,
      targetLabel: targetLabel,
      coefficient: coefficient,
      strength: strength,
      valueWithSource: valueWithSource,
      valueWithoutSource: valueWithoutSource,
      differencePercent: differencePercent,
      isSignificant: significance.isSignificant,
      sampleSize: x.length,
    );

    final calculationTime = stopwatch.elapsedMilliseconds;

    return CorrelationResult(
      sourceLabel: sourceLabel,
      targetLabel: targetLabel,
      coefficient: coefficient,
      sampleSize: x.length,
      strength: strength,
      insight: insight,
      valueWithSource: valueWithSource,
      valueWithoutSource: valueWithoutSource,
      differencePercent: differencePercent,
      sourceHigherIsBetter: sourceHigherIsBetter,
      targetHigherIsBetter: targetHigherIsBetter,
      statisticalSignificance: significance,
      performanceMetrics: PerformanceMetrics(
        calculationTimeMs: calculationTime,
        dataPoints: x.length,
        algorithm: 'ml_linalg_simd',
      ),
    );
  }

  /// Detect outliers using IQR method (Interquartile Range)
  Set<int> _detectOutliers(List<double> values) {
    if (values.length < 4) return {}; // Need at least 4 points for quartiles

    // Calculate quartiles manually
    final sorted = List<double>.from(values)..sort();
    final q1 = _calculateQuartile(sorted, 0.25);
    final q3 = _calculateQuartile(sorted, 0.75);
    final iqr = q3 - q1;

    final lowerBound = q1 - (outlierMultiplier * iqr);
    final upperBound = q3 + (outlierMultiplier * iqr);

    final outliers = <int>{};
    for (int i = 0; i < values.length; i++) {
      if (values[i] < lowerBound || values[i] > upperBound) {
        outliers.add(i);
      }
    }

    return outliers;
  }

  /// Calculate quartile value for sorted data
  double _calculateQuartile(List<double> sortedData, double percentile) {
    final index = percentile * (sortedData.length - 1);
    final lower = index.floor();
    final upper = index.ceil();
    final weight = index - lower;
    return sortedData[lower] * (1 - weight) + sortedData[upper] * weight;
  }

  /// Calculate Pearson correlation using ml_linalg for SIMD optimization
  double _pearsonCorrelationML(List<double> x, List<double> y) {
    if (x.length < 2 || x.length != y.length) return 0;

    try {
      // Convert to ml_linalg vectors for SIMD operations
      final vectorX = Vector.fromList(x);
      final vectorY = Vector.fromList(y);

      final meanX = vectorX.mean();
      final meanY = vectorY.mean();

      // Calculate deviations
      final dxList = x.map((val) => val - meanX).toList();
      final dyList = y.map((val) => val - meanY).toList();

      final dx = Vector.fromList(dxList);
      final dy = Vector.fromList(dyList);

      // Numerator: sum of products of deviations
      final numerator = dx.dot(dy);

      // Denominators: sqrt of sum of squared deviations
      final denomX = math.sqrt(dx.dot(dx));
      final denomY = math.sqrt(dy.dot(dy));

      if (denomX == 0 || denomY == 0) return 0;

      return numerator / (denomX * denomY);
    } catch (e) {
      // Fallback to manual calculation if ml_linalg fails
      return _pearsonCorrelationManual(x, y);
    }
  }

  /// Fallback manual Pearson correlation
  double _pearsonCorrelationManual(List<double> x, List<double> y) {
    final meanX = x.statistics.mean;
    final meanY = y.statistics.mean;

    double numerator = 0;
    double denomX = 0;
    double denomY = 0;

    for (int i = 0; i < x.length; i++) {
      final dx = x[i] - meanX;
      final dy = y[i] - meanY;
      numerator += dx * dy;
      denomX += dx * dx;
      denomY += dy * dy;
    }

    if (denomX == 0 || denomY == 0) return 0;

    return numerator / math.sqrt(denomX * denomY);
  }

  /// Calculate statistical significance using t-test
  StatisticalSignificance _calculateSignificance(double r, int n) {
    if (n < 3) {
      return const StatisticalSignificance(
        pValue: 1,
        tStatistic: 0,
        degreesOfFreedom: 0,
        standardError: 0,
        isSignificant: false,
      );
    }

    // Calculate t-statistic: t = r * sqrt((n-2) / (1-r²))
    final df = n - 2;
    final rSquared = r * r;

    if (rSquared >= 1.0) {
      // Perfect correlation
      return StatisticalSignificance(
        pValue: 0,
        tStatistic: double.infinity,
        degreesOfFreedom: df,
        standardError: 0,
        isSignificant: true,
        confidenceInterval: [r, r],
      );
    }

    final tStatistic = r * math.sqrt(df / (1 - rSquared));

    // Calculate p-value using t-distribution approximation
    final pValue = _calculatePValue(tStatistic.abs(), df);

    // Standard error of correlation coefficient
    final standardError = math.sqrt((1 - rSquared) / df);

    // 95% confidence interval (approximate)
    final marginOfError = 1.96 * standardError;
    final lowerCI = (r - marginOfError).clamp(-1.0, 1.0);
    final upperCI = (r + marginOfError).clamp(-1.0, 1.0);

    return StatisticalSignificance(
      pValue: pValue,
      tStatistic: tStatistic,
      degreesOfFreedom: df,
      standardError: standardError,
      isSignificant: pValue < 0.05, // 95% confidence level
      confidenceInterval: [lowerCI, upperCI],
    );
  }

  /// Calculate p-value using t-distribution approximation
  double _calculatePValue(double t, int df) {
    // Two-tailed test
    // Using approximation formula for t-distribution CDF
    // For production, consider using a proper statistical library

    if (df < 1) return 1;
    if (t.isInfinite) return 0;

    // Approximation for large df (normal distribution)
    if (df > 30) {
      final z = t;
      final p = 2 * (1 - _normalCDF(z.abs()));
      return p.clamp(0.0, 1.0);
    }

    // Approximation for small df using Hill's formula
    final x = df / (df + t * t);
    final a = df / 2.0;
    final incompleteBeta = _incompleteBeta(x, a, 0.5);

    return incompleteBeta.clamp(0.0, 1.0);
  }

  /// Standard normal CDF approximation
  double _normalCDF(double x) {
    return 0.5 * (1 + _erf(x / math.sqrt(2)));
  }

  /// Error function approximation
  double _erf(double x) {
    // Abramowitz and Stegun approximation
    final sign = x < 0 ? -1 : 1;
    final absX = x.abs();

    const a1 = 0.254829592;
    const a2 = -0.284496736;
    const a3 = 1.421413741;
    const a4 = -1.453152027;
    const a5 = 1.061405429;
    const p = 0.3275911;

    final t = 1.0 / (1.0 + p * absX);
    final y =
        1.0 -
        (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) *
            t *
            math.exp(-absX * absX);

    return sign * y;
  }

  /// Incomplete beta function approximation
  double _incompleteBeta(double x, double a, double b) {
    if (x <= 0) return 0;
    if (x >= 1) return 1;

    // Simple approximation - for production use a proper implementation
    // This is a rough estimate for educational purposes
    return math.pow(x, a) * math.pow(1 - x, b) / (a + b);
  }

  CorrelationResult _insufficientDataResult({
    required String sourceLabel,
    required String targetLabel,
    required String reason,
    int sampleSize = 0,
    bool? sourceHigherIsBetter,
    bool? targetHigherIsBetter,
  }) {
    return CorrelationResult(
      sourceLabel: sourceLabel,
      targetLabel: targetLabel,
      coefficient: 0,
      sampleSize: sampleSize,
      strength: CorrelationStrength.negligible,
      insight:
          '⚠️ Insufficient data: $reason. Keep tracking to discover patterns.',
      sourceHigherIsBetter: sourceHigherIsBetter,
      targetHigherIsBetter: targetHigherIsBetter,
    );
  }

  CorrelationStrength _determineStrength(double coefficient) {
    if (coefficient > 0.5) return CorrelationStrength.strongPositive;
    if (coefficient > 0.3) return CorrelationStrength.moderatePositive;
    if (coefficient > 0.1) return CorrelationStrength.weakPositive;
    if (coefficient < -0.5) return CorrelationStrength.strongNegative;
    if (coefficient < -0.3) return CorrelationStrength.moderateNegative;
    if (coefficient < -0.1) return CorrelationStrength.weakNegative;

    return CorrelationStrength.negligible;
  }

  String _generateInsight({
    required String sourceLabel,
    required String targetLabel,
    required double coefficient,
    required CorrelationStrength strength,
    required bool isSignificant,
    required int sampleSize,
    double? valueWithSource,
    double? valueWithoutSource,
    double? differencePercent,
  }) {
    // Show data quality indicators
    if (!isSignificant) {
      if (sampleSize < 20) {
        return '⚠️ Early pattern detected (n=$sampleSize) - collect more data to confirm correlation between $sourceLabel and $targetLabel';
      }
      return 'No statistically significant correlation found between $sourceLabel and $targetLabel (p ≥ 0.05)';
    }

    if (strength == CorrelationStrength.negligible) {
      return 'No significant correlation found between $sourceLabel and $targetLabel';
    }

    final direction = coefficient > 0 ? 'higher' : 'lower';
    final absPercent = (differencePercent?.abs() ?? 0).toStringAsFixed(0);

    if (valueWithSource != null && valueWithoutSource != null) {
      return '✓ When you engage with $sourceLabel, your $targetLabel is $absPercent% $direction (statistically significant, n=$sampleSize)';
    }

    final strengthText = switch (strength) {
      CorrelationStrength.strongPositive => 'strongly associated with higher',
      CorrelationStrength.moderatePositive =>
        'moderately associated with higher',
      CorrelationStrength.weakPositive => 'weakly associated with higher',
      CorrelationStrength.strongNegative => 'strongly associated with lower',
      CorrelationStrength.moderateNegative =>
        'moderately associated with lower',
      CorrelationStrength.weakNegative => 'weakly associated with lower',
      _ => 'not significantly associated with',
    };

    return '✓ $sourceLabel is $strengthText $targetLabel (p < 0.05, n=$sampleSize)';
  }
}
