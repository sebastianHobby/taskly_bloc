import 'package:flutter/foundation.dart';
import 'package:taskly_domain/src/core/model/value.dart';
import 'package:taskly_domain/src/core/model/occurrence_data.dart';
import 'package:taskly_domain/src/core/model/project.dart';

enum TaskReminderKind { none, absolute, beforeDue }

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
    this.myDaySnoozedUntilUtc,
    this.description,
    this.projectId,
    this.priority,
    this.isPinned = false,
    this.reminderKind = TaskReminderKind.none,
    this.reminderAtUtc,
    this.reminderMinutesBeforeDue,
    this.repeatIcalRrule,
    this.repeatFromCompletion = false,
    this.seriesEnded = false,
    this.project,
    this.values = const <Value>[],
    this.overridePrimaryValueId,
    this.overrideSecondaryValueId,
    this.occurrence,
  });

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String name;
  final bool completed;
  final DateTime? startDate;
  final DateTime? deadlineDate;

  /// When set and in the future, this task is temporarily suppressed from
  /// My Day surfaces.
  ///
  /// This is a My Day-specific visibility hint; it must not change the task's
  /// real scheduling semantics (start/deadline).
  final DateTime? myDaySnoozedUntilUtc;
  final String? description;
  final String? projectId;

  /// Priority level (1=P1/highest, 4=P4/lowest, null=none)
  final int? priority;

  /// Whether this task is pinned to the top of lists
  final bool isPinned;

  /// Reminder scheduling mode for this task.
  final TaskReminderKind reminderKind;

  /// Absolute reminder instant (UTC). Used when [reminderKind] is `absolute`.
  final DateTime? reminderAtUtc;

  /// Relative reminder offset in minutes before due date.
  ///
  /// Used when [reminderKind] is `beforeDue`.
  final int? reminderMinutesBeforeDue;

  final String? repeatIcalRrule;

  /// When true, recurrence is anchored to last completion date instead of
  /// original start date. Used for rolling/relative patterns.
  final bool repeatFromCompletion;

  /// When true, stops generating future occurrences for this repeating task.
  final bool seriesEnded;

  final Project? project;

  /// Explicitly assigned override values for this task.
  ///
  /// When empty, the task is considered to be inheriting values from its
  /// project (if any). Effective values should be derived via
  /// `TaskEffectiveValuesX` in
  /// [packages/taskly_domain/lib/domain/services/values/effective_values.dart].
  final List<Value> values;

  /// The ID of the override primary value for this task.
  ///
  /// When set, the task is considered to be explicitly overriding project
  /// values. When null, the task inherits project slots.
  final String? overridePrimaryValueId;

  /// The ID of the override secondary value for this task.
  ///
  /// Only meaningful when [overridePrimaryValueId] is set.
  final String? overrideSecondaryValueId;

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
    DateTime? myDaySnoozedUntilUtc,
    String? description,
    String? projectId,
    int? priority,
    bool? isPinned,
    TaskReminderKind? reminderKind,
    DateTime? reminderAtUtc,
    int? reminderMinutesBeforeDue,
    String? repeatIcalRrule,
    bool? repeatFromCompletion,
    bool? seriesEnded,
    Project? project,
    List<Value>? values,
    String? overridePrimaryValueId,
    String? overrideSecondaryValueId,
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
      myDaySnoozedUntilUtc: myDaySnoozedUntilUtc ?? this.myDaySnoozedUntilUtc,
      description: description ?? this.description,
      projectId: projectId ?? this.projectId,
      priority: priority ?? this.priority,
      isPinned: isPinned ?? this.isPinned,
      reminderKind: reminderKind ?? this.reminderKind,
      reminderAtUtc: reminderAtUtc ?? this.reminderAtUtc,
      reminderMinutesBeforeDue:
          reminderMinutesBeforeDue ?? this.reminderMinutesBeforeDue,
      repeatIcalRrule: repeatIcalRrule ?? this.repeatIcalRrule,
      repeatFromCompletion: repeatFromCompletion ?? this.repeatFromCompletion,
      seriesEnded: seriesEnded ?? this.seriesEnded,
      project: project ?? this.project,
      values: values ?? this.values,
      overridePrimaryValueId:
          overridePrimaryValueId ?? this.overridePrimaryValueId,
      overrideSecondaryValueId:
          overrideSecondaryValueId ?? this.overrideSecondaryValueId,
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
        other.myDaySnoozedUntilUtc == myDaySnoozedUntilUtc &&
        other.description == description &&
        other.projectId == projectId &&
        other.priority == priority &&
        other.isPinned == isPinned &&
        other.reminderKind == reminderKind &&
        other.reminderAtUtc == reminderAtUtc &&
        other.reminderMinutesBeforeDue == reminderMinutesBeforeDue &&
        other.repeatIcalRrule == repeatIcalRrule &&
        other.repeatFromCompletion == repeatFromCompletion &&
        other.seriesEnded == seriesEnded &&
        other.project == project &&
        listEquals(other.values, values) &&
        other.overridePrimaryValueId == overridePrimaryValueId &&
        other.overrideSecondaryValueId == overrideSecondaryValueId &&
        other.occurrence == occurrence;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      id,
      createdAt,
      updatedAt,
      name,
      completed,
      startDate,
      deadlineDate,
      myDaySnoozedUntilUtc,
      description,
      projectId,
      priority,
      isPinned,
      reminderKind,
      reminderAtUtc,
      reminderMinutesBeforeDue,
      repeatIcalRrule,
      repeatFromCompletion,
      seriesEnded,
      project,
      Object.hashAll(values),
      overridePrimaryValueId,
      overrideSecondaryValueId,
      occurrence,
    ]);
  }

  @override
  String toString() {
    return 'Task(id: $id, name: $name, completed: $completed, isPinned: $isPinned, '
        'projectId: $projectId, values: ${values.length} values, '
        'reminderKind: $reminderKind, reminderAtUtc: $reminderAtUtc, '
        'reminderMinutesBeforeDue: $reminderMinutesBeforeDue, '
        'overridePrimaryValueId: $overridePrimaryValueId, '
        'overrideSecondaryValueId: $overrideSecondaryValueId, '
        'isOccurrence: $isOccurrenceInstance)';
  }
}
