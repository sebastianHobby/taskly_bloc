import 'package:taskly_bloc/domain/analytics/model/date_range.dart';
import 'package:taskly_bloc/domain/interfaces/journal_repository_contract.dart';
import 'package:taskly_bloc/domain/journal/model/journal_entry.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_definition.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_definition_choice.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_event.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_preference.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_state_day.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_state_entry.dart';
import 'package:taskly_bloc/domain/queries/journal_query.dart';

/// Simple no-op implementation for tests that need a [JournalRepositoryContract]
/// instance but don't exercise journal behavior.
class StubJournalRepository implements JournalRepositoryContract {
  const StubJournalRepository();

  @override
  Stream<List<JournalEntry>> watchJournalEntries({DateRange? range}) {
    return Stream.value(const <JournalEntry>[]);
  }

  @override
  Stream<List<JournalEntry>> watchJournalEntriesByQuery(JournalQuery query) {
    return Stream.value(const <JournalEntry>[]);
  }

  @override
  Future<JournalEntry?> getJournalEntryById(String id) async {
    return null;
  }

  @override
  Future<JournalEntry?> getJournalEntryByDate({required DateTime date}) async {
    return null;
  }

  @override
  Future<List<JournalEntry>> getJournalEntriesByDate({
    required DateTime date,
  }) async {
    return const <JournalEntry>[];
  }

  @override
  Future<void> saveJournalEntry(JournalEntry entry) async {}

  @override
  Future<String> upsertJournalEntry(JournalEntry entry) async {
    return entry.id;
  }

  @override
  Future<void> deleteJournalEntry(String id) async {}

  @override
  Stream<List<TrackerDefinition>> watchTrackerDefinitions() {
    return Stream.value(const <TrackerDefinition>[]);
  }

  @override
  Stream<List<TrackerPreference>> watchTrackerPreferences() {
    return Stream.value(const <TrackerPreference>[]);
  }

  @override
  Stream<List<TrackerDefinitionChoice>> watchTrackerDefinitionChoices({
    required String trackerId,
  }) {
    return Stream.value(const <TrackerDefinitionChoice>[]);
  }

  @override
  Stream<List<TrackerStateDay>> watchTrackerStateDay({
    required DateRange range,
  }) {
    return Stream.value(const <TrackerStateDay>[]);
  }

  @override
  Stream<List<TrackerStateEntry>> watchTrackerStateEntry({
    required DateRange range,
  }) {
    return Stream.value(const <TrackerStateEntry>[]);
  }

  @override
  Future<void> saveTrackerDefinition(TrackerDefinition definition) async {}

  @override
  Future<void> saveTrackerPreference(TrackerPreference preference) async {}

  @override
  Future<void> saveTrackerDefinitionChoice(
    TrackerDefinitionChoice choice,
  ) async {}

  @override
  Future<void> appendTrackerEvent(TrackerEvent event) async {}

  @override
  Future<void> deleteTrackerAndData(String trackerId) async {}

  @override
  Stream<List<TrackerEvent>> watchTrackerEvents({
    DateRange? range,
    String? anchorType,
    String? entryId,
    DateTime? anchorDate,
    String? trackerId,
  }) {
    return Stream.value(const <TrackerEvent>[]);
  }

  @override
  Future<Map<DateTime, double>> getDailyMoodAverages({
    required DateRange range,
  }) async {
    return const <DateTime, double>{};
  }

  @override
  Future<Map<DateTime, double>> getTrackerValues({
    required String trackerId,
    required DateRange range,
  }) async {
    return const <DateTime, double>{};
  }
}
