import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:taskly_data/src/errors/failure_guard.dart';
import 'package:taskly_data/src/id/id_generator.dart';
import 'package:taskly_data/src/infrastructure/drift/drift_database.dart';
import 'package:taskly_data/src/repositories/mappers/journal_predicate_mapper.dart';
import 'package:taskly_data/src/repositories/mixins/query_builder_mixin.dart';
import 'package:taskly_data/src/repositories/query_stream_cache.dart';
import 'package:taskly_data/src/repositories/repository_exceptions.dart';
import 'package:taskly_data/src/repositories/stream_cache_policy.dart';
import 'package:taskly_domain/taskly_domain.dart' hide Value;

class JournalRepositoryImpl
    with QueryBuilderMixin
    implements JournalRepositoryContract {
  JournalRepositoryImpl(
    this._database,
    this._idGenerator, {
    this.clock = systemClock,
  }) : _predicateMapper = JournalPredicateMapper(clock: clock);

  final AppDatabase _database;
  final IdGenerator _idGenerator;

  @override
  final Clock clock;

  final JournalPredicateMapper _predicateMapper;
  final QueryStreamCache<JournalQuery, List<JournalEntry>>
  _sharedWatchAllCache = QueryStreamCache(maxEntries: 16);

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

    _applyJournalOrdering(query);

    return query.watch().map((rows) => rows.map(_mapToJournalEntry).toList());
  }

  @override
  Stream<List<JournalEntry>> watchJournalEntriesByQuery(
    JournalQuery journalQuery,
  ) {
    Stream<List<JournalEntry>> build() {
      final query = _database.select(_database.journalEntries);

      final whereExpr = _whereExpressionFromFilter(journalQuery.filter);
      if (whereExpr != null) {
        query.where((tbl) => whereExpr);
      }

      _applyJournalOrdering(query);

      return query.watch().map((rows) => rows.map(_mapToJournalEntry).toList());
    }

    if (!shouldCacheByDefault(hasDateFilter: journalQuery.hasDateFilter)) {
      return build();
    }

    return _sharedWatchAllCache.getOrCreate(journalQuery, build);
  }

  Expression<bool>? _whereExpressionFromFilter(
    QueryFilter<JournalPredicate> filter,
  ) {
    return whereExpressionFromFilter(
      filter: filter,
      predicateToExpression: (p) =>
          _predicateMapper.predicateToExpression(p, _database.journalEntries),
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
  Future<List<JournalEntry>> getJournalEntriesByDate({
    required DateTime date,
  }) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final query = _database.select(_database.journalEntries)
      ..where((e) => e.entryDate.equals(dateOnly))
      ..orderBy([
        (e) => OrderingTerm.desc(e.entryTime),
        (e) => OrderingTerm.desc(e.createdAt),
      ]);

    final results = await query.get();
    return results.map(_mapToJournalEntry).toList();
  }

  @override
  Future<String> createJournalEntry(
    JournalEntry entry, {
    OperationContext? context,
  }) async {
    return FailureGuard.run(
      () async {
        final entryId = entry.id.trim().isEmpty
            ? _idGenerator.journalEntryId()
            : entry.id;

        await _database
            .into(_database.journalEntries)
            .insert(
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
              mode: InsertMode.insertOrAbort,
            );

        return entryId;
      },
      area: 'data.journal',
      opName: 'createJournalEntry',
      context: context,
    );
  }

  @override
  Future<void> updateJournalEntry(
    JournalEntry entry, {
    OperationContext? context,
  }) async {
    return FailureGuard.run(
      () async {
        final entryId = entry.id.trim();
        if (entryId.isEmpty) {
          throw RepositoryException(
            'updateJournalEntry requires a non-empty entry id',
          );
        }

        final updated =
            await (_database.update(
              _database.journalEntries,
            )..where((e) => e.id.equals(entryId))).write(
              JournalEntriesCompanion(
                entryDate: Value(entry.entryDate),
                entryTime: Value(entry.entryTime),
                occurredAt: Value(entry.occurredAt),
                localDate: Value(entry.localDate),
                journalText: Value(entry.journalText),
                updatedAt: Value(entry.updatedAt),
                deletedAt: Value(entry.deletedAt),
                createdAt: const Value<DateTime>.absent(),
              ),
            );

        if (updated == 0) {
          throw RepositoryNotFoundException(
            'No journal entry found to update id=$entryId',
          );
        }
      },
      area: 'data.journal',
      opName: 'updateJournalEntry',
      context: context,
    );
  }

  @override
  Future<void> deleteJournalEntry(
    String id, {
    OperationContext? context,
  }) async {
    return FailureGuard.run(
      () async {
        await (_database.delete(
          _database.journalEntries,
        )..where((e) => e.id.equals(id))).go();
      },
      area: 'data.journal',
      opName: 'deleteJournalEntry',
      context: context,
    );
  }

  void _applyJournalOrdering(
    SimpleSelectStatement<$JournalEntriesTable, JournalEntryEntity> query,
  ) {
    query.orderBy([
      (e) => OrderingTerm.desc(e.entryDate),
      (e) => OrderingTerm.desc(e.entryTime),
      (e) => OrderingTerm.desc(e.createdAt),
    ]);
  }

  // === Trackers (OPT-A: event-log + projections) ===

  @override
  Stream<List<TrackerGroup>> watchTrackerGroups() {
    final query = _database.select(_database.trackerGroups)
      ..orderBy([(g) => OrderingTerm.asc(g.sortOrder)]);

    return query.watch().map((rows) => rows.map(_mapToTrackerGroup).toList());
  }

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
  Future<void> saveTrackerDefinition(
    TrackerDefinition definition, {
    OperationContext? context,
  }) async {
    return FailureGuard.run(
      () async {
        final id = definition.id.isEmpty
            ? _idGenerator.trackerDefinitionId(name: definition.name)
            : definition.id;

        final updated =
            await (_database.update(
              _database.trackerDefinitions,
            )..where((t) => t.id.equals(id))).write(
              TrackerDefinitionsCompanion(
                name: Value(definition.name),
                description: Value(definition.description),
                groupId: Value(definition.groupId),
                scope: Value(definition.scope),
                roles: Value(jsonEncode(definition.roles)),
                valueType: Value(definition.valueType),
                config: Value(jsonEncode(definition.config)),
                goal: Value(jsonEncode(definition.goal)),
                isActive: Value(definition.isActive),
                sortOrder: Value(definition.sortOrder),
                updatedAt: Value(definition.updatedAt),
                deletedAt: Value(definition.deletedAt),
                source: Value(definition.source),
                systemKey: Value(definition.systemKey),
                opKind: Value(definition.opKind),
                valueKind: Value(definition.valueKind),
                unitKind: Value(definition.unitKind),
                minInt: Value(definition.minInt),
                maxInt: Value(definition.maxInt),
                stepInt: Value(definition.stepInt),
                linkedValueId: Value(definition.linkedValueId),
                isOutcome: Value(definition.isOutcome),
                isInsightEnabled: Value(definition.isInsightEnabled),
                higherIsBetter: Value(definition.higherIsBetter),
                createdAt: const Value<DateTime>.absent(),
              ),
            );

        if (updated == 0) {
          final existing =
              await (_database.selectOnly(_database.trackerDefinitions)
                    ..addColumns([_database.trackerDefinitions.id])
                    ..where(_database.trackerDefinitions.id.equals(id)))
                  .getSingleOrNull();
          if (existing == null) {
            await _database
                .into(_database.trackerDefinitions)
                .insert(
                  TrackerDefinitionsCompanion(
                    id: Value(id),
                    name: Value(definition.name),
                    description: Value(definition.description),
                    groupId: Value(definition.groupId),
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
                    minInt: Value(definition.minInt),
                    maxInt: Value(definition.maxInt),
                    stepInt: Value(definition.stepInt),
                    linkedValueId: Value(definition.linkedValueId),
                    isOutcome: Value(definition.isOutcome),
                    isInsightEnabled: Value(definition.isInsightEnabled),
                    higherIsBetter: Value(definition.higherIsBetter),
                  ),
                  mode: InsertMode.insertOrAbort,
                );
          }
        }
      },
      area: 'data.journal',
      opName: 'saveTrackerDefinition',
      context: context,
    );
  }

  @override
  Future<void> saveTrackerGroup(
    TrackerGroup group, {
    OperationContext? context,
  }) async {
    return FailureGuard.run(
      () async {
        final id = await _resolveTrackerGroupIdForSave(group);

        final updated =
            await (_database.update(
              _database.trackerGroups,
            )..where((g) => g.id.equals(id))).write(
              TrackerGroupsCompanion(
                name: Value(group.name),
                sortOrder: Value(group.sortOrder),
                isActive: Value(group.isActive),
                updatedAt: Value(group.updatedAt),
                createdAt: const Value<DateTime>.absent(),
              ),
            );

        if (updated == 0) {
          final existing =
              await (_database.selectOnly(_database.trackerGroups)
                    ..addColumns([_database.trackerGroups.id])
                    ..where(_database.trackerGroups.id.equals(id)))
                  .getSingleOrNull();
          if (existing == null) {
            await _database
                .into(_database.trackerGroups)
                .insert(
                  TrackerGroupsCompanion(
                    id: Value(id),
                    name: Value(group.name),
                    sortOrder: Value(group.sortOrder),
                    isActive: Value(group.isActive),
                    createdAt: Value(group.createdAt),
                    updatedAt: Value(group.updatedAt),
                  ),
                  mode: InsertMode.insertOrAbort,
                );
          }
        }
      },
      area: 'data.journal',
      opName: 'saveTrackerGroup',
      context: context,
    );
  }

  Future<String> _resolveTrackerGroupIdForSave(TrackerGroup group) async {
    if (group.id.isNotEmpty) return group.id;

    final normalizedName = _normalizeTrackerGroupName(group.name);
    final existingId = await _findTrackerGroupIdByNormalizedName(
      normalizedName,
    );
    if (existingId != null) return existingId;

    return _idGenerator.trackerGroupId();
  }

  Future<String?> _findTrackerGroupIdByNormalizedName(
    String normalizedName,
  ) async {
    if (normalizedName.isEmpty) return null;

    final rows = await (_database.select(
      _database.trackerGroups,
    )..orderBy([(g) => OrderingTerm.desc(g.updatedAt)])).get();

    for (final row in rows) {
      if (_normalizeTrackerGroupName(row.name) == normalizedName) {
        return row.id;
      }
    }

    return null;
  }

  String _normalizeTrackerGroupName(String raw) {
    return raw.trim().toLowerCase();
  }

  @override
  Future<void> deleteTrackerGroup(
    String groupId, {
    OperationContext? context,
  }) async {
    return FailureGuard.run(
      () async {
        final trimmed = groupId.trim();
        if (trimmed.isEmpty) return;

        final nowUtc = clock.nowUtc();

        await (_database.update(
          _database.trackerGroups,
        )..where((g) => g.id.equals(trimmed))).write(
          TrackerGroupsCompanion(
            isActive: const Value(false),
            updatedAt: Value(nowUtc),
          ),
        );
      },
      area: 'data.journal',
      opName: 'deleteTrackerGroup',
      context: context,
    );
  }

  @override
  Future<void> saveTrackerPreference(
    TrackerPreference preference, {
    OperationContext? context,
  }) async {
    return FailureGuard.run(
      () async {
        final id = preference.id.isEmpty
            ? _idGenerator.trackerPreferenceId(trackerId: preference.trackerId)
            : preference.id;

        final updated =
            await (_database.update(
              _database.trackerPreferences,
            )..where((t) => t.id.equals(id))).write(
              TrackerPreferencesCompanion(
                trackerId: Value(preference.trackerId),
                isActive: Value(preference.isActive),
                sortOrder: Value(preference.sortOrder),
                pinned: Value(preference.pinned),
                showInQuickAdd: Value(preference.showInQuickAdd),
                color: Value(preference.color),
                updatedAt: Value(preference.updatedAt),
                createdAt: const Value<DateTime>.absent(),
              ),
            );

        if (updated == 0) {
          final existing =
              await (_database.selectOnly(_database.trackerPreferences)
                    ..addColumns([_database.trackerPreferences.id])
                    ..where(_database.trackerPreferences.id.equals(id)))
                  .getSingleOrNull();
          if (existing == null) {
            await _database
                .into(_database.trackerPreferences)
                .insert(
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
                  mode: InsertMode.insertOrAbort,
                );
          }
        }
      },
      area: 'data.journal',
      opName: 'saveTrackerPreference',
      context: context,
    );
  }

  @override
  Future<void> saveTrackerDefinitionChoice(
    TrackerDefinitionChoice choice, {
    OperationContext? context,
  }) async {
    return FailureGuard.run(
      () async {
        final id = choice.id.isEmpty
            ? _idGenerator.trackerDefinitionChoiceId(
                trackerId: choice.trackerId,
                choiceKey: choice.choiceKey,
              )
            : choice.id;

        final updated =
            await (_database.update(
              _database.trackerDefinitionChoices,
            )..where((c) => c.id.equals(id))).write(
              TrackerDefinitionChoicesCompanion(
                trackerId: Value(choice.trackerId),
                choiceKey: Value(choice.choiceKey),
                label: Value(choice.label),
                sortOrder: Value(choice.sortOrder),
                isActive: Value(choice.isActive),
                updatedAt: Value(choice.updatedAt),
                createdAt: const Value<DateTime>.absent(),
              ),
            );

        if (updated == 0) {
          final existing =
              await (_database.selectOnly(_database.trackerDefinitionChoices)
                    ..addColumns([_database.trackerDefinitionChoices.id])
                    ..where(_database.trackerDefinitionChoices.id.equals(id)))
                  .getSingleOrNull();
          if (existing == null) {
            await _database
                .into(_database.trackerDefinitionChoices)
                .insert(
                  TrackerDefinitionChoicesCompanion(
                    id: Value(id),
                    trackerId: Value(choice.trackerId),
                    choiceKey: Value(choice.choiceKey),
                    label: Value(choice.label),
                    sortOrder: Value(choice.sortOrder),
                    isActive: Value(choice.isActive),
                    createdAt: Value(choice.createdAt),
                    updatedAt: Value(choice.updatedAt),
                  ),
                  mode: InsertMode.insertOrAbort,
                );
          }
        }
      },
      area: 'data.journal',
      opName: 'saveTrackerDefinitionChoice',
      context: context,
    );
  }

  @override
  Future<void> appendTrackerEvent(
    TrackerEvent event, {
    OperationContext? context,
  }) async {
    return FailureGuard.run(
      () async {
        final id = event.id.isEmpty ? _idGenerator.trackerEventId() : event.id;

        String? value;
        if (event.value != null) {
          value = event.value is String
              ? event.value! as String
              : jsonEncode(event.value);
        }

        // Events are append-only; duplicate inserts are safe to ignore.
        await _database
            .into(_database.trackerEvents)
            .insert(
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
              mode: InsertMode.insertOrIgnore,
            );
      },
      area: 'data.journal',
      opName: 'appendTrackerEvent',
      context: context,
    );
  }

  @override
  Future<void> deleteTrackerAndData(
    String trackerId, {
    OperationContext? context,
  }) async {
    return FailureGuard.run(
      () async {
        final trimmed = trackerId.trim();
        if (trimmed.isEmpty) return;

        final nowUtc = clock.nowUtc();

        await _database.transaction(() async {
          // Soft delete the definition row (keeps it for sync/auditing).
          await (_database.update(
            _database.trackerDefinitions,
          )..where((t) => t.id.equals(trimmed))).write(
            TrackerDefinitionsCompanion(
              isActive: const Value(false),
              deletedAt: Value(nowUtc),
              updatedAt: Value(nowUtc),
            ),
          );

          // Purge local rows that would otherwise keep showing up in UI/analytics.
          await (_database.delete(
            _database.trackerPreferences,
          )..where((p) => p.trackerId.equals(trimmed))).go();

          await (_database.delete(
            _database.trackerDefinitionChoices,
          )..where((c) => c.trackerId.equals(trimmed))).go();

          await (_database.delete(
            _database.trackerEvents,
          )..where((e) => e.trackerId.equals(trimmed))).go();

          await (_database.delete(
            _database.trackerStateDay,
          )..where((s) => s.trackerId.equals(trimmed))).go();

          await (_database.delete(
            _database.trackerStateEntry,
          )..where((s) => s.trackerId.equals(trimmed))).go();
        });
      },
      area: 'data.journal',
      opName: 'deleteTrackerAndData',
      context: context,
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
    final moodTrackerId = await _getSystemTrackerId(systemKey: 'mood');
    if (moodTrackerId == null) return <DateTime, double>{};

    final events =
        await (_database.select(_database.trackerEvents)
              ..where((e) => e.trackerId.equals(moodTrackerId))
              ..where((e) => e.anchorType.equals('entry'))
              ..where(
                (e) =>
                    e.occurredAt.isBiggerOrEqualValue(range.start) &
                    e.occurredAt.isSmallerOrEqualValue(range.end),
              ))
            .get();

    final valuesByDay = <DateTime, List<double>>{};

    for (final e in events) {
      final decoded = _decodeTrackerValue(e.value);
      final asNumber = switch (decoded) {
        final int v => v.toDouble(),
        final double v => v,
        _ => null,
      };
      if (asNumber == null) continue;

      final day = dateOnly(e.occurredAt.toUtc());
      (valuesByDay[day] ??= <double>[]).add(asNumber);
    }

    final averages = <DateTime, double>{};
    for (final entry in valuesByDay.entries) {
      final values = entry.value;
      if (values.isEmpty) continue;
      final sum = values.fold<double>(0, (a, b) => a + b);
      averages[entry.key] = sum / values.length;
    }

    return averages;
  }

  @override
  Future<Map<DateTime, double>> getTrackerValues({
    required String trackerId,
    required DateRange range,
  }) async {
    final trimmed = trackerId.trim();
    if (trimmed.isEmpty) return <DateTime, double>{};

    final events =
        await (_database.select(_database.trackerEvents)
              ..where((e) => e.trackerId.equals(trimmed))
              ..where((e) => e.anchorType.equals('entry'))
              ..where(
                (e) =>
                    e.occurredAt.isBiggerOrEqualValue(range.start) &
                    e.occurredAt.isSmallerOrEqualValue(range.end),
              ))
            .get();

    // Aggregate by UTC day.
    final boolValuesByDay = <DateTime, List<bool>>{};
    final numValuesByDay = <DateTime, List<double>>{};

    for (final e in events) {
      final decoded = _decodeTrackerValue(e.value);
      final day = dateOnly(e.occurredAt.toUtc());

      if (decoded is bool) {
        (boolValuesByDay[day] ??= <bool>[]).add(decoded);
        continue;
      }

      final asNumber = switch (decoded) {
        final int v => v.toDouble(),
        final double v => v,
        _ => null,
      };
      if (asNumber == null) continue;
      (numValuesByDay[day] ??= <double>[]).add(asNumber);
    }

    final out = <DateTime, double>{};

    // For boolean trackers, treat a day as 1 if any event is true.
    for (final entry in boolValuesByDay.entries) {
      final anyTrue = entry.value.any((v) => v);
      out[entry.key] = anyTrue ? 1.0 : 0.0;
    }

    // For numeric trackers, average multiple events per day.
    for (final entry in numValuesByDay.entries) {
      final values = entry.value;
      if (values.isEmpty) continue;
      final sum = values.fold<double>(0, (a, b) => a + b);
      out[entry.key] = sum / values.length;
    }

    return out;
  }

  Future<String?> _getSystemTrackerId({required String systemKey}) async {
    final rows = await (_database.select(
      _database.trackerDefinitions,
    )..where((t) => t.systemKey.equals(systemKey))).get();

    if (rows.isEmpty) return null;
    return rows.first.id;
  }

  Object? _decodeTrackerValue(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    try {
      return jsonDecode(trimmed);
    } catch (_) {
      // Best-effort fallback for legacy/plain values.
      final asInt = int.tryParse(trimmed);
      if (asInt != null) return asInt;
      final asDouble = double.tryParse(trimmed);
      if (asDouble != null) return asDouble;
      if (trimmed.toLowerCase() == 'true') return true;
      if (trimmed.toLowerCase() == 'false') return false;
      return trimmed;
    }
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

  TrackerGroup _mapToTrackerGroup(TrackerGroupEntity row) {
    return TrackerGroup(
      id: row.id,
      userId: row.userId,
      name: row.name,
      sortOrder: row.sortOrder,
      isActive: row.isActive,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
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
      groupId: row.groupId,
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
      minInt: row.minInt,
      maxInt: row.maxInt,
      stepInt: row.stepInt,
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
