import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/services/notifications/scaffold_messenger_service.dart';
import 'package:taskly_bloc/core/utils/app_logger.dart';
import 'package:taskly_bloc/domain/models/notifications/pending_notification.dart';

/// Presents notifications as SnackBars inside the app.
class InAppSnackBarNotificationPresenter {
  InAppSnackBarNotificationPresenter(this._messengerService);

  final ScaffoldMessengerService _messengerService;
  final _logger = AppLogger.forService('in_app_notification_presenter');

  Future<bool> call(PendingNotification notification) async {
    final messenger = _messengerService.messengerKey.currentState;
    if (messenger == null) {
      _logger.debug(
        'No ScaffoldMessengerState available yet; skipping SnackBar',
      );
      return false;
    }

    final title = (notification.payload ?? const <String, dynamic>{})['name']
        ?.toString();

    final text = title == null || title.isEmpty
        ? 'You have a review due.'
        : 'Review due: $title';

    messenger.showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
      ),
    );

    return true;
  }
}
