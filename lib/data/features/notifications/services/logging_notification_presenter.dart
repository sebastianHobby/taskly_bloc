import 'package:taskly_bloc/core/utils/app_logger.dart';
import 'package:taskly_bloc/domain/models/notifications/pending_notification.dart';

/// Temporary presenter that logs notifications instead of displaying them.
class LoggingNotificationPresenter {
  LoggingNotificationPresenter();

  final _logger = AppLogger.forService('notification_presenter');

  Future<void> call(PendingNotification notification) async {
    final title = (notification.payload ?? const <String, dynamic>{})['name']
        ?.toString();
    _logger.info(
      'PRESENT: id=${notification.id} '
      'screen=${notification.screenDefinitionId} '
      'title=${title ?? 'n/a'}',
    );
  }
}
