@Tags(['unit'])
library;

import '../../../helpers/test_imports.dart';
import '../../../helpers/test_db.dart';

import 'package:drift/drift.dart';
import 'package:taskly_data/src/features/notifications/repositories/pending_notifications_repository_impl.dart';
import 'package:taskly_domain/taskly_domain.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('PendingNotificationsRepositoryImpl', () {
    testSafe('watchPending filters and maps rows', () async {
      final db = createAutoClosingDb();
      final repo = PendingNotificationsRepositoryImpl(db);

      final now = DateTime.utc(2025, 1, 1);
      await db.into(db.pendingNotifications).insert(
        PendingNotificationsCompanion.insert(
          id: 'p1',
          userId: 'u1',
          screenKey: 'screen',
          scheduledFor: now,
          status: 'pending',
          payload: const Value('{"a":1}'),
          createdAt: now,
        ),
      );
      await db.into(db.pendingNotifications).insert(
        PendingNotificationsCompanion.insert(
          id: 'p2',
          userId: 'u1',
          screenKey: 'screen',
          scheduledFor: now.add(const Duration(minutes: 1)),
          status: 'delivered',
          payload: const Value('{"a":2}'),
          createdAt: now,
        ),
      );
      await db.into(db.pendingNotifications).insert(
        PendingNotificationsCompanion.insert(
          id: 'p3',
          userId: 'u1',
          screenKey: 'screen',
          scheduledFor: now.add(const Duration(minutes: 2)),
          status: 'pending',
          payload: const Value('{"a":3}'),
          createdAt: now,
          deliveredAt: Value(now),
        ),
      );

      final pending = await repo.watchPending().first;
      expect(pending.length, equals(1));
      expect(pending.single.id, equals('p1'));
      expect(pending.single.payload, equals(const <String, dynamic>{'a': 1}));
    });

    testSafe('markDelivered updates status and deliveredAt', () async {
      final db = createAutoClosingDb();
      final repo = PendingNotificationsRepositoryImpl(db);

      final now = DateTime.utc(2025, 1, 1);
      await db.into(db.pendingNotifications).insert(
        PendingNotificationsCompanion.insert(
          id: 'p1',
          userId: 'u1',
          screenKey: 'screen',
          scheduledFor: now,
          status: 'pending',
          payload: const Value('{}'),
          createdAt: now,
        ),
      );

      final deliveredAt = DateTime.utc(2025, 1, 2);
      await repo.markDelivered(id: 'p1', deliveredAt: deliveredAt);

      final row = await db.select(db.pendingNotifications).getSingle();
      expect(row.status, equals('delivered'));
      expect(row.deliveredAt, equals(deliveredAt));
    });
  });
}
