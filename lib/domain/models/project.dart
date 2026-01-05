import 'package:flutter/foundation.dart';
import 'package:taskly_bloc/domain/models/value.dart';
import 'package:taskly_bloc/domain/models/occurrence_data.dart';

/// Domain representation of a Project used across the app.
///
/// When retrieved via occurrence expansion methods (`getOccurrences`,
/// `watchOccurrences`), the [occurrence] field will be populated with
/// occurrence-specific data. For base entities from CRUD methods,
/// [occurrence] will be null.
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
    this.priority,
    this.isPinned = false,
    this.lastReviewedAt,
    this.repeatIcalRrule,
    this.repeatFromCompletion = false,
    this.seriesEnded = false,
    this.values = const <Value>[],
    this.occurrence,
  });

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String name;
  final bool completed;
  final String? description;
  final DateTime? startDate;
  final DateTime? deadlineDate;

  /// Priority level (1=P1/highest, 4=P4/lowest, null=none)
  final int? priority;

  /// Whether this project is pinned to the top of lists
  final bool isPinned;

  /// Last time this project was reviewed in a workflow
  final DateTime? lastReviewedAt;

  final String? repeatIcalRrule;

  /// When true, recurrence is anchored to last completion date instead of
  /// original start date. Used for rolling/relative patterns.
  final bool repeatFromCompletion;

  /// When true, stops generating future occurrences for this repeating project.
  final bool seriesEnded;

  final List<Value> values;

  /// Occurrence-specific data. Only populated when this Project instance
  /// represents an expanded occurrence from `getOccurrences`/`watchOccurrences`.
  /// Null for base projects retrieved via standard CRUD methods.
  final OccurrenceData? occurrence;

  /// True when this instance represents an expanded occurrence.
  bool get isOccurrenceInstance => occurrence != null;

  /// True if this project has a recurrence rule defined.
  bool get isRepeating => repeatIcalRrule?.isNotEmpty ?? false;

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
    int? priority,
    bool? isPinned,
    String? repeatIcalRrule,
    bool? repeatFromCompletion,
    bool? seriesEnded,
    List<Value>? values,
    OccurrenceData? occurrence,
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
      priority: priority ?? this.priority,
      isPinned: isPinned ?? this.isPinned,
      repeatIcalRrule: repeatIcalRrule ?? this.repeatIcalRrule,
      repeatFromCompletion: repeatFromCompletion ?? this.repeatFromCompletion,
      seriesEnded: seriesEnded ?? this.seriesEnded,
      values: values ?? this.values,
      occurrence: occurrence ?? this.occurrence,
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
        other.priority == priority &&
        other.isPinned == isPinned &&
        other.repeatIcalRrule == repeatIcalRrule &&
        other.repeatFromCompletion == repeatFromCompletion &&
        other.seriesEnded == seriesEnded &&
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
    description,
    startDate,
    deadlineDate,
    priority,
    isPinned,
    repeatIcalRrule,
    repeatFromCompletion,
    seriesEnded,
    Object.hashAll(values),
    occurrence,
  );

  @override
  String toString() {
    return 'Project(id: $id, name: $name, completed: $completed, isPinned: $isPinned, '
        'values: ${values.length} values, isOccurrence: $isOccurrenceInstance)';
  }
}
