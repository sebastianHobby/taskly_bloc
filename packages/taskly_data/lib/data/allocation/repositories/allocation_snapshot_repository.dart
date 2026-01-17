import 'package:drift/drift.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_data/data/infrastructure/drift/converters/date_only_string_converter.dart';
import 'package:taskly_data/data/infrastructure/drift/drift_database.dart'
    as db;
import 'package:taskly_domain/taskly_domain.dart';

class AllocationSnapshotRepository
    implements AllocationSnapshotRepositoryContract {
  AllocationSnapshotRepository({required db.AppDatabase db}) : _db = db;

  final db.AppDatabase _db;

  @override
  Future<AllocationSnapshot?> getLatestForUtcDay(DateTime dayUtc) async {
    final normalizedDayUtc = dateOnly(dayUtc.toUtc());
    final snapshotRow = await _getLatestSnapshotRow(normalizedDayUtc);
    if (snapshotRow == null) return null;

    final entries = await (_db.select(
      _db.allocationSnapshotEntries,
    )..where((t) => t.snapshotId.equals(snapshotRow.id))).get();

    return _toDomain(snapshotRow, entries);
  }

  @override
  Stream<AllocationSnapshot?> watchLatestForUtcDay(DateTime dayUtc) {
    final normalizedDayUtc = dateOnly(dayUtc.toUtc());
    final snapshotQuery =
        (_db.select(_db.allocationSnapshots)
              ..where((t) => t.dayUtc.equalsValue(normalizedDayUtc))
              ..orderBy([(t) => OrderingTerm.desc(t.version)])
              ..limit(1))
            .watchSingleOrNull();

    return snapshotQuery.switchMap((snapshotRow) {
      if (snapshotRow == null) return Stream.value(null);

      final entriesStream = (_db.select(
        _db.allocationSnapshotEntries,
      )..where((t) => t.snapshotId.equals(snapshotRow.id))).watch();

      return entriesStream.map((entries) => _toDomain(snapshotRow, entries));
    });
  }

  @override
  Future<List<AllocationSnapshotTaskRef>> getLatestTaskRefsForUtcDay(
    DateTime dayUtc,
  ) async {
    final snapshot = await getLatestForUtcDay(dayUtc);
    return _taskRefsFromSnapshot(snapshot);
  }

  @override
  Stream<List<AllocationSnapshotTaskRef>> watchLatestTaskRefsForUtcDay(
    DateTime dayUtc,
  ) {
    return watchLatestForUtcDay(dayUtc).map(_taskRefsFromSnapshot);
  }

  @override
  Future<void> persistAllocatedForUtcDay({
    required DateTime dayUtc,
    required int capAtGeneration,
    required int candidatePoolCountAtGeneration,
    required List<AllocationSnapshotEntryInput> allocated,
  }) async {
    final normalizedDayUtc = dateOnly(dayUtc.toUtc());
    final nowUtc = DateTime.now().toUtc();

    final nextMembership = allocated
        .map((e) => _membershipKey(e.entity.type, e.entity.id))
        .toSet();

    await _db.transaction(() async {
      final latest = await _getLatestSnapshotRow(normalizedDayUtc);
      if (latest != null) {
        final existingEntries = await (_db.select(
          _db.allocationSnapshotEntries,
        )..where((t) => t.snapshotId.equals(latest.id))).get();

        final existingMembership = existingEntries
            .map((e) => _membershipKey(_parseType(e.entityType), e.entityId))
            .toSet();

        final metadataUnchanged =
            latest.capAtGeneration == capAtGeneration &&
            latest.candidatePoolCountAtGeneration ==
                candidatePoolCountAtGeneration;

        if (_setEquals(existingMembership, nextMembership) &&
            metadataUnchanged) {
          return;
        }
      }

      final nextVersion = (latest?.version ?? 0) + 1;

      final insertedSnapshot = await _db
          .into(_db.allocationSnapshots)
          .insertReturning(
            db.AllocationSnapshotsCompanion.insert(
              dayUtc: normalizedDayUtc,
              version: Value(nextVersion),
              capAtGeneration: capAtGeneration,
              candidatePoolCountAtGeneration: candidatePoolCountAtGeneration,
              createdAt: Value(nowUtc),
              updatedAt: Value(nowUtc),
            ),
          );

      final entryCompanions = allocated
          .map(
            (e) => db.AllocationSnapshotEntriesCompanion.insert(
              snapshotId: insertedSnapshot.id,
              entityType: e.entity.type.name,
              entityId: e.entity.id,
              projectId: Value(e.projectId),
              qualifyingValueId: Value(e.qualifyingValueId),
              effectivePrimaryValueId: Value(e.effectivePrimaryValueId),
              allocationScore: Value(e.allocationScore),
              createdAt: Value(nowUtc),
              updatedAt: Value(nowUtc),
            ),
          )
          .toList();

      await _db.batch((b) {
        b.insertAll(_db.allocationSnapshotEntries, entryCompanions);
      });

      talker.repositoryLog(
        'AllocationSnapshot',
        'Persisted allocation snapshot dayUtc=$normalizedDayUtc '
            'version=$nextVersion entries=${entryCompanions.length}',
      );
    });
  }

  @override
  Future<AllocationProjectHistoryWindow> getProjectHistoryWindow({
    required DateTime windowEndDayUtc,
    required int windowDays,
  }) async {
    final normalizedEnd = dateOnly(windowEndDayUtc.toUtc());
    final normalizedStart = dateOnly(
      normalizedEnd.subtract(Duration(days: windowDays - 1)),
    );

    final startSql = dateOnlyStringConverter.toSql(normalizedStart);
    final endSql = dateOnlyStringConverter.toSql(normalizedEnd);

    final snapshotRows =
        await (_db.select(_db.allocationSnapshots)
              ..where(
                (t) =>
                    t.dayUtc.isBiggerOrEqualValue(startSql) &
                    t.dayUtc.isSmallerOrEqualValue(endSql),
              )
              ..orderBy([
                (t) => OrderingTerm.desc(t.dayUtc),
                (t) => OrderingTerm.desc(t.version),
              ]))
            .get();

    // Pick latest snapshot per day (highest version).
    final latestByDay = <DateTime, db.AllocationSnapshot>{};
    for (final row in snapshotRows) {
      latestByDay.putIfAbsent(row.dayUtc, () => row);
    }

    final snapshotDaysUtc = latestByDay.keys.toSet();
    final snapshotIds = latestByDay.values.map((s) => s.id).toList();

    if (snapshotIds.isEmpty) {
      return AllocationProjectHistoryWindow(
        windowStartDayUtc: normalizedStart,
        windowEndDayUtc: normalizedEnd,
        snapshotDaysUtc: const <DateTime>{},
        lastAllocatedDayByProjectId: const <String, DateTime>{},
      );
    }

    final entriesWithSnapshot =
        _db.select(_db.allocationSnapshotEntries).join([
            innerJoin(
              _db.allocationSnapshots,
              _db.allocationSnapshots.id.equalsExp(
                _db.allocationSnapshotEntries.snapshotId,
              ),
            ),
          ])
          ..where(_db.allocationSnapshotEntries.snapshotId.isIn(snapshotIds))
          ..where(_db.allocationSnapshotEntries.projectId.isNotNull());

    final rows = await entriesWithSnapshot.get();
    final lastAllocatedDayByProjectId = <String, DateTime>{};

    for (final row in rows) {
      final entry = row.readTable(_db.allocationSnapshotEntries);
      final snapshot = row.readTable(_db.allocationSnapshots);
      final projectId = entry.projectId;
      if (projectId == null) continue;

      final day = snapshot.dayUtc;
      final existing = lastAllocatedDayByProjectId[projectId];
      if (existing == null || day.isAfter(existing)) {
        lastAllocatedDayByProjectId[projectId] = day;
      }
    }

    return AllocationProjectHistoryWindow(
      windowStartDayUtc: normalizedStart,
      windowEndDayUtc: normalizedEnd,
      snapshotDaysUtc: snapshotDaysUtc,
      lastAllocatedDayByProjectId: lastAllocatedDayByProjectId,
    );
  }

  @override
  Future<void> deleteAll() async {
    await _db.transaction(() async {
      await _db.delete(_db.allocationSnapshotEntries).go();
      await _db.delete(_db.allocationSnapshots).go();
    });
  }

  Future<db.AllocationSnapshot?> _getLatestSnapshotRow(DateTime dayUtc) {
    return (_db.select(_db.allocationSnapshots)
          ..where((t) => t.dayUtc.equalsValue(dayUtc))
          ..orderBy([(t) => OrderingTerm.desc(t.version)])
          ..limit(1))
        .getSingleOrNull();
  }

  AllocationSnapshot _toDomain(
    db.AllocationSnapshot snapshot,
    List<db.AllocationSnapshotEntry> entries,
  ) {
    return AllocationSnapshot(
      id: snapshot.id,
      dayUtc: snapshot.dayUtc,
      version: snapshot.version,
      capAtGeneration: snapshot.capAtGeneration,
      candidatePoolCountAtGeneration: snapshot.candidatePoolCountAtGeneration,
      allocated: entries
          .map(
            (e) => AllocationSnapshotEntryInput(
              entity: AllocationEntityRef(
                type: _parseType(e.entityType),
                id: e.entityId,
              ),
              projectId: e.projectId,
              qualifyingValueId: e.qualifyingValueId,
              effectivePrimaryValueId: e.effectivePrimaryValueId,
              allocationScore: e.allocationScore,
            ),
          )
          .toList(),
    );
  }

  AllocationSnapshotEntityType _parseType(String raw) {
    return AllocationSnapshotEntityType.values.firstWhere(
      (t) => t.name == raw,
      orElse: () => AllocationSnapshotEntityType.task,
    );
  }

  List<AllocationSnapshotTaskRef> _taskRefsFromSnapshot(
    AllocationSnapshot? snapshot,
  ) {
    if (snapshot == null) return const <AllocationSnapshotTaskRef>[];

    final taskEntries = snapshot.allocated
        .where((e) => e.entity.type == AllocationSnapshotEntityType.task)
        .toList(growable: false);

    final refs = <AllocationSnapshotTaskRef>[];
    for (var i = 0; i < taskEntries.length; i++) {
      final entry = taskEntries[i];
      refs.add(
        AllocationSnapshotTaskRef(
          taskId: entry.entity.id,
          allocationRank: i,
          projectId: entry.projectId,
          qualifyingValueId: entry.qualifyingValueId,
          effectivePrimaryValueId: entry.effectivePrimaryValueId,
          allocationScore: entry.allocationScore,
        ),
      );
    }
    return refs;
  }

  String _membershipKey(AllocationSnapshotEntityType type, String id) =>
      '${type.name}:$id';

  bool _setEquals(Set<String> a, Set<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final v in a) {
      if (!b.contains(v)) return false;
    }
    return true;
  }
}
