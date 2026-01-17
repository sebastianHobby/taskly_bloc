import 'package:taskly_domain/src/analytics/model/analytics_insight.dart';
import 'package:taskly_domain/src/analytics/model/analytics_snapshot.dart';
import 'package:taskly_domain/src/analytics/model/correlation_result.dart';
import 'package:taskly_domain/src/analytics/model/date_range.dart';
import 'package:taskly_domain/src/telemetry/operation_context.dart';

/// Repository contract for analytics data
abstract class AnalyticsRepositoryContract {
  // === Snapshots ===

  Future<List<AnalyticsSnapshot>> getSnapshots({
    required String entityType,
    required DateRange range,
    String? entityId,
  });

  Future<void> saveSnapshot(AnalyticsSnapshot snapshot, {OperationContext? context});

  Future<void> saveSnapshots(
    List<AnalyticsSnapshot> snapshots, {
    OperationContext? context,
  });

  // === Correlations ===

  Future<List<CorrelationResult>> getCachedCorrelations({
    required String correlationType,
    required DateRange range,
  });

  Future<void> saveCorrelation(
    CorrelationResult correlation, {
    OperationContext? context,
  });

  Future<void> saveCorrelations(
    List<CorrelationResult> correlations, {
    OperationContext? context,
  });

  // === Insights ===

  Future<List<AnalyticsInsight>> getRecentInsights({
    required DateRange range,
    int? limit,
  });

  Future<void> saveInsight(AnalyticsInsight insight, {OperationContext? context});

  Future<void> dismissInsight(String insightId, {OperationContext? context});
}
