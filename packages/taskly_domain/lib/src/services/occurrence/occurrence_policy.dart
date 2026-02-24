import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/time.dart';

/// Surfaces that render recurring entities with explicit display policy.
enum RecurrenceDisplaySurface {
  planMyDay,
  myDay,
  projects,
  scheduled,
  notifications,
}

/// Centralized recurrence/occurrence policy.
///
/// This keeps cross-screen behavior consistent while allowing Data to remain
/// the executor (PowerSync-safe writes, stream wiring) and Domain to own
/// selection semantics + configuration defaults.
abstract final class OccurrencePolicy {
  /// Default preview window for non-date feeds (e.g. Projects).
  static const int projectsPreviewPastDays = 365;
  static const int projectsPreviewFutureDays = 730;

  /// Default resolution window for domain commands that must deterministically
  /// resolve an occurrence (e.g. “complete next occurrence”).
  ///
  /// This is intentionally larger than the UI preview window.
  static const int commandResolutionPastDays = 365;
  static const int commandResolutionFutureDays = 1825;

  /// Default occurrence preview configuration for Projects.
  static OccurrencePreview projectsPreview({required DateTime asOfDayKey}) {
    return OccurrencePreview(
      asOfDayKey: dateOnly(asOfDayKey),
      pastDays: projectsPreviewPastDays,
      futureDays: projectsPreviewFutureDays,
    );
  }

  /// Computes a normalized preview expansion range for [preview].
  ///
  /// Ensures the day-key is treated as a date-only key (UTC midnight).
  static ({DateTime asOfDayKey, DateTime rangeStart, DateTime rangeEnd})
  previewRange(OccurrencePreview preview) {
    final asOfDayKey = dateOnly(preview.asOfDayKey);
    return (
      asOfDayKey: asOfDayKey,
      rangeStart: asOfDayKey.subtract(Duration(days: preview.pastDays)),
      rangeEnd: asOfDayKey.add(Duration(days: preview.futureDays)),
    );
  }

  /// Computes a normalized expansion range for domain occurrence resolution.
  static ({DateTime rangeStart, DateTime rangeEnd}) commandResolutionRange({
    required DateTime asOfDayKey,
  }) {
    final dayKey = dateOnly(asOfDayKey);
    return (
      rangeStart: dayKey.subtract(
        const Duration(days: commandResolutionPastDays),
      ),
      rangeEnd: dayKey.add(const Duration(days: commandResolutionFutureDays)),
    );
  }

  /// Returns whether this surface should render only the next active
  /// occurrence for a recurring entity.
  ///
  /// Scheduled intentionally remains hybrid and depends on recurrence mode.
  static bool showsSingleNextOnly({
    required RecurrenceDisplaySurface surface,
    required bool repeatFromCompletion,
  }) {
    return switch (surface) {
      RecurrenceDisplaySurface.planMyDay => true,
      RecurrenceDisplaySurface.myDay => true,
      RecurrenceDisplaySurface.projects => true,
      RecurrenceDisplaySurface.notifications => true,
      RecurrenceDisplaySurface.scheduled => repeatFromCompletion,
    };
  }
}
