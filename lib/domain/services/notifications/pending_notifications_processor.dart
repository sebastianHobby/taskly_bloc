import 'dart:async';

import 'package:taskly_bloc/core/utils/app_logger.dart';
import 'package:taskly_bloc/domain/models/notifications/pending_notification.dart';
import 'package:taskly_bloc/domain/repositories/pending_notifications_repository.dart';
import 'package:taskly_bloc/domain/services/notifications/notification_presenter.dart';

/// Watches for new pending notifications and processes them.
///
/// This is intentionally minimal: it logs the notification and marks it
/// delivered. Replace the "log" step with a real local notification
/// integration when ready.
class PendingNotificationsProcessor {
  PendingNotificationsProcessor({
    required PendingNotificationsRepository repository,
    required NotificationPresenter presenter,
  }) : _repository = repository,
       _presenter = presenter;

  final PendingNotificationsRepository _repository;
  final NotificationPresenter _presenter;
  final _logger = AppLogger.forService('pending_notifications');

  StreamSubscription<List<PendingNotification>>? _subscription;
  final Set<String> _inFlight = <String>{};

  void start() {
    if (_subscription != null) return;

    _logger.info('Starting pending notifications processor');
    _subscription = _repository.watchPending().listen(
      (items) {
        unawaited(_process(items));
      },
      onError: (Object error, StackTrace stackTrace) {
        _logger.error('Pending notifications stream error', error, stackTrace);
      },
    );
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _inFlight.clear();
    _logger.info('Stopped pending notifications processor');
  }

  Future<void> _process(List<PendingNotification> items) async {
    for (final item in items) {
      if (!_inFlight.add(item.id)) continue;

      try {
        if (item.scheduledFor.isAfter(DateTime.now())) {
          continue;
        }

        await _presenter(item);
        await _repository.markDelivered(id: item.id);
      } catch (error, stackTrace) {
        _logger.error(
          'Failed to process pending notification ${item.id}',
          error,
          stackTrace,
        );
      } finally {
        _inFlight.remove(item.id);
      }
    }
  }
}
