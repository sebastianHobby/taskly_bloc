import 'package:taskly_bloc/domain/models/analytics/date_range.dart';
import 'package:taskly_bloc/domain/models/wellbeing/journal_entry.dart';
import 'package:taskly_bloc/domain/models/wellbeing/tracker.dart';

/// Repository interface for wellbeing data
abstract class WellbeingRepository {
  // === Journal Entries ===

  Stream<List<JournalEntry>> watchJournalEntries({
    DateRange? range,
  });

  Future<JournalEntry?> getJournalEntryById(String id);

  Future<JournalEntry?> getJournalEntryByDate({
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
