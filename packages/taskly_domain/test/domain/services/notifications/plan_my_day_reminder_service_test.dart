@Tags(['unit'])
library;

import '../../../helpers/test_imports.dart';

import 'dart:async';

import 'package:taskly_domain/my_day.dart';
import 'package:taskly_domain/notifications.dart';
import 'package:taskly_domain/preferences.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/settings.dart';
import 'package:taskly_domain/telemetry.dart';
import 'package:taskly_domain/time.dart';

class _MutableClock implements Clock {
  _MutableClock(this._nowUtc);

  DateTime _nowUtc;

  void setNow(DateTime value) => _nowUtc = value;

  @override
  DateTime nowLocal() => _nowUtc.toLocal();

  @override
  DateTime nowUtc() => _nowUtc;
}

class _FakeLifecycleEvents implements AppLifecycleEvents {
  _FakeLifecycleEvents(this._controller);

  final StreamController<AppLifecycleEvent> _controller;

  @override
  Stream<AppLifecycleEvent> get events => _controller.stream;
}

class _FakeDayKeyService extends Fake implements HomeDayKeyService {
  _FakeDayKeyService(this._clock);

  final _MutableClock _clock;

  @override
  DateTime todayDayKeyUtc({DateTime? nowUtc}) => dateOnly(nowUtc ?? _clock.nowUtc());

  @override
  DateTime nextHomeDayBoundaryUtc({DateTime? nowUtc}) {
    final now = nowUtc ?? _clock.nowUtc();
    return dateOnly(now).add(const Duration(days: 1));
  }
}

class _FakeSettingsRepository implements SettingsRepositoryContract {
  _FakeSettingsRepository(this._settings);

  final StreamController<GlobalSettings> _controller =
      StreamController<GlobalSettings>.broadcast();
  GlobalSettings _settings;

  @override
  Future<T> load<T>(SettingsKey<T> key) async {
    if (key == SettingsKey.global) return _settings as T;
    throw UnsupportedError('Unsupported key: ${key.key}');
  }

  @override
  Future<void> save<T>(
    SettingsKey<T> key,
    T value, {
    OperationContext? context,
  }) async {
    if (key == SettingsKey.global) {
      _settings = value as GlobalSettings;
      _controller.add(_settings);
      return;
    }
    throw UnsupportedError('Unsupported key: ${key.key}');
  }

  @override
  Stream<T> watch<T>(SettingsKey<T> key) async* {
    if (key == SettingsKey.global) {
      yield _settings as T;
      yield* _controller.stream.cast<T>();
      return;
    }
    throw UnsupportedError('Unsupported key: ${key.key}');
  }
}

class _FakeMyDayRepository implements MyDayRepositoryContract {
  MyDayDayPicks day = MyDayDayPicks(
    dayKeyUtc: DateTime.utc(2026, 1, 1),
    ritualCompletedAtUtc: null,
    picks: const <MyDayPick>[],
  );

  @override
  Future<MyDayDayPicks> loadDay(DateTime dayKeyUtc) async {
    return day.copyWith(dayKeyUtc: dateOnly(dayKeyUtc));
  }

  @override
  Stream<MyDayDayPicks> watchDay(DateTime dayKeyUtc) =>
      Stream.value(day.copyWith(dayKeyUtc: dateOnly(dayKeyUtc)));

  @override
  Future<void> appendPick({
    required DateTime dayKeyUtc,
    required String taskId,
    required MyDayPickBucket bucket,
    required OperationContext context,
  }) async {}

  @override
  Future<void> clearDay({
    required DateTime dayKeyUtc,
    OperationContext? context,
  }) async {}

  @override
  Future<void> setDayPicks({
    required DateTime dayKeyUtc,
    required DateTime ritualCompletedAtUtc,
    required List<MyDayPick> picks,
    required OperationContext context,
  }) async {}
}

Future<void> _flushMicrotasks() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  testSafe('notifies once when reminder is due and no plan exists', () async {
    final clock = _MutableClock(DateTime.utc(2026, 1, 2, 0, 5));
    final settingsRepo = _FakeSettingsRepository(
      const GlobalSettings(
        homeTimeZoneOffsetMinutes: 0,
        planMyDayReminderEnabled: true,
        planMyDayReminderTimeMinutes: 0,
      ),
    );
    final myDayRepo = _FakeMyDayRepository();
    final dayKeyService = _FakeDayKeyService(clock);

    final lifecycleController = StreamController<AppLifecycleEvent>.broadcast();
    addTearDown(lifecycleController.close);
    final temporal = TemporalTriggerService(
      dayKeyService: dayKeyService,
      lifecycleService: _FakeLifecycleEvents(lifecycleController),
      clock: clock,
    )..start();
    addTearDown(temporal.stop);

    final presented = <PendingNotification>[];
    final service = PlanMyDayReminderService(
      settingsRepository: settingsRepo,
      myDayRepository: myDayRepo,
      homeDayKeyService: dayKeyService,
      temporalTriggerService: temporal,
      presenter: (notification) async {
        presented.add(notification);
      },
      clock: clock,
    );

    service.start();
    await _flushMicrotasks();

    expect(presented, hasLength(1));
    expect(presented.single.payload?['type'], 'plan_my_day_reminder');

    lifecycleController.add(AppLifecycleEvent.resumed);
    await _flushMicrotasks();
    expect(presented, hasLength(1));

    service.stop();
  });

  testSafe('does not notify when plan is already created', () async {
    final clock = _MutableClock(DateTime.utc(2026, 1, 2, 0, 10));
    final settingsRepo = _FakeSettingsRepository(
      const GlobalSettings(
        homeTimeZoneOffsetMinutes: 0,
        planMyDayReminderEnabled: true,
        planMyDayReminderTimeMinutes: 0,
      ),
    );
    final myDayRepo = _FakeMyDayRepository()
      ..day = MyDayDayPicks(
        dayKeyUtc: DateTime.utc(2026, 1, 2),
        ritualCompletedAtUtc: DateTime.utc(2026, 1, 2, 0, 1),
        picks: const <MyDayPick>[],
      );
    final dayKeyService = _FakeDayKeyService(clock);

    final lifecycleController = StreamController<AppLifecycleEvent>.broadcast();
    addTearDown(lifecycleController.close);
    final temporal = TemporalTriggerService(
      dayKeyService: dayKeyService,
      lifecycleService: _FakeLifecycleEvents(lifecycleController),
      clock: clock,
    )..start();
    addTearDown(temporal.stop);

    final presented = <PendingNotification>[];
    final service = PlanMyDayReminderService(
      settingsRepository: settingsRepo,
      myDayRepository: myDayRepo,
      homeDayKeyService: dayKeyService,
      temporalTriggerService: temporal,
      presenter: (notification) async {
        presented.add(notification);
      },
      clock: clock,
    );

    service.start();
    await _flushMicrotasks();

    expect(presented, isEmpty);
    service.stop();
  });
}
