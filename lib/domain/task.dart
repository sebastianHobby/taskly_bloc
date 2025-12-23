import 'package:flutter/foundation.dart';
import 'package:taskly_bloc/domain/label.dart';
import 'package:taskly_bloc/domain/project.dart';

/// Domain representation of a Task used across the app.
@immutable
class Task {
  const Task({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    required this.completed,
    this.startDate,
    this.deadlineDate,
    this.description,
    this.projectId,
    this.repeatIcalRrule,
    this.project,
    this.labels = const <Label>[],
  });

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String name;
  final bool completed;
  final DateTime? startDate;
  final DateTime? deadlineDate;
  final String? description;
  final String? projectId;
  final String? repeatIcalRrule;
  final Project? project;
  final List<Label> labels;

  /// Creates a copy of this Task with the given fields replaced.
  Task copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? name,
    bool? completed,
    DateTime? startDate,
    DateTime? deadlineDate,
    String? description,
    String? projectId,
    String? repeatIcalRrule,
    Project? project,
    List<Label>? labels,
  }) {
    return Task(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      completed: completed ?? this.completed,
      startDate: startDate ?? this.startDate,
      deadlineDate: deadlineDate ?? this.deadlineDate,
      description: description ?? this.description,
      projectId: projectId ?? this.projectId,
      repeatIcalRrule: repeatIcalRrule ?? this.repeatIcalRrule,
      project: project ?? this.project,
      labels: labels ?? this.labels,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Task &&
        other.id == id &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.name == name &&
        other.completed == completed &&
        other.startDate == startDate &&
        other.deadlineDate == deadlineDate &&
        other.description == description &&
        other.projectId == projectId &&
        other.repeatIcalRrule == repeatIcalRrule &&
        other.project == project &&
        listEquals(other.labels, labels);
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    name,
    completed,
    startDate,
    deadlineDate,
    description,
    projectId,
    repeatIcalRrule,
    project,
    Object.hashAll(labels),
  );

  @override
  String toString() {
    return 'Task(id: $id, name: $name, completed: $completed, '
        'projectId: $projectId, labels: ${labels.length} labels)';
  }
}
