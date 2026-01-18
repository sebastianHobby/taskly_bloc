import 'package:flutter/foundation.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/core.dart';

import 'package:taskly_domain/src/models/scheduled/scheduled_date_tag.dart';
import 'package:taskly_domain/src/models/scheduled/scheduled_occurrence_ref.dart';

/// A single occurrence row for the Scheduled feed.
@immutable
final class ScheduledOccurrence {
  const ScheduledOccurrence._({
    required this.ref,
    required this.name,
    required this.isCondensed,
    required this.isAfterCompletionRepeat,
    required this.task,
    required this.project,
  });

  factory ScheduledOccurrence.forTask({
    required ScheduledOccurrenceRef ref,
    required String name,
    required Task task,
    bool isAfterCompletionRepeat = false,
  }) {
    return ScheduledOccurrence._(
      ref: ref,
      name: name,
      isCondensed: ref.tag == ScheduledDateTag.ongoing,
      isAfterCompletionRepeat: isAfterCompletionRepeat,
      task: task,
      project: null,
    );
  }

  factory ScheduledOccurrence.forProject({
    required ScheduledOccurrenceRef ref,
    required String name,
    required Project project,
    bool isAfterCompletionRepeat = false,
  }) {
    return ScheduledOccurrence._(
      ref: ref,
      name: name,
      isCondensed: ref.tag == ScheduledDateTag.ongoing,
      isAfterCompletionRepeat: isAfterCompletionRepeat,
      task: null,
      project: project,
    );
  }

  final ScheduledOccurrenceRef ref;

  final String name;

  /// Whether this row should be rendered in a condensed “ongoing” style.
  final bool isCondensed;

  /// Whether this represents an after-completion recurrence.
  final bool isAfterCompletionRepeat;

  final Task? task;
  final Project? project;

  EntityType get entityType => ref.entityType;
  String get entityId => ref.entityId;
  DateTime get localDay => ref.localDay;
  ScheduledDateTag get tag => ref.tag;

  bool get isTask => entityType == EntityType.task;
  bool get isProject => entityType == EntityType.project;
}
