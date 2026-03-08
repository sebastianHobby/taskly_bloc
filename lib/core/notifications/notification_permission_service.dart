import 'package:meta/meta.dart';

@immutable
enum NotificationPermissionStatus {
  unsupported,
  denied,
  granted,
}

extension NotificationPermissionStatusX on NotificationPermissionStatus {
  bool get isGranted => this == NotificationPermissionStatus.granted;
  bool get isSupported => this != NotificationPermissionStatus.unsupported;
}

abstract interface class NotificationPermissionService {
  Future<NotificationPermissionStatus> getStatus();

  Future<NotificationPermissionStatus> requestPermission();

  Future<void> openSettings();
}
