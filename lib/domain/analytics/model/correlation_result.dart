import 'package:freezed_annotation/freezed_annotation.dart';

part 'correlation_result.freezed.dart';
part 'correlation_result.g.dart';

/// Correlation between any two data series
@freezed
abstract class CorrelationResult with _$CorrelationResult {
  const factory CorrelationResult({
    required String sourceLabel,
    required String targetLabel,
    required double coefficient,
    required CorrelationStrength strength,
    String? sourceId,
    String? targetId,
    String? sourceType,
    String? targetType,
    int? sampleSize,
    String? insight,
    double? valueWithSource,
    double? valueWithoutSource,
    double? differencePercent,
    bool? sourceHigherIsBetter,
    bool? targetHigherIsBetter,
    StatisticalSignificance? statisticalSignificance,
    PerformanceMetrics? performanceMetrics,
  }) = _CorrelationResult;
  const CorrelationResult._();

  factory CorrelationResult.fromJson(Map<String, dynamic> json) =>
      _$CorrelationResultFromJson(json);
}

/// Statistical significance metrics for correlation
@freezed
abstract class StatisticalSignificance with _$StatisticalSignificance {
  const factory StatisticalSignificance({
    required double pValue, // Probability correlation is by chance
    required double tStatistic, // t-test statistic
    required int degreesOfFreedom, // n - 2
    required double standardError, // Standard error of coefficient
    required bool isSignificant, // p < 0.05
    @Default([0, 0]) List<double> confidenceInterval, // 95% CI [lower, upper]
  }) = _StatisticalSignificance;

  factory StatisticalSignificance.fromJson(Map<String, dynamic> json) =>
      _$StatisticalSignificanceFromJson(json);
}

/// Performance metrics for calculation tracking
@freezed
abstract class PerformanceMetrics with _$PerformanceMetrics {
  const factory PerformanceMetrics({
    required int calculationTimeMs,
    required int dataPoints,
    required String algorithm, // 'ml_linalg_simd' or 'manual'
    int? memoryUsedBytes,
  }) = _PerformanceMetrics;

  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) =>
      _$PerformanceMetricsFromJson(json);
}

enum CorrelationStrength {
  strongPositive, // r > 0.5
  moderatePositive, // r > 0.3
  weakPositive, // r > 0.1
  negligible, // |r| <= 0.1
  weakNegative, // r < -0.1
  moderateNegative, // r < -0.3
  strongNegative, // r < -0.5
}
