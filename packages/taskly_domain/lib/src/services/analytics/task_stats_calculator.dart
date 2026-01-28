import 'package:taskly_domain/src/analytics/model/date_range.dart';
import 'package:taskly_domain/src/analytics/model/entity_type.dart';
import 'package:taskly_domain/src/analytics/model/stat_result.dart';
import 'package:taskly_domain/src/analytics/model/task_stat_type.dart';
import 'package:taskly_domain/src/core/model/task.dart';
import 'package:taskly_domain/src/services/values/effective_values.dart';

/// Default number of days after which a task is considered stale.
const int kDefaultStaleThresholdDays = 14;

/// Calculates task-related statistics
class TaskStatsCalculator {
  /// Creates a TaskStatsCalculator.
  ///
  /// [staleThresholdDays] controls how many days without activity makes a task
  /// "stale".
  TaskStatsCalculator({
    this.staleThresholdDays = kDefaultStaleThresholdDays,
  });

  /// Number of days without activity before a task is considered stale.
  final int staleThresholdDays;

  StatResult calculate({
    required List<Task> tasks,
    required TaskStatType statType,
    required DateTime nowUtc,
    required DateTime todayDayKeyUtc,
    DateRange? range,
  }) {
    final relevantTasks = range != null
        ? tasks.where((t) => _isInRange(t, range)).toList()
        : tasks;

    return switch (statType) {
      TaskStatType.totalCount => _calculateTotalCount(
        statType,
        relevantTasks,
      ),
      TaskStatType.completedCount => _calculateCompletedCount(
        statType,
        relevantTasks,
      ),
      TaskStatType.completionRate => _calculateCompletionRate(
        statType,
        relevantTasks,
      ),
      TaskStatType.staleCount => _calculateStaleCount(
        statType,
        relevantTasks,
        nowUtc: nowUtc,
      ),
      TaskStatType.overdueCount => _calculateOverdueCount(
        statType,
        relevantTasks,
        todayDayKeyUtc: todayDayKeyUtc,
      ),
      TaskStatType.avgDaysToComplete => _calculateAvgDaysToComplete(
        statType,
        relevantTasks,
      ),
      TaskStatType.completedThisWeek => _calculateCompletedThisWeek(
        statType,
        relevantTasks,
        todayDayKeyUtc: todayDayKeyUtc,
      ),
      TaskStatType.velocity => _calculateVelocity(
        statType,
        relevantTasks,
        range,
      ),
    };
  }

  bool _isInRange(Task task, DateRange range) {
    // Check if task was completed in range
    if (task.completed) {
      final completedAt = task.occurrence?.completedAt;
      if (completedAt != null && range.contains(completedAt)) {
        return true;
      }
    }
    // Check if task was created in range
    final createdAt = task.createdAt;
    if (range.contains(createdAt)) {
      return true;
    }
    return false;
  }

  StatResult _calculateTotalCount(TaskStatType statType, List<Task> tasks) {
    return StatResult(
      statType: statType,
      value: tasks.length,
    );
  }

  StatResult _calculateCompletedCount(TaskStatType statType, List<Task> tasks) {
    final completed = tasks.where((t) => t.completed).length;
    return StatResult(
      statType: statType,
      value: completed,
      severity: StatSeverity.positive,
    );
  }

  StatResult _calculateCompletionRate(
    TaskStatType statType,
    List<Task> tasks,
  ) {
    if (tasks.isEmpty) {
      return StatResult(statType: statType, value: 0);
    }

    final completed = tasks.where((t) => t.completed).length;
    final rate = completed / tasks.length * 100;

    return StatResult(
      statType: statType,
      value: rate,
      severity: rate >= 70 ? StatSeverity.positive : StatSeverity.normal,
    );
  }

  StatResult _calculateStaleCount(
    TaskStatType statType,
    List<Task> tasks, {
    required DateTime nowUtc,
  }) {
    final staleThreshold = nowUtc.subtract(Duration(days: staleThresholdDays));

    final stale = tasks.where((t) {
      if (t.completed) return false;
      final lastActivity = t.updatedAt;
      return lastActivity.isBefore(staleThreshold);
    }).length;

    return StatResult(
      statType: statType,
      value: stale,
      severity: stale > 0 ? StatSeverity.warning : StatSeverity.normal,
      metadata: <String, Object?>{'staleThresholdDays': staleThresholdDays},
    );
  }

  StatResult _calculateOverdueCount(
    TaskStatType statType,
    List<Task> tasks, {
    required DateTime todayDayKeyUtc,
  }) {
    final overdue = tasks.where((t) {
      if (t.completed) return false;
      final dueDate = t.deadlineDate;
      return dueDate != null && dueDate.isBefore(todayDayKeyUtc);
    }).length;

    return StatResult(
      statType: statType,
      value: overdue,
      severity: overdue > 0 ? StatSeverity.warning : StatSeverity.normal,
    );
  }

  StatResult _calculateAvgDaysToComplete(
    TaskStatType statType,
    List<Task> tasks,
  ) {
    final completedTasks = tasks
        .where((t) => t.completed && t.occurrence?.completedAt != null)
        .toList();

    if (completedTasks.isEmpty) {
      return StatResult(statType: statType, value: 0);
    }

    final totalDays = completedTasks.fold<int>(0, (sum, task) {
      final created = task.createdAt;
      final completed = task.occurrence!.completedAt!;
      return sum + completed.difference(created).inDays;
    });

    final avg = totalDays / completedTasks.length;

    return StatResult(
      statType: statType,
      value: avg,
    );
  }

  StatResult _calculateCompletedThisWeek(
    TaskStatType statType,
    List<Task> tasks, {
    required DateTime todayDayKeyUtc,
  }) {
    final weekStart = todayDayKeyUtc.subtract(
      Duration(days: todayDayKeyUtc.weekday - 1),
    );
    final weekEnd = weekStart.add(const Duration(days: 7));

    final completed = tasks.where((t) {
      final completedAt = t.occurrence?.completedAt;
      return t.completed &&
          completedAt != null &&
          completedAt.isAfter(weekStart) &&
          completedAt.isBefore(weekEnd);
    }).length;

    return StatResult(
      statType: statType,
      value: completed,
      severity: StatSeverity.positive,
    );
  }

  StatResult _calculateVelocity(
    TaskStatType statType,
    List<Task> tasks,
    DateRange? range,
  ) {
    final completedTasks = tasks.where((t) => t.completed).toList();

    if (completedTasks.isEmpty || range == null) {
      return StatResult(statType: statType, value: 0);
    }

    final weeks = range.daysDifference / 7;
    if (weeks == 0) {
      return StatResult(
        statType: statType,
        value: completedTasks.length,
      );
    }

    final velocity = completedTasks.length / weeks;

    return StatResult(
      statType: statType,
      value: velocity,
    );
  }

  Map<String, List<DateTime>> getTaskDaysForEntity({
    required List<Task> tasks,
    required String entityId,
    required EntityType entityType,
    required DateRange range,
  }) {
    final relevantTasks = tasks.where((t) {
      if (!t.completed) return false;
      final completedAt = t.occurrence?.completedAt;
      if (completedAt == null || !range.contains(completedAt)) {
        return false;
      }

      return switch (entityType) {
        EntityType.task => t.id == entityId,
        EntityType.project => t.projectId == entityId,
        EntityType.value => t.effectiveValues.any((v) => v.id == entityId),
      };
    }).toList();

    final Map<String, List<DateTime>> result = {
      'days':
          relevantTasks
              .map((t) => t.occurrence?.completedAt)
              .where((dt) => dt != null)
              .cast<DateTime>()
              .map((dt) => DateTime(dt.year, dt.month, dt.day))
              .toSet()
              .toList()
            ..sort(),
    };

    return result;
  }
}
