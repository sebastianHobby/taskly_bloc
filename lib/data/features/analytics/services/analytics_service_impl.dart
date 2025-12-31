import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/interfaces/label_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/models/analytics/analytics_snapshot.dart';
import 'package:taskly_bloc/domain/models/analytics/correlation_request.dart';
import 'package:taskly_bloc/domain/models/analytics/correlation_result.dart';
import 'package:taskly_bloc/domain/models/analytics/date_range.dart';
import 'package:taskly_bloc/domain/models/analytics/entity_type.dart';
import 'package:taskly_bloc/domain/models/analytics/mood_summary.dart';
import 'package:taskly_bloc/domain/models/analytics/stat_result.dart';
import 'package:taskly_bloc/domain/models/analytics/task_stat_type.dart';
import 'package:taskly_bloc/domain/models/analytics/trend_data.dart';
import 'package:taskly_bloc/domain/interfaces/analytics_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/wellbeing_repository_contract.dart';
import 'package:taskly_bloc/domain/services/analytics/analytics_service.dart';
import 'package:taskly_bloc/domain/services/analytics/correlation_calculator.dart';
import 'package:taskly_bloc/domain/services/analytics/mood_stats_calculator.dart';
import 'package:taskly_bloc/domain/services/analytics/task_stats_calculator.dart';
import 'package:taskly_bloc/domain/services/analytics/trend_calculator.dart';

class AnalyticsServiceImpl implements AnalyticsService {
  AnalyticsServiceImpl({
    required AnalyticsRepositoryContract analyticsRepo,
    required TaskRepositoryContract taskRepo,
    required ProjectRepositoryContract projectRepo,
    required LabelRepositoryContract labelRepo,
    required WellbeingRepositoryContract wellbeingRepo,
  }) : _analyticsRepo = analyticsRepo,
       _taskRepo = taskRepo,
       _projectRepo = projectRepo,
       _labelRepo = labelRepo,
       _wellbeingRepo = wellbeingRepo,
       _taskStatsCalculator = TaskStatsCalculator(),
       _trendCalculator = TrendCalculator(),
       _moodStatsCalculator = MoodStatsCalculator(TrendCalculator()),
       _correlationCalculator = CorrelationCalculator();
  final AnalyticsRepositoryContract _analyticsRepo;
  final TaskRepositoryContract _taskRepo;
  final ProjectRepositoryContract _projectRepo;
  final LabelRepositoryContract _labelRepo;
  final WellbeingRepositoryContract _wellbeingRepo;
  final TaskStatsCalculator _taskStatsCalculator;
  final CorrelationCalculator _correlationCalculator;
  final MoodStatsCalculator _moodStatsCalculator;
  final TrendCalculator _trendCalculator;

  @override
  Future<StatResult> getTaskStat({
    required String entityId,
    required EntityType entityType,
    required TaskStatType statType,
    DateRange? range,
  }) async {
    final tasks = await _getTasksForEntity(
      entityId: entityId,
      entityType: entityType,
    );

    return _taskStatsCalculator.calculate(
      tasks: tasks,
      statType: statType,
      range: range,
    );
  }

  @override
  Future<Map<TaskStatType, StatResult>> getTaskStats({
    required String entityId,
    required EntityType entityType,
    required Set<TaskStatType> statTypes,
    DateRange? range,
  }) async {
    final tasks = await _getTasksForEntity(
      entityId: entityId,
      entityType: entityType,
    );

    final Map<TaskStatType, StatResult> results = {};
    for (final statType in statTypes) {
      results[statType] = _taskStatsCalculator.calculate(
        tasks: tasks,
        statType: statType,
        range: range,
      );
    }

    return results;
  }

  @override
  Future<TrendData> getMoodTrend({
    required DateRange range,
    TrendGranularity granularity = TrendGranularity.daily,
  }) async {
    final moodData = await _wellbeingRepo.getDailyMoodAverages(
      range: range,
    );

    return _moodStatsCalculator.calculateTrend(
      moodData: moodData,
      range: range,
      granularity: granularity,
    );
  }

  @override
  Future<Map<int, int>> getMoodDistribution({
    required DateRange range,
  }) async {
    final moodData = await _wellbeingRepo.getDailyMoodAverages(
      range: range,
    );

    return _moodStatsCalculator.calculateDistribution(moodData: moodData);
  }

  @override
  Future<MoodSummary> getMoodSummary({
    required DateRange range,
  }) async {
    final moodData = await _wellbeingRepo.getDailyMoodAverages(
      range: range,
    );

    return _moodStatsCalculator.calculateSummary(moodData: moodData);
  }

  @override
  Future<TrendData> getTrackerTrend({
    required String trackerId,
    required DateRange range,
    TrendGranularity granularity = TrendGranularity.daily,
  }) async {
    final trackerData = await _wellbeingRepo.getTrackerValues(
      trackerId: trackerId,
      range: range,
    );

    return _trendCalculator.calculate(
      data: trackerData,
      range: range,
      granularity: granularity,
    );
  }

  @override
  Future<CorrelationResult> calculateCorrelation({
    required CorrelationRequest request,
  }) async {
    return request.when(
      moodVsTracker: (trackerId, range) async {
        return _calculateMoodVsTracker(trackerId, range);
      },
      moodVsEntity: (entityId, entityType, range) async {
        return _calculateMoodVsEntity(entityId, entityType, range);
      },
      trackerVsTracker: (trackerId1, trackerId2, range) async {
        return _calculateTrackerVsTracker(
          trackerId1,
          trackerId2,
          range,
        );
      },
    );
  }

  @override
  Future<List<CorrelationResult>> getTopMoodCorrelations({
    required DateRange range,
    int limit = 10,
  }) async {
    // Get all trackers
    final trackers = await _wellbeingRepo.getAllTrackers();

    // Calculate correlations for each tracker
    final List<CorrelationResult> correlations = [];
    for (final tracker in trackers) {
      try {
        final correlation = await _calculateMoodVsTracker(
          tracker.id,
          range,
        );
        if (correlation.coefficient.abs() > 0.1) {
          // Only include meaningful correlations
          correlations.add(correlation);
        }
      } catch (_) {
        // Skip trackers with insufficient data
      }
    }

    // Sort by absolute coefficient value
    correlations.sort(
      (a, b) => b.coefficient.abs().compareTo(a.coefficient.abs()),
    );

    return correlations.take(limit).toList();
  }

  @override
  Future<List<AnalyticsSnapshot>> getSnapshots({
    required String entityType,
    required DateRange range,
    String? entityId,
  }) async {
    return _analyticsRepo.getSnapshots(
      entityType: entityType,
      entityId: entityId,
      range: range,
    );
  }

  // === Private Helper Methods ===

  Future<List<Task>> _getTasksForEntity({
    required String entityId,
    required EntityType entityType,
  }) async {
    // Get all tasks - in a real implementation, this would be filtered
    final allTasks = await _taskRepo.watchAll().first;
    return allTasks;
  }

  Future<CorrelationResult> _calculateMoodVsTracker(
    String trackerId,
    DateRange range,
  ) async {
    final tracker = await _wellbeingRepo.getTrackerById(trackerId);
    final trackerValues = await _wellbeingRepo.getTrackerValues(
      trackerId: trackerId,
      range: range,
    );
    final moodData = await _wellbeingRepo.getDailyMoodAverages(
      range: range,
    );

    // Get days where tracker had values
    final sourceDays = trackerValues.keys.toList();

    return _correlationCalculator.calculate(
      sourceLabel: tracker?.name ?? 'Tracker',
      targetLabel: 'Mood',
      sourceDays: sourceDays,
      targetData: moodData,
    );
  }

  Future<CorrelationResult> _calculateMoodVsEntity(
    String entityId,
    EntityType entityType,
    DateRange range,
  ) async {
    final tasks = await _getTasksForEntity(
      entityId: entityId,
      entityType: entityType,
    );

    final taskDays = _taskStatsCalculator.getTaskDaysForEntity(
      tasks: tasks,
      entityId: entityId,
      entityType: entityType,
      range: range,
    );

    final moodData = await _wellbeingRepo.getDailyMoodAverages(
      range: range,
    );

    final entityLabel = await _getEntityLabel(entityId, entityType);

    return _correlationCalculator.calculate(
      sourceLabel: '$entityLabel tasks',
      targetLabel: 'Mood',
      sourceDays: taskDays['days'] ?? [],
      targetData: moodData,
    );
  }

  Future<CorrelationResult> _calculateTrackerVsTracker(
    String trackerId1,
    String trackerId2,
    DateRange range,
  ) async {
    final tracker1 = await _wellbeingRepo.getTrackerById(trackerId1);
    final tracker2 = await _wellbeingRepo.getTrackerById(trackerId2);

    final tracker1Values = await _wellbeingRepo.getTrackerValues(
      trackerId: trackerId1,
      range: range,
    );

    final tracker2Values = await _wellbeingRepo.getTrackerValues(
      trackerId: trackerId2,
      range: range,
    );

    return _correlationCalculator.calculate(
      sourceLabel: tracker1?.name ?? 'Tracker 1',
      targetLabel: tracker2?.name ?? 'Tracker 2',
      sourceDays: tracker1Values.keys.toList(),
      targetData: tracker2Values,
    );
  }

  Future<String> _getEntityLabel(String entityId, EntityType entityType) async {
    return switch (entityType) {
      EntityType.task => await _getTaskLabel(entityId),
      EntityType.project => await _getProjectLabel(entityId),
      EntityType.label => await _getLabelLabel(entityId),
      EntityType.value => await _getValueLabel(entityId),
    };
  }

  Future<String> _getTaskLabel(String taskId) async {
    final task = await _taskRepo.getById(taskId);
    return task?.name ?? 'Unknown Task';
  }

  Future<String> _getProjectLabel(String projectId) async {
    final project = await _projectRepo.get(projectId);
    return project?.name ?? 'Unknown Project';
  }

  Future<String> _getLabelLabel(String labelId) async {
    final label = await _labelRepo.get(labelId);
    return label?.name ?? 'Unknown Label';
  }

  Future<String> _getValueLabel(String valueId) async {
    // Values are typically labels with type=value
    final label = await _labelRepo.get(valueId);
    return label?.name ?? 'Unknown Value';
  }
}
