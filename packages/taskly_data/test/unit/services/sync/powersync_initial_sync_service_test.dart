import 'package:powersync/powersync.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_data/src/services/sync/powersync_initial_sync_service.dart';

import '../../../helpers/test_imports.dart';

class _MockPowerSyncDatabase extends Mock implements PowerSyncDatabase {}

void main() {
  group('mapInitialSyncProgress', () {
    testSafe('uses priority 2 status for sync checkpoint fields', () async {
      final priorityTwoSyncedAt = DateTime.utc(2026, 2, 18, 12, 0, 0);
      final status = SyncStatus(
        connected: true,
        connecting: false,
        downloading: false,
        uploading: false,
        hasSynced: false,
        lastSyncedAt: null,
        priorityStatusEntries: <SyncPriorityStatus>[
          (
            priority: StreamPriority(2),
            hasSynced: true,
            lastSyncedAt: priorityTwoSyncedAt,
          ),
        ],
      );

      final mapped = mapInitialSyncProgress(status);

      expect(mapped.hasSynced, isTrue);
      expect(mapped.lastSyncedAt, priorityTwoSyncedAt);
    });

    testSafe(
      'falls back to full sync status when no priority entry exists',
      () async {
        final fullSyncedAt = DateTime.utc(2026, 2, 18, 13, 0, 0);
        final status = SyncStatus(
          connected: true,
          connecting: false,
          downloading: false,
          uploading: false,
          hasSynced: true,
          lastSyncedAt: fullSyncedAt,
        );

        final mapped = mapInitialSyncProgress(status);

        expect(mapped.hasSynced, isTrue);
        expect(mapped.lastSyncedAt, fullSyncedAt);
      },
    );
  });

  group('PowerSyncInitialSyncService', () {
    late _MockPowerSyncDatabase db;

    setUp(() {
      db = _MockPowerSyncDatabase();
    });

    testSafe(
      'waitForFirstSync no-ops when initial state is already synced',
      () async {
        when(
          () => db.statusStream,
        ).thenAnswer(
          (_) => Stream<SyncStatus>.value(
            SyncStatus(
              connected: true,
              connecting: false,
              downloading: false,
              uploading: false,
              hasSynced: true,
              lastSyncedAt: DateTime.utc(2026, 2, 18, 14),
            ),
          ),
        );

        final service = PowerSyncInitialSyncService(db);
        await service.waitForFirstSync();

        verifyNever(
          () => db.waitForFirstSync(priority: any(named: 'priority')),
        );
      },
    );

    testSafe(
      'waitForFirstSync delegates to database when not yet synced',
      () async {
        when(
          () => db.statusStream,
        ).thenAnswer(
          (_) => Stream<SyncStatus>.value(
            const SyncStatus(
              connected: true,
              connecting: false,
              downloading: true,
              uploading: false,
              hasSynced: false,
              lastSyncedAt: null,
            ),
          ),
        );
        when(
          () => db.waitForFirstSync(priority: any(named: 'priority')),
        ).thenAnswer((_) async {});

        final service = PowerSyncInitialSyncService(db);
        await service.waitForFirstSync();

        verify(
          () => db.waitForFirstSync(priority: any(named: 'priority')),
        ).called(1);
      },
    );
  });
}
