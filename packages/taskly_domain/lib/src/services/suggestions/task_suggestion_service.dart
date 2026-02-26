import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/src/services/values/effective_values.dart';
import 'package:taskly_domain/src/services/time/home_day_key_service.dart';
import 'package:taskly_domain/src/time/clock.dart';
import 'package:taskly_domain/time.dart' show dateOnly, dateOnlyOrNull;
import 'package:taskly_domain/telemetry.dart';

final class SuggestedTask {
  const SuggestedTask({
    required this.task,
    required this.rank,
    required this.qualifyingValueId,
    required this.reasonCodes,
  });

  final Task task;
  final int rank;
  final String? qualifyingValueId;
  final List<AllocationReasonCode> reasonCodes;
}

final class ValueRatingSummary {
  const ValueRatingSummary({
    required this.averageRating,
    required this.trendDelta,
  });

  final double? averageRating;
  final double? trendDelta;
}

final class TaskSuggestionSnapshot {
  const TaskSuggestionSnapshot({
    required this.dayKeyUtc,
    required this.suggested,
    required this.snoozed,
    required this.requiresValueSetup,
    required this.requiresRatings,
    required this.neglectDeficits,
    required this.anchorProjectIds,
    this.spotlightTaskId,
  });

  final DateTime dayKeyUtc;
  final List<SuggestedTask> suggested;
  final List<Task> snoozed;
  final bool requiresValueSetup;
  final bool requiresRatings;
  final Map<String, double> neglectDeficits;
  final List<String> anchorProjectIds;
  final String? spotlightTaskId;
}

final class TaskSuggestionService {
  TaskSuggestionService({
    required AllocationOrchestrator allocationOrchestrator,
    required TaskRepositoryContract taskRepository,
    required ValueRatingsRepositoryContract valueRatingsRepository,
    required HomeDayKeyService dayKeyService,
    Clock clock = systemClock,
  }) : _allocationOrchestrator = allocationOrchestrator,
       _taskRepository = taskRepository,
       _valueRatingsRepository = valueRatingsRepository,
       _dayKeyService = dayKeyService,
       _clock = clock;

  final AllocationOrchestrator _allocationOrchestrator;
  final TaskRepositoryContract _taskRepository;
  final ValueRatingsRepositoryContract _valueRatingsRepository;
  final HomeDayKeyService _dayKeyService;
  final Clock _clock;

  static const int _ratingsWindowWeeks = 4;
  static const int _ratingsHistoryWeeks = 8;
  static const double _trendEmphasisThreshold = -0.6;
  static const double _lowAverageThreshold = 4.5;
  static const int _showMoreIncrement = 3;
  static const int _poolExtraCount = _showMoreIncrement * 2;

  Future<TaskSuggestionSnapshot> getSnapshot({
    required int batchCount,
    int? suggestedTargetCount,
    List<Task>? tasksOverride,
    Map<String, int> routineSelectionsByValue = const {},
    DateTime? nowUtc,
    OperationContext? context,
  }) async {
    final resolvedNowUtc = nowUtc ?? _clock.nowUtc();
    final dayKeyUtc = _dayKeyService.todayDayKeyUtc(nowUtc: resolvedNowUtc);
    final tasks =
        tasksOverride ?? await _taskRepository.getAll(TaskQuery.incomplete());

    final snoozed = _buildSnoozed(tasks, nowUtc: resolvedNowUtc);
    final snoozedIds = snoozed.map((t) => t.id).toSet();

    final allocation = suggestedTargetCount != null && suggestedTargetCount > 0
        ? await _allocationOrchestrator.getSuggestedSnapshotForTargetCount(
            suggestedTaskTarget: suggestedTargetCount,
            nowUtc: resolvedNowUtc,
            routineSelectionsByValue: routineSelectionsByValue,
            context: context,
          )
        : await _allocationOrchestrator.getSuggestedSnapshot(
            batchCount: batchCount,
            nowUtc: resolvedNowUtc,
            routineSelectionsByValue: routineSelectionsByValue,
            context: context,
          );

    final ratingSummaries = await _buildRatingSummaries(
      tasks: tasks,
      nowUtc: resolvedNowUtc,
    );
    final baseSuggested = _buildSuggested(
      allocation,
      excludedIds: snoozedIds,
    );
    final triageFilteredSuggested = _excludeDueAndPlannedTasks(
      baseSuggested,
      dayKeyUtc: dayKeyUtc,
    );
    final rankedSuggested = _applyRanks(triageFilteredSuggested);
    final pooledSuggested = _applyPerValuePools(
      rankedSuggested,
      ratingSummaries: ratingSummaries,
    );
    final suggested = _applyRanks(pooledSuggested);

    return TaskSuggestionSnapshot(
      dayKeyUtc: dayKeyUtc,
      suggested: suggested,
      snoozed: snoozed,
      requiresValueSetup: allocation.requiresValueSetup,
      requiresRatings: allocation.requiresRatings,
      neglectDeficits: allocation.reasoning.neglectDeficits,
      anchorProjectIds: allocation.anchorProjectIds,
      spotlightTaskId: null,
    );
  }

  List<Task> _buildSnoozed(List<Task> tasks, {required DateTime nowUtc}) {
    return tasks
        .where(
          (t) =>
              t.myDaySnoozedUntilUtc != null &&
              t.myDaySnoozedUntilUtc!.isAfter(nowUtc),
        )
        .toList(growable: false);
  }

  List<SuggestedTask> _buildSuggested(
    AllocationResult allocation, {
    required Set<String> excludedIds,
  }) {
    final suggested = <SuggestedTask>[];
    final allocated = allocation.allocatedTasks;

    for (var i = 0; i < allocated.length; i++) {
      final entry = allocated[i];
      if (excludedIds.contains(entry.task.id)) continue;
      suggested.add(
        SuggestedTask(
          task: entry.task,
          rank: i + 1,
          qualifyingValueId: entry.qualifyingValueId,
          reasonCodes: entry.reasonCodes,
        ),
      );
    }

    return suggested;
  }

  List<SuggestedTask> _applyRanks(List<SuggestedTask> suggested) {
    return [
      for (var i = 0; i < suggested.length; i++)
        SuggestedTask(
          task: suggested[i].task,
          rank: i + 1,
          qualifyingValueId: suggested[i].qualifyingValueId,
          reasonCodes: suggested[i].reasonCodes,
        ),
    ];
  }

  List<SuggestedTask> _excludeDueAndPlannedTasks(
    List<SuggestedTask> suggested, {
    required DateTime dayKeyUtc,
  }) {
    final day = dateOnly(dayKeyUtc);
    return suggested
        .where((entry) {
          final deadline = dateOnlyOrNull(entry.task.deadlineDate);
          final start = dateOnlyOrNull(entry.task.startDate);
          final isDueTodayOrOverdue =
              deadline != null && !deadline.isAfter(day);
          final isPlannedForTodayOrEarlier =
              start != null && !start.isAfter(day);
          return !isDueTodayOrOverdue && !isPlannedForTodayOrEarlier;
        })
        .toList(growable: false);
  }

  List<SuggestedTask> _applyPerValuePools(
    List<SuggestedTask> suggested, {
    required Map<String, ValueRatingSummary> ratingSummaries,
  }) {
    if (suggested.isEmpty) return suggested;

    final poolLimits = <String, int>{};
    for (final entry in suggested) {
      final valueId = _qualifyingValueId(entry);
      if (valueId == null) continue;
      if (poolLimits.containsKey(valueId)) continue;
      final summary = ratingSummaries[valueId];
      final defaultVisible = _defaultVisibleCount(summary);
      poolLimits[valueId] = defaultVisible + _poolExtraCount;
    }

    if (poolLimits.isEmpty) return suggested;

    final pooled = <SuggestedTask>[];
    final counts = <String, int>{};
    for (final entry in suggested) {
      final valueId = _qualifyingValueId(entry);
      if (valueId == null) continue;
      final limit = poolLimits[valueId];
      if (limit == null || limit <= 0) continue;
      final nextCount = (counts[valueId] ?? 0) + 1;
      if (nextCount > limit) continue;
      counts[valueId] = nextCount;
      pooled.add(entry);
    }

    return pooled;
  }

  int _defaultVisibleCount(ValueRatingSummary? summary) {
    final averageRating = summary?.averageRating;
    if (averageRating == null) return 0;
    final trendDelta = summary?.trendDelta;
    if (trendDelta != null && trendDelta <= _trendEmphasisThreshold) {
      return 3;
    }
    if (averageRating <= _lowAverageThreshold) {
      return 2;
    }
    return 1;
  }

  String? _qualifyingValueId(SuggestedTask entry) {
    final raw = entry.qualifyingValueId?.trim();
    if (raw == null || raw.isEmpty) return entry.task.effectivePrimaryValueId;
    return raw;
  }

  Future<Map<String, ValueRatingSummary>> _buildRatingSummaries({
    required List<Task> tasks,
    required DateTime nowUtc,
  }) async {
    final valuesById = <String, Value>{};
    for (final task in tasks) {
      for (final value in task.effectiveValues) {
        valuesById[value.id] = value;
      }
    }

    if (valuesById.isEmpty) return const {};

    final ratings = await _valueRatingsRepository.getAll(
      weeks: _ratingsHistoryWeeks,
    );
    final ratingsByValue = <String, Map<DateTime, int>>{};
    for (final rating in ratings) {
      final weekStart = _weekStartFor(rating.weekStartUtc);
      (ratingsByValue[rating.valueId] ??= {})[weekStart] = rating.rating.clamp(
        1,
        10,
      );
    }

    final nowWeekStart = _weekStartFor(nowUtc);
    final recentWeeks = <DateTime>[
      for (var i = _ratingsWindowWeeks - 1; i >= 0; i--)
        nowWeekStart.subtract(Duration(days: i * 7)),
    ];
    final priorWeeks = <DateTime>[
      for (var i = (_ratingsWindowWeeks * 2) - 1; i >= _ratingsWindowWeeks; i--)
        nowWeekStart.subtract(Duration(days: i * 7)),
    ];

    final summaries = <String, ValueRatingSummary>{};
    for (final valueId in valuesById.keys) {
      final perWeek = ratingsByValue[valueId] ?? const {};
      final recentRatings = <int>[
        for (final week in recentWeeks)
          if (perWeek[week] != null) perWeek[week]!,
      ];
      final priorRatings = <int>[
        for (final week in priorWeeks)
          if (perWeek[week] != null) perWeek[week]!,
      ];

      final averageRating = recentRatings.isEmpty
          ? null
          : recentRatings.fold<int>(0, (sum, v) => sum + v) /
                recentRatings.length;
      final priorAverage = priorRatings.isEmpty
          ? null
          : priorRatings.fold<int>(0, (sum, v) => sum + v) /
                priorRatings.length;
      final trendDelta = (averageRating != null && priorAverage != null)
          ? averageRating - priorAverage
          : null;

      summaries[valueId] = ValueRatingSummary(
        averageRating: averageRating,
        trendDelta: trendDelta,
      );
    }

    return summaries;
  }

  DateTime _weekStartFor(DateTime dateTime) {
    final day = dateOnly(dateTime);
    return day.subtract(Duration(days: day.weekday - 1));
  }
}
