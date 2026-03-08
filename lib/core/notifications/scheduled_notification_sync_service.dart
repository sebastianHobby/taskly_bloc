import 'package:taskly_domain/taskly_domain.dart';

abstract interface class ScheduledNotificationSyncService {
  Future<void> syncScheduledNotifications({
    required String namespace,
    required Iterable<PendingNotification> notifications,
  });

  Future<void> clearScheduledNotifications({required String namespace});
}
