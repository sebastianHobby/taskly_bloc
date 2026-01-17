import 'package:freezed_annotation/freezed_annotation.dart';

part 'trend_data.freezed.dart';
part 'trend_data.g.dart';

/// Time series data for trend visualization
@freezed
abstract class TrendData with _$TrendData {
  const factory TrendData({
    required List<TrendPoint> points,
    required TrendGranularity granularity,
    double? average,
    double? min,
    double? max,
    TrendDirection? overallTrend,
  }) = _TrendData;

  factory TrendData.fromJson(Map<String, dynamic> json) =>
      _$TrendDataFromJson(json);
}

@freezed
abstract class TrendPoint with _$TrendPoint {
  const factory TrendPoint({
    required DateTime date,
    required double value,
    int? sampleCount,
  }) = _TrendPoint;

  factory TrendPoint.fromJson(Map<String, dynamic> json) =>
      _$TrendPointFromJson(json);
}

enum TrendGranularity {
  daily,
  weekly,
  monthly,
}

enum TrendDirection {
  up,
  down,
  stable,
}
