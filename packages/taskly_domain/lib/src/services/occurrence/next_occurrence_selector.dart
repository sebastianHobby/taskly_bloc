import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/time.dart';

/// Selects the "next" (single) virtual occurrence per entity.
///
/// This is intended for non-date feeds (like Projects) that want to render one
/// representative occurrence (and completion state) for repeating entities.
abstract final class NextOccurrenceSelector {
  /// Returns the next *uncompleted* occurrence per task id.
  ///
  /// Selection policy:
  /// - Prefer the earliest uncompleted occurrence on/after [asOfDay].
  /// - If none exist, fall back to the most recent uncompleted occurrence
  ///   before [asOfDay] (closest overdue).
  static Map<String, OccurrenceData> nextUncompletedTaskOccurrenceByTaskId({
    required List<Task> expandedTasks,
    required DateTime asOfDay,
  }) {
    final dayKey = dateOnly(asOfDay);

    final occurrencesById = <String, List<OccurrenceData>>{};

    for (final task in expandedTasks) {
      final occurrence = task.occurrence;
      if (occurrence == null) continue;
      if (occurrence.isCompleted) continue;

      (occurrencesById[task.id] ??= <OccurrenceData>[]).add(occurrence);
    }

    return {
      for (final entry in occurrencesById.entries)
        entry.key: ?_selectNext(entry.value, dayKey),
    };
  }

  /// Returns the next *uncompleted* occurrence per project id.
  ///
  /// Same selection policy as [nextUncompletedTaskOccurrenceByTaskId].
  static Map<String, OccurrenceData>
  nextUncompletedProjectOccurrenceByProjectId({
    required List<Project> expandedProjects,
    required DateTime asOfDay,
  }) {
    final dayKey = dateOnly(asOfDay);

    final occurrencesById = <String, List<OccurrenceData>>{};

    for (final project in expandedProjects) {
      final occurrence = project.occurrence;
      if (occurrence == null) continue;
      if (occurrence.isCompleted) continue;

      (occurrencesById[project.id] ??= <OccurrenceData>[]).add(occurrence);
    }

    return {
      for (final entry in occurrencesById.entries)
        entry.key: ?_selectNext(entry.value, dayKey),
    };
  }

  static OccurrenceData? _selectNext(
    List<OccurrenceData> occurrences,
    DateTime asOfDay,
  ) {
    if (occurrences.isEmpty) return null;

    OccurrenceData? bestFuture;
    OccurrenceData? bestOverdue;

    for (final o in occurrences) {
      final day = dateOnly(o.date);

      if (!day.isBefore(asOfDay)) {
        if (bestFuture == null || day.isBefore(dateOnly(bestFuture.date))) {
          bestFuture = o;
        }
      } else {
        if (bestOverdue == null || day.isAfter(dateOnly(bestOverdue.date))) {
          bestOverdue = o;
        }
      }
    }

    return bestFuture ?? bestOverdue;
  }
}
