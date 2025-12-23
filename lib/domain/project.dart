import 'package:flutter/foundation.dart';
import 'package:taskly_bloc/domain/label.dart';

/// Domain representation of a Project used across the app.
@immutable
class Project {
  const Project({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    required this.completed,
    this.description,
    this.startDate,
    this.deadlineDate,
    this.repeatIcalRrule,
    this.labels = const <Label>[],
  });

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String name;
  final bool completed;
  final String? description;
  final DateTime? startDate;
  final DateTime? deadlineDate;
  final String? repeatIcalRrule;
  final List<Label> labels;

  /// Creates a copy of this Project with the given fields replaced.
  Project copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? name,
    bool? completed,
    String? description,
    DateTime? startDate,
    DateTime? deadlineDate,
    String? repeatIcalRrule,
    List<Label>? labels,
  }) {
    return Project(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      completed: completed ?? this.completed,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      deadlineDate: deadlineDate ?? this.deadlineDate,
      repeatIcalRrule: repeatIcalRrule ?? this.repeatIcalRrule,
      labels: labels ?? this.labels,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Project &&
        other.id == id &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.name == name &&
        other.completed == completed &&
        other.description == description &&
        other.startDate == startDate &&
        other.deadlineDate == deadlineDate &&
        other.repeatIcalRrule == repeatIcalRrule &&
        listEquals(other.labels, labels);
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    name,
    completed,
    description,
    startDate,
    deadlineDate,
    repeatIcalRrule,
    Object.hashAll(labels),
  );

  @override
  String toString() {
    return 'Project(id: $id, name: $name, completed: $completed, '
        'labels: ${labels.length} labels)';
  }
}
