import 'package:drift/drift.dart';
import 'package:taskly_bloc/core/utils/app_logger.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart' as db;
import 'package:taskly_bloc/domain/models/notifications/pending_notification.dart';
import 'package:taskly_bloc/domain/repositories/pending_notifications_repository.dart';

/// Drift implementation of [PendingNotificationsRepository].
class PendingNotificationsRepositoryImpl
    implements PendingNotificationsRepository {
  PendingNotificationsRepositoryImpl(this._db);

  final db.AppDatabase _db;
  final _logger = AppLogger.forRepository('pending_notifications');

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
                  screenDefinitionId: e.screenDefinitionId,
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
      _logger.error(
        'Failed to mark notification delivered: $id',
        error,
        stackTrace,
      );
      rethrow;
    }
  }
}
