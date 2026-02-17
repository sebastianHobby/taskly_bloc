import 'dart:async';

import 'package:taskly_core/logging.dart';
import 'package:taskly_domain/src/interfaces/my_day_repository_contract.dart';
import 'package:taskly_domain/src/interfaces/settings_repository_contract.dart';
import 'package:taskly_domain/src/notifications/model/pending_notification.dart';
import 'package:taskly_domain/src/preferences/model/settings_key.dart';
import 'package:taskly_domain/src/services/notifications/notification_presenter.dart';
import 'package:taskly_domain/src/services/time/temporal_trigger_service.dart';
import 'package:taskly_domain/src/services/time/home_day_key_service.dart';
import 'package:taskly_domain/src/settings/model/global_settings.dart';
import 'package:taskly_domain/src/time/clock.dart';
import 'package:taskly_domain/src/time/date_only.dart';

/// Triggers a daily Plan My Day reminder based on [GlobalSettings].
///
/// Reminder is emitted only when:
/// - reminder setting is enabled
/// - current instant is at/after configured reminder time (home timezone)
/// - today's plan has not been created yet (`ritualCompletedAtUtc == null`)
///
/// Presentation is delegated to [NotificationPresenter] so delivery can remain
/// swappable (logging/local notifications/push bridge).
class PlanMyDayReminderService {
  PlanMyDayReminderService({
    required SettingsRepositoryContract settingsRepository,
    required MyDayRepositoryContract myDayRepository,
    required HomeDayKeyService homeDayKeyService,
    required TemporalTriggerService temporalTriggerService,
    required NotificationPresenter presenter,
    Clock clock = systemClock,
  }) : _settingsRepository = settingsRepository,
       _myDayRepository = myDayRepository,
       _homeDayKeyService = homeDayKeyService,
       _temporalTriggerService = temporalTriggerService,
       _presenter = presenter,
       _clock = clock;

  final SettingsRepositoryContract _settingsRepository;
  final MyDayRepositoryContract _myDayRepository;
  final HomeDayKeyService _homeDayKeyService;
  final TemporalTriggerService _temporalTriggerService;
  final NotificationPresenter _presenter;
  final Clock _clock;

  StreamSubscription<GlobalSettings>? _settingsSub;
  StreamSubscription<TemporalTriggerEvent>? _temporalSub;
  Timer? _timer;
  GlobalSettings _settings = const GlobalSettings();
  DateTime? _lastNotifiedDayKeyUtc;
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;

    _settingsSub = _settingsRepository
        .watch(SettingsKey.global)
        .listen(
          (
            settings,
          ) {
            _settings = settings;
            _scheduleNextTick();
            _scheduleEvaluation(source: 'settings_change');
          },
          onError: (Object error, StackTrace stackTrace) {
            AppLog.handleStructured(
              'notifications.plan_my_day',
              'settings stream failed',
              error,
              stackTrace,
            );
          },
        );

    _temporalSub = _temporalTriggerService.events.listen(
      (_) {
        _scheduleNextTick();
        _scheduleEvaluation(source: 'temporal_trigger');
      },
      onError: (Object error, StackTrace stackTrace) {
        AppLog.handleStructured(
          'notifications.plan_my_day',
          'temporal trigger stream failed',
          error,
          stackTrace,
        );
      },
    );

    _scheduleNextTick();
    _scheduleEvaluation(source: 'start');
  }

  void stop() {
    if (!_started) return;
    _started = false;
    _timer?.cancel();
    _timer = null;
    _settingsSub?.cancel();
    _settingsSub = null;
    _temporalSub?.cancel();
    _temporalSub = null;
  }

  Future<void> _evaluateAndNotify({required String source}) async {
    if (!_started || !_settings.planMyDayReminderEnabled) return;

    final nowUtc = _clock.nowUtc();
    final dayKeyUtc = _homeDayKeyService.todayDayKeyUtc(nowUtc: nowUtc);
    final dueUtc = _dueUtcForDay(dayKeyUtc);

    if (nowUtc.isBefore(dueUtc)) return;
    if (_isSameDay(dayKeyUtc, _lastNotifiedDayKeyUtc)) return;

    final day = await _myDayRepository.loadDay(dayKeyUtc);
    if (day.ritualCompletedAtUtc != null) {
      talker.debug(
        '[PlanMyDayReminder] skip; plan already exists '
        'day=${dayKeyUtc.toIso8601String()} source=$source',
      );
      return;
    }

    final notification = PendingNotification(
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
    );

    await _presenter(notification);
    _lastNotifiedDayKeyUtc = dayKeyUtc;
    talker.info(
      '[PlanMyDayReminder] delivered day=${dayKeyUtc.toIso8601String()} '
      'source=$source',
    );
  }

  void _scheduleNextTick() {
    _timer?.cancel();
    if (!_started || !_settings.planMyDayReminderEnabled) return;

    final nowUtc = _clock.nowUtc();
    final todayKeyUtc = _homeDayKeyService.todayDayKeyUtc(nowUtc: nowUtc);
    final dueTodayUtc = _dueUtcForDay(todayKeyUtc);
    final nextDueUtc = nowUtc.isBefore(dueTodayUtc)
        ? dueTodayUtc
        : _dueUtcForDay(todayKeyUtc.add(const Duration(days: 1)));

    final delay = nextDueUtc.difference(nowUtc);
    _timer = Timer(
      delay.isNegative ? Duration.zero : delay,
      () {
        _scheduleEvaluation(source: 'timer');
        _scheduleNextTick();
      },
    );
  }

  void _scheduleEvaluation({required String source}) {
    unawaited(
      _evaluateAndNotify(source: source).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        AppLog.handleStructured(
          'notifications.plan_my_day',
          'evaluation failed',
          error,
          stackTrace,
          <String, Object?>{'source': source},
        );
      }),
    );
  }

  DateTime _dueUtcForDay(DateTime dayKeyUtc) {
    final day = dateOnly(dayKeyUtc);
    final offset = Duration(minutes: _settings.homeTimeZoneOffsetMinutes);
    final minutes = _settings.planMyDayReminderTimeMinutes.clamp(0, 1439);
    final dayStartUtc = day.subtract(offset);
    return dayStartUtc.add(Duration(minutes: minutes));
  }

  bool _isSameDay(DateTime a, DateTime? b) {
    if (b == null) return false;
    return dateOnly(a).isAtSameMomentAs(dateOnly(b));
  }
}
