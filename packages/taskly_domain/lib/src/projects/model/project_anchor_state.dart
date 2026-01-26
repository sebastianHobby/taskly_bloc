import 'package:flutter/foundation.dart';

@immutable
class ProjectAnchorState {
  const ProjectAnchorState({
    required this.id,
    required this.projectId,
    required this.lastAnchoredAtUtc,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });

  final String id;
  final String projectId;
  final DateTime lastAnchoredAtUtc;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;

  ProjectAnchorState copyWith({
    String? id,
    String? projectId,
    DateTime? lastAnchoredAtUtc,
    DateTime? createdAtUtc,
    DateTime? updatedAtUtc,
  }) {
    return ProjectAnchorState(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      lastAnchoredAtUtc: lastAnchoredAtUtc ?? this.lastAnchoredAtUtc,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ProjectAnchorState &&
        other.id == id &&
        other.projectId == projectId &&
        other.lastAnchoredAtUtc == lastAnchoredAtUtc &&
        other.createdAtUtc == createdAtUtc &&
        other.updatedAtUtc == updatedAtUtc;
  }

  @override
  int get hashCode => Object.hash(
        id,
        projectId,
        lastAnchoredAtUtc,
        createdAtUtc,
        updatedAtUtc,
      );
}
