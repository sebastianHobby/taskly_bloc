import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_domain/src/core/model/task.dart';
import 'package:taskly_domain/src/interfaces/task_repository_contract.dart';
import 'package:taskly_domain/src/notifications/model/pending_notification.dart';
import 'package:taskly_domain/src/queries/task_query.dart';
import 'package:taskly_domain/src/services/notifications/notification_presenter.dart';
import 'package:taskly_domain/src/services/time/temporal_trigger_service.dart';
import 'package:taskly_domain/src/time/clock.dart';
import 'package:taskly_domain/src/time/date_only.dart';

/// Triggers task reminders based on each task's reminder configuration.
///
/// Supported reminder modes:
/// - [TaskReminderKind.absolute]
/// - [TaskReminderKind.beforeDue]
///
/// Repeating tasks resolve "before due" reminders against the next active
/// occurrence only.
class TaskReminderService {
  TaskReminderService({
    required TaskRepositoryContract taskRepository,
    required TemporalTriggerService temporalTriggerService,
    required NotificationPresenter presenter,
    Clock clock = systemClock,
    bool Function()? supportsReminderPlatform,
  }) : _taskRepository = taskRepository,
       _temporalTriggerService = temporalTriggerService,
       _presenter = presenter,
       _clock = clock,
       _supportsReminderPlatform =
           supportsReminderPlatform ?? _defaultSupportsReminderPlatform;

  final TaskRepositoryContract _taskRepository;
  final TemporalTriggerService _temporalTriggerService;
  final NotificationPresenter _presenter;
  final Clock _clock;
  final bool Function() _supportsReminderPlatform;

  StreamSubscription<List<Task>>? _tasksSub;
  StreamSubscription<TemporalTriggerEvent>? _temporalSub;
  Timer? _timer;

  List<Task> _tasks = const <Task>[];
  final Set<String> _deliveredKeys = <String>{};
  Future<void> _evaluationQueue = Future<void>.value();
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;

    if (!_supportsReminderPlatform()) {
      AppLog.info(
        'notifications.task_reminders',
        'task reminders disabled on this platform',
      );
      return;
    }

    _tasksSub = _taskRepository
        .watchAll(TaskQuery.incomplete())
        .listen(
          (tasks) {
            _tasks = tasks;
            _pruneDeliveredKeys(activeTasks: tasks);
            _scheduleEvaluation(source: 'tasks_changed');
          },
          onError: (Object error, StackTrace stackTrace) {
            AppLog.handleStructured(
              'notifications.task_reminders',
              'task stream failed',
              error,
              stackTrace,
            );
          },
        );

    _temporalSub = _temporalTriggerService.events.listen(
      (_) => _scheduleEvaluation(source: 'temporal_trigger'),
      onError: (Object error, StackTrace stackTrace) {
        AppLog.handleStructured(
          'notifications.task_reminders',
          'temporal trigger stream failed',
          error,
          stackTrace,
        );
      },
    );

    _scheduleEvaluation(source: 'start');
  }

  void stop() {
    if (!_started) return;
    _started = false;
    _timer?.cancel();
    _timer = null;
    _tasksSub?.cancel();
    _tasksSub = null;
    _temporalSub?.cancel();
    _temporalSub = null;
  }

  Future<void> _evaluateAndNotify({required String source}) async {
    if (!_started || !_supportsReminderPlatform()) return;

    final nowUtc = _clock.nowUtc();
    final candidates = await _buildCandidates(nowUtc);
    final dueNow =
        candidates
            .where((candidate) => !candidate.dueUtc.isAfter(nowUtc))
            .toList(growable: false)
          ..sort((a, b) => a.dueUtc.compareTo(b.dueUtc));

    for (final candidate in dueNow) {
      if (_deliveredKeys.contains(candidate.key)) continue;

      await _presenter(candidate.notification(nowUtc: nowUtc));
      _deliveredKeys.add(candidate.key);
      AppLog.info(
        'notifications.task_reminders',
        'delivered task=${candidate.taskId} due=${candidate.dueUtc.toIso8601String()} source=$source',
      );
    }

    final nextDue = _nextDueAfter(candidates, nowUtc);
    _scheduleNextTick(nextDue);
  }

  Future<List<_ReminderCandidate>> _buildCandidates(DateTime nowUtc) async {
    final candidates = <_ReminderCandidate>[];
    for (final task in _tasks) {
      if (task.completed) continue;
      final candidate = await _resolveCandidate(task: task, nowUtc: nowUtc);
      if (candidate == null) continue;
      candidates.add(candidate);
    }
    return candidates;
  }

  Future<_ReminderCandidate?> _resolveCandidate({
    required Task task,
    required DateTime nowUtc,
  }) async {
    switch (task.reminderKind) {
      case TaskReminderKind.none:
        return null;
      case TaskReminderKind.absolute:
        final dueUtc = task.reminderAtUtc;
        if (dueUtc == null) return null;
        return _ReminderCandidate(
          taskId: task.id,
          taskName: task.name,
          dueUtc: dueUtc,
          key: _deliveryKey(
            taskId: task.id,
            reminderKind: TaskReminderKind.absolute,
            dueUtc: dueUtc,
          ),
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
        return _ReminderCandidate(
          taskId: task.id,
          taskName: task.name,
          dueUtc: dueUtc,
          key: _deliveryKey(
            taskId: task.id,
            reminderKind: TaskReminderKind.beforeDue,
            dueUtc: dueUtc,
            dueDateUtc: dueDateUtc,
          ),
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

  DateTime? _nextDueAfter(
    List<_ReminderCandidate> candidates,
    DateTime nowUtc,
  ) {
    DateTime? next;
    for (final candidate in candidates) {
      if (!candidate.dueUtc.isAfter(nowUtc)) continue;
      if (next == null || candidate.dueUtc.isBefore(next)) {
        next = candidate.dueUtc;
      }
    }
    return next;
  }

  void _scheduleNextTick(DateTime? nextDueUtc) {
    _timer?.cancel();
    _timer = null;
    if (!_started || !_supportsReminderPlatform() || nextDueUtc == null) return;

    final nowUtc = _clock.nowUtc();
    final delay = nextDueUtc.difference(nowUtc);
    _timer = Timer(
      delay.isNegative ? Duration.zero : delay,
      () => _scheduleEvaluation(source: 'timer'),
    );
  }

  void _scheduleEvaluation({required String source}) {
    _evaluationQueue = _evaluationQueue
        .catchError((_) {
          // Keep queue alive after failures.
        })
        .then((_) => _evaluateAndNotify(source: source))
        .catchError((Object error, StackTrace stackTrace) {
          AppLog.handleStructured(
            'notifications.task_reminders',
            'evaluation failed',
            error,
            stackTrace,
            <String, Object?>{'source': source},
          );
        });
    unawaited(_evaluationQueue);
  }

  void _pruneDeliveredKeys({required List<Task> activeTasks}) {
    final activeIds = activeTasks.map((task) => task.id).toSet();
    _deliveredKeys.removeWhere((key) {
      final splitIndex = key.indexOf('|');
      if (splitIndex <= 0) return true;
      final taskId = key.substring(0, splitIndex);
      return !activeIds.contains(taskId);
    });
  }

  static String _deliveryKey({
    required String taskId,
    required TaskReminderKind reminderKind,
    required DateTime dueUtc,
    DateTime? dueDateUtc,
  }) {
    final suffix = dueDateUtc == null ? '' : '|${dueDateUtc.toIso8601String()}';
    return '$taskId|${reminderKind.name}|${dueUtc.toIso8601String()}$suffix';
  }

  static bool _defaultSupportsReminderPlatform() {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }
}

final class _ReminderCandidate {
  const _ReminderCandidate({
    required this.taskId,
    required this.taskName,
    required this.dueUtc,
    required this.key,
  });

  final String taskId;
  final String taskName;
  final DateTime dueUtc;
  final String key;

  PendingNotification notification({required DateTime nowUtc}) {
    return PendingNotification(
      id: 'task_reminder_${taskId}_${dueUtc.toIso8601String()}',
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
