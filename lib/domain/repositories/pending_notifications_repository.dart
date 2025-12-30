import 'package:taskly_bloc/domain/models/notifications/pending_notification.dart';

abstract class PendingNotificationsRepository {
  Stream<List<PendingNotification>> watchPending();

  Future<void> markDelivered({
    required String id,
    DateTime? deliveredAt,
  });
}
