import 'package:taskly_bloc/domain/time/date_only.dart';
import 'package:taskly_bloc/domain/allocation/contracts/allocation_snapshot_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/allocation/model/allocation_day_stats.dart';
import 'package:taskly_bloc/domain/allocation/model/allocation_snapshot.dart';
import 'package:taskly_bloc/domain/allocation/model/allocation_config.dart';
import 'package:taskly_bloc/domain/allocation/model/focus_mode.dart';
import 'package:taskly_bloc/domain/settings/model/project_health_review_settings.dart';
import 'package:taskly_bloc/domain/preferences/model/settings_key.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/core/model/task.dart';
import 'package:taskly_bloc/domain/allocation/engine/allocation_history_metrics.dart';
import 'package:taskly_bloc/domain/services/values/effective_values.dart';

/// Computes Phase 5 stats derived from allocation snapshots + completion history.
///
/// Notes:
/// - Allocation snapshot is authoritative for “planned”.
/// - Completion history is authoritative for “done” (via TaskDateField.completedAt).
/// - All day bucketing is UTC date-only.
class AllocationDayStatsService {
  AllocationDayStatsService({
    required AllocationSnapshotRepositoryContract allocationSnapshotRepository,
    required TaskRepositoryContract taskRepository,
    required ProjectRepositoryContract projectRepository,
    required SettingsRepositoryContract settingsRepository,
  }) : _allocationSnapshotRepository = allocationSnapshotRepository,
       _taskRepository = taskRepository,
       _projectRepository = projectRepository,
       _settingsRepository = settingsRepository;

  final AllocationSnapshotRepositoryContract _allocationSnapshotRepository;
  final TaskRepositoryContract _taskRepository;
  final ProjectRepositoryContract _projectRepository;
  final SettingsRepositoryContract _settingsRepository;

  /// Computes stats for a given UTC day.
  ///
  /// If the allocation snapshot is missing for the day, allocated metrics are
  /// computed as zero/empty, but completion metrics still work.
  Future<AllocationDayStats> computeForUtcDay({
    required DateTime dayUtc,
    int repeatWindowDays = 14,
  }) async {
    final normalizedDayUtc = dateOnly(dayUtc.toUtc());

    final allocationConfig = await _settingsRepository.load(
      SettingsKey.allocation,
    );
    final projectHealthSettings = _resolveProjectHealthSettings(
      allocationConfig,
    );

    final snapshot = await _allocationSnapshotRepository.getLatestForUtcDay(
      normalizedDayUtc,
    );

    final allocatedTaskEntries = _allocatedTaskEntries(snapshot);
    final allocatedTaskIds = allocatedTaskEntries
        .map((e) => e.entity.id)
        .toSet();

    final completedTasks = await _getCompletedTasksForUtcDay(normalizedDayUtc);
    final completedTaskIds = completedTasks.map((t) => t.id).toSet();

    final allocatedCompleted = allocatedTaskIds
        .where(completedTaskIds.contains)
        .toSet();
    final completedUnallocated = completedTaskIds
        .where((id) => !allocatedTaskIds.contains(id))
        .toSet();

    final allocatedByEffectivePrimaryValueId = <String, int>{};
    for (final entry in allocatedTaskEntries) {
      final v = entry.effectivePrimaryValueId;
      if (v == null || v.isEmpty) continue;
      allocatedByEffectivePrimaryValueId[v] =
          (allocatedByEffectivePrimaryValueId[v] ?? 0) + 1;
    }

    final completedByEffectivePrimaryValueId = <String, int>{};
    for (final task in completedTasks) {
      final v = task.effectivePrimaryValueId;
      if (v == null || v.isEmpty) continue;
      completedByEffectivePrimaryValueId[v] =
          (completedByEffectivePrimaryValueId[v] ?? 0) + 1;
    }

    final allocatedTasksInProject = <String, int>{};
    for (final entry in allocatedTaskEntries) {
      final projectId = entry.projectId;
      if (projectId == null || projectId.isEmpty) continue;
      allocatedTasksInProject[projectId] =
          (allocatedTasksInProject[projectId] ?? 0) + 1;
    }

    final completedTasksInProject = <String, int>{};
    for (final task in completedTasks) {
      final projectId = task.projectId;
      if (projectId == null || projectId.isEmpty) continue;
      completedTasksInProject[projectId] =
          (completedTasksInProject[projectId] ?? 0) + 1;
    }

    final projectProgressedToday = <String, bool>{
      for (final e in completedTasksInProject.entries) e.key: e.value > 0,
    };

    final (
      daysSinceLastAllocatedForProject,
      daysSinceCoverageSufficient,
    ) = await _computeDaysSinceLastAllocatedForProject(
      dayUtc: normalizedDayUtc,
      settings: projectHealthSettings,
    );

    final (
      repeatAllocatedNotCompletedByTaskId,
      repeatCoverageDays,
    ) = await _computeRepeatAllocatedNotCompleted(
      endDayUtc: normalizedDayUtc,
      windowDays: repeatWindowDays,
    );

    return AllocationDayStats(
      dayUtc: normalizedDayUtc,
      allocatedTaskCount: allocatedTaskIds.length,
      allocatedCompletedCount: allocatedCompleted.length,
      allocatedNotCompletedCount:
          allocatedTaskIds.length - allocatedCompleted.length,
      completedUnallocatedCount: completedUnallocated.length,
      allocatedByEffectivePrimaryValueId: allocatedByEffectivePrimaryValueId,
      completedByEffectivePrimaryValueId: completedByEffectivePrimaryValueId,
      allocatedTasksInProject: allocatedTasksInProject,
      completedTasksInProject: completedTasksInProject,
      projectProgressedToday: projectProgressedToday,
      daysSinceLastAllocatedForProject: daysSinceLastAllocatedForProject,
      daysSinceLastAllocatedCoverageSufficient: daysSinceCoverageSufficient,
      repeatAllocatedNotCompletedByTaskId: repeatAllocatedNotCompletedByTaskId,
      repeatWindowDays: repeatWindowDays,
      repeatCoverageDays: repeatCoverageDays,
    );
  }

  List<AllocationSnapshotEntryInput> _allocatedTaskEntries(
    AllocationSnapshot? snapshot,
  ) {
    if (snapshot == null) return const <AllocationSnapshotEntryInput>[];
    return snapshot.allocated
        .where((e) => e.entity.type == AllocationSnapshotEntityType.task)
        .toList(growable: false);
  }

  Future<List<Task>> _getCompletedTasksForUtcDay(
    DateTime dayUtc,
  ) async {
    final start = dateOnly(dayUtc.toUtc());
    final endExclusive = start.add(const Duration(days: 1));

    final query = TaskQuery(
      filter: QueryFilter<TaskPredicate>(
        shared: [
          TaskDatePredicate(
            field: TaskDateField.completedAt,
            operator: DateOperator.onOrAfter,
            date: start,
          ),
          TaskDatePredicate(
            field: TaskDateField.completedAt,
            operator: DateOperator.before,
            date: endExclusive,
          ),
        ],
      ),
    );

    return _taskRepository.getAll(query);
  }

  ProjectHealthReviewSettings _resolveProjectHealthSettings(
    AllocationConfig allocationConfig,
  ) {
    final persisted = allocationConfig.projectHealthReviewSettings;
    if (allocationConfig.focusMode == FocusMode.personalized) {
      return persisted;
    }

    // Use preset defaults when not personalized, but keep runtime-gate state stable.
    final preset = ProjectHealthReviewSettings.forFocusMode(
      allocationConfig.focusMode,
    );
    return preset.copyWith(
      noAllocatableFirstDayUtc: persisted.noAllocatableFirstDayUtc,
    );
  }

  Future<(Map<String, int?>, bool)> _computeDaysSinceLastAllocatedForProject({
    required DateTime dayUtc,
    required ProjectHealthReviewSettings settings,
  }) async {
    final historyWindow = await _allocationSnapshotRepository
        .getProjectHistoryWindow(
          windowEndDayUtc: dayUtc,
          windowDays: settings.historyWindowDays,
        );

    final sufficient = AllocationHistoryMetrics.hasSufficientCoverage(
      historyWindow: historyWindow,
      settings: settings,
    );

    if (!sufficient) {
      return (<String, int?>{}, false);
    }

    final projects = await _projectRepository.watchAll().first;
    final activeProjectIds = projects
        .where((p) => !p.completed)
        .map((p) => p.id);

    final result = <String, int?>{};
    for (final projectId in activeProjectIds) {
      final lastDay = historyWindow.lastAllocatedDayByProjectId[projectId];
      result[projectId] = AllocationHistoryMetrics.daysSinceLastAllocated(
        todayUtc: dayUtc,
        lastAllocatedDayUtc: lastDay,
        settings: settings,
      );
    }

    return (result, true);
  }

  Future<(Map<String, int>, int)> _computeRepeatAllocatedNotCompleted({
    required DateTime endDayUtc,
    required int windowDays,
  }) async {
    final normalizedEnd = dateOnly(endDayUtc.toUtc());

    final counts = <String, int>{};
    var coverageDays = 0;

    for (var offset = 0; offset < windowDays; offset++) {
      final day = normalizedEnd.subtract(Duration(days: offset));
      final snapshot = await _allocationSnapshotRepository.getLatestForUtcDay(
        day,
      );
      if (snapshot == null) continue;
      coverageDays++;

      final allocatedTaskIds = _allocatedTaskEntries(
        snapshot,
      ).map((e) => e.entity.id).toSet();

      if (allocatedTaskIds.isEmpty) continue;

      final completedTasks = await _getCompletedTasksForUtcDay(day);
      final completedTaskIds = completedTasks.map((t) => t.id).toSet();

      for (final taskId in allocatedTaskIds) {
        if (completedTaskIds.contains(taskId)) continue;
        counts[taskId] = (counts[taskId] ?? 0) + 1;
      }
    }

    return (counts, coverageDays);
  }
}
