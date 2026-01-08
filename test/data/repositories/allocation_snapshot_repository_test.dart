import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/core/utils/date_only.dart';
import 'package:taskly_bloc/data/repositories/allocation_snapshot_repository.dart';
import 'package:taskly_bloc/domain/models/allocation/allocation_snapshot.dart';

import '../../helpers/test_db.dart';

void main() {
  group('AllocationSnapshotRepository', () {
    test('persists first snapshot with version 1', () async {
      final db = createTestDb();
      addTearDown(() => closeTestDb(db));

      final repo = AllocationSnapshotRepository(db: db);
      final dayUtc = dateOnly(DateTime.now().toUtc());

      await repo.persistAllocatedForUtcDay(
        dayUtc: dayUtc,
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
      expect(snap.allocated.length, 2);
    });

    test('does not bump version when membership unchanged', () async {
      final db = createTestDb();
      addTearDown(() => closeTestDb(db));

      final repo = AllocationSnapshotRepository(db: db);
      final dayUtc = dateOnly(DateTime.now().toUtc());

      await repo.persistAllocatedForUtcDay(
        dayUtc: dayUtc,
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
