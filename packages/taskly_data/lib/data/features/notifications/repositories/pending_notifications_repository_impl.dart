import 'package:drift/drift.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_data/data/infrastructure/drift/drift_database.dart'
    as db;
import 'package:taskly_domain/taskly_domain.dart';

/// Drift implementation of [PendingNotificationsRepositoryContract].
class PendingNotificationsRepositoryImpl
    implements PendingNotificationsRepositoryContract {
  PendingNotificationsRepositoryImpl(this._db);

  final db.AppDatabase _db;

  @override
  Stream<List<PendingNotification>> watchPending() {
    return (_db.select(_db.pendingNotifications)
          ..where(
            (t) => t.status.equals('pending') & t.deliveredAt.isNull(),
          )
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
  }) async {
    final now = deliveredAt ?? DateTime.now();

    try {
      await (_db.update(
        _db.pendingNotifications,
      )..where((t) => t.id.equals(id))).write(
        db.PendingNotificationsCompanion(
          status: const Value('delivered'),
          deliveredAt: Value(now),
        ),
      );
    } catch (error, stackTrace) {
      talker.handle(
        error,
        stackTrace,
        '[PendingNotificationsRepo] Failed to mark notification '
        'delivered: $id',
      );
      rethrow;
    }
  }
}
