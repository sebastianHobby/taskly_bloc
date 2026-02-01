import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/src/services/values/effective_values.dart';
import 'package:taskly_domain/src/services/time/home_day_key_service.dart';
import 'package:taskly_domain/src/time/clock.dart';

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

final class TaskSuggestionSnapshot {
  const TaskSuggestionSnapshot({
    required this.dayKeyUtc,
    required this.suggested,
    required this.snoozed,
    required this.requiresValueSetup,
    required this.requiresRatings,
    required this.neglectDeficits,
    this.spotlightTaskId,
  });

  final DateTime dayKeyUtc;
  final List<SuggestedTask> suggested;
  final List<Task> snoozed;
  final bool requiresValueSetup;
  final bool requiresRatings;
  final Map<String, double> neglectDeficits;
  final String? spotlightTaskId;
}

final class TaskSuggestionService {
  TaskSuggestionService({
    required AllocationOrchestrator allocationOrchestrator,
    required TaskRepositoryContract taskRepository,
    required HomeDayKeyService dayKeyService,
    Clock clock = systemClock,
  }) : _allocationOrchestrator = allocationOrchestrator,
       _taskRepository = taskRepository,
       _dayKeyService = dayKeyService,
       _clock = clock;

  final AllocationOrchestrator _allocationOrchestrator;
  final TaskRepositoryContract _taskRepository;
  final HomeDayKeyService _dayKeyService;
  final Clock _clock;

  static const double _spotlightDeficitThreshold = 0.20;
  static const double _attentionDeficitThreshold = 0.20;
  static const int _showMoreIncrement = 3;
  static const int _poolExtraCount = _showMoreIncrement * 2;

  Future<TaskSuggestionSnapshot> getSnapshot({
    required int batchCount,
    int? suggestedTargetCount,
    List<Task>? tasksOverride,
    Map<String, int> routineSelectionsByValue = const {},
    DateTime? nowUtc,
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
          )
        : await _allocationOrchestrator.getSuggestedSnapshot(
            batchCount: batchCount,
            nowUtc: resolvedNowUtc,
            routineSelectionsByValue: routineSelectionsByValue,
          );

    final baseSuggested = _buildSuggested(
      allocation,
      excludedIds: snoozedIds,
    );
    final spotlightValueId = _spotlightValueId(allocation);
    final orderedSuggested = _applySpotlightOrder(
      baseSuggested,
      spotlightValueId: spotlightValueId,
    );
    final rankedSuggested = _applyRanks(orderedSuggested);
    final pooledSuggested = _applyPerValuePools(
      rankedSuggested,
      deficits: allocation.reasoning.neglectDeficits,
    );
    final suggested = _applyRanks(pooledSuggested);
    final spotlightTaskId = _spotlightTaskId(
      suggested,
      spotlightValueId: spotlightValueId,
    );

    return TaskSuggestionSnapshot(
      dayKeyUtc: dayKeyUtc,
      suggested: suggested,
      snoozed: snoozed,
      requiresValueSetup: allocation.requiresValueSetup,
      requiresRatings: allocation.requiresRatings,
      neglectDeficits: allocation.reasoning.neglectDeficits,
      spotlightTaskId: spotlightTaskId,
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

  List<SuggestedTask> _applySpotlightOrder(
    List<SuggestedTask> suggested, {
    required String? spotlightValueId,
  }) {
    if (spotlightValueId == null || suggested.isEmpty) return suggested;

    final index = suggested.indexWhere(
      (entry) => entry.qualifyingValueId == spotlightValueId,
    );
    if (index <= 0) return suggested;

    final reordered = [...suggested];
    final spotlightTask = reordered.removeAt(index);
    reordered.insert(0, spotlightTask);
    return reordered;
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

  List<SuggestedTask> _applyPerValuePools(
    List<SuggestedTask> suggested, {
    required Map<String, double> deficits,
  }) {
    if (suggested.isEmpty) return suggested;

    final poolLimits = <String, int>{};
    for (final entry in suggested) {
      final valueId = _qualifyingValueId(entry);
      if (valueId == null) continue;
      if (poolLimits.containsKey(valueId)) continue;
      final value = _resolveValue(entry.task, valueId);
      if (value == null) continue;
      final deficit = deficits[valueId] ?? 0.0;
      final attentionNeeded = deficit >= _attentionDeficitThreshold;
      final defaultVisible = _defaultVisibleCount(
        value.priority,
        attentionNeeded: attentionNeeded,
      );
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

  int _defaultVisibleCount(
    ValuePriority priority, {
    required bool attentionNeeded,
  }) {
    return switch (priority) {
      ValuePriority.high => attentionNeeded ? 4 : 3,
      ValuePriority.medium => attentionNeeded ? 3 : 2,
      ValuePriority.low => attentionNeeded ? 2 : 1,
    };
  }

  String? _qualifyingValueId(SuggestedTask entry) {
    final raw = entry.qualifyingValueId?.trim();
    if (raw == null || raw.isEmpty) return entry.task.effectivePrimaryValueId;
    return raw;
  }

  Value? _resolveValue(Task task, String valueId) {
    for (final value in task.effectiveValues) {
      if (value.id == valueId) return value;
    }
    return null;
  }

  String? _spotlightValueId(AllocationResult allocation) {
    final topNeglectScore = allocation.reasoning.topNeglectScore ?? 0.0;
    if (topNeglectScore < _spotlightDeficitThreshold) return null;
    return allocation.reasoning.topNeglectValueId;
  }

  String? _spotlightTaskId(
    List<SuggestedTask> suggested, {
    required String? spotlightValueId,
  }) {
    if (spotlightValueId == null || suggested.isEmpty) return null;
    for (final entry in suggested) {
      if (entry.qualifyingValueId == spotlightValueId) {
        return entry.task.id;
      }
    }
    return null;
  }
}
