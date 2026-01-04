import 'package:json_annotation/json_annotation.dart';

/// Problem types for soft gates detection.
///
/// Naming convention: `[entity][State]` where:
/// - Entity: task, project, allocation, journal, tracker
/// - State: the problem condition (overdue, stale, orphan, etc.)
enum ProblemType {
  /// Task is past its deadline
  @JsonValue('task_overdue')
  taskOverdue,

  /// Task hasn't been updated recently
  @JsonValue('task_stale')
  taskStale,

  /// Task has no value assigned
  @JsonValue('task_orphan')
  taskOrphan,

  /// Project has no actionable tasks
  @JsonValue('project_idle')
  projectIdle,

  /// Allocation is weighted unevenly across values
  @JsonValue('allocation_unbalanced')
  allocationUnbalanced,

  /// No journal entry for configurable number of days
  @JsonValue('journal_overdue')
  journalOverdue,

  /// Daily tracker not filled for today
  @JsonValue('tracker_missing')
  trackerMissing,
}
