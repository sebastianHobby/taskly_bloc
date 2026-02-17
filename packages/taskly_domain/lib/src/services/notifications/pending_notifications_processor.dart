import 'dart:async';

import 'package:taskly_core/logging.dart';
import 'package:taskly_domain/src/notifications/model/pending_notification.dart';
import 'package:taskly_domain/src/interfaces/pending_notifications_repository_contract.dart';
import 'package:taskly_domain/src/services/notifications/notification_presenter.dart';
import 'package:taskly_domain/src/time/clock.dart';
import 'package:taskly_domain/telemetry.dart';

/// Watches for new pending notifications and processes them.
///
/// This is intentionally minimal: it logs the notification and marks it
/// delivered. Replace the "log" step with a real local notification
/// integration when ready.
class PendingNotificationsProcessor {
  PendingNotificationsProcessor({
    required PendingNotificationsRepositoryContract repository,
    required NotificationPresenter presenter,
    Clock clock = systemClock,
  }) : _repository = repository,
       _presenter = presenter,
       _clock = clock;

  final PendingNotificationsRepositoryContract _repository;
  final NotificationPresenter _presenter;
  final Clock _clock;

  StreamSubscription<List<PendingNotification>>? _subscription;
  final Set<String> _inFlight = <String>{};

  void start() {
    if (_subscription != null) return;

    AppLog.info('notifications', 'starting pending notifications processor');
    _subscription = _repository.watchPending().listen(
      _scheduleProcess,
      onError: (Object error, StackTrace stackTrace) {
        AppLog.handleStructured(
          'notifications',
          'pending notifications stream error',
          error,
          stackTrace,
        );
      },
    );
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _inFlight.clear();
    AppLog.info('notifications', 'stopped pending notifications processor');
  }

  Future<void> _process(List<PendingNotification> items) async {
    for (final item in items) {
      if (!_inFlight.add(item.id)) continue;

      try {
        if (item.scheduledFor.isAfter(_clock.nowUtc())) {
          continue;
        }

        await _presenter(item);
        final context = systemOperationContext(
          feature: 'notifications',
          intent: 'deliver_pending_notification',
          operation: 'notifications.markDelivered',
          entityType: 'pending_notification',
          entityId: item.id,
          extraFields: <String, Object?>{
            'scheduledFor': item.scheduledFor.toIso8601String(),
          },
        );
        await _repository.markDelivered(id: item.id, context: context);
      } catch (error, stackTrace) {
        AppLog.handleStructured(
          'notifications',
          'process pending notification failed',
          error,
          stackTrace,
          <String, Object?>{
            'pendingNotificationId': item.id,
            'scheduledFor': item.scheduledFor.toIso8601String(),
          },
        );
      } finally {
        _inFlight.remove(item.id);
      }
    }
  }

  void _scheduleProcess(List<PendingNotification> items) {
    unawaited(
      _process(items).catchError((Object error, StackTrace stackTrace) {
        AppLog.handleStructured(
          'notifications',
          'pending processor cycle failed',
          error,
          stackTrace,
          <String, Object?>{'pendingCount': items.length},
        );
      }),
    );
  }
}
