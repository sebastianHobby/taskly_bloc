import 'dart:async';

import 'package:taskly_bloc/core/logging/talker_service.dart';
import 'package:taskly_bloc/domain/notifications/model/pending_notification.dart';
import 'package:taskly_bloc/domain/interfaces/pending_notifications_repository_contract.dart';
import 'package:taskly_bloc/domain/services/notifications/notification_presenter.dart';

/// Watches for new pending notifications and processes them.
///
/// This is intentionally minimal: it logs the notification and marks it
/// delivered. Replace the "log" step with a real local notification
/// integration when ready.
class PendingNotificationsProcessor {
  PendingNotificationsProcessor({
    required PendingNotificationsRepositoryContract repository,
    required NotificationPresenter presenter,
  }) : _repository = repository,
       _presenter = presenter;

  final PendingNotificationsRepositoryContract _repository;
  final NotificationPresenter _presenter;

  StreamSubscription<List<PendingNotification>>? _subscription;
  final Set<String> _inFlight = <String>{};

  void start() {
    if (_subscription != null) return;

    talker.info('[notifications] Starting pending notifications processor');
    _subscription = _repository.watchPending().listen(
      (items) {
        unawaited(_process(items));
      },
      onError: (Object error, StackTrace stackTrace) {
        talker.handle(error, stackTrace, 'Pending notifications stream error');
      },
    );
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _inFlight.clear();
    talker.info('[notifications] Stopped pending notifications processor');
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
        talker.handle(
          error,
          stackTrace,
          'Failed to process pending notification ${item.id}',
        );
      } finally {
        _inFlight.remove(item.id);
      }
    }
  }
}
