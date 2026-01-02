import 'package:json_annotation/json_annotation.dart';

/// Problem types for soft gates detection
enum ProblemType {
  /// Urgent task excluded from current allocation
  @JsonValue('excluded_urgent_task')
  excludedUrgentTask,

  /// High priority task that is overdue
  @JsonValue('overdue_high_priority')
  overdueHighPriority,

  /// Project or value has no next actions
  @JsonValue('no_next_actions')
  noNextActions,

  /// Unbalanced allocation across values
  @JsonValue('unbalanced_allocation')
  unbalancedAllocation,

  /// Tasks not updated in a long time
  @JsonValue('stale_tasks')
  staleTasks,
}
