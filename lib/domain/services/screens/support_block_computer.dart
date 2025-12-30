import 'package:taskly_bloc/core/utils/date_only.dart';
import 'package:taskly_bloc/domain/filtering/evaluation_context.dart';
import 'package:taskly_bloc/domain/models/analytics/correlation_result.dart';
import 'package:taskly_bloc/domain/models/analytics/date_range.dart';
import 'package:taskly_bloc/domain/models/analytics/stat_result.dart';
import 'package:taskly_bloc/domain/models/analytics/task_stat_type.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/models/screens/support_block.dart';
import 'package:taskly_bloc/domain/models/screens/workflow_item.dart';
import 'package:taskly_bloc/domain/models/screens/workflow_progress.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';
import 'package:taskly_bloc/domain/queries/task_filter_evaluator.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart';
import 'package:taskly_bloc/domain/services/analytics/analytics_service.dart';
import 'package:taskly_bloc/domain/services/analytics/correlation_calculator.dart';
import 'package:taskly_bloc/domain/services/analytics/task_stats_calculator.dart';

/// Computes support block data by delegating to existing analytics services
class SupportBlockComputer {
  SupportBlockComputer(
    this._statsCalculator,
    this._analyticsService,
  );

  final TaskStatsCalculator _statsCalculator;
  final AnalyticsService _analyticsService;

  /// Computes the data for a task stats block
  /// Requires tasks to be passed in - caller must query repository
  Future<StatResult> computeTaskStats(
    TaskStatsBlock block,
    List<Task> tasks,
  ) async {
    return _statsCalculator.calculate(
      tasks: tasks,
      statType: block.statType,
      range: block.range,
    );
  }

  /// Computes workflow progress from a list of workflow items
  WorkflowProgress computeWorkflowProgress<T>(
    List<WorkflowItem<T>> items,
  ) {
    final total = items.length;
    final completed = items
        .where((i) => i.status == WorkflowItemStatus.completed)
        .length;
    final skipped = items
        .where((i) => i.status == WorkflowItemStatus.skipped)
        .length;
    final pending = items
        .where((i) => i.status == WorkflowItemStatus.pending)
        .length;

    return WorkflowProgress(
      total: total,
      completed: completed,
      skipped: skipped,
      pending: pending,
    );
  }

  /// Computes breakdown statistics by dimension
  Future<Map<String, StatResult>> computeBreakdown(
    BreakdownBlock block,
    List<Task> tasks,
  ) async {
    final tasksByKey = _groupTasks(tasks: tasks, dimension: block.dimension);

    final results = <String, StatResult>{};
    for (final entry in tasksByKey.entries) {
      results[entry.key] = _statsCalculator.calculate(
        tasks: entry.value,
        statType: block.statType,
        range: block.range,
      );
    }

    final sortedKeys = results.keys.toList(growable: false)
      ..sort(
        (a, b) => (results[b]?.value ?? 0).compareTo(results[a]?.value ?? 0),
      );

    return <String, StatResult>{
      for (final key in sortedKeys.take(block.maxItems)) key: results[key]!,
    };
  }

  /// Computes a filtered list from an in-memory task set.
  ///
  /// This is intended for workflow support blocks, where the screen already has
  /// a concrete list of tasks. The block's [filterJson] uses the same shape as
  /// `QueryFilter<TaskPredicate>.toJson(...)`.
  Future<List<Task>> computeFilteredTasks(
    FilteredListBlock block,
    List<Task> tasks, {
    required DateTime now,
  }) async {
    if (block.entityType != 'task') return const <Task>[];

    QueryFilter<TaskPredicate> filter;
    try {
      filter = QueryFilter.fromJson<TaskPredicate>(
        block.filterJson,
        TaskPredicate.fromJson,
      );
    } catch (_) {
      return const <Task>[];
    }

    final evaluator = TaskFilterEvaluator();
    final ctx = EvaluationContext.forDate(now);

    return tasks
        .where((t) => evaluator.matches(t, filter, ctx))
        .toList(growable: false);
  }

  /// Computes a mood correlation result against the current task set.
  ///
  /// Implementation notes:
  /// - Mood data comes from [AnalyticsService.getMoodTrend] (daily granularity).
  /// - Task activity is modeled as a binary series of "activity days".
  /// - For workflows based on base tasks (no occurrences), completion day is
  ///   approximated via `updatedAt`.
  Future<CorrelationResult> computeMoodCorrelation(
    MoodCorrelationBlock block,
    List<Task> tasks,
  ) async {
    final range = block.range;
    final effectiveRange =
        range ??
        DateRange(
          start: DateTime.now().subtract(const Duration(days: 30)),
          end: DateTime.now(),
        );

    final moodTrend = await _analyticsService.getMoodTrend(
      range: effectiveRange,
    );

    final targetData = <DateTime, double>{
      for (final point in moodTrend.points) dateOnly(point.date): point.value,
    };

    final sourceDays = _taskActivityDays(
      tasks: tasks,
      statType: block.statType,
      range: effectiveRange,
    );

    return CorrelationCalculator().calculate(
      sourceLabel: 'Task activity',
      targetLabel: 'Mood',
      sourceDays: sourceDays,
      targetData: targetData,
    );
  }

  Map<String, List<Task>> _groupTasks({
    required List<Task> tasks,
    required BreakdownDimension dimension,
  }) {
    final grouped = <String, List<Task>>{};

    void addToGroup(String key, Task task) {
      final list = grouped.putIfAbsent(key, () => <Task>[]);
      list.add(task);
    }

    for (final task in tasks) {
      switch (dimension) {
        case BreakdownDimension.project:
          addToGroup(task.project?.name ?? 'No project', task);
        case BreakdownDimension.label:
          final labels = task.labels.where((l) => l.type == LabelType.label);
          for (final label in labels) {
            addToGroup(label.name, task);
          }
        case BreakdownDimension.value:
          final values = task.labels.where((l) => l.type == LabelType.value);
          for (final value in values) {
            addToGroup(value.name, task);
          }
        case BreakdownDimension.priority:
          addToGroup(task.deadlineDate != null ? 'Deadline' : 'None', task);
        case BreakdownDimension.status:
          addToGroup(task.completed ? 'Completed' : 'Open', task);
      }
    }

    return grouped;
  }

  List<DateTime> _taskActivityDays({
    required List<Task> tasks,
    required TaskStatType statType,
    required DateRange range,
  }) {
    DateTime? activityDate(Task task) {
      final completionBased =
          statType == TaskStatType.completedCount ||
          statType == TaskStatType.completedThisWeek ||
          statType == TaskStatType.avgDaysToComplete ||
          statType == TaskStatType.velocity;

      if (completionBased && task.completed) {
        return task.occurrence?.completedAt ?? task.updatedAt;
      }

      return task.createdAt;
    }

    return tasks
        .map(activityDate)
        .whereType<DateTime>()
        .where(range.contains)
        .map(dateOnly)
        .toSet()
        .toList(growable: false)
      ..sort();
  }
}
