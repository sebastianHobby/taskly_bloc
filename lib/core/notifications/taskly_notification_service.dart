import 'dart:convert';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:taskly_bloc/core/notifications/notification_permission_service.dart';
import 'package:taskly_bloc/l10n/gen/app_localizations.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_domain/taskly_domain.dart';

class TasklyNotificationService implements NotificationPermissionService {
  TasklyNotificationService({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String _channelId = 'taskly_reminders';
  static const String _channelName = 'Taskly reminders';
  static const String _channelDescription =
      'Reminders for Plan My Day and tasks.';

  final FlutterLocalNotificationsPlugin _plugin;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || !_supportsNotifications()) return;

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _plugin.initialize(initializationSettings);
    _initialized = true;
  }

  @override
  Future<NotificationPermissionStatus> getStatus() async {
    if (!_supportsNotifications()) {
      return NotificationPermissionStatus.unsupported;
    }

    await initialize();

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final android = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        final enabled = await android?.areNotificationsEnabled() ?? false;
        return enabled
            ? NotificationPermissionStatus.granted
            : NotificationPermissionStatus.denied;
      case TargetPlatform.iOS:
        final ios = _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        final permissions = await ios?.checkPermissions();
        final enabled = permissions?.isEnabled ?? false;
        return enabled
            ? NotificationPermissionStatus.granted
            : NotificationPermissionStatus.denied;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return NotificationPermissionStatus.unsupported;
    }
  }

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    if (!_supportsNotifications()) {
      return NotificationPermissionStatus.unsupported;
    }

    await initialize();

    bool granted = false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final android = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        granted = await android?.requestNotificationsPermission() ?? false;
      case TargetPlatform.iOS:
        final ios = _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        granted =
            await ios?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return NotificationPermissionStatus.unsupported;
    }

    return granted
        ? NotificationPermissionStatus.granted
        : NotificationPermissionStatus.denied;
  }

  @override
  Future<void> openSettings() async {
    if (!_supportsNotifications()) return;

    await AppSettings.openAppSettings(type: AppSettingsType.notification);
  }

  Future<void> call(PendingNotification notification) async {
    final status = await getStatus();
    if (!status.isGranted) {
      AppLog.infoStructured(
        'notifications.presenter',
        'skipping local notification; permission not granted',
        fields: <String, Object?>{
          'notificationId': notification.id,
          'status': status.name,
        },
      );
      return;
    }

    await initialize();

    final content = _buildContent(notification);
    final details = NotificationDetails(
      android: const AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.show(
      _notificationId(notification.id),
      content.title,
      content.body,
      details,
      payload: jsonEncode(<String, Object?>{
        'id': notification.id,
        'screenKey': notification.screenKey,
        'scheduledFor': notification.scheduledFor.toIso8601String(),
      }),
    );
  }

  _ResolvedNotificationContent _buildContent(PendingNotification notification) {
    final l10n = _resolveL10n();
    final payload = notification.payload ?? const <String, dynamic>{};
    final type = payload['type']?.toString();

    if (type == 'plan_my_day_reminder') {
      return _ResolvedNotificationContent(
        title: l10n.settingsPlanMyDayReminderTitle,
        body: l10n.planMyDayReminderNotificationBody,
      );
    }

    if (type == 'task_reminder') {
      final taskName = payload['name']?.toString().trim();
      return _ResolvedNotificationContent(
        title: (taskName?.isNotEmpty ?? false)
            ? taskName!
            : l10n.taskReminderChipLabel,
        body: l10n.taskReminderNotificationBody,
      );
    }

    return _ResolvedNotificationContent(
      title: l10n.settingsNotificationsTitle,
      body: l10n.settingsNotificationsSubtitle,
    );
  }

  AppLocalizations _resolveL10n() {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final supported = AppLocalizations.supportedLocales.firstWhere(
      (candidate) => candidate.languageCode == locale.languageCode,
      orElse: () => const Locale('en'),
    );
    return lookupAppLocalizations(supported);
  }

  int _notificationId(String rawId) {
    return rawId.hashCode & 0x7fffffff;
  }

  bool _supportsNotifications() {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }
}

final class _ResolvedNotificationContent {
  const _ResolvedNotificationContent({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;
}
