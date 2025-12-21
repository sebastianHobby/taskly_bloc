import 'package:flutter/foundation.dart';

/// Defines how tasks should be filtered and sorted for a given list page.
///
/// This is a presentation-layer concept: it describes *what* the UI wants to
/// show, independent of any particular page.
@immutable
class TaskListQuery {
  const TaskListQuery({
    this.completion = TaskCompletionFilter.all,
    this.sort = TaskSort.name,
    this.onlyWithoutProject = false,
    this.projectId,
    this.onOrBeforeDate,
    this.onOrAfterDate,
  });

  /// A query for a "Today"-style view.
  ///
  /// Includes any task whose start date or deadline date is on or before
  /// today's date.
  factory TaskListQuery.today({required DateTime now}) {
    final today = DateTime(now.year, now.month, now.day);
    return TaskListQuery(onOrBeforeDate: today);
  }

  /// A query for an "Upcoming"-style view.
  ///
  /// Includes any task whose start date or deadline date is on or after
  /// tomorrow's date.
  factory TaskListQuery.upcoming({required DateTime now}) {
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return TaskListQuery(onOrAfterDate: tomorrow);
  }

  /// Whether to show all tasks, only active, or only completed.
  final TaskCompletionFilter completion;

  /// How tasks should be sorted.
  final TaskSort sort;

  /// Whether tasks should be restricted to items without a project.
  ///
  /// Used by Inbox-style views.
  final bool onlyWithoutProject;

  /// If set, only tasks linked to this project are included.
  final String? projectId;

  /// If set, only tasks with a start date or deadline date on or before this
  /// date are included.
  ///
  /// The comparison is done at day precision.
  final DateTime? onOrBeforeDate;

  /// If set, only tasks with a start date or deadline date on or after this
  /// date are included.
  ///
  /// The comparison is done at day precision.
  final DateTime? onOrAfterDate;

  static const all = TaskListQuery();

  static const inbox = TaskListQuery(onlyWithoutProject: true);

  TaskListQuery copyWith({
    TaskCompletionFilter? completion,
    TaskSort? sort,
    bool? onlyWithoutProject,
    String? projectId,
    DateTime? onOrBeforeDate,
    DateTime? onOrAfterDate,
  }) {
    return TaskListQuery(
      completion: completion ?? this.completion,
      sort: sort ?? this.sort,
      onlyWithoutProject: onlyWithoutProject ?? this.onlyWithoutProject,
      projectId: projectId ?? this.projectId,
      onOrBeforeDate: onOrBeforeDate ?? this.onOrBeforeDate,
      onOrAfterDate: onOrAfterDate ?? this.onOrAfterDate,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TaskListQuery &&
        other.completion == completion &&
        other.sort == sort &&
        other.onlyWithoutProject == onlyWithoutProject &&
        other.projectId == projectId &&
        other.onOrBeforeDate == onOrBeforeDate &&
        other.onOrAfterDate == onOrAfterDate;
  }

  @override
  int get hashCode => Object.hash(
    completion,
    sort,
    onlyWithoutProject,
    projectId,
    onOrBeforeDate,
    onOrAfterDate,
  );
}

enum TaskCompletionFilter {
  all,
  active,
  completed,
}

enum TaskSort {
  name,
  deadline,
}
