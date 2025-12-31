import 'package:taskly_bloc/domain/models/notifications/pending_notification.dart';

/// Repository contract for pending notifications
abstract class PendingNotificationsRepositoryContract {
  Stream<List<PendingNotification>> watchPending();

  Future<void> markDelivered({
    required String id,
    DateTime? deliveredAt,
  });
}
