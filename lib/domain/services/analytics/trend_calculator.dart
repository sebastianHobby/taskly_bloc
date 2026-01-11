import 'package:taskly_bloc/domain/analytics/model/date_range.dart';
import 'package:taskly_bloc/domain/analytics/model/trend_data.dart';

/// Calculates time series trends
class TrendCalculator {
  TrendData calculate({
    required Map<DateTime, double> data,
    required DateRange range,
    required TrendGranularity granularity,
  }) {
    if (data.isEmpty) {
      return TrendData(
        points: const [],
        granularity: granularity,
        average: 0,
        min: 0,
        max: 0,
      );
    }

    // Aggregate by granularity
    final aggregated = _aggregate(data, granularity);

    // Create trend points
    final points = aggregated.entries.map((e) {
      return TrendPoint(
        date: e.key,
        value: e.value['average']! as double,
        sampleCount: e.value['count']! as int,
      );
    }).toList()..sort((a, b) => a.date.compareTo(b.date));

    // Calculate statistics
    final values = points.map((p) => p.value).toList();
    final average = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a + b) / values.length;
    final min = values.isEmpty ? 0.0 : values.reduce((a, b) => a < b ? a : b);
    final max = values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);

    final trend = _determineTrend(points);

    return TrendData(
      points: points,
      granularity: granularity,
      average: average,
      min: min,
      max: max,
      overallTrend: trend,
    );
  }

  Map<DateTime, Map<String, num>> _aggregate(
    Map<DateTime, double> data,
    TrendGranularity granularity,
  ) {
    final Map<DateTime, List<double>> grouped = {};

    for (final entry in data.entries) {
      final key = _getKey(entry.key, granularity);
      grouped.putIfAbsent(key, () => []).add(entry.value);
    }

    return grouped.map((key, values) {
      return MapEntry(key, {
        'average': values.reduce((a, b) => a + b) / values.length,
        'count': values.length,
      });
    });
  }

  DateTime _getKey(DateTime date, TrendGranularity granularity) {
    return switch (granularity) {
      TrendGranularity.daily => DateTime(date.year, date.month, date.day),
      TrendGranularity.weekly => _getWeekStart(date),
      TrendGranularity.monthly => DateTime(date.year, date.month),
    };
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(Duration(days: weekday - 1));
  }

  TrendDirection _determineTrend(List<TrendPoint> points) {
    if (points.length < 2) return TrendDirection.stable;

    final firstHalf = points.sublist(0, points.length ~/ 2);
    final secondHalf = points.sublist(points.length ~/ 2);

    final firstAvg = firstHalf.isEmpty
        ? 0.0
        : firstHalf.map((p) => p.value).reduce((a, b) => a + b) /
              firstHalf.length;
    final secondAvg = secondHalf.isEmpty
        ? 0.0
        : secondHalf.map((p) => p.value).reduce((a, b) => a + b) /
              secondHalf.length;

    final diff = secondAvg - firstAvg;
    const threshold = 0.1;

    if (diff > threshold) return TrendDirection.up;
    if (diff < -threshold) return TrendDirection.down;
    return TrendDirection.stable;
  }
}
