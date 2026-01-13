import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/value_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/analytics/model/analytics_snapshot.dart';
import 'package:taskly_bloc/domain/analytics/model/correlation_request.dart';
import 'package:taskly_bloc/domain/analytics/model/correlation_result.dart';
import 'package:taskly_bloc/domain/analytics/model/date_range.dart';
import 'package:taskly_bloc/domain/analytics/model/entity_type.dart';
import 'package:taskly_bloc/domain/analytics/model/mood_summary.dart';
import 'package:taskly_bloc/domain/queries/project_predicate.dart';
import 'package:taskly_bloc/domain/queries/project_query.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/analytics/model/stat_result.dart';
import 'package:taskly_bloc/domain/analytics/model/task_stat_type.dart';
import 'package:taskly_bloc/domain/analytics/model/trend_data.dart';
import 'package:taskly_bloc/domain/interfaces/analytics_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/journal_repository_contract.dart';
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
    required ValueRepositoryContract valueRepo,
    required JournalRepositoryContract journalRepo,
  }) : _analyticsRepo = analyticsRepo,
       _taskRepo = taskRepo,
       _projectRepo = projectRepo,
       _valueRepo = valueRepo,
       _journalRepo = journalRepo,
       _taskStatsCalculator = TaskStatsCalculator(),
       _trendCalculator = TrendCalculator(),
       _moodStatsCalculator = MoodStatsCalculator(TrendCalculator()),
       _correlationCalculator = CorrelationCalculator();
  final AnalyticsRepositoryContract _analyticsRepo;
  final TaskRepositoryContract _taskRepo;
  final ProjectRepositoryContract _projectRepo;
  final ValueRepositoryContract _valueRepo;
  final JournalRepositoryContract _journalRepo;
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
    final moodData = await _journalRepo.getDailyMoodAverages(
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
    final moodData = await _journalRepo.getDailyMoodAverages(
      range: range,
    );

    return _moodStatsCalculator.calculateDistribution(moodData: moodData);
  }

  @override
  Future<MoodSummary> getMoodSummary({
    required DateRange range,
  }) async {
    final moodData = await _journalRepo.getDailyMoodAverages(
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
    final trackerData = await _journalRepo.getTrackerValues(
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
    final trackers = await _journalRepo.getAllTrackers();

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
    final tracker = await _journalRepo.getTrackerById(trackerId);
    final trackerValues = await _journalRepo.getTrackerValues(
      trackerId: trackerId,
      range: range,
    );
    final moodData = await _journalRepo.getDailyMoodAverages(
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

    final moodData = await _journalRepo.getDailyMoodAverages(
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
    final tracker1 = await _journalRepo.getTrackerById(trackerId1);
    final tracker2 = await _journalRepo.getTrackerById(trackerId2);

    final tracker1Values = await _journalRepo.getTrackerValues(
      trackerId: trackerId1,
      range: range,
    );

    final tracker2Values = await _journalRepo.getTrackerValues(
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
      EntityType.value => await _getValueLabel(entityId),
    };
  }

  Future<String> _getTaskLabel(String taskId) async {
    final task = await _taskRepo.getById(taskId);
    return task?.name ?? 'Unknown Task';
  }

  Future<String> _getProjectLabel(String projectId) async {
    final project = await _projectRepo.getById(projectId);
    return project?.name ?? 'Unknown Project';
  }

  Future<String> _getValueLabel(String valueId) async {
    final value = await _valueRepo.getById(valueId);
    return value?.name ?? 'Unknown Value';
  }

  @override
  Future<Map<String, int>> getRecentCompletionsByValue({
    required int days,
  }) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));

    // Query completed tasks since cutoff using TaskQuery
    final query = TaskQuery(
      filter: QueryFilter<TaskPredicate>(
        shared: [
          const TaskBoolPredicate(
            field: TaskBoolField.completed,
            operator: BoolOperator.isTrue,
          ),
          TaskDatePredicate(
            field: TaskDateField.completedAt,
            operator: DateOperator.onOrAfter,
            date: cutoff,
          ),
        ],
      ),
    );
    final completedTasks = await _taskRepo.getAll(query);

    // Count by value
    final counts = <String, int>{};
    for (final task in completedTasks) {
      // Get values for this task
      for (final value in task.values) {
        counts[value.id] = (counts[value.id] ?? 0) + 1;
      }
    }

    return counts;
  }

  @override
  Future<int> getTotalRecentCompletions({required int days}) async {
    final completionsByValue = await getRecentCompletionsByValue(days: days);
    return completionsByValue.values.fold<int>(0, (sum, count) => sum + count);
  }

  @override
  Future<Map<String, List<double>>> getValueWeeklyTrends({
    required int weeks,
  }) async {
    final trends = <String, List<double>>{};
    final now = DateTime.now();

    // Initialize trends map for all values
    final values = await _valueRepo.getAll();
    for (final value in values) {
      trends[value.id] = List.filled(weeks, 0);
    }

    for (var i = weeks - 1; i >= 0; i--) {
      final weekStart = now.subtract(Duration(days: (i + 1) * 7));
      final weekEnd = now.subtract(Duration(days: i * 7));

      // Query completed tasks in range using TaskQuery
      final query = TaskQuery(
        filter: QueryFilter<TaskPredicate>(
          shared: [
            const TaskBoolPredicate(
              field: TaskBoolField.completed,
              operator: BoolOperator.isTrue,
            ),
            TaskDatePredicate(
              field: TaskDateField.completedAt,
              operator: DateOperator.between,
              startDate: weekStart,
              endDate: weekEnd,
            ),
          ],
        ),
      );
      final completions = await _taskRepo.getAll(query);

      // Count total completions this week
      final totalThisWeek = completions.length;
      if (totalThisWeek == 0) continue;

      // Count per value and calculate percentage
      final valueCounts = <String, int>{};
      for (final task in completions) {
        for (final value in task.values) {
          valueCounts[value.id] = (valueCounts[value.id] ?? 0) + 1;
        }
      }

      for (final entry in valueCounts.entries) {
        final weekIndex = weeks - 1 - i;
        if (trends.containsKey(entry.key)) {
          trends[entry.key]![weekIndex] = entry.value / totalThisWeek * 100;
        }
      }
    }

    return trends;
  }

  @override
  Future<Map<String, ValueActivityStats>> getValueActivityStats() async {
    final stats = <String, ValueActivityStats>{};

    // Get incomplete tasks using TaskQuery
    final taskQuery = TaskQuery(
      filter: const QueryFilter<TaskPredicate>(
        shared: [
          TaskBoolPredicate(
            field: TaskBoolField.completed,
            operator: BoolOperator.isFalse,
          ),
        ],
      ),
    );
    final tasks = await _taskRepo.getAll(taskQuery);

    final taskCounts = <String, int>{};
    for (final task in tasks) {
      for (final value in task.values) {
        taskCounts[value.id] = (taskCounts[value.id] ?? 0) + 1;
      }
    }

    // Get incomplete projects using ProjectQuery
    final projectQuery = ProjectQuery(
      filter: const QueryFilter<ProjectPredicate>(
        shared: [
          ProjectBoolPredicate(
            field: ProjectBoolField.completed,
            operator: BoolOperator.isFalse,
          ),
        ],
      ),
    );
    final projects = await _projectRepo.getAll(projectQuery);

    final projectCounts = <String, int>{};
    for (final project in projects) {
      for (final value in project.values) {
        projectCounts[value.id] = (projectCounts[value.id] ?? 0) + 1;
      }
    }

    // Combine into stats
    final allValueIds = {...taskCounts.keys, ...projectCounts.keys};
    for (final valueId in allValueIds) {
      stats[valueId] = ValueActivityStats(
        taskCount: taskCounts[valueId] ?? 0,
        projectCount: projectCounts[valueId] ?? 0,
      );
    }

    return stats;
  }
}
