import 'package:drift/drift.dart';
import 'package:taskly_data/src/errors/failure_guard.dart';
import 'package:taskly_data/src/infrastructure/drift/drift_database.dart' as db;
import 'package:taskly_domain/taskly_domain.dart' hide Value;
import 'package:taskly_domain/time.dart' show Clock, systemClock;

/// Drift implementation of [PendingNotificationsRepositoryContract].
class PendingNotificationsRepositoryImpl
    implements PendingNotificationsRepositoryContract {
  PendingNotificationsRepositoryImpl(
    this._db, {
    Clock clock = systemClock,
  }) : _clock = clock;

  final db.AppDatabase _db;
  final Clock _clock;

  @override
  Stream<List<PendingNotification>> watchPending() {
    return (_db.select(_db.pendingNotifications)
          ..where((t) => t.status.equals('pending') & t.deliveredAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.scheduledFor)]))
        .watch()
        .map(
          (rows) => rows
              .map(
                (e) => PendingNotification(
                  id: e.id,
                  userId: e.userId,
                  screenKey: e.screenKey,
                  scheduledFor: e.scheduledFor,
                  status: e.status,
                  payload: PendingNotification.tryDecodePayload(e.payload),
                  createdAt: e.createdAt,
                  deliveredAt: e.deliveredAt,
                  seenAt: e.seenAt,
                ),
              )
              .toList(growable: false),
        );
  }

  @override
  Future<void> markDelivered({
    required String id,
    DateTime? deliveredAt,
    OperationContext? context,
  }) async {
    final now = deliveredAt ?? _clock.nowUtc();

    return FailureGuard.run(
      () async {
        await (_db.update(
          _db.pendingNotifications,
        )..where((t) => t.id.equals(id))).write(
          db.PendingNotificationsCompanion(
            status: const Value('delivered'),
            deliveredAt: Value(now),
          ),
        );
      },
      area: 'data.notifications',
      opName: 'markDelivered',
      context: context,
    );
  }
}
