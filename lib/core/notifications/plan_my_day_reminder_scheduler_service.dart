import 'dart:async';

import 'package:taskly_bloc/core/notifications/scheduled_notification_sync_service.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/my_day.dart';
import 'package:taskly_domain/preferences.dart';
import 'package:taskly_domain/settings.dart';
import 'package:taskly_domain/taskly_domain.dart';

class PlanMyDayReminderSchedulerService {
  PlanMyDayReminderSchedulerService({
    required SettingsRepositoryContract settingsRepository,
    required MyDayRepositoryContract myDayRepository,
    required HomeDayKeyService homeDayKeyService,
    required TemporalTriggerService temporalTriggerService,
    required ScheduledNotificationSyncService notificationSyncService,
    Clock clock = systemClock,
    this.windowDays = 30,
  }) : _settingsRepository = settingsRepository,
       _myDayRepository = myDayRepository,
       _homeDayKeyService = homeDayKeyService,
       _temporalTriggerService = temporalTriggerService,
       _notificationSyncService = notificationSyncService,
       _clock = clock;

  static const String namespace = 'plan_my_day';

  final SettingsRepositoryContract _settingsRepository;
  final MyDayRepositoryContract _myDayRepository;
  final HomeDayKeyService _homeDayKeyService;
  final TemporalTriggerService _temporalTriggerService;
  final ScheduledNotificationSyncService _notificationSyncService;
  final Clock _clock;
  final int windowDays;

  StreamSubscription<GlobalSettings>? _settingsSub;
  StreamSubscription<TemporalTriggerEvent>? _temporalSub;
  StreamSubscription<MyDayDayPicks>? _todaySub;
  GlobalSettings _settings = const GlobalSettings();
  DateTime? _watchedDayKeyUtc;
  Future<void> _refreshQueue = Future<void>.value();
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;

    _settingsSub = _settingsRepository
        .watch(SettingsKey.global)
        .listen(
          (settings) {
            _settings = settings;
            _resubscribeToday();
            _scheduleRefresh(source: 'settings_changed');
          },
          onError: (Object error, StackTrace stackTrace) {
            AppLog.handleStructured(
              'notifications.plan_my_day_scheduler',
              'settings stream failed',
              error,
              stackTrace,
            );
          },
        );

    _temporalSub = _temporalTriggerService.events.listen(
      (_) {
        _resubscribeToday();
        _scheduleRefresh(source: 'temporal_trigger');
      },
      onError: (Object error, StackTrace stackTrace) {
        AppLog.handleStructured(
          'notifications.plan_my_day_scheduler',
          'temporal stream failed',
          error,
          stackTrace,
        );
      },
    );

    _resubscribeToday();
    _scheduleRefresh(source: 'start');
  }

  Future<void> stop() async {
    if (!_started) return;
    _started = false;
    await _settingsSub?.cancel();
    _settingsSub = null;
    await _temporalSub?.cancel();
    _temporalSub = null;
    await _todaySub?.cancel();
    _todaySub = null;
    _watchedDayKeyUtc = null;
    await _notificationSyncService.clearScheduledNotifications(
      namespace: namespace,
    );
  }

  void _resubscribeToday() {
    if (!_started) return;
    final currentDayKeyUtc = _homeDayKeyService.todayDayKeyUtc(
      nowUtc: _clock.nowUtc(),
    );
    if (_watchedDayKeyUtc?.isAtSameMomentAs(currentDayKeyUtc) ?? false) {
      return;
    }

    unawaited(_todaySub?.cancel());
    _watchedDayKeyUtc = currentDayKeyUtc;
    _todaySub = _myDayRepository
        .watchDay(currentDayKeyUtc)
        .listen(
          (_) => _scheduleRefresh(source: 'today_changed'),
          onError: (Object error, StackTrace stackTrace) {
            AppLog.handleStructured(
              'notifications.plan_my_day_scheduler',
              'today stream failed',
              error,
              stackTrace,
            );
          },
        );
  }

  void _scheduleRefresh({required String source}) {
    _refreshQueue = _refreshQueue
        .catchError((_) {})
        .then((_) => _refresh(source: source))
        .catchError((Object error, StackTrace stackTrace) {
          AppLog.handleStructured(
            'notifications.plan_my_day_scheduler',
            'refresh failed',
            error,
            stackTrace,
            <String, Object?>{'source': source},
          );
        });
    unawaited(_refreshQueue);
  }

  Future<void> _refresh({required String source}) async {
    if (!_started) return;

    if (!_settings.planMyDayReminderEnabled) {
      await _notificationSyncService.clearScheduledNotifications(
        namespace: namespace,
      );
      return;
    }

    final nowUtc = _clock.nowUtc();
    final todayDayKeyUtc = _homeDayKeyService.todayDayKeyUtc(nowUtc: nowUtc);
    final today = await _myDayRepository.loadDay(todayDayKeyUtc);

    final notifications = <PendingNotification>[];
    for (var dayOffset = 0; dayOffset < windowDays; dayOffset++) {
      final dayKeyUtc = todayDayKeyUtc.add(Duration(days: dayOffset));
      final dueUtc = _dueUtcForDay(dayKeyUtc);
      if (!dueUtc.isAfter(nowUtc)) continue;
      if (dayOffset == 0 && today.ritualCompletedAtUtc != null) continue;

      notifications.add(
        PendingNotification(
          id: 'plan_my_day_${dayKeyUtc.toIso8601String()}',
          userId: null,
          screenKey: 'my_day',
          scheduledFor: dueUtc,
          status: 'pending',
          payload: <String, dynamic>{
            'type': 'plan_my_day_reminder',
            'day_key_utc': dayKeyUtc.toIso8601String(),
          },
          createdAt: nowUtc,
          deliveredAt: null,
          seenAt: null,
        ),
      );
    }

    await _notificationSyncService.syncScheduledNotifications(
      namespace: namespace,
      notifications: notifications,
    );

    AppLog.infoStructured(
      'notifications.plan_my_day_scheduler',
      'synchronized plan my day reminders',
      fields: <String, Object?>{
        'count': notifications.length,
        'source': source,
      },
    );
  }

  DateTime _dueUtcForDay(DateTime dayKeyUtc) {
    final day = dateOnly(dayKeyUtc);
    final offset = Duration(minutes: _settings.homeTimeZoneOffsetMinutes);
    final minutes = _settings.planMyDayReminderTimeMinutes.clamp(0, 1439);
    final dayStartUtc = day.subtract(offset);
    return dayStartUtc.add(Duration(minutes: minutes));
  }
}
