import 'package:flutter/foundation.dart';
import 'package:taskly_bloc/domain/models/value.dart';
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
    this.priority,
    this.isPinned = false,
    this.repeatIcalRrule,
    this.repeatFromCompletion = false,
    this.seriesEnded = false,
    this.lastReviewedAt,
    this.project,
    this.values = const <Value>[],
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

  /// Priority level (1=P1/highest, 4=P4/lowest, null=none)
  final int? priority;

  /// Whether this task is pinned to the top of lists
  final bool isPinned;

  final String? repeatIcalRrule;

  /// When true, recurrence is anchored to last completion date instead of
  /// original start date. Used for rolling/relative patterns.
  final bool repeatFromCompletion;

  /// When true, stops generating future occurrences for this repeating task.
  final bool seriesEnded;

  /// Timestamp of when this task was last reviewed in a workflow.
  final DateTime? lastReviewedAt;

  final Project? project;
  final List<Value> values;

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
    int? priority,
    bool? isPinned,
    String? repeatIcalRrule,
    bool? repeatFromCompletion,
    bool? seriesEnded,
    DateTime? lastReviewedAt,
    Project? project,
    List<Value>? values,
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
      priority: priority ?? this.priority,
      isPinned: isPinned ?? this.isPinned,
      repeatIcalRrule: repeatIcalRrule ?? this.repeatIcalRrule,
      repeatFromCompletion: repeatFromCompletion ?? this.repeatFromCompletion,
      seriesEnded: seriesEnded ?? this.seriesEnded,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      project: project ?? this.project,
      values: values ?? this.values,
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
        other.priority == priority &&
        other.isPinned == isPinned &&
        other.repeatIcalRrule == repeatIcalRrule &&
        other.repeatFromCompletion == repeatFromCompletion &&
        other.seriesEnded == seriesEnded &&
        other.lastReviewedAt == lastReviewedAt &&
        other.project == project &&
        listEquals(other.values, values) &&
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
    priority,
    isPinned,
    repeatIcalRrule,
    repeatFromCompletion,
    seriesEnded,
    lastReviewedAt,
    project,
    Object.hashAll(values),
    occurrence,
  );

  @override
  String toString() {
    return 'Task(id: $id, name: $name, completed: $completed, isPinned: $isPinned, '
        'projectId: $projectId, values: ${values.length} values, '
        'isOccurrence: $isOccurrenceInstance)';
  }
}
