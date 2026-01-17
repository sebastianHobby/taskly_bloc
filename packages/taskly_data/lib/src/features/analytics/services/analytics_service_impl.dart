import 'package:taskly_domain/taskly_domain.dart';

class AnalyticsServiceImpl implements AnalyticsService {
  AnalyticsServiceImpl({
    required AnalyticsRepositoryContract analyticsRepo,
    required TaskRepositoryContract taskRepo,
    required ProjectRepositoryContract projectRepo,
    required ValueRepositoryContract valueRepo,
    required JournalRepositoryContract journalRepo,
    required HomeDayKeyService dayKeyService,
    Clock clock = systemClock,
  }) : _analyticsRepo = analyticsRepo,
       _taskRepo = taskRepo,
       _projectRepo = projectRepo,
       _valueRepo = valueRepo,
       _journalRepo = journalRepo,
       _dayKeyService = dayKeyService,
       _clock = clock,
       _taskStatsCalculator = TaskStatsCalculator(),
       _correlationCalculator = CorrelationCalculator();
  final AnalyticsRepositoryContract _analyticsRepo;
  final TaskRepositoryContract _taskRepo;
  final ProjectRepositoryContract _projectRepo;
  final ValueRepositoryContract _valueRepo;
  final JournalRepositoryContract _journalRepo;
  final HomeDayKeyService _dayKeyService;
  final Clock _clock;
  final TaskStatsCalculator _taskStatsCalculator;
  final CorrelationCalculator _correlationCalculator;

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

    final nowUtc = _clock.nowUtc();
    final todayDayKeyUtc = _dayKeyService.todayDayKeyUtc(nowUtc: nowUtc);

    return _taskStatsCalculator.calculate(
      tasks: tasks,
      statType: statType,
      nowUtc: nowUtc,
      todayDayKeyUtc: todayDayKeyUtc,
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

    final nowUtc = _clock.nowUtc();
    final todayDayKeyUtc = _dayKeyService.todayDayKeyUtc(nowUtc: nowUtc);

    final Map<TaskStatType, StatResult> results = {};
    for (final statType in statTypes) {
      results[statType] = _taskStatsCalculator.calculate(
        tasks: tasks,
        statType: statType,
        nowUtc: nowUtc,
        todayDayKeyUtc: todayDayKeyUtc,
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
    final daily = await _journalRepo.getDailyMoodAverages(range: range);
    final points = _aggregateTrend(daily, granularity);
    return _buildTrend(points: points, granularity: granularity);
  }

  @override
  Future<Map<int, int>> getMoodDistribution({
    required DateRange range,
  }) async {
    final moodTrackerId = await _getMoodTrackerId();
    if (moodTrackerId == null) return const <int, int>{};

    final events = await _journalRepo
        .watchTrackerEvents(
          range: range,
          anchorType: 'entry',
          trackerId: moodTrackerId,
        )
        .first;

    final dist = <int, int>{};
    for (final e in events) {
      final value = e.value;
      final rating = switch (value) {
        final int v => v,
        final double v => v.round(),
        _ => null,
      };
      if (rating == null) continue;
      dist[rating] = (dist[rating] ?? 0) + 1;
    }

    return dist;
  }

  @override
  Future<MoodSummary> getMoodSummary({
    required DateRange range,
  }) async {
    final moodTrackerId = await _getMoodTrackerId();
    if (moodTrackerId == null) {
      return const MoodSummary(
        average: 0,
        totalEntries: 0,
        min: 0,
        max: 0,
        distribution: {},
      );
    }

    final events = await _journalRepo
        .watchTrackerEvents(
          range: range,
          anchorType: 'entry',
          trackerId: moodTrackerId,
        )
        .first;

    final values = <double>[];
    final distribution = <int, int>{};

    for (final e in events) {
      final asDouble = switch (e.value) {
        final int v => v.toDouble(),
        final double v => v,
        _ => null,
      };
      if (asDouble == null) continue;

      values.add(asDouble);
      distribution[asDouble.round()] =
          (distribution[asDouble.round()] ?? 0) + 1;
    }

    if (values.isEmpty) {
      return const MoodSummary(
        average: 0,
        totalEntries: 0,
        min: 0,
        max: 0,
        distribution: {},
      );
    }

    final sum = values.fold<double>(0, (a, b) => a + b);
    final avg = sum / values.length;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);

    return MoodSummary(
      average: avg,
      totalEntries: values.length,
      min: min.round(),
      max: max.round(),
      distribution: distribution,
    );
  }

  @override
  Future<TrendData> getTrackerTrend({
    required String trackerId,
    required DateRange range,
    TrendGranularity granularity = TrendGranularity.daily,
  }) async {
    final daily = await _journalRepo.getTrackerValues(
      trackerId: trackerId,
      range: range,
    );
    final points = _aggregateTrend(daily, granularity);
    return _buildTrend(points: points, granularity: granularity);
  }

  @override
  Future<CorrelationResult> calculateCorrelation({
    required CorrelationRequest request,
  }) async {
    final defs = await _journalRepo.watchTrackerDefinitions().first;
    final defById = {for (final d in defs) d.id: d};

    TrackerDefinition? moodDefinition;
    for (final d in defs) {
      if (d.systemKey == 'mood') {
        moodDefinition = d;
        break;
      }
    }

    return request.when(
      moodVsTracker: (trackerId, range) async {
        final moodByDay = await _journalRepo.getDailyMoodAverages(range: range);
        final trackerByDay = await _journalRepo.getTrackerValues(
          trackerId: trackerId,
          range: range,
        );

        final trackerDays = trackerByDay.entries
            .where((e) => e.value > 0)
            .map((e) => e.key)
            .toList(growable: false);

        final labels = await _getTrackerLabels();

        return _correlationCalculator.calculate(
          sourceLabel: labels[trackerId] ?? 'Tracker',
          targetLabel: 'Mood',
          sourceDays: trackerDays,
          targetData: moodByDay,
          sourceHigherIsBetter: defById[trackerId]?.higherIsBetter,
          targetHigherIsBetter: moodDefinition?.higherIsBetter,
        );
      },
      moodVsEntity: (entityId, entityType, range) async {
        final moodByDay = await _journalRepo.getDailyMoodAverages(range: range);
        final activityDays = await _getEntityActivityDays(
          entityId: entityId,
          entityType: entityType,
          range: range,
        );

        final sourceLabel = await _getEntityLabel(
          entityId: entityId,
          entityType: entityType,
        );

        return _correlationCalculator.calculate(
          sourceLabel: sourceLabel,
          targetLabel: 'Mood',
          sourceDays: activityDays,
          targetData: moodByDay,
          targetHigherIsBetter: moodDefinition?.higherIsBetter,
        );
      },
      trackerVsTracker: (trackerId1, trackerId2, range) async {
        final series1 = await _journalRepo.getTrackerValues(
          trackerId: trackerId1,
          range: range,
        );
        final series2 = await _journalRepo.getTrackerValues(
          trackerId: trackerId2,
          range: range,
        );

        final sourceDays = series1.entries
            .where((e) => e.value > 0)
            .map((e) => e.key)
            .toList(growable: false);

        final labels = await _getTrackerLabels();

        return _correlationCalculator.calculate(
          sourceLabel: labels[trackerId1] ?? 'Tracker',
          targetLabel: labels[trackerId2] ?? 'Tracker',
          sourceDays: sourceDays,
          targetData: series2,
          sourceHigherIsBetter: defById[trackerId1]?.higherIsBetter,
          targetHigherIsBetter: defById[trackerId2]?.higherIsBetter,
        );
      },
    );
  }

  @override
  Future<List<CorrelationResult>> getTopMoodCorrelations({
    required DateRange range,
    int limit = 10,
  }) async {
    final moodByDay = await _journalRepo.getDailyMoodAverages(range: range);
    if (moodByDay.isEmpty) return const <CorrelationResult>[];

    final defs = await _journalRepo.watchTrackerDefinitions().first;

    TrackerDefinition? moodDefinition;
    for (final d in defs) {
      if (d.systemKey == 'mood') {
        moodDefinition = d;
        break;
      }
    }

    final defById = {for (final d in defs) d.id: d};

    final labels = {
      for (final d in defs)
        if (d.deletedAt == null && d.systemKey == null && d.isActive)
          d.id: d.name,
    };

    final results = <CorrelationResult>[];

    for (final trackerId in labels.keys) {
      final trackerByDay = await _journalRepo.getTrackerValues(
        trackerId: trackerId,
        range: range,
      );

      final trackerDays = trackerByDay.entries
          .where((e) => e.value > 0)
          .map((e) => e.key)
          .toList(growable: false);

      final result = _correlationCalculator.calculate(
        sourceLabel: labels[trackerId] ?? 'Tracker',
        targetLabel: 'Mood',
        sourceDays: trackerDays,
        targetData: moodByDay,
        sourceHigherIsBetter: defById[trackerId]?.higherIsBetter,
        targetHigherIsBetter: moodDefinition?.higherIsBetter,
      );

      results.add(result);
    }

    results.sort(
      (a, b) => b.coefficient.abs().compareTo(a.coefficient.abs()),
    );

    return results.take(limit).toList(growable: false);
  }

  // === Journal/Tracker Analytics Helpers ===

  Future<String?> _getMoodTrackerId() async {
    final defs = await _journalRepo.watchTrackerDefinitions().first;
    for (final d in defs) {
      if (d.systemKey == 'mood') return d.id;
    }
    return null;
  }

  Future<Map<String, String>> _getTrackerLabels() async {
    final defs = await _journalRepo.watchTrackerDefinitions().first;
    return {
      for (final d in defs) d.id: d.name,
    };
  }

  Future<String> _getEntityLabel({
    required String entityId,
    required EntityType entityType,
  }) async {
    return switch (entityType) {
      EntityType.task => (await _taskRepo.getById(entityId))?.name ?? 'Task',
      EntityType.project =>
        (await _projectRepo.getById(entityId))?.name ?? 'Project',
      EntityType.value => (await _valueRepo.getById(entityId))?.name ?? 'Value',
    };
  }

  Future<List<DateTime>> _getEntityActivityDays({
    required String entityId,
    required EntityType entityType,
    required DateRange range,
  }) async {
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
            startDate: range.start,
            endDate: range.end,
          ),
          if (entityType == EntityType.project)
            TaskProjectPredicate(
              operator: ProjectOperator.matches,
              projectId: entityId,
            ),
          if (entityType == EntityType.value)
            TaskValuePredicate(
              operator: ValueOperator.hasAll,
              valueIds: [entityId],
              includeInherited: true,
            ),
        ],
      ),
      occurrenceExpansion: OccurrenceExpansion(
        rangeStart: range.start,
        rangeEnd: range.end,
      ),
    );

    final completions = await _taskRepo.getAll(query);

    final days = <DateTime>{};
    for (final task in completions) {
      if (entityType == EntityType.task && task.id != entityId) continue;
      final completedAt = task.occurrence?.completedAt;
      if (completedAt == null || !range.contains(completedAt)) continue;
      final utc = completedAt.toUtc();
      days.add(DateTime.utc(utc.year, utc.month, utc.day));
    }

    final result = days.toList()..sort();
    return result;
  }

  List<TrendPoint> _aggregateTrend(
    Map<DateTime, double> daily,
    TrendGranularity granularity,
  ) {
    if (daily.isEmpty) return const <TrendPoint>[];

    final entries = daily.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    DateTime bucketKey(DateTime day) {
      final utc = DateTime.utc(day.year, day.month, day.day);
      return switch (granularity) {
        TrendGranularity.daily => utc,
        TrendGranularity.weekly => utc.subtract(
          Duration(days: utc.weekday - 1),
        ),
        TrendGranularity.monthly => DateTime.utc(utc.year, utc.month, 1),
      };
    }

    final valuesByBucket = <DateTime, List<double>>{};
    for (final e in entries) {
      (valuesByBucket[bucketKey(e.key)] ??= <double>[]).add(e.value);
    }

    final points = <TrendPoint>[];
    for (final bucket
        in valuesByBucket.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key))) {
      final values = bucket.value;
      if (values.isEmpty) continue;
      final sum = values.fold<double>(0, (a, b) => a + b);
      points.add(
        TrendPoint(
          date: bucket.key,
          value: sum / values.length,
          sampleCount: values.length,
        ),
      );
    }
    return points;
  }

  TrendData _buildTrend({
    required List<TrendPoint> points,
    required TrendGranularity granularity,
  }) {
    if (points.isEmpty) {
      return TrendData(points: const [], granularity: granularity);
    }

    final values = points.map((p) => p.value).toList(growable: false);
    final sum = values.fold<double>(0, (a, b) => a + b);
    final avg = sum / values.length;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);

    TrendDirection overall;
    if (values.length < 2) {
      overall = TrendDirection.stable;
    } else {
      final delta = values.last - values.first;
      if (delta > 0.1) {
        overall = TrendDirection.up;
      } else if (delta < -0.1) {
        overall = TrendDirection.down;
      } else {
        overall = TrendDirection.stable;
      }
    }

    return TrendData(
      points: points,
      granularity: granularity,
      average: avg,
      min: min,
      max: max,
      overallTrend: overall,
    );
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

  Iterable<Value> _effectiveValuesForTask(Task task) {
    return task.effectiveValues;
  }

  String? _effectivePrimaryValueIdForTask(Task task) {
    return task.effectivePrimaryValueId;
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
      // Count effective values (task overrides project; else inherit).
      final effectiveValueIds = _effectiveValuesForTask(
        task,
      ).map((v) => v.id).toSet();
      for (final valueId in effectiveValueIds) {
        counts[valueId] = (counts[valueId] ?? 0) + 1;
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

      // Count per value based on effective values.
      // IMPORTANT: use a denominator consistent with multi-value tagging.
      // Each completed task may contribute to multiple values.
      final valueCounts = <String, int>{};
      var totalTaggedThisWeek = 0;
      for (final task in completions) {
        final effectiveValueIds = _effectiveValuesForTask(
          task,
        ).map((v) => v.id).toSet();
        if (effectiveValueIds.isEmpty) continue;
        totalTaggedThisWeek += effectiveValueIds.length;
        for (final valueId in effectiveValueIds) {
          valueCounts[valueId] = (valueCounts[valueId] ?? 0) + 1;
        }
      }

      if (totalTaggedThisWeek == 0) continue;

      for (final entry in valueCounts.entries) {
        final weekIndex = weeks - 1 - i;
        if (trends.containsKey(entry.key)) {
          trends[entry.key]![weekIndex] =
              entry.value / totalTaggedThisWeek * 100;
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
      final effectiveValueIds = _effectiveValuesForTask(
        task,
      ).map((v) => v.id).toSet();
      for (final valueId in effectiveValueIds) {
        taskCounts[valueId] = (taskCounts[valueId] ?? 0) + 1;
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

  @override
  Future<Map<String, ValuePrimarySecondaryStats>>
  getValuePrimarySecondaryStats() async {
    // Incomplete tasks using TaskQuery
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

    final primaryTaskCounts = <String, int>{};
    final secondaryTaskCounts = <String, int>{};

    for (final task in tasks) {
      final effectiveValues = _effectiveValuesForTask(
        task,
      ).map((v) => v.id).toSet();
      if (effectiveValues.isEmpty) continue;

      final primaryValueId = _effectivePrimaryValueIdForTask(task);

      for (final valueId in effectiveValues) {
        if (primaryValueId != null && valueId == primaryValueId) {
          primaryTaskCounts[valueId] = (primaryTaskCounts[valueId] ?? 0) + 1;
        } else {
          secondaryTaskCounts[valueId] =
              (secondaryTaskCounts[valueId] ?? 0) + 1;
        }
      }
    }

    // Incomplete projects using ProjectQuery
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

    final primaryProjectCounts = <String, int>{};
    final secondaryProjectCounts = <String, int>{};

    for (final project in projects) {
      final valueIds = project.values.map((v) => v.id).toSet();
      if (valueIds.isEmpty) continue;

      final primaryValueId = project.primaryValueId;

      for (final valueId in valueIds) {
        if (primaryValueId != null && valueId == primaryValueId) {
          primaryProjectCounts[valueId] =
              (primaryProjectCounts[valueId] ?? 0) + 1;
        } else {
          secondaryProjectCounts[valueId] =
              (secondaryProjectCounts[valueId] ?? 0) + 1;
        }
      }
    }

    final allValueIds = {
      ...primaryTaskCounts.keys,
      ...secondaryTaskCounts.keys,
      ...primaryProjectCounts.keys,
      ...secondaryProjectCounts.keys,
    };

    final stats = <String, ValuePrimarySecondaryStats>{};
    for (final valueId in allValueIds) {
      stats[valueId] = ValuePrimarySecondaryStats(
        primaryTaskCount: primaryTaskCounts[valueId] ?? 0,
        secondaryTaskCount: secondaryTaskCounts[valueId] ?? 0,
        primaryProjectCount: primaryProjectCounts[valueId] ?? 0,
        secondaryProjectCount: secondaryProjectCounts[valueId] ?? 0,
      );
    }

    return stats;
  }
}
