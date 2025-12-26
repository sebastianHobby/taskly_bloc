import 'package:taskly_bloc/presentation/features/analytics/domain/models/analytics_snapshot.dart';
import 'package:taskly_bloc/presentation/features/analytics/domain/models/correlation_request.dart';
import 'package:taskly_bloc/presentation/features/analytics/domain/models/correlation_result.dart';
import 'package:taskly_bloc/presentation/features/analytics/domain/models/date_range.dart';
import 'package:taskly_bloc/presentation/features/analytics/domain/models/entity_type.dart';
import 'package:taskly_bloc/presentation/features/analytics/domain/models/mood_summary.dart';
import 'package:taskly_bloc/presentation/features/analytics/domain/models/stat_result.dart';
import 'package:taskly_bloc/presentation/features/analytics/domain/models/task_stat_type.dart';
import 'package:taskly_bloc/presentation/features/analytics/domain/models/trend_data.dart';

/// Main entry point for all analytics
abstract class AnalyticsService {
  // === Task Statistics ===

  /// Get task-related statistics for an entity
  Future<StatResult> getTaskStat({
    required String entityId,
    required EntityType entityType,
    required TaskStatType statType,
    DateRange? range,
  });

  /// Get multiple task stats at once
  Future<Map<TaskStatType, StatResult>> getTaskStats({
    required String entityId,
    required EntityType entityType,
    required Set<TaskStatType> statTypes,
    DateRange? range,
  });

  // === Mood Statistics ===

  /// Get mood trend over time
  Future<TrendData> getMoodTrend({
    required DateRange range,
    TrendGranularity granularity = TrendGranularity.daily,
  });

  /// Get mood distribution (count per rating)
  Future<Map<int, int>> getMoodDistribution({
    required DateRange range,
  });

  /// Get mood summary stats
  Future<MoodSummary> getMoodSummary({
    required DateRange range,
  });

  // === Tracker Statistics ===

  /// Get trend for a specific tracker
  Future<TrendData> getTrackerTrend({
    required String trackerId,
    required DateRange range,
    TrendGranularity granularity = TrendGranularity.daily,
  });

  // === Correlations ===

  /// Calculate correlation between any two data series
  Future<CorrelationResult> calculateCorrelation({
    required CorrelationRequest request,
  });

  /// Get top correlations for mood
  Future<List<CorrelationResult>> getTopMoodCorrelations({
    required DateRange range,
    int limit = 10,
  });

  // === Snapshots (Server-Side) ===

  /// Get historical snapshots for trend analysis
  Future<List<AnalyticsSnapshot>> getSnapshots({
    required String entityType,
    required DateRange range,
    String? entityId,
  });
}
