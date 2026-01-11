import 'package:taskly_bloc/domain/core/model/task.dart';
import 'package:taskly_bloc/domain/analytics/model/date_range.dart';
import 'package:taskly_bloc/domain/analytics/model/entity_type.dart';
import 'package:taskly_bloc/domain/analytics/model/stat_result.dart';
import 'package:taskly_bloc/domain/analytics/model/task_stat_type.dart';

/// Default number of days after which a task is considered stale.
const int kDefaultStaleThresholdDays = 14;

/// Calculates task-related statistics
class TaskStatsCalculator {
  /// Creates a TaskStatsCalculator.
  ///
  /// [staleThresholdDays] controls how many days without activity makes a task
  /// "stale". Should be set from SoftGatesSettings.staleAfterDaysWithoutUpdates
  /// for consistency across the app. Defaults to 30 days.
  TaskStatsCalculator({
    this.staleThresholdDays = kDefaultStaleThresholdDays,
  });

  /// Number of days without activity before a task is considered stale.
  final int staleThresholdDays;

  StatResult calculate({
    required List<Task> tasks,
    required TaskStatType statType,
    DateRange? range,
  }) {
    final relevantTasks = range != null
        ? tasks.where((t) => _isInRange(t, range)).toList()
        : tasks;

    return switch (statType) {
      TaskStatType.totalCount => _calculateTotalCount(relevantTasks),
      TaskStatType.completedCount => _calculateCompletedCount(relevantTasks),
      TaskStatType.completionRate => _calculateCompletionRate(relevantTasks),
      TaskStatType.staleCount => _calculateStaleCount(relevantTasks),
      TaskStatType.overdueCount => _calculateOverdueCount(relevantTasks),
      TaskStatType.avgDaysToComplete => _calculateAvgDaysToComplete(
        relevantTasks,
      ),
      TaskStatType.completedThisWeek => _calculateCompletedThisWeek(
        relevantTasks,
      ),
      TaskStatType.velocity => _calculateVelocity(relevantTasks, range),
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

  StatResult _calculateTotalCount(List<Task> tasks) {
    return StatResult(
      label: 'Total Tasks',
      value: tasks.length,
      formattedValue: '${tasks.length}',
    );
  }

  StatResult _calculateCompletedCount(List<Task> tasks) {
    final completed = tasks.where((t) => t.completed).length;
    return StatResult(
      label: 'Completed',
      value: completed,
      formattedValue: '$completed',
      severity: StatSeverity.positive,
    );
  }

  StatResult _calculateCompletionRate(List<Task> tasks) {
    if (tasks.isEmpty) {
      return const StatResult(
        label: 'Completion Rate',
        value: 0,
        formattedValue: '0%',
      );
    }

    final completed = tasks.where((t) => t.completed).length;
    final rate = completed / tasks.length * 100;

    return StatResult(
      label: 'Completion Rate',
      value: rate,
      formattedValue: '${rate.toStringAsFixed(0)}%',
      severity: rate >= 70 ? StatSeverity.positive : StatSeverity.normal,
    );
  }

  StatResult _calculateStaleCount(List<Task> tasks) {
    final now = DateTime.now();
    final staleThreshold = now.subtract(Duration(days: staleThresholdDays));

    final stale = tasks.where((t) {
      if (t.completed) return false;
      final lastActivity = t.updatedAt;
      return lastActivity.isBefore(staleThreshold);
    }).length;

    return StatResult(
      label: 'Stale Tasks',
      value: stale,
      formattedValue: '$stale',
      description: 'No activity for $staleThresholdDays+ days',
      severity: stale > 0 ? StatSeverity.warning : StatSeverity.normal,
    );
  }

  StatResult _calculateOverdueCount(List<Task> tasks) {
    final now = DateTime.now();

    final overdue = tasks.where((t) {
      if (t.completed) return false;
      final dueDate = t.deadlineDate;
      return dueDate != null && dueDate.isBefore(now);
    }).length;

    return StatResult(
      label: 'Overdue',
      value: overdue,
      formattedValue: '$overdue',
      severity: overdue > 0 ? StatSeverity.warning : StatSeverity.normal,
    );
  }

  StatResult _calculateAvgDaysToComplete(List<Task> tasks) {
    final completedTasks = tasks
        .where((t) => t.completed && t.occurrence?.completedAt != null)
        .toList();

    if (completedTasks.isEmpty) {
      return const StatResult(
        label: 'Avg Days to Complete',
        value: 0,
        formattedValue: 'N/A',
      );
    }

    final totalDays = completedTasks.fold<int>(0, (sum, task) {
      final created = task.createdAt;
      final completed = task.occurrence!.completedAt!;
      return sum + completed.difference(created).inDays;
    });

    final avg = totalDays / completedTasks.length;

    return StatResult(
      label: 'Avg Days to Complete',
      value: avg,
      formattedValue: '${avg.toStringAsFixed(1)} days',
    );
  }

  StatResult _calculateCompletedThisWeek(List<Task> tasks) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    final completed = tasks.where((t) {
      final completedAt = t.occurrence?.completedAt;
      return t.completed &&
          completedAt != null &&
          completedAt.isAfter(weekStart) &&
          completedAt.isBefore(weekEnd);
    }).length;

    return StatResult(
      label: 'Completed This Week',
      value: completed,
      formattedValue: '$completed',
      severity: StatSeverity.positive,
    );
  }

  StatResult _calculateVelocity(List<Task> tasks, DateRange? range) {
    final completedTasks = tasks.where((t) => t.completed).toList();

    if (completedTasks.isEmpty || range == null) {
      return const StatResult(
        label: 'Velocity',
        value: 0,
        formattedValue: '0 tasks/week',
      );
    }

    final weeks = range.daysDifference / 7;
    if (weeks == 0) {
      return StatResult(
        label: 'Velocity',
        value: completedTasks.length,
        formattedValue: '${completedTasks.length} tasks/week',
      );
    }

    final velocity = completedTasks.length / weeks;

    return StatResult(
      label: 'Velocity',
      value: velocity,
      formattedValue: '${velocity.toStringAsFixed(1)} tasks/week',
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
        EntityType.value => t.values.any((v) => v.id == entityId),
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
