import 'package:taskly_bloc/domain/analytics/model/date_range.dart';
import 'package:taskly_bloc/domain/wellbeing/model/daily_tracker_response.dart';
import 'package:taskly_bloc/domain/wellbeing/model/journal_entry.dart';
import 'package:taskly_bloc/domain/wellbeing/model/tracker.dart';
import 'package:taskly_bloc/domain/queries/journal_query.dart';

/// Repository contract for wellbeing data
abstract class WellbeingRepositoryContract {
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

  /// Get all journal entries for a specific date (supports multiple entries per day)
  Future<List<JournalEntry>> getJournalEntriesByDate({
    required DateTime date,
  });

  Future<void> saveJournalEntry(JournalEntry entry);

  Future<void> deleteJournalEntry(String id);

  // === Trackers ===

  Stream<List<Tracker>> watchTrackers();

  Future<List<Tracker>> getAllTrackers();

  Future<Tracker?> getTrackerById(String trackerId);

  Future<void> saveTracker(Tracker tracker);

  Future<void> deleteTracker(String trackerId);

  Future<void> reorderTrackers(List<String> trackerIds);

  // === Daily Tracker Responses (allDay scope) ===

  Stream<List<DailyTrackerResponse>> watchDailyTrackerResponses({
    required DateTime date,
  });

  Future<List<DailyTrackerResponse>> getDailyTrackerResponses({
    required DateTime date,
  });

  Future<void> saveDailyTrackerResponse(DailyTrackerResponse response);

  Future<void> deleteDailyTrackerResponse(String id);

  // === Analytics Helpers ===

  /// Get daily mood averages for a date range
  Future<Map<DateTime, double>> getDailyMoodAverages({
    required DateRange range,
  });

  /// Get tracker values for a date range (normalized to double)
  Future<Map<DateTime, double>> getTrackerValues({
    required String trackerId,
    required DateRange range,
  });
}
