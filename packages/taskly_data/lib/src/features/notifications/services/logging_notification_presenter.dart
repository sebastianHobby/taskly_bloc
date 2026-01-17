import 'package:taskly_core/logging.dart';
import 'package:taskly_domain/taskly_domain.dart';

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
