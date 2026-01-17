import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/allocation/repositories/allocation_snapshot_repository.dart';

import '../../helpers/test_db.dart';

import 'package:taskly_domain/taskly_domain.dart';
void main() {
  group('AllocationSnapshotRepository', () {
    test('persists first snapshot with version 1', () async {
      final db = createTestDb();
      addTearDown(() => closeTestDb(db));

      final repo = AllocationSnapshotRepository(db: db);
      final dayUtc = dateOnly(DateTime.now().toUtc());

      await repo.persistAllocatedForUtcDay(
        dayUtc: dayUtc,
        capAtGeneration: 3,
        candidatePoolCountAtGeneration: 2,
        allocated: const [
          AllocationSnapshotEntryInput(
            entity: AllocationEntityRef(
              type: AllocationSnapshotEntityType.task,
              id: 't1',
            ),
            qualifyingValueId: 'v1',
            allocationScore: 1,
          ),
          AllocationSnapshotEntryInput(
            entity: AllocationEntityRef(
              type: AllocationSnapshotEntityType.task,
              id: 't2',
            ),
            qualifyingValueId: 'v2',
            allocationScore: 2,
          ),
        ],
      );

      final snap = await repo.getLatestForUtcDay(dayUtc);
      expect(snap, isA<AllocationSnapshot>());
      expect(snap!.version, 1);
      expect(snap.capAtGeneration, 3);
      expect(snap.candidatePoolCountAtGeneration, 2);
      expect(snap.allocated.length, 2);
    });

    test('does not bump version when membership unchanged', () async {
      final db = createTestDb();
      addTearDown(() => closeTestDb(db));

      final repo = AllocationSnapshotRepository(db: db);
      final dayUtc = dateOnly(DateTime.now().toUtc());

      await repo.persistAllocatedForUtcDay(
        dayUtc: dayUtc,
        capAtGeneration: 3,
        candidatePoolCountAtGeneration: 1,
        allocated: const [
          AllocationSnapshotEntryInput(
            entity: AllocationEntityRef(
              type: AllocationSnapshotEntityType.task,
              id: 't1',
            ),
            allocationScore: 1,
          ),
        ],
      );

      await repo.persistAllocatedForUtcDay(
        dayUtc: dayUtc,
        capAtGeneration: 3,
        candidatePoolCountAtGeneration: 1,
        allocated: const [
          // Same membership, different score.
          AllocationSnapshotEntryInput(
            entity: AllocationEntityRef(
              type: AllocationSnapshotEntityType.task,
              id: 't1',
            ),
            allocationScore: 999,
          ),
        ],
      );

      final snapshots = await (db.select(
        db.allocationSnapshots,
      )..where((t) => t.dayUtc.equalsValue(dayUtc))).get();

      expect(snapshots, hasLength(1));
      expect(snapshots.single.version, 1);
    });

    test('bumps version when membership changes', () async {
      final db = createTestDb();
      addTearDown(() => closeTestDb(db));

      final repo = AllocationSnapshotRepository(db: db);
      final dayUtc = dateOnly(DateTime.now().toUtc());

      await repo.persistAllocatedForUtcDay(
        dayUtc: dayUtc,
        capAtGeneration: 3,
        candidatePoolCountAtGeneration: 1,
        allocated: const [
          AllocationSnapshotEntryInput(
            entity: AllocationEntityRef(
              type: AllocationSnapshotEntityType.task,
              id: 't1',
            ),
          ),
        ],
      );

      await repo.persistAllocatedForUtcDay(
        dayUtc: dayUtc,
        capAtGeneration: 3,
        candidatePoolCountAtGeneration: 2,
        allocated: const [
          AllocationSnapshotEntryInput(
            entity: AllocationEntityRef(
              type: AllocationSnapshotEntityType.task,
              id: 't1',
            ),
          ),
          AllocationSnapshotEntryInput(
            entity: AllocationEntityRef(
              type: AllocationSnapshotEntityType.task,
              id: 't2',
            ),
          ),
        ],
      );

      final snapshots =
          await (db.select(db.allocationSnapshots)
                ..where((t) => t.dayUtc.equalsValue(dayUtc))
                ..orderBy([(t) => OrderingTerm.asc(t.version)]))
              .get();

      expect(snapshots, hasLength(2));
      expect(snapshots.first.version, 1);
      expect(snapshots.last.version, 2);
    });
  });
}
