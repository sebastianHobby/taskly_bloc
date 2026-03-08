@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/core/notifications/plan_my_day_reminder_scheduler_service.dart';
import 'package:taskly_bloc/core/notifications/scheduled_notification_sync_service.dart';
import 'package:taskly_bloc/core/notifications/task_reminder_scheduler_service.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/my_day.dart';
import 'package:taskly_domain/preferences.dart';
import 'package:taskly_domain/settings.dart';
import 'package:taskly_domain/taskly_domain.dart';

class _MutableClock implements Clock {
  _MutableClock(this._nowUtc);

  DateTime _nowUtc;

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
  DateTime todayDayKeyUtc({DateTime? nowUtc}) =>
      dateOnly(nowUtc ?? _clock.nowUtc());

  @override
  DateTime nextHomeDayBoundaryUtc({DateTime? nowUtc}) {
    final now = nowUtc ?? _clock.nowUtc();
    return dateOnly(now).add(const Duration(days: 1));
  }
}

class _MockTaskRepository extends Mock implements TaskRepositoryContract {}

class _RecordingScheduledNotificationSyncService
    implements ScheduledNotificationSyncService {
  final Map<String, List<PendingNotification>> syncedByNamespace =
      <String, List<PendingNotification>>{};
  final List<String> clearedNamespaces = <String>[];

  @override
  Future<void> clearScheduledNotifications({required String namespace}) async {
    clearedNamespaces.add(namespace);
    syncedByNamespace.remove(namespace);
  }

  @override
  Future<void> syncScheduledNotifications({
    required String namespace,
    required Iterable<PendingNotification> notifications,
  }) async {
    syncedByNamespace[namespace] = notifications.toList(growable: false);
  }
}

class _FakeSettingsRepository implements SettingsRepositoryContract {
  _FakeSettingsRepository(this._settings);

  final StreamController<GlobalSettings> _controller =
      StreamController<GlobalSettings>.broadcast();
  GlobalSettings _settings;

  Future<void> dispose() => _controller.close();

  @override
  Future<T> load<T>(SettingsKey<T> key) async {
    if (key == SettingsKey.global) return _settings as T;
    throw UnsupportedError('Unsupported key: $key');
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
    throw UnsupportedError('Unsupported key: $key');
  }

  @override
  Stream<T> watch<T>(SettingsKey<T> key) async* {
    if (key == SettingsKey.global) {
      yield _settings as T;
      yield* _controller.stream.cast<T>();
      return;
    }
    throw UnsupportedError('Unsupported key: $key');
  }
}

class _FakeMyDayRepository implements MyDayRepositoryContract {
  _FakeMyDayRepository({required this.today});

  final StreamController<MyDayDayPicks> _controller =
      StreamController<MyDayDayPicks>.broadcast();
  MyDayDayPicks today;

  Future<void> dispose() => _controller.close();

  @override
  Future<MyDayDayPicks> loadDay(DateTime dayKeyUtc) async {
    final normalized = dateOnly(dayKeyUtc);
    if (normalized.isAtSameMomentAs(dateOnly(today.dayKeyUtc))) {
      return today;
    }
    return MyDayDayPicks(
      dayKeyUtc: normalized,
      ritualCompletedAtUtc: null,
      picks: const <MyDayPick>[],
    );
  }

  @override
  Stream<MyDayDayPicks> watchDay(DateTime dayKeyUtc) async* {
    yield await loadDay(dayKeyUtc);
    yield* _controller.stream.where(
      (day) => dateOnly(day.dayKeyUtc).isAtSameMomentAs(dateOnly(dayKeyUtc)),
    );
  }

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

Task _task({
  required String id,
  required String name,
  required TaskReminderKind reminderKind,
  DateTime? reminderAtUtc,
  int? reminderMinutesBeforeDue,
  DateTime? deadlineDate,
  String? repeatIcalRrule,
}) {
  return Task(
    id: id,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
    name: name,
    completed: false,
    reminderKind: reminderKind,
    reminderAtUtc: reminderAtUtc,
    reminderMinutesBeforeDue: reminderMinutesBeforeDue,
    deadlineDate: deadlineDate,
    repeatIcalRrule: repeatIcalRrule,
  );
}

Future<void> _settle() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(const Duration(milliseconds: 20));
}

void main() {
  setUpAll(() {
    initializeLoggingForTest();
    registerFallbackValue(const TaskQuery());
  });

  testSafe('task scheduler syncs only future absolute reminders', () async {
    final clock = _MutableClock(DateTime.utc(2026, 1, 2, 9));
    final repository = _MockTaskRepository();
    final taskStream = StreamController<List<Task>>.broadcast();
    addTearDown(taskStream.close);

    when(() => repository.watchAll(any())).thenAnswer((_) => taskStream.stream);
    when(
      () => repository.getOccurrencesForTask(
        taskId: any(named: 'taskId'),
        rangeStart: any(named: 'rangeStart'),
        rangeEnd: any(named: 'rangeEnd'),
      ),
    ).thenAnswer((_) async => const <Task>[]);

    final lifecycleController = StreamController<AppLifecycleEvent>.broadcast();
    addTearDown(lifecycleController.close);
    final temporal = TemporalTriggerService(
      dayKeyService: _FakeDayKeyService(clock),
      lifecycleService: _FakeLifecycleEvents(lifecycleController),
      clock: clock,
    )..start();
    addTearDown(temporal.stop);

    final syncService = _RecordingScheduledNotificationSyncService();
    final service = TaskReminderSchedulerService(
      taskRepository: repository,
      temporalTriggerService: temporal,
      notificationSyncService: syncService,
      clock: clock,
    );
    addTearDown(service.stop);

    service.start();
    taskStream.add(<Task>[
      _task(
        id: 'future-task',
        name: 'Future reminder',
        reminderKind: TaskReminderKind.absolute,
        reminderAtUtc: DateTime.utc(2026, 1, 2, 9, 15),
      ),
      _task(
        id: 'past-task',
        name: 'Past reminder',
        reminderKind: TaskReminderKind.absolute,
        reminderAtUtc: DateTime.utc(2026, 1, 2, 8, 45),
      ),
    ]);
    await _settle();

    final synced =
        syncService.syncedByNamespace[TaskReminderSchedulerService.namespace] ??
        const <PendingNotification>[];

    expect(synced, hasLength(1));
    expect(synced.single.payload?['task_id'], 'future-task');
    expect(synced.single.payload?['type'], 'task_reminder');
    expect(
      synced.single.scheduledFor,
      DateTime.utc(2026, 1, 2, 9, 15),
    );
  });

  testSafe(
    'plan my day scheduler skips today when ritual is already complete',
    () async {
      final clock = _MutableClock(DateTime.utc(2026, 1, 2, 0, 30));
      final settingsRepository = _FakeSettingsRepository(
        const GlobalSettings(
          homeTimeZoneOffsetMinutes: 0,
          planMyDayReminderEnabled: true,
          planMyDayReminderTimeMinutes: 60,
        ),
      );
      addTearDown(settingsRepository.dispose);

      final myDayRepository = _FakeMyDayRepository(
        today: MyDayDayPicks(
          dayKeyUtc: DateTime.utc(2026, 1, 2),
          ritualCompletedAtUtc: DateTime.utc(2026, 1, 2, 0, 5),
          picks: const <MyDayPick>[],
        ),
      );
      addTearDown(myDayRepository.dispose);

      final lifecycleController =
          StreamController<AppLifecycleEvent>.broadcast();
      addTearDown(lifecycleController.close);
      final temporal = TemporalTriggerService(
        dayKeyService: _FakeDayKeyService(clock),
        lifecycleService: _FakeLifecycleEvents(lifecycleController),
        clock: clock,
      )..start();
      addTearDown(temporal.stop);

      final syncService = _RecordingScheduledNotificationSyncService();
      final service = PlanMyDayReminderSchedulerService(
        settingsRepository: settingsRepository,
        myDayRepository: myDayRepository,
        homeDayKeyService: _FakeDayKeyService(clock),
        temporalTriggerService: temporal,
        notificationSyncService: syncService,
        clock: clock,
        windowDays: 3,
      );
      addTearDown(service.stop);

      service.start();
      await _settle();

      final synced =
          syncService.syncedByNamespace[PlanMyDayReminderSchedulerService
              .namespace] ??
          const <PendingNotification>[];

      expect(synced, hasLength(2));
      expect(
        synced.map((notification) => notification.payload?['day_key_utc']),
        <String>[
          DateTime.utc(2026, 1, 3).toIso8601String(),
          DateTime.utc(2026, 1, 4).toIso8601String(),
        ],
      );
      expect(
        synced.map((notification) => notification.scheduledFor),
        <DateTime>[
          DateTime.utc(2026, 1, 3, 1),
          DateTime.utc(2026, 1, 4, 1),
        ],
      );
    },
  );
}
