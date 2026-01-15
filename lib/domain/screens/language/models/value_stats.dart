import 'package:freezed_annotation/freezed_annotation.dart';

part 'value_stats.freezed.dart';
part 'value_stats.g.dart';

/// Statistics for a single value entity.
///
/// Used by typed enrichment results to provide per-value statistics.
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
    /// Length determined by the requested sparkline weeks.
    required List<double> weeklyTrend,

    /// Number of active tasks where this value is the *primary* value.
    @Default(0) int primaryTaskCount,

    /// Number of active tasks where this value is a *secondary* value.
    @Default(0) int secondaryTaskCount,

    /// Number of active projects where this value is the *primary* value.
    @Default(0) int primaryProjectCount,

    /// Number of active projects where this value is a *secondary* value.
    @Default(0) int secondaryProjectCount,

    /// Lookback window used for the recent completion attribution.
    ///
    /// This is a UX-facing value used to explain the badge/statistics.
    @Default(28) int lookbackDays,

    /// Number of completed tasks (effective values) attributed to this value
    /// in the lookback window.
    @Default(0) int recentCompletionCount,

    /// Expected number of completions for this value in the lookback window,
    /// derived from targetPercent and the total number of completions.
    ///
    /// This can be fractional; UI may present a rounded value.
    @Default(0) double expectedRecentCompletionCount,

    /// Whether this value should show the “Needs attention” badge.
    ///
    /// This is computed as part of enrichment (not a pure function of the
    /// per-value fields) because it depends on comparing values.
    @Default(false) bool needsAttention,

    /// Gap warning threshold from enrichment config.
    /// Range: 5-50%, Default: 15%
    @Default(15) int gapWarningThreshold,
  }) = _ValueStats;

  factory ValueStats.fromJson(Map<String, dynamic> json) =>
      _$ValueStatsFromJson(json);

  const ValueStats._();

  /// Difference between actual and target percentage.
  double get gap => actualPercent - targetPercent;

  /// Recent shortfall count relative to expected completions.
  ///
  /// Always non-negative.
  double get recentShortfallCount {
    final shortfall = expectedRecentCompletionCount - recentCompletionCount;
    return shortfall <= 0 ? 0 : shortfall;
  }

  /// Whether the gap exceeds the warning threshold.
  bool get isSignificantGap => gap.abs() >= gapWarningThreshold;
}
