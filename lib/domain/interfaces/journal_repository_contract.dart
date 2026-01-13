import 'package:taskly_bloc/domain/analytics/model/date_range.dart';
import 'package:taskly_bloc/domain/journal/model/journal_entry.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_definition.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_definition_choice.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_event.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_preference.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_state_day.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_state_entry.dart';
import 'package:taskly_bloc/domain/queries/journal_query.dart';

/// Repository contract for journal data.
///
/// Phase 02 replaces the tracker-related APIs.
abstract class JournalRepositoryContract {
  // === Journal Entries ===

  Stream<List<JournalEntry>> watchJournalEntries({
    DateRange? range,
  });

  /// Watch journal entries with query-based filtering.
  ///
  /// Supports filtering by date, mood, text content via [JournalQuery].
  Stream<List<JournalEntry>> watchJournalEntriesByQuery(JournalQuery query);

  Future<JournalEntry?> getJournalEntryById(String id);

  Future<JournalEntry?> getJournalEntryByDate({
    required DateTime date,
  });

  /// Get all journal entries for a specific date (supports multiple entries per
  /// day).
  Future<List<JournalEntry>> getJournalEntriesByDate({
    required DateTime date,
  });

  Future<void> saveJournalEntry(JournalEntry entry);

  /// Upsert a journal entry and return the ID that was used.
  ///
  /// This is useful for workflows that need a stable entry ID to attach
  /// tracker events (e.g. mood) to the entry.
  Future<String> upsertJournalEntry(JournalEntry entry);

  Future<void> deleteJournalEntry(String id);

  // === Trackers (OPT-A: event-log + projections) ===

  Stream<List<TrackerDefinition>> watchTrackerDefinitions();

  Stream<List<TrackerPreference>> watchTrackerPreferences();

  Stream<List<TrackerDefinitionChoice>> watchTrackerDefinitionChoices({
    required String trackerId,
  });

  Stream<List<TrackerStateDay>> watchTrackerStateDay({
    required DateRange range,
  });

  Stream<List<TrackerStateEntry>> watchTrackerStateEntry({
    required DateRange range,
  });

  Future<void> saveTrackerDefinition(TrackerDefinition definition);

  Future<void> saveTrackerPreference(TrackerPreference preference);

  Future<void> appendTrackerEvent(TrackerEvent event);

  /// Watch raw tracker events for building B1 Journal UIs.
  ///
  /// Prefer projections for heavy analytics, but the hub UI needs to reflect
  /// local writes immediately (before server-side projections update).
  Stream<List<TrackerEvent>> watchTrackerEvents({
    DateRange? range,
    String? anchorType,
    String? entryId,
    DateTime? anchorDate,
    String? trackerId,
  });

  // === Analytics Helpers ===

  Future<Map<DateTime, double>> getDailyMoodAverages({
    required DateRange range,
  });

  Future<Map<DateTime, double>> getTrackerValues({
    required String trackerId,
    required DateRange range,
  });
}
