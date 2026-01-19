import 'package:taskly_domain/src/analytics/model/date_range.dart';
import 'package:taskly_domain/src/journal/model/journal_entry.dart';
import 'package:taskly_domain/src/journal/model/tracker_definition.dart';
import 'package:taskly_domain/src/journal/model/tracker_definition_choice.dart';
import 'package:taskly_domain/src/journal/model/tracker_event.dart';
import 'package:taskly_domain/src/journal/model/tracker_preference.dart';
import 'package:taskly_domain/src/journal/model/tracker_state_day.dart';
import 'package:taskly_domain/src/journal/model/tracker_state_entry.dart';
import 'package:taskly_domain/src/queries/journal_query.dart';
import 'package:taskly_domain/src/telemetry/operation_context.dart';

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

  Future<void> saveJournalEntry(
    JournalEntry entry, {
    OperationContext? context,
  });

  /// Upsert a journal entry and return the ID that was used.
  ///
  /// This is useful for workflows that need a stable entry ID to attach
  /// tracker events (e.g. mood) to the entry.
  Future<String> upsertJournalEntry(
    JournalEntry entry, {
    OperationContext? context,
  });

  Future<void> deleteJournalEntry(String id, {OperationContext? context});

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

  Future<void> saveTrackerDefinition(
    TrackerDefinition definition, {
    OperationContext? context,
  });

  Future<void> saveTrackerPreference(
    TrackerPreference preference, {
    OperationContext? context,
  });

  Future<void> saveTrackerDefinitionChoice(
    TrackerDefinitionChoice choice, {
    OperationContext? context,
  });

  Future<void> appendTrackerEvent(
    TrackerEvent event, {
    OperationContext? context,
  });

  /// Soft-delete a tracker definition and purge its local event/projection data.
  ///
  /// This keeps the definition row (with `deletedAt`) for sync/auditing while
  /// removing local UI/analytics noise from associated events and projections.
  Future<void> deleteTrackerAndData(
    String trackerId, {
    OperationContext? context,
  });

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
