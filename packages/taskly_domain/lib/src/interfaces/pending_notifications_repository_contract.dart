import 'package:taskly_domain/src/notifications/model/pending_notification.dart';
import 'package:taskly_domain/src/telemetry/operation_context.dart';

/// Repository contract for pending notifications
abstract class PendingNotificationsRepositoryContract {
  /// Watch pending notifications.
  ///
  /// Stream contract:
  /// - broadcast: do not assume
  /// - replay: none
  /// - cold/hot: typically hot
  Stream<List<PendingNotification>> watchPending();

  Future<void> markDelivered({
    required String id,
    DateTime? deliveredAt,
    OperationContext? context,
  });
}
