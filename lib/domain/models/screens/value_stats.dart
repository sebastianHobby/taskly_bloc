import 'package:freezed_annotation/freezed_annotation.dart';

part 'value_stats.freezed.dart';
part 'value_stats.g.dart';

/// Statistics for a single value entity.
///
/// Used by EnrichmentResult.valueStats to provide per-value statistics
/// that can be rendered inline in value cards.
@freezed
abstract class ValueStats with _$ValueStats {
  const factory ValueStats({
    /// Target percentage based on value ranking weight.
    required double targetPercent,

    /// Actual percentage based on recent task completions.
    required double actualPercent,

    /// Number of active (non-completed) tasks with this value.
    required int taskCount,

    /// Number of projects associated with this value.
    required int projectCount,

    /// Weekly completion percentages for sparkline visualization.
    /// Length determined by EnrichmentConfig.sparklineWeeks.
    required List<double> weeklyTrend,

    /// Gap warning threshold from enrichment config.
    /// Range: 5-50%, Default: 15%
    @Default(15) int gapWarningThreshold,
  }) = _ValueStats;

  factory ValueStats.fromJson(Map<String, dynamic> json) =>
      _$ValueStatsFromJson(json);

  const ValueStats._();

  /// Difference between actual and target percentage.
  double get gap => actualPercent - targetPercent;

  /// Whether the gap exceeds the warning threshold.
  bool get isSignificantGap => gap.abs() >= gapWarningThreshold;
}
