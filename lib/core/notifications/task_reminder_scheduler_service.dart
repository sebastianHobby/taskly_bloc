import 'dart:async';

import 'package:taskly_bloc/core/notifications/scheduled_notification_sync_service.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/taskly_domain.dart';

class TaskReminderSchedulerService {
  TaskReminderSchedulerService({
    required TaskRepositoryContract taskRepository,
    required TemporalTriggerService temporalTriggerService,
    required ScheduledNotificationSyncService notificationSyncService,
    Clock clock = systemClock,
  }) : _taskRepository = taskRepository,
       _temporalTriggerService = temporalTriggerService,
       _notificationSyncService = notificationSyncService,
       _clock = clock;

  static const String namespace = 'task_reminder';

  final TaskRepositoryContract _taskRepository;
  final TemporalTriggerService _temporalTriggerService;
  final ScheduledNotificationSyncService _notificationSyncService;
  final Clock _clock;

  StreamSubscription<List<Task>>? _tasksSub;
  StreamSubscription<TemporalTriggerEvent>? _temporalSub;
  List<Task> _tasks = const <Task>[];
  Future<void> _refreshQueue = Future<void>.value();
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;

    _tasksSub = _taskRepository
        .watchAll(TaskQuery.incomplete())
        .listen(
          (tasks) {
            _tasks = tasks;
            _scheduleRefresh(source: 'tasks_changed');
          },
          onError: (Object error, StackTrace stackTrace) {
            AppLog.handleStructured(
              'notifications.task_scheduler',
              'task stream failed',
              error,
              stackTrace,
            );
          },
        );

    _temporalSub = _temporalTriggerService.events.listen(
      (_) => _scheduleRefresh(source: 'temporal_trigger'),
      onError: (Object error, StackTrace stackTrace) {
        AppLog.handleStructured(
          'notifications.task_scheduler',
          'temporal stream failed',
          error,
          stackTrace,
        );
      },
    );

    _scheduleRefresh(source: 'start');
  }

  Future<void> stop() async {
    if (!_started) return;
    _started = false;
    await _tasksSub?.cancel();
    _tasksSub = null;
    await _temporalSub?.cancel();
    _temporalSub = null;
    await _notificationSyncService.clearScheduledNotifications(
      namespace: namespace,
    );
  }

  void _scheduleRefresh({required String source}) {
    _refreshQueue = _refreshQueue
        .catchError((_) {})
        .then((_) => _refresh(source: source))
        .catchError((Object error, StackTrace stackTrace) {
          AppLog.handleStructured(
            'notifications.task_scheduler',
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

    final nowUtc = _clock.nowUtc();
    final notifications = <PendingNotification>[];
    for (final task in _tasks) {
      if (task.completed) continue;
      final notification = await _resolveNotification(
        task: task,
        nowUtc: nowUtc,
      );
      if (notification == null) continue;
      if (!notification.scheduledFor.isAfter(nowUtc)) continue;
      notifications.add(notification);
    }

    await _notificationSyncService.syncScheduledNotifications(
      namespace: namespace,
      notifications: notifications,
    );

    AppLog.infoStructured(
      'notifications.task_scheduler',
      'synchronized task reminders',
      fields: <String, Object?>{
        'count': notifications.length,
        'source': source,
      },
    );
  }

  Future<PendingNotification?> _resolveNotification({
    required Task task,
    required DateTime nowUtc,
  }) async {
    switch (task.reminderKind) {
      case TaskReminderKind.none:
        return null;
      case TaskReminderKind.absolute:
        final dueUtc = task.reminderAtUtc;
        if (dueUtc == null) return null;
        return _buildNotification(
          id: 'task_reminder_${task.id}_${dueUtc.toIso8601String()}',
          taskId: task.id,
          taskName: task.name,
          dueUtc: dueUtc,
          nowUtc: nowUtc,
        );
      case TaskReminderKind.beforeDue:
        final minutesBefore = task.reminderMinutesBeforeDue;
        if (minutesBefore == null || minutesBefore < 0) return null;

        final dueDateUtc = await _resolveReminderDueDateUtc(
          task: task,
          nowUtc: nowUtc,
        );
        if (dueDateUtc == null) return null;

        final dueUtc = dueDateUtc.subtract(Duration(minutes: minutesBefore));
        return _buildNotification(
          id: 'task_reminder_${task.id}_${dueUtc.toIso8601String()}_${dueDateUtc.toIso8601String()}',
          taskId: task.id,
          taskName: task.name,
          dueUtc: dueUtc,
          nowUtc: nowUtc,
        );
    }
  }

  Future<DateTime?> _resolveReminderDueDateUtc({
    required Task task,
    required DateTime nowUtc,
  }) async {
    if (!task.isRepeating || task.seriesEnded) {
      return task.deadlineDate;
    }

    final rangeStart = dateOnly(nowUtc);
    final rangeEnd = rangeStart.add(const Duration(days: 366));
    final occurrences = await _taskRepository.getOccurrencesForTask(
      taskId: task.id,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
    if (occurrences.isEmpty) return null;

    final sorted = occurrences.toList(growable: false)
      ..sort((a, b) {
        final aDate = a.occurrence?.date ?? a.startDate ?? a.deadlineDate;
        final bDate = b.occurrence?.date ?? b.startDate ?? b.deadlineDate;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return aDate.compareTo(bDate);
      });

    for (final occurrence in sorted) {
      final isCompleted =
          occurrence.occurrence?.isCompleted ?? occurrence.completed;
      if (isCompleted) continue;
      final deadlineUtc =
          occurrence.occurrence?.deadline ?? occurrence.deadlineDate;
      if (deadlineUtc != null) return deadlineUtc;
    }

    return null;
  }

  PendingNotification _buildNotification({
    required String id,
    required String taskId,
    required String taskName,
    required DateTime dueUtc,
    required DateTime nowUtc,
  }) {
    return PendingNotification(
      id: id,
      userId: null,
      screenKey: 'task',
      scheduledFor: dueUtc,
      status: 'pending',
      payload: <String, dynamic>{
        'type': 'task_reminder',
        'task_id': taskId,
        'name': taskName,
        'due_utc': dueUtc.toIso8601String(),
      },
      createdAt: nowUtc,
      deliveredAt: null,
      seenAt: null,
    );
  }
}
