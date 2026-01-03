import 'package:taskly_bloc/domain/models/analytics/analytics_snapshot.dart';
import 'package:taskly_bloc/domain/models/analytics/correlation_request.dart';
import 'package:taskly_bloc/domain/models/analytics/correlation_result.dart';
import 'package:taskly_bloc/domain/models/analytics/date_range.dart';
import 'package:taskly_bloc/domain/models/analytics/entity_type.dart';
import 'package:taskly_bloc/domain/models/analytics/mood_summary.dart';
import 'package:taskly_bloc/domain/models/analytics/stat_result.dart';
import 'package:taskly_bloc/domain/models/analytics/task_stat_type.dart';
import 'package:taskly_bloc/domain/models/analytics/trend_data.dart';

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

  // === Orphan Tasks ===

  /// Returns count of incomplete tasks without a value assigned.
  ///
  /// Counts tasks where:
  /// - `completed == false`
  /// - Has no labels of type `LabelType.value`
  ///
  /// If [excludeWithDeadline] is true, tasks with deadlines are
  /// not counted (they may still appear via urgency handling).
  Future<int> getOrphanTaskCount({bool excludeWithDeadline = false});

  // === Reflector Mode Analytics ===

  /// Returns count of completed tasks per value over the last [days] days.
  ///
  /// Used by Reflector mode to calculate neglect scores.
  /// Returns map of valueId -> completion count.
  ///
  /// Tasks are counted based on their completion date, not creation date.
  /// Only tasks that have a value label assigned are counted.
  Future<Map<String, int>> getRecentCompletionsByValue({required int days});

  /// Returns the total number of completions in the last [days] days.
  ///
  /// Used to determine if Reflector mode has sufficient history.
  Future<int> getTotalRecentCompletions({required int days});

  // === Enhanced Values Screen Analytics ===

  /// Returns completion distribution by value over the last [weeks] weeks.
  ///
  /// Returns a map of valueId -> list of weekly completion percentages.
  /// Each inner list has [weeks] elements, oldest first.
  Future<Map<String, List<double>>> getValueWeeklyTrends({required int weeks});

  /// Returns active task and project counts per value.
  ///
  /// "Active" means incomplete tasks and projects.
  Future<Map<String, ValueActivityStats>> getValueActivityStats();
}

/// Activity statistics for a single value.
class ValueActivityStats {
  const ValueActivityStats({
    required this.taskCount,
    required this.projectCount,
  });

  final int taskCount;
  final int projectCount;
}
