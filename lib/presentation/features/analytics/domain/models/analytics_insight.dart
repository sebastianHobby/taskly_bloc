import 'package:freezed_annotation/freezed_annotation.dart';

part 'analytics_insight.freezed.dart';
part 'analytics_insight.g.dart';

/// Statistical insight generated from correlation and trend analysis
@freezed
abstract class AnalyticsInsight with _$AnalyticsInsight {
  const factory AnalyticsInsight({
    required String id,
    required String userId,
    required InsightType insightType,
    required String title,
    required String description,
    required DateTime generatedAt,
    required DateTime periodStart,
    required DateTime periodEnd,
    @Default({}) Map<String, dynamic> metadata,
    double? score, // 0-100 importance score
    double? confidence, // 0-1 statistical confidence
    @Default(true) bool isPositive,
  }) = _AnalyticsInsight;

  factory AnalyticsInsight.fromJson(Map<String, dynamic> json) =>
      _$AnalyticsInsightFromJson(json);
}

enum InsightType {
  @JsonValue('correlation_discovery')
  correlationDiscovery,
  @JsonValue('trend_alert')
  trendAlert,
  @JsonValue('anomaly_detection')
  anomalyDetection,
  @JsonValue('productivity_pattern')
  productivityPattern,
  @JsonValue('mood_pattern')
  moodPattern,
  @JsonValue('recommendation')
  recommendation,
}
