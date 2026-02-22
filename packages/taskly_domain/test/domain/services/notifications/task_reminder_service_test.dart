@Tags(['unit'])
library;

import '../../../helpers/test_imports.dart';

import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/notifications.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/services.dart';
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
  DateTime todayDayKeyUtc({DateTime? nowUtc}) =>
      dateOnly(nowUtc ?? _clock.nowUtc());

  @override
  DateTime nextHomeDayBoundaryUtc({DateTime? nowUtc}) {
    final now = nowUtc ?? _clock.nowUtc();
    return dateOnly(now).add(const Duration(days: 1));
  }
}

class _MockTaskRepository extends Mock implements TaskRepositoryContract {}

Future<void> _flushMicrotasks() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
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

void main() {
  setUpAll(() {
    initializeLoggingForTest();
    registerFallbackValue(const TaskQuery());
  });

  testSafe('delivers absolute reminder once when due', () async {
    final clock = _MutableClock(DateTime.utc(2026, 1, 2, 9, 0));
    final repository = _MockTaskRepository();
    final taskStream = StreamController<List<Task>>.broadcast();
    addTearDown(taskStream.close);

    when(() => repository.watchAll(TaskQuery.incomplete())).thenAnswer(
      (_) => taskStream.stream,
    );
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

    final presented = <PendingNotification>[];
    final service = TaskReminderService(
      taskRepository: repository,
      temporalTriggerService: temporal,
      presenter: (notification) async => presented.add(notification),
      clock: clock,
      supportsReminderPlatform: () => true,
    );

    service.start();
    taskStream.add([
      _task(
        id: 'task-1',
        name: 'Reminder',
        reminderKind: TaskReminderKind.absolute,
        reminderAtUtc: DateTime.utc(2026, 1, 2, 8, 55),
      ),
    ]);
    await _flushMicrotasks();

    expect(presented, hasLength(1));
    expect(presented.single.payload?['type'], 'task_reminder');
    expect(presented.single.payload?['task_id'], 'task-1');

    lifecycleController.add(AppLifecycleEvent.resumed);
    await _flushMicrotasks();

    expect(presented, hasLength(1));
    service.stop();
  });

  testSafe(
    'does not deliver before-due reminder when task has no due date',
    () async {
      final clock = _MutableClock(DateTime.utc(2026, 1, 2, 9, 0));
      final repository = _MockTaskRepository();
      final taskStream = StreamController<List<Task>>.broadcast();
      addTearDown(taskStream.close);

      when(() => repository.watchAll(TaskQuery.incomplete())).thenAnswer(
        (_) => taskStream.stream,
      );
      when(
        () => repository.getOccurrencesForTask(
          taskId: any(named: 'taskId'),
          rangeStart: any(named: 'rangeStart'),
          rangeEnd: any(named: 'rangeEnd'),
        ),
      ).thenAnswer((_) async => const <Task>[]);

      final lifecycleController =
          StreamController<AppLifecycleEvent>.broadcast();
      addTearDown(lifecycleController.close);
      final temporal = TemporalTriggerService(
        dayKeyService: _FakeDayKeyService(clock),
        lifecycleService: _FakeLifecycleEvents(lifecycleController),
        clock: clock,
      )..start();
      addTearDown(temporal.stop);

      final presented = <PendingNotification>[];
      final service = TaskReminderService(
        taskRepository: repository,
        temporalTriggerService: temporal,
        presenter: (notification) async => presented.add(notification),
        clock: clock,
        supportsReminderPlatform: () => true,
      );

      service.start();
      taskStream.add([
        _task(
          id: 'task-2',
          name: 'No due',
          reminderKind: TaskReminderKind.beforeDue,
          reminderMinutesBeforeDue: 30,
        ),
      ]);
      await _flushMicrotasks();

      expect(presented, isEmpty);
      service.stop();
    },
  );

  testSafe(
    'resolves before-due reminder for next active recurring occurrence',
    () async {
      final clock = _MutableClock(DateTime.utc(2026, 1, 2, 9, 0));
      final repository = _MockTaskRepository();
      final taskStream = StreamController<List<Task>>.broadcast();
      addTearDown(taskStream.close);

      when(() => repository.watchAll(TaskQuery.incomplete())).thenAnswer(
        (_) => taskStream.stream,
      );
      when(
        () => repository.getOccurrencesForTask(
          taskId: 'task-r',
          rangeStart: any(named: 'rangeStart'),
          rangeEnd: any(named: 'rangeEnd'),
        ),
      ).thenAnswer(
        (_) async => [
          _task(
            id: 'task-r',
            name: 'Recurring',
            reminderKind: TaskReminderKind.beforeDue,
            reminderMinutesBeforeDue: 30,
            repeatIcalRrule: 'FREQ=DAILY',
          ).copyWith(
            occurrence: OccurrenceData(
              date: DateTime.utc(2026, 1, 2),
              deadline: DateTime.utc(2026, 1, 2, 9, 15),
              isRescheduled: false,
              completionId: 'done',
              completedAt: DateTime.utc(2026, 1, 2, 9, 10),
            ),
          ),
          _task(
            id: 'task-r',
            name: 'Recurring',
            reminderKind: TaskReminderKind.beforeDue,
            reminderMinutesBeforeDue: 30,
            repeatIcalRrule: 'FREQ=DAILY',
          ).copyWith(
            occurrence: OccurrenceData(
              date: DateTime.utc(2026, 1, 3),
              deadline: DateTime.utc(2026, 1, 2, 9, 25),
              isRescheduled: false,
            ),
          ),
        ],
      );

      final lifecycleController =
          StreamController<AppLifecycleEvent>.broadcast();
      addTearDown(lifecycleController.close);
      final temporal = TemporalTriggerService(
        dayKeyService: _FakeDayKeyService(clock),
        lifecycleService: _FakeLifecycleEvents(lifecycleController),
        clock: clock,
      )..start();
      addTearDown(temporal.stop);

      final presented = <PendingNotification>[];
      final service = TaskReminderService(
        taskRepository: repository,
        temporalTriggerService: temporal,
        presenter: (notification) async => presented.add(notification),
        clock: clock,
        supportsReminderPlatform: () => true,
      );

      service.start();
      taskStream.add([
        _task(
          id: 'task-r',
          name: 'Recurring',
          reminderKind: TaskReminderKind.beforeDue,
          reminderMinutesBeforeDue: 30,
          repeatIcalRrule: 'FREQ=DAILY',
        ),
      ]);
      await _flushMicrotasks();

      expect(presented, hasLength(1));
      expect(presented.single.payload?['task_id'], 'task-r');
      service.stop();
    },
  );
}
