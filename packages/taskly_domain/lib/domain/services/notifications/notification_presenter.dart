import '../../notifications/model/pending_notification.dart';

/// Presents a notification to the user.
///
/// This is an abstraction so the core processing logic does not depend on a
/// specific delivery mechanism (e.g. `flutter_local_notifications`).
typedef NotificationPresenter =
    Future<void> Function(
      PendingNotification notification,
    );
