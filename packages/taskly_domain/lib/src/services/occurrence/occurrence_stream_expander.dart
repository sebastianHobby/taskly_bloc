import 'package:rrule/rrule.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/time.dart';

/// Implementation of [OccurrenceStreamExpanderContract].
///
/// Transforms raw database streams into expanded occurrence streams,
/// applying RRULE expansion, exception handling, and completion merging.
class OccurrenceStreamExpander implements OccurrenceStreamExpanderContract {
  OccurrenceStreamExpander({Clock clock = systemClock}) : _clock = clock;

  final Clock _clock;

  /// Debounce duration to prevent rapid re-expansions when multiple
  /// underlying tables (entity, completion, exception) update in quick
  /// succession. 50ms is short enough to feel instant to users while
  /// preventing unnecessary recomputation during batch updates.
  static const _debounceDuration = Duration(milliseconds: 50);

  /// Cache for parsed RRULE objects.
  /// RRULE parsing (~1ms per parse) is expensive but strings rarely change.
  /// Limited to 100 entries to prevent unbounded memory growth.
  static final _rruleCache = <String, RecurrenceRule>{};
  static const _rruleCacheMaxSize = 100;

  /// Parse an RRULE string, using cache when available.
  static RecurrenceRule? _parseRrule(String rruleString) {
    // Check cache first
    final normalizedRrule = rruleString.trim();
    final rruleText = normalizedRrule.startsWith('RRULE:')
        ? normalizedRrule
        : 'RRULE:$normalizedRrule';

    final cached = _rruleCache[rruleText];
    if (cached != null) return cached;

    // Parse and cache
    try {
      final rrule = RecurrenceRule.fromString(rruleText);

      // Evict oldest entries if cache is full (simple LRU approximation)
      if (_rruleCache.length >= _rruleCacheMaxSize) {
        final keysToRemove = _rruleCache.keys.take(10).toList();
        keysToRemove.forEach(_rruleCache.remove);
      }

      _rruleCache[rruleText] = rrule;
      return rrule;
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<List<Task>> expandTaskOccurrences({
    required Stream<List<Task>> tasksStream,
    required Stream<List<CompletionHistoryData>> completionsStream,
    required Stream<List<RecurrenceExceptionData>> exceptionsStream,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    bool Function(Task)? postExpansionFilter,
  }) {
    return Rx.combineLatest3(
      tasksStream,
      completionsStream,
      exceptionsStream,
      (tasks, completions, exceptions) => expandTaskOccurrencesSync(
        tasks: tasks,
        completions: completions,
        exceptions: exceptions,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
        postExpansionFilter: postExpansionFilter,
      ),
    ).debounceTime(_debounceDuration);
  }

  @override
  Stream<List<Project>> expandProjectOccurrences({
    required Stream<List<Project>> projectsStream,
    required Stream<List<CompletionHistoryData>> completionsStream,
    required Stream<List<RecurrenceExceptionData>> exceptionsStream,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    bool Function(Project)? postExpansionFilter,
  }) {
    return Rx.combineLatest3(
      projectsStream,
      completionsStream,
      exceptionsStream,
      (projects, completions, exceptions) => expandProjectOccurrencesSync(
        projects: projects,
        completions: completions,
        exceptions: exceptions,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
        postExpansionFilter: postExpansionFilter,
      ),
    ).debounceTime(_debounceDuration);
  }

  @override
  List<Task> expandTaskOccurrencesSync({
    required List<Task> tasks,
    required List<CompletionHistoryData> completions,
    required List<RecurrenceExceptionData> exceptions,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    bool Function(Task)? postExpansionFilter,
  }) {
    final normalizedRangeStart = _normalizeDate(rangeStart);
    final normalizedRangeEnd = _normalizeDate(rangeEnd);

    // Group completions and exceptions by entity ID for efficient lookup
    final completionsByTask = _groupBy(completions, (c) => c.entityId);
    final exceptionsByTask = _groupBy(exceptions, (e) => e.entityId);

    final allOccurrences = <Task>[];

    for (final task in tasks) {
      final taskCompletions = completionsByTask[task.id] ?? [];
      final taskExceptions = exceptionsByTask[task.id] ?? [];

      final expanded = _expandEntity<Task>(
        entity: task,
        entityId: task.id,
        startDate: task.startDate ?? task.deadlineDate ?? task.createdAt,
        deadlineDate: task.deadlineDate,
        repeatIcalRrule: task.repeatIcalRrule,
        repeatFromCompletion: task.repeatFromCompletion,
        seriesEnded: task.seriesEnded,
        completions: taskCompletions,
        exceptions: taskExceptions,
        rangeStart: normalizedRangeStart,
        rangeEnd: normalizedRangeEnd,
        builder: (occurrence) => _normalizeTaskOccurrence(task, occurrence),
      );

      allOccurrences.addAll(expanded);
    }

    // Apply post-expansion filter if provided (for two-phase filtering)
    final filtered = postExpansionFilter != null
        ? allOccurrences.where(postExpansionFilter).toList()
        : allOccurrences;

    // Sort by occurrence date
    filtered.sort(
      (a, b) => a.occurrence!.date.compareTo(b.occurrence!.date),
    );

    return filtered;
  }

  @override
  List<Project> expandProjectOccurrencesSync({
    required List<Project> projects,
    required List<CompletionHistoryData> completions,
    required List<RecurrenceExceptionData> exceptions,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    bool Function(Project)? postExpansionFilter,
  }) {
    final normalizedRangeStart = _normalizeDate(rangeStart);
    final normalizedRangeEnd = _normalizeDate(rangeEnd);

    // Group completions and exceptions by entity ID for efficient lookup
    final completionsByProject = _groupBy(completions, (c) => c.entityId);
    final exceptionsByProject = _groupBy(exceptions, (e) => e.entityId);

    final allOccurrences = <Project>[];

    for (final project in projects) {
      final projectCompletions = completionsByProject[project.id] ?? [];
      final projectExceptions = exceptionsByProject[project.id] ?? [];

      final expanded = _expandEntity<Project>(
        entity: project,
        entityId: project.id,
        startDate:
            project.startDate ?? project.deadlineDate ?? project.createdAt,
        deadlineDate: project.deadlineDate,
        repeatIcalRrule: project.repeatIcalRrule,
        repeatFromCompletion: project.repeatFromCompletion,
        seriesEnded: project.seriesEnded,
        completions: projectCompletions,
        exceptions: projectExceptions,
        rangeStart: normalizedRangeStart,
        rangeEnd: normalizedRangeEnd,
        builder: (occurrence) =>
            _normalizeProjectOccurrence(project, occurrence),
      );

      allOccurrences.addAll(expanded);
    }

    // Apply post-expansion filter if provided (for two-phase filtering)
    final filtered = postExpansionFilter != null
        ? allOccurrences.where(postExpansionFilter).toList()
        : allOccurrences;

    // Sort by occurrence date
    filtered.sort((a, b) => a.occurrence!.date.compareTo(b.occurrence!.date));

    return filtered;
  }

  // ===========================================================================
  // PRIVATE: Generic Entity Expansion
  // ===========================================================================

  /// Expands a single entity (task or project) into its occurrences.
  List<T> _expandEntity<T>({
    required T entity,
    required String entityId,
    required DateTime startDate,
    required DateTime? deadlineDate,
    required String? repeatIcalRrule,
    required bool repeatFromCompletion,
    required bool seriesEnded,
    required List<CompletionHistoryData> completions,
    required List<RecurrenceExceptionData> exceptions,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required T Function(OccurrenceData occurrence) builder,
  }) {
    // Calculate deadline offset for occurrence deadline computation
    final deadlineOffset = (deadlineDate != null)
        ? deadlineDate.difference(startDate)
        : null;

    // Non-repeating entity
    if (repeatIcalRrule == null || repeatIcalRrule.isEmpty) {
      return _expandNonRepeating(
        entity: entity,
        startDate: startDate,
        deadlineDate: deadlineDate,
        completions: completions,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
        builder: builder,
      );
    }

    // Repeating entity
    return _expandRepeating(
      entity: entity,
      entityId: entityId,
      startDate: startDate,
      deadlineDate: deadlineDate,
      deadlineOffset: deadlineOffset,
      repeatIcalRrule: repeatIcalRrule,
      repeatFromCompletion: repeatFromCompletion,
      seriesEnded: seriesEnded,
      completions: completions,
      exceptions: exceptions,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
      builder: builder,
    );
  }

  /// Expands a non-repeating entity into a single occurrence if in range.
  List<T> _expandNonRepeating<T>({
    required T entity,
    required DateTime startDate,
    required DateTime? deadlineDate,
    required List<CompletionHistoryData> completions,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required T Function(OccurrenceData occurrence) builder,
  }) {
    final normalizedStartDate = _normalizeDate(startDate);

    final normalizedDeadlineDate = deadlineDate == null
        ? null
        : _normalizeDate(deadlineDate);

    final startInRange =
        !normalizedStartDate.isBefore(rangeStart) &&
        !normalizedStartDate.isAfter(rangeEnd);

    final deadlineInRange =
        normalizedDeadlineDate != null &&
        !normalizedDeadlineDate.isBefore(rangeStart) &&
        !normalizedDeadlineDate.isAfter(rangeEnd);

    // Include the entity if either the start date OR deadline is in range.
    // This preserves Scheduled semantics where entities can appear on due days
    // even if the start day falls outside the window.
    if (!startInRange && !deadlineInRange) {
      return [];
    }

    // Find completion for non-repeating entity (occurrence_date is null)
    final completion = completions
        .where((c) => c.occurrenceDate == null)
        .firstOrNull;

    final occurrence = OccurrenceData(
      date: startInRange ? normalizedStartDate : normalizedDeadlineDate!,
      deadline: deadlineDate,
      isRescheduled: false,
      completionId: completion?.id,
      completedAt: completion?.completedAt,
      completionNotes: completion?.notes,
    );

    return [builder(occurrence)];
  }

  /// Expands a repeating entity into multiple occurrences based on RRULE.
  List<T> _expandRepeating<T>({
    required T entity,
    required String entityId,
    required DateTime startDate,
    required DateTime? deadlineDate,
    required Duration? deadlineOffset,
    required String repeatIcalRrule,
    required bool repeatFromCompletion,
    required bool seriesEnded,
    required List<CompletionHistoryData> completions,
    required List<RecurrenceExceptionData> exceptions,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required T Function(OccurrenceData occurrence) builder,
  }) {
    // Parse RRULE (using cache for performance)
    final rrule = _parseRrule(repeatIcalRrule);
    if (rrule == null) {
      // Invalid RRULE - treat as non-repeating
      return _expandNonRepeating(
        entity: entity,
        startDate: startDate,
        deadlineDate: deadlineDate,
        completions: completions,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
        builder: builder,
      );
    }

    // Determine anchor date for RRULE expansion.
    // We use UTC date-times for the rrule package (it asserts the start is a
    // valid RRULE DateTime), but normalize outputs/keys to local date-only.
    DateTime anchorLocalDate = _normalizeDate(startDate);
    if (repeatFromCompletion && completions.isNotEmpty) {
      // For rolling recurrence, anchor from last completion
      final lastCompletion = completions.reduce(
        (a, b) => a.completedAt.isAfter(b.completedAt) ? a : b,
      );
      anchorLocalDate = _normalizeDate(lastCompletion.completedAt);
    }

    final anchorUtc = _normalizeDateUtcForRrule(anchorLocalDate);
    final rangeStartUtc = _normalizeDateUtcForRrule(rangeStart);
    final rangeEndUtc = _normalizeDateUtcForRrule(rangeEnd);

    // Generate RRULE dates.
    // The rrule package asserts that `after >= start`, so clamp the window.
    final afterUtc = rangeStartUtc.subtract(const Duration(days: 1));
    final safeAfterUtc = afterUtc.isBefore(anchorUtc) ? anchorUtc : afterUtc;

    final rruleDatesUtc = rrule
        .getInstances(
          start: anchorUtc,
          after: safeAfterUtc,
          before: rangeEndUtc.add(const Duration(days: 1)),
        )
        .toList();

    // When `after == start`, the rrule package returns instances strictly
    // after the start. For our use-case, the anchor date is itself a valid
    // occurrence, so include it explicitly.
    if (safeAfterUtc.isAtSameMomentAs(anchorUtc)) {
      rruleDatesUtc.insert(0, anchorUtc);
    }

    rruleDatesUtc.sort();

    // Deduplicate (rrule output + manual insertion can overlap).
    //
    // Keep dates in UTC for consistency: the DB values and tests are UTC-based,
    // and converting to local time can shift the time-of-day unexpectedly.
    final uniqueDates = <DateTime>[];
    for (final dateUtc in rruleDatesUtc) {
      final normalizedLocal = _normalizeDate(dateUtc);
      if (uniqueDates.isEmpty ||
          !uniqueDates.last.isAtSameMomentAs(normalizedLocal)) {
        uniqueDates.add(normalizedLocal);
      }
    }

    // Filter to exact range and respect seriesEnded
    final filteredDates = uniqueDates
        .where(
          (d) =>
              !d.isBefore(rangeStart) &&
              !d.isAfter(rangeEnd) &&
              (!seriesEnded || d.isBefore(_clock.nowLocal())),
        )
        .toList();

    // Build exceptions map keyed by normalized original date
    final exceptionsMap = {
      for (final e in exceptions) _normalizeDate(e.originalDate): e,
    };

    // Build completions map keyed by normalized original occurrence date
    final completionsMap = {
      for (final c in completions)
        if (c.originalOccurrenceDate != null)
          _normalizeDate(c.originalOccurrenceDate!): c,
    };

    final occurrences = <T>[];

    for (final originalDate in filteredDates) {
      // Check if this occurrence was skipped/rescheduled
      final exception = exceptionsMap[originalDate];

      if (exception?.exceptionType == RecurrenceExceptionType.skip) {
        // Skip this occurrence entirely
        continue;
      }

      // Determine the actual occurrence date (rescheduled or original)
      final occurrenceDate =
          exception?.exceptionType == RecurrenceExceptionType.reschedule
          ? _normalizeDate(exception!.newDate!)
          : originalDate;

      // Determine the deadline for this occurrence
      DateTime? occurrenceDeadline;
      if (exception?.exceptionType == RecurrenceExceptionType.reschedule &&
          exception!.newDeadline != null) {
        // Use rescheduled deadline if provided
        occurrenceDeadline = _normalizeDate(exception.newDeadline!);
      } else if (deadlineOffset != null) {
        // Calculate deadline based on offset from start
        occurrenceDeadline = occurrenceDate.add(deadlineOffset);
      }

      final completion = completionsMap[originalDate];

      final occurrence = OccurrenceData(
        date: occurrenceDate,
        deadline: occurrenceDeadline,
        isRescheduled:
            exception?.exceptionType == RecurrenceExceptionType.reschedule,
        completionId: completion?.id,
        completedAt: completion?.completedAt,
        completionNotes: completion?.notes,
        originalDate: originalDate,
      );

      occurrences.add(builder(occurrence));
    }

    return occurrences;
  }

  // ===========================================================================
  // PRIVATE: Helper Methods
  // ===========================================================================

  /// Normalize date to midnight (date-only).
  DateTime _normalizeDate(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  /// Normalize date for rrule package (UTC, preserving date).
  DateTime _normalizeDateUtcForRrule(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  /// Group list items by a key function.
  Map<String, List<T>> _groupBy<T>(
    List<T> items,
    String Function(T) keyFn,
  ) {
    final map = <String, List<T>>{};
    for (final item in items) {
      final key = keyFn(item);
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }

  /// Normalize task occurrence data.
  Task _normalizeTaskOccurrence(Task task, OccurrenceData occurrence) {
    return task.copyWith(occurrence: occurrence);
  }

  /// Normalize project occurrence data.
  Project _normalizeProjectOccurrence(
    Project project,
    OccurrenceData occurrence,
  ) {
    return project.copyWith(occurrence: occurrence);
  }
}
