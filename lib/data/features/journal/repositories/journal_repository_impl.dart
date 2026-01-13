import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:taskly_bloc/data/id/id_generator.dart';
import 'package:taskly_bloc/data/infrastructure/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/mappers/journal_predicate_mapper.dart';
import 'package:taskly_bloc/data/repositories/mixins/query_builder_mixin.dart';
import 'package:taskly_bloc/domain/analytics/model/date_range.dart';
import 'package:taskly_bloc/domain/interfaces/journal_repository_contract.dart';
import 'package:taskly_bloc/domain/journal/model/journal_entry.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_definition.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_definition_choice.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_event.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_preference.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_state_day.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_state_entry.dart';
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

  BigInt? _bigIntOrNull(int? value) =>
      value == null ? null : BigInt.from(value);

  @override
  Stream<List<JournalEntry>> watchJournalEntries({DateRange? range}) {
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
  Stream<List<JournalEntry>> watchJournalEntriesByQuery(
    JournalQuery journalQuery,
  ) {
    final query = _database.select(_database.journalEntries);

    final whereExpr = _whereExpressionFromFilter(journalQuery.filter);
    if (whereExpr != null) {
      query.where((tbl) => whereExpr);
    }

    query.orderBy([(e) => OrderingTerm.desc(e.entryDate)]);

    return query.watch().map((rows) => rows.map(_mapToJournalEntry).toList());
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
    return result == null ? null : _mapToJournalEntry(result);
  }

  @override
  Future<JournalEntry?> getJournalEntryByDate({required DateTime date}) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final query = _database.select(_database.journalEntries)
      ..where((e) => e.entryDate.equals(dateOnly))
      ..orderBy([(e) => OrderingTerm.desc(e.entryTime)]);

    final result = await query.getSingleOrNull();
    return result == null ? null : _mapToJournalEntry(result);
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
    return results.map(_mapToJournalEntry).toList();
  }

  @override
  Future<void> saveJournalEntry(JournalEntry entry) async {
    await upsertJournalEntry(entry);
  }

  @override
  Future<String> upsertJournalEntry(JournalEntry entry) async {
    final entryId = entry.id.isEmpty ? _idGenerator.journalEntryId() : entry.id;

    await _database
        .into(_database.journalEntries)
        .insertOnConflictUpdate(
          JournalEntriesCompanion(
            id: Value(entryId),
            entryDate: Value(entry.entryDate),
            entryTime: Value(entry.entryTime),
            occurredAt: Value(entry.occurredAt),
            localDate: Value(entry.localDate),
            journalText: Value(entry.journalText),
            createdAt: Value(entry.createdAt),
            updatedAt: Value(entry.updatedAt),
            deletedAt: Value(entry.deletedAt),
          ),
        );

    return entryId;
  }

  @override
  Future<void> deleteJournalEntry(String id) async {
    await (_database.delete(
      _database.journalEntries,
    )..where((e) => e.id.equals(id))).go();
  }

  // === Trackers (OPT-A: event-log + projections) ===

  @override
  Stream<List<TrackerDefinition>> watchTrackerDefinitions() {
    final query = _database.select(_database.trackerDefinitions)
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]);

    return query.watch().map(
      (rows) => rows.map(_mapToTrackerDefinition).toList(),
    );
  }

  @override
  Stream<List<TrackerPreference>> watchTrackerPreferences() {
    final query = _database.select(_database.trackerPreferences)
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]);

    return query.watch().map(
      (rows) => rows.map(_mapToTrackerPreference).toList(),
    );
  }

  @override
  Stream<List<TrackerDefinitionChoice>> watchTrackerDefinitionChoices({
    required String trackerId,
  }) {
    final query = _database.select(_database.trackerDefinitionChoices)
      ..where((c) => c.trackerId.equals(trackerId))
      ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]);

    return query.watch().map(
      (rows) => rows.map(_mapToTrackerDefinitionChoice).toList(),
    );
  }

  @override
  Stream<List<TrackerStateDay>> watchTrackerStateDay({
    required DateRange range,
  }) {
    final query = _database.select(_database.trackerStateDay)
      ..where(
        (s) =>
            s.anchorDate.isBiggerOrEqualValue(range.start) &
            s.anchorDate.isSmallerOrEqualValue(range.end),
      );

    return query.watch().map(
      (rows) => rows.map(_mapToTrackerStateDay).toList(),
    );
  }

  @override
  Stream<List<TrackerStateEntry>> watchTrackerStateEntry({
    required DateRange range,
  }) {
    // tracker_state_entry does not include an anchor date; filter must be done
    // via joins if/when needed.
    final query = _database.select(_database.trackerStateEntry);
    return query.watch().map(
      (rows) => rows.map(_mapToTrackerStateEntry).toList(),
    );
  }

  @override
  Future<void> saveTrackerDefinition(TrackerDefinition definition) async {
    final id = definition.id.isEmpty
        ? _idGenerator.trackerDefinitionId(name: definition.name)
        : definition.id;

    await _database
        .into(_database.trackerDefinitions)
        .insertOnConflictUpdate(
          TrackerDefinitionsCompanion(
            id: Value(id),
            name: Value(definition.name),
            description: Value(definition.description),
            scope: Value(definition.scope),
            roles: Value(jsonEncode(definition.roles)),
            valueType: Value(definition.valueType),
            config: Value(jsonEncode(definition.config)),
            goal: Value(jsonEncode(definition.goal)),
            isActive: Value(definition.isActive),
            sortOrder: Value(definition.sortOrder),
            createdAt: Value(definition.createdAt),
            updatedAt: Value(definition.updatedAt),
            deletedAt: Value(definition.deletedAt),
            source: Value(definition.source),
            systemKey: Value(definition.systemKey),
            opKind: Value(definition.opKind),
            valueKind: Value(definition.valueKind),
            unitKind: Value(definition.unitKind),
            minInt: Value(_bigIntOrNull(definition.minInt)),
            maxInt: Value(_bigIntOrNull(definition.maxInt)),
            stepInt: Value(_bigIntOrNull(definition.stepInt)),
            linkedValueId: Value(definition.linkedValueId),
            isOutcome: Value(definition.isOutcome),
            isInsightEnabled: Value(definition.isInsightEnabled),
            higherIsBetter: Value(definition.higherIsBetter),
          ),
        );
  }

  @override
  Future<void> saveTrackerPreference(TrackerPreference preference) async {
    final id = preference.id.isEmpty
        ? _idGenerator.trackerPreferenceId(trackerId: preference.trackerId)
        : preference.id;

    await _database
        .into(_database.trackerPreferences)
        .insertOnConflictUpdate(
          TrackerPreferencesCompanion(
            id: Value(id),
            trackerId: Value(preference.trackerId),
            isActive: Value(preference.isActive),
            sortOrder: Value(preference.sortOrder),
            pinned: Value(preference.pinned),
            showInQuickAdd: Value(preference.showInQuickAdd),
            color: Value(preference.color),
            createdAt: Value(preference.createdAt),
            updatedAt: Value(preference.updatedAt),
          ),
        );
  }

  @override
  Future<void> appendTrackerEvent(TrackerEvent event) async {
    final id = event.id.isEmpty ? _idGenerator.trackerEventId() : event.id;

    String? value;
    if (event.value != null) {
      value = event.value is String
          ? event.value! as String
          : jsonEncode(event.value);
    }

    await _database
        .into(_database.trackerEvents)
        .insertOnConflictUpdate(
          TrackerEventsCompanion(
            id: Value(id),
            trackerId: Value(event.trackerId),
            anchorType: Value(event.anchorType),
            entryId: Value(event.entryId),
            anchorDate: Value(event.anchorDate),
            op: Value(event.op),
            value: Value(value),
            occurredAt: Value(event.occurredAt),
            recordedAt: Value(event.recordedAt),
          ),
        );
  }

  @override
  Stream<List<TrackerEvent>> watchTrackerEvents({
    DateRange? range,
    String? anchorType,
    String? entryId,
    DateTime? anchorDate,
    String? trackerId,
  }) {
    final query = _database.select(_database.trackerEvents);

    if (range != null) {
      query.where(
        (e) =>
            e.occurredAt.isBiggerOrEqualValue(range.start) &
            e.occurredAt.isSmallerOrEqualValue(range.end),
      );
    }
    if (anchorType != null) {
      query.where((e) => e.anchorType.equals(anchorType));
    }
    if (entryId != null) {
      query.where((e) => e.entryId.equals(entryId));
    }
    if (anchorDate != null) {
      query.where((e) => e.anchorDate.equals(anchorDate));
    }
    if (trackerId != null) {
      query.where((e) => e.trackerId.equals(trackerId));
    }

    query.orderBy([(e) => OrderingTerm.desc(e.occurredAt)]);

    return query.watch().map((rows) => rows.map(_mapToTrackerEvent).toList());
  }

  // === Analytics Helpers ===

  @override
  Future<Map<DateTime, double>> getDailyMoodAverages({
    required DateRange range,
  }) async {
    // Mood is now represented as tracker events (system trackers).
    return <DateTime, double>{};
  }

  @override
  Future<Map<DateTime, double>> getTrackerValues({
    required String trackerId,
    required DateRange range,
  }) async {
    // Tracker values should be read from projections (tracker_state_day / tracker_state_entry).
    return <DateTime, double>{};
  }

  JournalEntry _mapToJournalEntry(JournalEntryEntity row) {
    return JournalEntry(
      id: row.id,
      entryDate: row.entryDate,
      entryTime: row.entryTime,
      occurredAt: row.occurredAt,
      localDate: row.localDate,
      journalText: row.journalText,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }

  TrackerDefinition _mapToTrackerDefinition(TrackerDefinitionEntity row) {
    final roles = _tryDecodeJsonListOfStrings(row.roles) ?? const <String>[];
    final config = _tryDecodeJsonMap(row.config) ?? const <String, dynamic>{};
    final goal = _tryDecodeJsonMap(row.goal) ?? const <String, dynamic>{};

    return TrackerDefinition(
      id: row.id,
      userId: row.userId,
      name: row.name,
      description: row.description,
      scope: row.scope,
      roles: roles,
      valueType: row.valueType,
      config: config,
      goal: goal,
      isActive: row.isActive,
      sortOrder: row.sortOrder,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
      source: row.source,
      systemKey: row.systemKey,
      opKind: row.opKind,
      valueKind: row.valueKind,
      unitKind: row.unitKind,
      minInt: row.minInt?.toInt(),
      maxInt: row.maxInt?.toInt(),
      stepInt: row.stepInt?.toInt(),
      linkedValueId: row.linkedValueId,
      isOutcome: row.isOutcome,
      isInsightEnabled: row.isInsightEnabled,
      higherIsBetter: row.higherIsBetter,
    );
  }

  TrackerPreference _mapToTrackerPreference(TrackerPreferenceEntity row) {
    return TrackerPreference(
      id: row.id,
      userId: row.userId,
      trackerId: row.trackerId,
      isActive: row.isActive,
      sortOrder: row.sortOrder,
      pinned: row.pinned,
      showInQuickAdd: row.showInQuickAdd,
      color: row.color,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  TrackerDefinitionChoice _mapToTrackerDefinitionChoice(
    TrackerDefinitionChoiceEntity row,
  ) {
    return TrackerDefinitionChoice(
      id: row.id,
      userId: row.userId,
      trackerId: row.trackerId,
      choiceKey: row.choiceKey,
      label: row.label,
      sortOrder: row.sortOrder,
      isActive: row.isActive,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  TrackerEvent _mapToTrackerEvent(TrackerEventEntity row) {
    return TrackerEvent(
      id: row.id,
      userId: row.userId,
      trackerId: row.trackerId,
      anchorType: row.anchorType,
      entryId: row.entryId,
      anchorDate: row.anchorDate,
      op: row.op,
      value: _tryDecodeJsonValue(row.value),
      occurredAt: row.occurredAt,
      recordedAt: row.recordedAt,
    );
  }

  Object? _tryDecodeJsonValue(String? raw) {
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return raw;
    }
  }

  TrackerStateDay _mapToTrackerStateDay(TrackerStateDayEntity row) {
    return TrackerStateDay(
      id: row.id,
      userId: row.userId,
      anchorType: row.anchorType,
      anchorDate: row.anchorDate,
      trackerId: row.trackerId,
      value: _tryDecodeJsonAny(row.value),
      lastEventId: row.lastEventId,
      updatedAt: row.updatedAt,
    );
  }

  TrackerStateEntry _mapToTrackerStateEntry(TrackerStateEntryEntity row) {
    return TrackerStateEntry(
      id: row.id,
      userId: row.userId,
      entryId: row.entryId,
      trackerId: row.trackerId,
      value: _tryDecodeJsonAny(row.value),
      lastEventId: row.lastEventId,
      updatedAt: row.updatedAt,
    );
  }

  Map<String, dynamic>? _tryDecodeJsonMap(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(value);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  List<String>? _tryDecodeJsonListOfStrings(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(value);
      if (decoded is! List) return null;
      return decoded.whereType<String>().toList(growable: false);
    } catch (_) {
      return null;
    }
  }

  Object? _tryDecodeJsonAny(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    try {
      return jsonDecode(value);
    } catch (_) {
      return value;
    }
  }
}
