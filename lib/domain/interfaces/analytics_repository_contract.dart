import 'package:taskly_bloc/domain/analytics/model/analytics_insight.dart';
import 'package:taskly_bloc/domain/analytics/model/analytics_snapshot.dart';
import 'package:taskly_bloc/domain/analytics/model/correlation_result.dart';
import 'package:taskly_bloc/domain/analytics/model/date_range.dart';

/// Repository contract for analytics data
abstract class AnalyticsRepositoryContract {
  // === Snapshots ===

  Future<List<AnalyticsSnapshot>> getSnapshots({
    required String entityType,
    required DateRange range,
    String? entityId,
  });

  Future<void> saveSnapshot(AnalyticsSnapshot snapshot);

  Future<void> saveSnapshots(List<AnalyticsSnapshot> snapshots);

  // === Correlations ===

  Future<List<CorrelationResult>> getCachedCorrelations({
    required String correlationType,
    required DateRange range,
  });

  Future<void> saveCorrelation(CorrelationResult correlation);

  Future<void> saveCorrelations(List<CorrelationResult> correlations);

  // === Insights ===

  Future<List<AnalyticsInsight>> getRecentInsights({
    required DateRange range,
    int? limit,
  });

  Future<void> saveInsight(AnalyticsInsight insight);

  Future<void> dismissInsight(String insightId);
}
