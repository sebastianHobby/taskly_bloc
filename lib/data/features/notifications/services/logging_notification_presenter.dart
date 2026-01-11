import 'package:taskly_bloc/core/logging/talker_service.dart';
import 'package:taskly_bloc/domain/models/notifications/pending_notification.dart';

/// Temporary presenter that logs notifications instead of displaying them.
class LoggingNotificationPresenter {
  LoggingNotificationPresenter();

  Future<void> call(PendingNotification notification) async {
    final title = (notification.payload ?? const <String, dynamic>{})['name']
        ?.toString();
    talker.info(
      '[NotificationPresenter] PRESENT: id=${notification.id} '
      'screen=${notification.screenKey} '
      'title=${title ?? 'n/a'}',
    );
  }
}
