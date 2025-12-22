import 'package:flutter/foundation.dart' show immutable;

/// Represents task counts for a project.
@immutable
class ProjectTaskCounts {
  const ProjectTaskCounts({
    required this.projectId,
    required this.totalCount,
    required this.completedCount,
  });

  /// The project ID these counts belong to.
  final String projectId;

  /// Total number of tasks in the project.
  final int totalCount;

  /// Number of completed tasks in the project.
  final int completedCount;

  /// Number of incomplete tasks in the project.
  int get incompleteCount => totalCount - completedCount;

  /// Progress ratio (0.0 to 1.0). Returns null if no tasks.
  double? get progressRatio =>
      totalCount > 0 ? completedCount / totalCount : null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectTaskCounts &&
          runtimeType == other.runtimeType &&
          projectId == other.projectId &&
          totalCount == other.totalCount &&
          completedCount == other.completedCount;

  @override
  int get hashCode => Object.hash(projectId, totalCount, completedCount);

  @override
  String toString() =>
      'ProjectTaskCounts(projectId: $projectId, total: $totalCount, completed: $completedCount)';
}
