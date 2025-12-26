import 'package:taskly_bloc/presentation/features/analytics/domain/models/date_range.dart';
import 'package:taskly_bloc/presentation/features/analytics/domain/models/mood_summary.dart';
import 'package:taskly_bloc/presentation/features/analytics/domain/models/trend_data.dart';
import 'package:taskly_bloc/presentation/features/analytics/domain/services/trend_calculator.dart';

/// Calculates mood-related statistics
class MoodStatsCalculator {
  MoodStatsCalculator(this._trendCalculator);
  final TrendCalculator _trendCalculator;

  MoodSummary calculateSummary({
    required Map<DateTime, double> moodData,
  }) {
    if (moodData.isEmpty) {
      return const MoodSummary(
        average: 0,
        totalEntries: 0,
        min: 0,
        max: 0,
        distribution: {},
      );
    }

    final values = moodData.values.toList();
    final average = values.reduce((a, b) => a + b) / values.length;
    final min = values.map((v) => v.round()).reduce((a, b) => a < b ? a : b);
    final max = values.map((v) => v.round()).reduce((a, b) => a > b ? a : b);

    // Calculate distribution
    final Map<int, int> distribution = {};
    for (final value in values) {
      final rating = value.round();
      distribution[rating] = (distribution[rating] ?? 0) + 1;
    }

    return MoodSummary(
      average: average,
      totalEntries: values.length,
      min: min,
      max: max,
      distribution: distribution,
    );
  }

  Map<int, int> calculateDistribution({
    required Map<DateTime, double> moodData,
  }) {
    final Map<int, int> distribution = {};

    for (final value in moodData.values) {
      final rating = value.round();
      distribution[rating] = (distribution[rating] ?? 0) + 1;
    }

    return distribution;
  }

  TrendData calculateTrend({
    required Map<DateTime, double> moodData,
    required DateRange range,
    TrendGranularity granularity = TrendGranularity.daily,
  }) {
    return _trendCalculator.calculate(
      data: moodData,
      range: range,
      granularity: granularity,
    );
  }
}
