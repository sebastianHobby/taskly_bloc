import 'package:flutter/foundation.dart';
import 'package:taskly_bloc/domain/core/model/value.dart';
import 'package:taskly_bloc/domain/core/model/occurrence_data.dart';
import 'package:taskly_bloc/domain/core/model/project.dart';

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
    this.project,
    this.values = const <Value>[],
    this.primaryValueId,
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

  final Project? project;
  final List<Value> values;

  /// The ID of the primary value for this task.
  ///
  /// Only one value can be primary per task. The primary value is used for
  /// grouping in My Day view and determines the main color/category.
  final String? primaryValueId;

  /// Occurrence-specific data. Only populated when this Task instance
  /// represents an expanded occurrence from `getOccurrences`/`watchOccurrences`.
  /// Null for base tasks retrieved via standard CRUD methods.
  final OccurrenceData? occurrence;

  /// True when this instance represents an expanded occurrence.
  bool get isOccurrenceInstance => occurrence != null;

  /// True if this task has a recurrence rule defined.
  bool get isRepeating => repeatIcalRrule?.isNotEmpty ?? false;

  /// Returns the primary value if set and exists in the values list.
  Value? get primaryValue {
    if (primaryValueId == null) return null;
    return values.cast<Value?>().firstWhere(
      (v) => v?.id == primaryValueId,
      orElse: () => null,
    );
  }

  /// Returns all secondary (non-primary) values.
  List<Value> get secondaryValues {
    if (primaryValueId == null) return values;
    return values.where((v) => v.id != primaryValueId).toList();
  }

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
    Project? project,
    List<Value>? values,
    String? primaryValueId,
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
      project: project ?? this.project,
      values: values ?? this.values,
      primaryValueId: primaryValueId ?? this.primaryValueId,
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
        other.project == project &&
        listEquals(other.values, values) &&
        other.primaryValueId == primaryValueId &&
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
    project,
    Object.hashAll(values),
    primaryValueId,
    occurrence,
  );

  @override
  String toString() {
    return 'Task(id: $id, name: $name, completed: $completed, isPinned: $isPinned, '
        'projectId: $projectId, values: ${values.length} values, '
        'primaryValueId: $primaryValueId, isOccurrence: $isOccurrenceInstance)';
  }
}
