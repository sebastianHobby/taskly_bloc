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
import 'package:taskly_bloc/domain/services/analytics/task_stats_calculator.dart';

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
       _taskStatsCalculator = TaskStatsCalculator();
  final AnalyticsRepositoryContract _analyticsRepo;
  final TaskRepositoryContract _taskRepo;
  final ProjectRepositoryContract _projectRepo;
  final ValueRepositoryContract _valueRepo;
  final JournalRepositoryContract _journalRepo;
  final TaskStatsCalculator _taskStatsCalculator;
  static const _journalAnalyticsStubMessage =
      'Journal/tracker analytics are being rebuilt.';

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
    // The journal system is mid-migration to an event-log tracker model.
    // Read whatever the repository can provide, but keep rendering stable.
    await _journalRepo.getDailyMoodAverages(range: range);
    return TrendData(points: const [], granularity: granularity);
  }

  @override
  Future<Map<int, int>> getMoodDistribution({
    required DateRange range,
  }) async {
    // Stub while journal/tracker analytics are rebuilt.
    await _journalRepo.getDailyMoodAverages(range: range);
    return const {};
  }

  @override
  Future<MoodSummary> getMoodSummary({
    required DateRange range,
  }) async {
    // Stub while journal/tracker analytics are rebuilt.
    await _journalRepo.getDailyMoodAverages(range: range);
    return const MoodSummary(
      average: 0,
      totalEntries: 0,
      min: 0,
      max: 0,
      distribution: {},
    );
  }

  @override
  Future<TrendData> getTrackerTrend({
    required String trackerId,
    required DateRange range,
    TrendGranularity granularity = TrendGranularity.daily,
  }) async {
    // Stub while tracker event/projection reads are being finalized.
    await _journalRepo.getTrackerValues(trackerId: trackerId, range: range);
    return TrendData(points: const [], granularity: granularity);
  }

  @override
  Future<CorrelationResult> calculateCorrelation({
    required CorrelationRequest request,
  }) async {
    // Stub while journal/tracker analytics are rebuilt.
    return request.when(
      moodVsTracker: (trackerId, range) async => const CorrelationResult(
        sourceLabel: 'Tracker',
        targetLabel: 'Mood',
        coefficient: 0,
        strength: CorrelationStrength.negligible,
        sampleSize: 0,
        insight: _journalAnalyticsStubMessage,
      ),
      moodVsEntity: (entityId, entityType, range) async =>
          const CorrelationResult(
            sourceLabel: 'Entity',
            targetLabel: 'Mood',
            coefficient: 0,
            strength: CorrelationStrength.negligible,
            sampleSize: 0,
            insight: _journalAnalyticsStubMessage,
          ),
      trackerVsTracker: (trackerId1, trackerId2, range) async =>
          const CorrelationResult(
            sourceLabel: 'Tracker',
            targetLabel: 'Tracker',
            coefficient: 0,
            strength: CorrelationStrength.negligible,
            sampleSize: 0,
            insight: _journalAnalyticsStubMessage,
          ),
    );
  }

  @override
  Future<List<CorrelationResult>> getTopMoodCorrelations({
    required DateRange range,
    int limit = 10,
  }) async {
    // Stub while journal/tracker analytics are rebuilt.
    return const [];
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
