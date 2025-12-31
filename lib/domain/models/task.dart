import 'package:flutter/foundation.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/models/occurrence_data.dart';
import 'package:taskly_bloc/domain/models/project.dart';

/// Domain representation of a Task used across the app.
///
/// When retrieved via occurrence expansion methods (`getOccurrences`,
/// `watchOccurrences`), the [occurrence] field will be populated with
/// occurrence-specific data. For base entities from CRUD methods,
/// [occurrence] will be null.
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
    this.repeatFromCompletion = false,
    this.seriesEnded = false,
    this.project,
    this.labels = const <Label>[],
    this.occurrence,
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

  /// When true, recurrence is anchored to last completion date instead of
  /// original start date. Used for rolling/relative patterns.
  final bool repeatFromCompletion;

  /// When true, stops generating future occurrences for this repeating task.
  final bool seriesEnded;

  final Project? project;
  final List<Label> labels;

  /// Occurrence-specific data. Only populated when this Task instance
  /// represents an expanded occurrence from `getOccurrences`/`watchOccurrences`.
  /// Null for base tasks retrieved via standard CRUD methods.
  final OccurrenceData? occurrence;

  /// True when this instance represents an expanded occurrence.
  bool get isOccurrenceInstance => occurrence != null;

  /// True if this task has a recurrence rule defined.
  bool get isRepeating => repeatIcalRrule?.isNotEmpty ?? false;

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
    bool? repeatFromCompletion,
    bool? seriesEnded,
    Project? project,
    List<Label>? labels,
    OccurrenceData? occurrence,
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
      repeatFromCompletion: repeatFromCompletion ?? this.repeatFromCompletion,
      seriesEnded: seriesEnded ?? this.seriesEnded,
      project: project ?? this.project,
      labels: labels ?? this.labels,
      occurrence: occurrence ?? this.occurrence,
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
        other.repeatFromCompletion == repeatFromCompletion &&
        other.seriesEnded == seriesEnded &&
        other.project == project &&
        listEquals(other.labels, labels) &&
        other.occurrence == occurrence;
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
    repeatFromCompletion,
    seriesEnded,
    project,
    Object.hashAll(labels),
    occurrence,
  );

  @override
  String toString() {
    return 'Task(id: $id, name: $name, completed: $completed, '
        'projectId: $projectId, labels: ${labels.length} labels, '
        'isOccurrence: $isOccurrenceInstance)';
  }
}
