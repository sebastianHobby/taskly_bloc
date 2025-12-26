import 'package:flutter/foundation.dart';

/// Represents task counts for a project.
@immutable
class ProjectTaskCounts {
  const ProjectTaskCounts({
    required this.projectId,
    required this.totalCount,
    required this.completedCount,
  });

  final String projectId;
  final int totalCount;
  final int completedCount;

  /// Number of incomplete tasks in the project.
  int get incompleteCount => totalCount - completedCount;

  /// Progress ratio (0.0 to 1.0). Returns null if no tasks.
  double? get progressRatio =>
      totalCount > 0 ? completedCount / totalCount : null;

  /// Returns true if all tasks are completed.
  bool get isComplete => totalCount > 0 && completedCount == totalCount;

  /// Creates a copy of this ProjectTaskCounts with the given fields replaced.
  ProjectTaskCounts copyWith({
    String? projectId,
    int? totalCount,
    int? completedCount,
  }) {
    return ProjectTaskCounts(
      projectId: projectId ?? this.projectId,
      totalCount: totalCount ?? this.totalCount,
      completedCount: completedCount ?? this.completedCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProjectTaskCounts &&
        other.projectId == projectId &&
        other.totalCount == totalCount &&
        other.completedCount == completedCount;
  }

  @override
  int get hashCode => Object.hash(projectId, totalCount, completedCount);

  @override
  String toString() {
    return 'ProjectTaskCounts(projectId: $projectId, '
        'total: $totalCount, completed: $completedCount)';
  }
}
