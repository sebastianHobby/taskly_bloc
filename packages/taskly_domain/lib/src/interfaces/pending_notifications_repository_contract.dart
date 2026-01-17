import 'package:taskly_domain/src/notifications/model/pending_notification.dart';
import 'package:taskly_domain/src/telemetry/operation_context.dart';

/// Repository contract for pending notifications
abstract class PendingNotificationsRepositoryContract {
  Stream<List<PendingNotification>> watchPending();

  Future<void> markDelivered({
    required String id,
    DateTime? deliveredAt,
    OperationContext? context,
  });
}
