import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/domain/models/analytics/date_range.dart';
import 'package:taskly_bloc/domain/models/wellbeing/daily_tracker_response.dart';
import 'package:taskly_bloc/domain/models/wellbeing/journal_entry.dart';
import 'package:taskly_bloc/domain/models/wellbeing/mood_rating.dart';
import 'package:taskly_bloc/domain/models/wellbeing/tracker.dart';
import 'package:taskly_bloc/domain/models/wellbeing/tracker_response.dart';
import 'package:taskly_bloc/domain/models/wellbeing/tracker_response_config.dart';
import 'package:taskly_bloc/domain/interfaces/wellbeing_repository_contract.dart';

class WellbeingRepositoryImpl implements WellbeingRepositoryContract {
  WellbeingRepositoryImpl(this._database);
  final AppDatabase _database;

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
    final entryId = entry.id.isEmpty ? _generateId() : entry.id;

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

    await _database
        .into(_database.dailyTrackerResponses)
        .insertOnConflictUpdate(
          DailyTrackerResponsesCompanion(
            id: Value(response.id),
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
    await _database
        .into(_database.trackers)
        .insertOnConflictUpdate(
          TrackersCompanion(
            id: Value(tracker.id.isEmpty ? _generateId() : tracker.id),
            name: Value(tracker.name),
            description: Value(tracker.description),
            entryScope: Value(tracker.entryScope.name),
            responseType: Value(
              tracker.config.map(
                choice: (_) => 'choice',
                scale: (_) => 'scale',
                yesNo: (_) => 'yesNo',
              ),
            ),
            responseConfig: Value(jsonEncode(_configToJson(tracker.config))),
            sortOrder: Value(tracker.sortOrder),
            createdAt: Value(tracker.createdAt),
            updatedAt: Value(tracker.updatedAt),
          ),
        );
  }

  @override
  Future<void> deleteTracker(String trackerId) async {
    // Since there's no deletedAt column, do hard delete
    await (_database.delete(
      _database.trackers,
    )..where((t) => t.id.equals(trackerId))).go();
  }

  @override
  Future<void> reorderTrackers(List<String> trackerIds) async {
    await _database.batch((batch) {
      for (var i = 0; i < trackerIds.length; i++) {
        batch.update(
          _database.trackers,
          TrackersCompanion(sortOrder: Value(i)),
          where: (t) => t.id.equals(trackerIds[i]),
        );
      }
    });
  }

  @override
  Future<Map<DateTime, double>> getDailyMoodAverages({
    required DateRange range,
  }) async {
    final query = _database.select(_database.journalEntries)
      ..where(
        (e) =>
            e.entryDate.isBiggerOrEqualValue(range.start) &
            e.entryDate.isSmallerOrEqualValue(range.end),
      )
      ..orderBy([(e) => OrderingTerm.asc(e.entryDate)]);

    final results = await query.get();
    return Map.fromEntries(
      results
          .where((e) => e.moodRating != null)
          .map((e) => MapEntry(e.entryDate, e.moodRating!.toDouble())),
    );
  }

  @override
  Future<Map<DateTime, double>> getTrackerValues({
    required String trackerId,
    required DateRange range,
  }) async {
    // First, check the tracker scope
    final tracker = await getTrackerById(trackerId);
    if (tracker == null) return {};

    if (tracker.entryScope == TrackerEntryScope.allDay) {
      // For allDay trackers, query DailyTrackerResponses table
      final query = _database.select(_database.dailyTrackerResponses)
        ..where(
          (r) =>
              r.trackerId.equals(trackerId) &
              r.responseDate.isBiggerOrEqualValue(range.start) &
              r.responseDate.isSmallerOrEqualValue(range.end),
        )
        ..orderBy([(r) => OrderingTerm.asc(r.responseDate)]);

      final results = await query.get();
      return Map.fromEntries(
        results.map((row) {
          final responseData =
              jsonDecode(row.responseValue) as Map<String, dynamic>;
          final date = DateTime(
            row.responseDate.year,
            row.responseDate.month,
            row.responseDate.day,
          );
          return MapEntry(date, _extractNumericValue(responseData));
        }),
      );
    } else {
      // For perEntry trackers, query TrackerResponses and aggregate by date
      final query =
          _database.select(_database.trackerResponses).join([
              innerJoin(
                _database.journalEntries,
                _database.journalEntries.id.equalsExp(
                  _database.trackerResponses.journalEntryId,
                ),
              ),
            ])
            ..where(
              _database.trackerResponses.trackerId.equals(trackerId) &
                  _database.journalEntries.entryDate.isBiggerOrEqualValue(
                    range.start,
                  ) &
                  _database.journalEntries.entryDate.isSmallerOrEqualValue(
                    range.end,
                  ),
            )
            ..orderBy([OrderingTerm.asc(_database.journalEntries.entryDate)]);

      final results = await query.get();

      // Group by date and calculate average
      final Map<DateTime, List<double>> valuesByDate = {};

      for (final row in results) {
        final response = row.readTable(_database.trackerResponses);
        final entry = row.readTable(_database.journalEntries);
        final date = DateTime(
          entry.entryDate.year,
          entry.entryDate.month,
          entry.entryDate.day,
        );

        final responseData =
            jsonDecode(response.responseValue) as Map<String, dynamic>;
        final value = _extractNumericValue(responseData);

        valuesByDate.putIfAbsent(date, () => []).add(value);
      }

      // Calculate average for each date
      return valuesByDate.map(
        (date, values) => MapEntry(
          date,
          values.reduce((a, b) => a + b) / values.length,
        ),
      );
    }
  }

  double _extractNumericValue(Map<String, dynamic> responseData) {
    if (responseData.containsKey('value')) {
      final value = responseData['value'];
      if (value is int) {
        return value.toDouble();
      } else if (value is bool) {
        return value ? 1.0 : 0.0;
      } else if (value is double) {
        return value;
      }
    }
    return 0;
  }

  JournalEntry _mapToJournalEntry(
    JournalEntryEntity entity,
    List<TrackerResponse> trackerResponses,
  ) {
    return JournalEntry(
      id: entity.id,
      entryDate: entity.entryDate,
      entryTime: entity.entryTime,
      moodRating: entity.moodRating != null
          ? MoodRating.values.firstWhere(
              (m) => m.value == entity.moodRating,
              orElse: () => MoodRating.neutral,
            )
          : null,
      journalText: entity.journalText,
      perEntryTrackerResponses: trackerResponses,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Future<List<TrackerResponse>> _getTrackerResponsesForEntry(
    String journalEntryId,
  ) async {
    final query = _database.select(_database.trackerResponses)
      ..where((r) => r.journalEntryId.equals(journalEntryId));
    final rows = await query.get();
    return rows.map(_mapToTrackerResponse).toList();
  }

  TrackerResponse _mapToTrackerResponse(TrackerResponseEntity entity) {
    final valueJson = jsonDecode(entity.responseValue) as Map<String, dynamic>;
    return TrackerResponse(
      id: entity.id,
      journalEntryId: entity.journalEntryId,
      trackerId: entity.trackerId,
      value: TrackerResponseValue.fromJson(valueJson),
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  DailyTrackerResponse _mapToDailyTrackerResponse(
    DailyTrackerResponseEntity entity,
  ) {
    final valueJson = jsonDecode(entity.responseValue) as Map<String, dynamic>;
    return DailyTrackerResponse(
      id: entity.id,
      responseDate: entity.responseDate,
      trackerId: entity.trackerId,
      value: TrackerResponseValue.fromJson(valueJson),
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Future<void> _syncTrackerResponses({
    required String journalEntryId,
    required List<TrackerResponse> responses,
  }) async {
    final desiredTrackerIds = responses
        .map((r) => r.trackerId)
        .where((id) => id.isNotEmpty)
        .toSet();

    if (desiredTrackerIds.isEmpty) {
      await (_database.delete(
        _database.trackerResponses,
      )..where((r) => r.journalEntryId.equals(journalEntryId))).go();
    } else {
      await (_database.delete(
            _database.trackerResponses,
          )..where(
            (r) =>
                r.journalEntryId.equals(journalEntryId) &
                r.trackerId.isNotIn(desiredTrackerIds.toList()),
          ))
          .go();
    }

    for (final response in responses) {
      await _database
          .into(_database.trackerResponses)
          .insertOnConflictUpdate(
            TrackerResponsesCompanion(
              id: Value(response.id),
              journalEntryId: Value(journalEntryId),
              trackerId: Value(response.trackerId),
              responseValue: Value(jsonEncode(response.value.toJson())),
              createdAt: Value(response.createdAt),
              updatedAt: Value(response.updatedAt),
            ),
          );
    }
  }

  Tracker _mapToTracker(TrackerEntity entity) {
    final configJson =
        jsonDecode(entity.responseConfig) as Map<String, dynamic>;

    // Parse responseType from string
    final responseType = TrackerResponseType.values.firstWhere(
      (t) => t.name == entity.responseType,
      orElse: () => TrackerResponseType.choice,
    );

    final config = _jsonToConfig(entity.responseType, configJson);

    return Tracker(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      responseType: responseType,
      config: config,
      entryScope: entity.entryScope == 'perEntry'
          ? TrackerEntryScope.perEntry
          : TrackerEntryScope.allDay,
      sortOrder: entity.sortOrder,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  TrackerResponseConfig _jsonToConfig(String type, Map<String, dynamic> json) {
    switch (type) {
      case 'choice':
        return TrackerResponseConfig.choice(
          options: (json['options'] as List).cast<String>(),
        );
      case 'scale':
        return TrackerResponseConfig.scale(
          min: json['min'] as int? ?? 1,
          max: json['max'] as int? ?? 5,
          minLabel: json['minLabel'] as String?,
          maxLabel: json['maxLabel'] as String?,
        );
      case 'yesNo':
        return const TrackerResponseConfig.yesNo();
      default:
        throw ArgumentError('Unknown tracker type: $type');
    }
  }

  Map<String, dynamic> _configToJson(TrackerResponseConfig config) {
    return config.map(
      choice: (c) => {'options': c.options},
      scale: (s) => {
        'min': s.min,
        'max': s.max,
        'minLabel': s.minLabel,
        'maxLabel': s.maxLabel,
      },
      yesNo: (_) => <String, dynamic>{},
    );
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
