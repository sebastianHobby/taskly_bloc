import 'package:flutter/foundation.dart';

@immutable
class ProjectNextAction {
  const ProjectNextAction({
    required this.id,
    required this.projectId,
    required this.taskId,
    required this.rank,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });

  final String id;
  final String projectId;
  final String taskId;
  final int rank;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;

  ProjectNextAction copyWith({
    String? id,
    String? projectId,
    String? taskId,
    int? rank,
    DateTime? createdAtUtc,
    DateTime? updatedAtUtc,
  }) {
    return ProjectNextAction(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      taskId: taskId ?? this.taskId,
      rank: rank ?? this.rank,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ProjectNextAction &&
        other.id == id &&
        other.projectId == projectId &&
        other.taskId == taskId &&
        other.rank == rank &&
        other.createdAtUtc == createdAtUtc &&
        other.updatedAtUtc == updatedAtUtc;
  }

  @override
  int get hashCode => Object.hash(
        id,
        projectId,
        taskId,
        rank,
        createdAtUtc,
        updatedAtUtc,
      );
}
