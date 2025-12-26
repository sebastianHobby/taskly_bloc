import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/presentation/features/analytics/domain/models/date_range.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/domain/models/journal_entry.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/domain/models/mood_rating.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/domain/models/tracker.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/domain/models/tracker_response_config.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/domain/repositories/wellbeing_repository.dart';

class WellbeingRepositoryImpl implements WellbeingRepository {
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

    return query.watch().map((rows) => rows.map(_mapToJournalEntry).toList());
  }

  @override
  Future<JournalEntry?> getJournalEntryById(String id) async {
    final query = _database.select(_database.journalEntries)
      ..where((e) => e.id.equals(id));

    final result = await query.getSingleOrNull();
    return result != null ? _mapToJournalEntry(result) : null;
  }

  @override
  Future<JournalEntry?> getJournalEntryByDate({
    required DateTime date,
  }) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final query = _database.select(_database.journalEntries)
      ..where((e) => e.entryDate.equals(dateOnly));

    final result = await query.getSingleOrNull();
    return result != null ? _mapToJournalEntry(result) : null;
  }

  @override
  Future<void> saveJournalEntry(JournalEntry entry) async {
    await _database
        .into(_database.journalEntries)
        .insertOnConflictUpdate(
          JournalEntriesCompanion(
            id: Value(entry.id.isEmpty ? _generateId() : entry.id),
            entryDate: Value(entry.entryDate),
            entryTime: Value(entry.entryTime),
            moodRating: Value(entry.moodRating?.value),
            journalText: Value(entry.journalText ?? ''),
            createdAt: Value(entry.createdAt),
            updatedAt: Value(entry.updatedAt),
          ),
        );
  }

  @override
  Future<void> deleteJournalEntry(String id) async {
    await (_database.delete(
      _database.journalEntries,
    )..where((e) => e.id.equals(id))).go();
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
            config: Value(jsonEncode(_configToJson(tracker.config))),
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
    final query = _database.select(_database.trackerResponses)
      ..where(
        (r) =>
            r.trackerId.equals(trackerId) &
            r.createdAt.isBiggerOrEqualValue(range.start) &
            r.createdAt.isSmallerOrEqualValue(range.end),
      )
      ..orderBy([(r) => OrderingTerm.asc(r.createdAt)]);

    final results = await query.get();
    final Map<DateTime, double> values = {};

    for (final row in results) {
      final responseData =
          jsonDecode(row.responseValue) as Map<String, dynamic>;
      final date = DateTime(
        row.createdAt.year,
        row.createdAt.month,
        row.createdAt.day,
      );

      // Extract numeric value based on response type
      if (responseData.containsKey('value')) {
        final value = responseData['value'];
        if (value is int) {
          values[date] = value.toDouble();
        } else if (value is bool) {
          values[date] = value ? 1.0 : 0.0;
        }
      }
    }

    return values;
  }

  JournalEntry _mapToJournalEntry(JournalEntryEntity entity) {
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
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Tracker _mapToTracker(TrackerEntity entity) {
    final configJson = jsonDecode(entity.config) as Map<String, dynamic>;

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
