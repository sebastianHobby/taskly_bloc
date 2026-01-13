import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:taskly_bloc/data/id/id_generator.dart';
import 'package:taskly_bloc/data/infrastructure/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/mappers/journal_predicate_mapper.dart';
import 'package:taskly_bloc/data/repositories/mixins/query_builder_mixin.dart';
import 'package:taskly_bloc/domain/analytics/model/date_range.dart';
import 'package:taskly_bloc/domain/interfaces/journal_repository_contract.dart';
import 'package:taskly_bloc/domain/journal/model/daily_tracker_response.dart';
import 'package:taskly_bloc/domain/journal/model/journal_entry.dart';
import 'package:taskly_bloc/domain/journal/model/mood_rating.dart';
import 'package:taskly_bloc/domain/journal/model/tracker.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_response.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_response_config.dart';
import 'package:taskly_bloc/domain/queries/journal_predicate.dart';
import 'package:taskly_bloc/domain/queries/journal_query.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';

class JournalRepositoryImpl
    with QueryBuilderMixin
    implements JournalRepositoryContract {
  JournalRepositoryImpl(this._database, this._idGenerator);

  final AppDatabase _database;
  final IdGenerator _idGenerator;
  final JournalPredicateMapper _predicateMapper =
      const JournalPredicateMapper();

  @override
  Stream<List<JournalEntry>> watchJournalEntries({
    DateRange? range,
  }) {
    final query = _database.select(_database.journalEntries);

    if (range != null) {
      query.where(
        (e) =>
            e.entryDate.isBiggerOrEqualValue(range.start) &
            e.entryDate.isSmallerOrEqualValue(range.end),
      );
    }

    query.orderBy([(e) => OrderingTerm.desc(e.entryDate)]);

    return query.watch().asyncMap((rows) async {
      final entries = <JournalEntry>[];
      for (final row in rows) {
        final responses = await _getTrackerResponsesForEntry(row.id);
        entries.add(_mapToJournalEntry(row, responses));
      }
      return entries;
    });
  }

  @override
  Stream<List<JournalEntry>> watchJournalEntriesByQuery(
    JournalQuery journalQuery,
  ) {
    final query = _database.select(_database.journalEntries);

    final whereExpr = _whereExpressionFromFilter(journalQuery.filter);
    if (whereExpr != null) {
      query.where((tbl) => whereExpr);
    }

    query.orderBy([(e) => OrderingTerm.desc(e.entryDate)]);

    return query.watch().asyncMap((rows) async {
      final entries = <JournalEntry>[];
      for (final row in rows) {
        final responses = await _getTrackerResponsesForEntry(row.id);
        entries.add(_mapToJournalEntry(row, responses));
      }
      return entries;
    });
  }

  Expression<bool>? _whereExpressionFromFilter(
    QueryFilter<JournalPredicate> filter,
  ) {
    return whereExpressionFromFilter(
      filter: filter,
      predicateToExpression: (p) => _predicateMapper.predicateToExpression(
        p,
        _database.journalEntries,
      ),
    );
  }

  @override
  Future<JournalEntry?> getJournalEntryById(String id) async {
    final query = _database.select(_database.journalEntries)
      ..where((e) => e.id.equals(id));

    final result = await query.getSingleOrNull();
    if (result == null) return null;
    final responses = await _getTrackerResponsesForEntry(result.id);
    return _mapToJournalEntry(result, responses);
  }

  @override
  Future<JournalEntry?> getJournalEntryByDate({
    required DateTime date,
  }) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final query = _database.select(_database.journalEntries)
      ..where((e) => e.entryDate.equals(dateOnly));

    final result = await query.getSingleOrNull();
    if (result == null) return null;
    final responses = await _getTrackerResponsesForEntry(result.id);
    return _mapToJournalEntry(result, responses);
  }

  @override
  Future<List<JournalEntry>> getJournalEntriesByDate({
    required DateTime date,
  }) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final query = _database.select(_database.journalEntries)
      ..where((e) => e.entryDate.equals(dateOnly))
      ..orderBy([(e) => OrderingTerm.desc(e.entryTime)]);

    final results = await query.get();
    final entries = <JournalEntry>[];
    for (final row in results) {
      final responses = await _getTrackerResponsesForEntry(row.id);
      entries.add(_mapToJournalEntry(row, responses));
    }
    return entries;
  }

  @override
  Future<void> saveJournalEntry(JournalEntry entry) async {
    final entryId = entry.id.isEmpty ? _idGenerator.journalEntryId() : entry.id;

    await _database
        .into(_database.journalEntries)
        .insertOnConflictUpdate(
          JournalEntriesCompanion(
            id: Value(entryId),
            entryDate: Value(entry.entryDate),
            entryTime: Value(entry.entryTime),
            moodRating: Value(entry.moodRating?.value),
            journalText: Value(entry.journalText),
            createdAt: Value(entry.createdAt),
            updatedAt: Value(entry.updatedAt),
          ),
        );

    await _syncTrackerResponses(
      journalEntryId: entryId,
      responses: entry.perEntryTrackerResponses,
    );
  }

  @override
  Future<void> deleteJournalEntry(String id) async {
    await (_database.delete(
      _database.trackerResponses,
    )..where((r) => r.journalEntryId.equals(id))).go();

    await (_database.delete(
      _database.journalEntries,
    )..where((e) => e.id.equals(id))).go();
  }

  @override
  Stream<List<DailyTrackerResponse>> watchDailyTrackerResponses({
    required DateTime date,
  }) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final query = _database.select(_database.dailyTrackerResponses)
      ..where((r) => r.responseDate.equals(dateOnly));

    return query.watch().map(
      (rows) => rows.map(_mapToDailyTrackerResponse).toList(),
    );
  }

  @override
  Future<List<DailyTrackerResponse>> getDailyTrackerResponses({
    required DateTime date,
  }) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final query = _database.select(_database.dailyTrackerResponses)
      ..where((r) => r.responseDate.equals(dateOnly));

    final results = await query.get();
    return results.map(_mapToDailyTrackerResponse).toList();
  }

  @override
  Future<void> saveDailyTrackerResponse(DailyTrackerResponse response) async {
    final dateOnly = DateTime(
      response.responseDate.year,
      response.responseDate.month,
      response.responseDate.day,
    );

    final responseId = response.id.isEmpty
        ? _idGenerator.dailyTrackerResponseId(
            trackerId: response.trackerId,
            responseDate: dateOnly,
          )
        : response.id;

    await _database
        .into(_database.dailyTrackerResponses)
        .insertOnConflictUpdate(
          DailyTrackerResponsesCompanion(
            id: Value(responseId),
            responseDate: Value(dateOnly),
            trackerId: Value(response.trackerId),
            responseValue: Value(jsonEncode(response.value.toJson())),
            createdAt: Value(response.createdAt),
            updatedAt: Value(response.updatedAt),
          ),
        );
  }

  @override
  Future<void> deleteDailyTrackerResponse(String id) async {
    await (_database.delete(
      _database.dailyTrackerResponses,
    )..where((r) => r.id.equals(id))).go();
  }

  @override
  Stream<List<Tracker>> watchTrackers() {
    final query = _database.select(_database.trackers)
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]);

    return query.watch().map((rows) => rows.map(_mapToTracker).toList());
  }

  @override
  Future<List<Tracker>> getAllTrackers() async {
    final query = _database.select(_database.trackers)
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]);

    final results = await query.get();
    return results.map(_mapToTracker).toList();
  }

  @override
  Future<Tracker?> getTrackerById(String trackerId) async {
    final query = _database.select(_database.trackers)
      ..where((t) => t.id.equals(trackerId));

    final result = await query.getSingleOrNull();
    return result != null ? _mapToTracker(result) : null;
  }

  @override
  Future<void> saveTracker(Tracker tracker) async {
    final trackerId = tracker.id.isEmpty
        ? _idGenerator.trackerId(name: tracker.name)
        : tracker.id;

    await _database
        .into(_database.trackers)
        .insertOnConflictUpdate(
          TrackersCompanion(
            id: Value(trackerId),
            name: Value(tracker.name),
            description: Value(tracker.description),
            responseType: Value(tracker.responseType.name),
            responseConfig: Value(jsonEncode(tracker.config.toJson())),
            entryScope: Value(tracker.entryScope.name),
            sortOrder: Value(tracker.sortOrder),
            createdAt: Value(tracker.createdAt),
            updatedAt: Value(tracker.updatedAt),
          ),
        );
  }

  @override
  Future<Map<DateTime, double>> getDailyMoodAverages({
    required DateRange range,
  }) async {
    final query = _database.select(_database.journalEntries)
      ..where(
        (e) =>
            e.entryDate.isBiggerOrEqualValue(range.start) &
            e.entryDate.isSmallerOrEqualValue(range.end) &
            e.moodRating.isNotNull(),
      );

    final rows = await query.get();
    final byDate = <DateTime, List<int>>{};

    for (final row in rows) {
      final mood = row.moodRating;
      if (mood == null) continue;
      byDate.putIfAbsent(row.entryDate, () => <int>[]).add(mood);
    }

    final result = <DateTime, double>{};
    for (final entry in byDate.entries) {
      final values = entry.value;
      if (values.isEmpty) continue;
      result[entry.key] =
          values.reduce((a, b) => a + b) / values.length.toDouble();
    }

    return result;
  }

  @override
  Future<Map<DateTime, double>> getTrackerValues({
    required String trackerId,
    required DateRange range,
  }) async {
    // Prefer all-day responses for a date-based series.
    final dailyQuery = _database.select(_database.dailyTrackerResponses)
      ..where(
        (r) =>
            r.trackerId.equals(trackerId) &
            r.responseDate.isBiggerOrEqualValue(range.start) &
            r.responseDate.isSmallerOrEqualValue(range.end),
      );

    final dailyRows = await dailyQuery.get();
    final result = <DateTime, double>{};
    for (final row in dailyRows) {
      final decoded = jsonDecode(row.responseValue) as Map<String, dynamic>;
      final value = TrackerResponseValue.fromJson(decoded);
      final numeric = _toNumeric(value);
      if (numeric != null) {
        result[row.responseDate] = numeric;
      }
    }

    if (result.isNotEmpty) return result;

    // Fallback: per-entry responses joined via journal entry date.
    final entryQuery = _database.select(_database.journalEntries)
      ..where(
        (e) =>
            e.entryDate.isBiggerOrEqualValue(range.start) &
            e.entryDate.isSmallerOrEqualValue(range.end),
      );
    final entries = await entryQuery.get();
    if (entries.isEmpty) return const {};

    final entryIds = entries.map((e) => e.id).toList();
    final entryDateById = <String, DateTime>{
      for (final e in entries) e.id: e.entryDate,
    };

    final responseQuery = _database.select(_database.trackerResponses)
      ..where(
        (r) => r.trackerId.equals(trackerId) & r.journalEntryId.isIn(entryIds),
      );
    final responseRows = await responseQuery.get();

    final valuesByDate = <DateTime, List<double>>{};
    for (final row in responseRows) {
      final date = entryDateById[row.journalEntryId];
      if (date == null) continue;

      final decoded = jsonDecode(row.responseValue) as Map<String, dynamic>;
      final value = TrackerResponseValue.fromJson(decoded);
      final numeric = _toNumeric(value);
      if (numeric == null) continue;
      valuesByDate.putIfAbsent(date, () => <double>[]).add(numeric);
    }

    final averaged = <DateTime, double>{};
    for (final entry in valuesByDate.entries) {
      final values = entry.value;
      if (values.isEmpty) continue;
      averaged[entry.key] =
          values.reduce((a, b) => a + b) / values.length.toDouble();
    }

    return averaged;
  }

  @override
  Future<void> deleteTracker(String trackerId) async {
    await (_database.delete(
      _database.trackerResponses,
    )..where((r) => r.trackerId.equals(trackerId))).go();

    await (_database.delete(
      _database.dailyTrackerResponses,
    )..where((r) => r.trackerId.equals(trackerId))).go();

    await (_database.delete(
      _database.trackers,
    )..where((t) => t.id.equals(trackerId))).go();
  }

  @override
  Future<void> reorderTrackers(List<String> orderedIds) async {
    await _database.transaction(() async {
      for (var i = 0; i < orderedIds.length; i++) {
        await (_database.update(_database.trackers)
              ..where((t) => t.id.equals(orderedIds[i])))
            .write(TrackersCompanion(sortOrder: Value(i)));
      }
    });
  }

  Future<List<TrackerResponse>> _getTrackerResponsesForEntry(
    String journalEntryId,
  ) async {
    final query = _database.select(_database.trackerResponses)
      ..where((r) => r.journalEntryId.equals(journalEntryId));

    final results = await query.get();
    return results.map(_mapToTrackerResponse).toList();
  }

  Future<void> _syncTrackerResponses({
    required String journalEntryId,
    required List<TrackerResponse> responses,
  }) async {
    final existing = await _getTrackerResponsesForEntry(journalEntryId);
    final existingIds = existing.map((r) => r.id).toSet();
    final newIds = responses
        .map((r) => r.id)
        .where((id) => id.isNotEmpty)
        .toSet();

    final idsToDelete = existingIds.difference(newIds);
    if (idsToDelete.isNotEmpty) {
      await (_database.delete(
        _database.trackerResponses,
      )..where((r) => r.id.isIn(idsToDelete))).go();
    }

    for (final response in responses) {
      final responseId = response.id.isEmpty
          ? _idGenerator.trackerResponseId(
              journalEntryId: journalEntryId,
              trackerId: response.trackerId,
            )
          : response.id;

      await _database
          .into(_database.trackerResponses)
          .insertOnConflictUpdate(
            TrackerResponsesCompanion(
              id: Value(responseId),
              journalEntryId: Value(journalEntryId),
              trackerId: Value(response.trackerId),
              responseValue: Value(jsonEncode(response.value.toJson())),
              createdAt: Value(response.createdAt),
              updatedAt: Value(response.updatedAt),
            ),
          );
    }
  }

  JournalEntry _mapToJournalEntry(
    JournalEntryEntity row,
    List<TrackerResponse> responses,
  ) {
    return JournalEntry(
      id: row.id,
      entryDate: row.entryDate,
      entryTime: row.entryTime,
      moodRating: row.moodRating != null
          ? MoodRating.fromValue(row.moodRating!)
          : null,
      journalText: row.journalText,
      perEntryTrackerResponses: responses,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  DailyTrackerResponse _mapToDailyTrackerResponse(
    DailyTrackerResponseEntity row,
  ) {
    return DailyTrackerResponse(
      id: row.id,
      responseDate: row.responseDate,
      trackerId: row.trackerId,
      value: TrackerResponseValue.fromJson(
        jsonDecode(row.responseValue) as Map<String, dynamic>,
      ),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  Tracker _mapToTracker(TrackerEntity row) {
    return Tracker(
      id: row.id,
      name: row.name,
      description: row.description,
      responseType: TrackerResponseType.values.byName(row.responseType),
      config: TrackerResponseConfig.fromJson(
        jsonDecode(row.responseConfig) as Map<String, dynamic>,
      ),
      entryScope: TrackerEntryScope.values.byName(row.entryScope),
      sortOrder: row.sortOrder,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  double? _toNumeric(TrackerResponseValue value) {
    return value.when(
      choice: (selected) => null,
      scale: (value) => value.toDouble(),
      yesNo: (value) => value ? 1.0 : 0.0,
    );
  }

  TrackerResponse _mapToTrackerResponse(TrackerResponseEntity row) {
    return TrackerResponse(
      id: row.id,
      journalEntryId: row.journalEntryId,
      trackerId: row.trackerId,
      value: TrackerResponseValue.fromJson(
        jsonDecode(row.responseValue) as Map<String, dynamic>,
      ),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
