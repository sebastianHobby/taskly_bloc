import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/src/services/time/home_day_key_service.dart';
import 'package:taskly_domain/time.dart';

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
    required this.dueSoonNotSuggested,
    required this.availableToStartNotSuggested,
    required this.snoozed,
    required this.requiresValueSetup,
  });

  final DateTime dayKeyUtc;
  final List<SuggestedTask> suggested;
  final List<Task> dueSoonNotSuggested;
  final List<Task> availableToStartNotSuggested;
  final List<Task> snoozed;
  final bool requiresValueSetup;
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

  Future<TaskSuggestionSnapshot> getSnapshot({
    required int dueWindowDays,
    required bool includeDueSoon,
    required bool includeAvailableToStart,
    required int batchCount,
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

    final activeTasks = tasks
        .where((t) => !snoozedIds.contains(t.id) && !t.isPinned)
        .toList(growable: false);

    final allocation = await _allocationOrchestrator.getSuggestedSnapshot(
      batchCount: batchCount,
      nowUtc: resolvedNowUtc,
      routineSelectionsByValue: routineSelectionsByValue,
    );

    final suggested = _buildSuggested(
      allocation,
      excludedIds: snoozedIds,
    );
    final suggestedIds = suggested.map((s) => s.task.id).toSet();

    final dueSoonNotSuggested = includeDueSoon
        ? _filterDueSoon(
            activeTasks,
            dayKeyUtc: dayKeyUtc,
            dueWindowDays: dueWindowDays,
            excludedIds: suggestedIds,
          )
        : const <Task>[];

    final availableToStartNotSuggested = includeAvailableToStart
        ? _filterAvailableToStart(
            activeTasks,
            dayKeyUtc: dayKeyUtc,
            excludedIds: suggestedIds,
          )
        : const <Task>[];

    return TaskSuggestionSnapshot(
      dayKeyUtc: dayKeyUtc,
      suggested: suggested,
      dueSoonNotSuggested: dueSoonNotSuggested,
      availableToStartNotSuggested: availableToStartNotSuggested,
      snoozed: snoozed,
      requiresValueSetup: allocation.requiresValueSetup,
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

  List<Task> _filterDueSoon(
    List<Task> tasks, {
    required DateTime dayKeyUtc,
    required int dueWindowDays,
    required Set<String> excludedIds,
  }) {
    final today = dateOnly(dayKeyUtc);
    final days = dueWindowDays.clamp(1, 30);
    final dueLimit = today.add(Duration(days: days - 1));

    return tasks
        .where(
          (task) =>
              !excludedIds.contains(task.id) &&
              _isDueWithinWindow(task, dueLimit),
        )
        .toList(growable: false);
  }

  List<Task> _filterAvailableToStart(
    List<Task> tasks, {
    required DateTime dayKeyUtc,
    required Set<String> excludedIds,
  }) {
    final today = dateOnly(dayKeyUtc);
    return tasks
        .where(
          (task) =>
              !excludedIds.contains(task.id) &&
              _isAvailableToStart(task, today),
        )
        .toList(growable: false);
  }

  DateTime? _deadlineDateOnly(Task task) {
    final raw = task.occurrence?.deadline ?? task.deadlineDate;
    return dateOnlyOrNull(raw);
  }

  DateTime? _startDateOnly(Task task) {
    final raw = task.occurrence?.date ?? task.startDate;
    return dateOnlyOrNull(raw);
  }

  bool _isAvailableToStart(Task task, DateTime today) {
    final start = _startDateOnly(task);
    return start != null && !start.isAfter(today);
  }

  bool _isDueWithinWindow(Task task, DateTime dueLimit) {
    final deadline = _deadlineDateOnly(task);
    return deadline != null && !deadline.isAfter(dueLimit);
  }
}
