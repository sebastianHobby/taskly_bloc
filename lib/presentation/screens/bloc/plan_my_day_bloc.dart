import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter/foundation.dart';
import 'package:taskly_bloc/presentation/shared/telemetry/operation_context_factory.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/my_day.dart' as my_day;
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/preferences.dart';
import 'package:taskly_domain/settings.dart' as settings;
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/time.dart';

sealed class PlanMyDayEvent {
  const PlanMyDayEvent();
}

final class PlanMyDayStarted extends PlanMyDayEvent {
  const PlanMyDayStarted();
}

final class PlanMyDayToggleTask extends PlanMyDayEvent {
  const PlanMyDayToggleTask(this.taskId, {required this.selected});

  final String taskId;
  final bool selected;
}

final class PlanMyDayDueWindowDaysChanged extends PlanMyDayEvent {
  const PlanMyDayDueWindowDaysChanged(this.days);

  final int days;
}

final class PlanMyDayDueSoonEnabledChanged extends PlanMyDayEvent {
  const PlanMyDayDueSoonEnabledChanged(this.enabled);

  final bool enabled;
}

final class PlanMyDayShowAvailableToStartChanged extends PlanMyDayEvent {
  const PlanMyDayShowAvailableToStartChanged(this.enabled);

  final bool enabled;
}

final class PlanMyDayConfirm extends PlanMyDayEvent {
  const PlanMyDayConfirm({this.closeOnSuccess = false});

  final bool closeOnSuccess;
}

final class PlanMyDaySnoozeTaskRequested extends PlanMyDayEvent {
  const PlanMyDaySnoozeTaskRequested({
    required this.taskId,
    required this.untilUtc,
  });

  final String taskId;
  final DateTime? untilUtc;
}

final class PlanMyDayMoreSuggestionsRequested extends PlanMyDayEvent {
  const PlanMyDayMoreSuggestionsRequested();
}

enum PlanMyDayAppendBucket {
  due,
  starts,
  focus,
}

final class PlanMyDayAppendToToday extends PlanMyDayEvent {
  const PlanMyDayAppendToToday({required this.bucket, required this.taskId});

  final PlanMyDayAppendBucket bucket;
  final String taskId;
}

sealed class PlanMyDayState {
  const PlanMyDayState();
}

final class PlanMyDayLoading extends PlanMyDayState {
  const PlanMyDayLoading();
}

enum PlanMyDayNav {
  closePage,
}

@immutable
final class PlanMyDayReady extends PlanMyDayState {
  const PlanMyDayReady({
    required this.needsPlan,
    required this.dueWindowDays,
    required this.showAvailableToStart,
    required this.showDueSoon,
    required this.suggested,
    required this.reviewDue,
    required this.reviewStarts,
    required this.pinnedTasks,
    required this.snoozed,
    required this.completedPicks,
    required this.selectedTaskIds,
    required this.dayKeyUtc,
    this.nav,
    this.navRequestId = 0,
  });

  final bool needsPlan;
  final int dueWindowDays;
  final bool showAvailableToStart;
  final bool showDueSoon;
  final List<Task> suggested;
  final List<Task> reviewDue;
  final List<Task> reviewStarts;
  final List<Task> pinnedTasks;
  final List<Task> snoozed;
  final List<Task> completedPicks;
  final Set<String> selectedTaskIds;
  final DateTime dayKeyUtc;
  final PlanMyDayNav? nav;
  final int navRequestId;

  PlanMyDayReady copyWith({
    bool? needsPlan,
    int? dueWindowDays,
    bool? showAvailableToStart,
    bool? showDueSoon,
    List<Task>? suggested,
    List<Task>? reviewDue,
    List<Task>? reviewStarts,
    List<Task>? pinnedTasks,
    List<Task>? snoozed,
    List<Task>? completedPicks,
    Set<String>? selectedTaskIds,
    DateTime? dayKeyUtc,
    PlanMyDayNav? nav,
    int? navRequestId,
  }) {
    return PlanMyDayReady(
      needsPlan: needsPlan ?? this.needsPlan,
      dueWindowDays: dueWindowDays ?? this.dueWindowDays,
      showAvailableToStart: showAvailableToStart ?? this.showAvailableToStart,
      showDueSoon: showDueSoon ?? this.showDueSoon,
      suggested: suggested ?? this.suggested,
      reviewDue: reviewDue ?? this.reviewDue,
      reviewStarts: reviewStarts ?? this.reviewStarts,
      pinnedTasks: pinnedTasks ?? this.pinnedTasks,
      snoozed: snoozed ?? this.snoozed,
      completedPicks: completedPicks ?? this.completedPicks,
      selectedTaskIds: selectedTaskIds ?? this.selectedTaskIds,
      dayKeyUtc: dayKeyUtc ?? this.dayKeyUtc,
      nav: nav ?? this.nav,
      navRequestId: navRequestId ?? this.navRequestId,
    );
  }
}

class PlanMyDayBloc extends Bloc<PlanMyDayEvent, PlanMyDayState> {
  PlanMyDayBloc({
    required SettingsRepositoryContract settingsRepository,
    required MyDayRepositoryContract myDayRepository,
    required TaskSuggestionService taskSuggestionService,
    required TaskRepositoryContract taskRepository,
    required HomeDayKeyService dayKeyService,
    required TemporalTriggerService temporalTriggerService,
    required NowService nowService,
  }) : _settingsRepository = settingsRepository,
       _myDayRepository = myDayRepository,
       _taskSuggestionService = taskSuggestionService,
       _taskRepository = taskRepository,
       _dayKeyService = dayKeyService,
       _temporalTriggerService = temporalTriggerService,
       _nowService = nowService,
       _dayKeyUtc = dayKeyService.todayDayKeyUtc(),
       super(const PlanMyDayLoading()) {
    on<PlanMyDayStarted>(_onStarted, transformer: restartable());
    on<PlanMyDayToggleTask>(_onToggleTask);
    on<PlanMyDayDueWindowDaysChanged>(_onDueWindowDaysChanged);
    on<PlanMyDayDueSoonEnabledChanged>(_onDueSoonEnabledChanged);
    on<PlanMyDayShowAvailableToStartChanged>(
      _onShowAvailableToStartChanged,
    );
    on<PlanMyDayConfirm>(_onConfirm);
    on<PlanMyDaySnoozeTaskRequested>(_onSnoozeTaskRequested);
    on<PlanMyDayAppendToToday>(_onAppendToToday);
    on<PlanMyDayMoreSuggestionsRequested>(_onMoreSuggestionsRequested);
    on<_PlanMyDayInputsChanged>(_onInputsChanged);
    add(const PlanMyDayStarted());
  }

  bool? _lastObservedNeedsPlan;

  final SettingsRepositoryContract _settingsRepository;
  final MyDayRepositoryContract _myDayRepository;
  final TaskSuggestionService _taskSuggestionService;
  final TaskRepositoryContract _taskRepository;
  final HomeDayKeyService _dayKeyService;
  final TemporalTriggerService _temporalTriggerService;
  final NowService _nowService;
  final OperationContextFactory _contextFactory =
      const OperationContextFactory();

  StreamSubscription? _daySub;

  TaskSuggestionSnapshot? _suggestionSnapshot;
  List<Task> _tasks = const <Task>[];
  late my_day.MyDayDayPicks _dayPicks;
  settings.GlobalSettings _globalSettings = const settings.GlobalSettings();
  DateTime _dayKeyUtc;

  int _suggestionBatchCount = 1;
  List<Task> _completedPicks = const <Task>[];
  Set<String> _lockedCompletedPickIds = const <String>{};

  Completer<void>? _refreshCompleter;

  bool _hasUserSelection = false;
  Set<String> _selectedTaskIds = <String>{};

  @override
  Future<void> close() async {
    await _daySub?.cancel();
    return super.close();
  }

  Future<void> _onStarted(
    PlanMyDayStarted event,
    Emitter<PlanMyDayState> emit,
  ) async {
    _dayKeyUtc = _dayKeyService.todayDayKeyUtc();
    _suggestionBatchCount = 1;
    _completedPicks = const <Task>[];
    _lockedCompletedPickIds = const <String>{};
    _dayPicks = my_day.MyDayDayPicks(
      dayKeyUtc: dateOnly(_dayKeyUtc),
      ritualCompletedAtUtc: null,
      picks: const <my_day.MyDayPick>[],
    );

    await _daySub?.cancel();

    emit(const PlanMyDayLoading());
    await _refreshSnapshots(resetSelection: true);
    add(const _PlanMyDayInputsChanged());

    _daySub = _temporalTriggerService.events
        .where((e) => e is HomeDayBoundaryCrossed || e is AppResumed)
        .listen((event) async {
          final nextDay = _dayKeyService.todayDayKeyUtc();
          final isDayChange = !_isSameDayUtc(nextDay, _dayKeyUtc);

          if (isDayChange) {
            _dayKeyUtc = nextDay;
            await _refreshSnapshots(resetSelection: true);
            add(const _PlanMyDayInputsChanged());
            return;
          }

          // Optional refresh on app resume, but avoid clobbering in-progress
          // plan selection.
          if (event is AppResumed && !_hasUserSelection) {
            await _refreshSnapshots(resetSelection: false);
            add(const _PlanMyDayInputsChanged());
          }
        });
  }

  Future<void> _onDueWindowDaysChanged(
    PlanMyDayDueWindowDaysChanged event,
    Emitter<PlanMyDayState> emit,
  ) async {
    final clamped = event.days.clamp(1, 30);
    if (clamped == _globalSettings.myDayDueWindowDays) return;

    final updated = _globalSettings.copyWith(myDayDueWindowDays: clamped);
    await _settingsRepository.save(SettingsKey.global, updated);
  }

  Future<void> _onDueSoonEnabledChanged(
    PlanMyDayDueSoonEnabledChanged event,
    Emitter<PlanMyDayState> emit,
  ) async {
    if (event.enabled == _globalSettings.myDayDueSoonEnabled) return;

    final updated = _globalSettings.copyWith(
      myDayDueSoonEnabled: event.enabled,
    );
    await _settingsRepository.save(SettingsKey.global, updated);
  }

  Future<void> _onShowAvailableToStartChanged(
    PlanMyDayShowAvailableToStartChanged event,
    Emitter<PlanMyDayState> emit,
  ) async {
    if (event.enabled == _globalSettings.myDayShowAvailableToStart) return;

    final updated = _globalSettings.copyWith(
      myDayShowAvailableToStart: event.enabled,
    );
    await _settingsRepository.save(SettingsKey.global, updated);
  }

  Future<void> _refreshSnapshots({required bool resetSelection}) async {
    final inFlight = _refreshCompleter;
    if (inFlight != null) {
      await inFlight.future;
      return;
    }
    final completer = Completer<void>();
    _refreshCompleter = completer;

    if (resetSelection) {
      _hasUserSelection = false;
      _selectedTaskIds = <String>{};
      _suggestionBatchCount = 1;
    }

    try {
      final results = await Future.wait([
        _settingsRepository.load<settings.GlobalSettings>(SettingsKey.global),
        _myDayRepository.loadDay(_dayKeyUtc),
        _taskRepository.getAll(TaskQuery.incomplete()),
      ]);

      _globalSettings = results[0] as settings.GlobalSettings;

      final picks = results[1] as my_day.MyDayDayPicks;
      final before = _dayPicks.ritualCompletedAtUtc;
      _dayPicks = picks;
      if (before != _dayPicks.ritualCompletedAtUtc) {}

      final incompleteTasks = results[2] as List<Task>;

      final pickedIds = _dayPicks.picks.map((p) => p.taskId).toSet();
      final incompleteIds = incompleteTasks.map((t) => t.id).toSet();
      final missingPickIds = pickedIds.difference(incompleteIds);

      final missingPickTasks = missingPickIds.isEmpty
          ? const <Task>[]
          : await _taskRepository.getByIds(missingPickIds);

      _completedPicks = missingPickTasks
          .where((t) => t.completed)
          .toList(growable: false);

      _lockedCompletedPickIds = Set.unmodifiable(
        _completedPicks.map((t) => t.id),
      );

      _tasks = [...incompleteTasks, ...missingPickTasks];

      _suggestionSnapshot = await _taskSuggestionService.getSnapshot(
        dueWindowDays: _globalSettings.myDayDueWindowDays,
        includeDueSoon: _globalSettings.myDayDueSoonEnabled,
        includeAvailableToStart: _globalSettings.myDayShowAvailableToStart,
        batchCount: _suggestionBatchCount,
        tasksOverride: incompleteTasks,
      );
    } finally {
      _refreshCompleter = null;
      completer.complete();
    }
  }

  void _onInputsChanged(
    _PlanMyDayInputsChanged event,
    Emitter<PlanMyDayState> emit,
  ) {
    final snapshot = _suggestionSnapshot;
    final suggested = snapshot == null
        ? const <Task>[]
        : snapshot.suggested.map((entry) => entry.task).toList(growable: false);
    final reviewDue = snapshot?.dueSoonNotSuggested ?? const <Task>[];
    final reviewStarts =
        snapshot?.availableToStartNotSuggested ?? const <Task>[];
    final snoozedRaw = snapshot?.snoozed ?? const <Task>[];
    final snoozed = [...snoozedRaw]
      ..sort(
        (a, b) => a.myDaySnoozedUntilUtc!.compareTo(b.myDaySnoozedUntilUtc!),
      );
    final snoozedIds = snoozed.map((t) => t.id).toSet();

    final pinnedTasks = _tasks
        .where(
          (t) => !t.completed && t.isPinned && !snoozedIds.contains(t.id),
        )
        .toList(growable: false);

    if (!_hasUserSelection) {
      final selectableIds = <String>{
        for (final task in suggested) task.id,
        for (final task in reviewDue) task.id,
        for (final task in reviewStarts) task.id,
      };
      _selectedTaskIds = _dayPicks.ritualCompletedAtUtc == null
          ? <String>{}
          : _dayPicks.selectedTaskIds.intersection(selectableIds);
    }

    final needsPlan = _dayPicks.ritualCompletedAtUtc == null;

    final previousNeedsPlan = _lastObservedNeedsPlan;
    if (previousNeedsPlan == null || previousNeedsPlan != needsPlan) {
      _lastObservedNeedsPlan = needsPlan;
    }

    emit(
      PlanMyDayReady(
        needsPlan: needsPlan,
        dueWindowDays: _globalSettings.myDayDueWindowDays,
        showAvailableToStart: _globalSettings.myDayShowAvailableToStart,
        showDueSoon: _globalSettings.myDayDueSoonEnabled,
        suggested: suggested,
        reviewDue: reviewDue,
        reviewStarts: reviewStarts,
        pinnedTasks: pinnedTasks,
        snoozed: snoozed,
        completedPicks: _completedPicks,
        selectedTaskIds: _selectedTaskIds,
        dayKeyUtc: _dayKeyUtc,
        nav: null,
      ),
    );
  }

  void _onToggleTask(
    PlanMyDayToggleTask event,
    Emitter<PlanMyDayState> emit,
  ) {
    if (state is! PlanMyDayReady) return;

    // Completed picks are locked for the day (they remain in the plan/history).
    if (!event.selected && _lockedCompletedPickIds.contains(event.taskId)) {
      return;
    }

    _hasUserSelection = true;
    if (event.selected) {
      _selectedTaskIds = {..._selectedTaskIds, event.taskId};
    } else {
      _selectedTaskIds = {..._selectedTaskIds}..remove(event.taskId);
    }
    emit(
      (state as PlanMyDayReady).copyWith(selectedTaskIds: _selectedTaskIds),
    );
  }

  Future<void> _onConfirm(
    PlanMyDayConfirm event,
    Emitter<PlanMyDayState> emit,
  ) async {
    if (state is! PlanMyDayReady) return;
    final current = state as PlanMyDayReady;

    final suggested = current.suggested;
    final reviewDue = current.reviewDue;
    final reviewStarts = current.reviewStarts;
    final selectedIds = _selectedTaskIds;

    if (selectedIds.isEmpty && !event.closeOnSuccess) return;

    final ordered = <String>[];
    for (final task in suggested) {
      if (selectedIds.contains(task.id)) ordered.add(task.id);
    }
    for (final task in reviewDue) {
      if (selectedIds.contains(task.id) && !ordered.contains(task.id)) {
        ordered.add(task.id);
      }
    }
    for (final task in reviewStarts) {
      if (selectedIds.contains(task.id) && !ordered.contains(task.id)) {
        ordered.add(task.id);
      }
    }
    for (final id in selectedIds) {
      if (!ordered.contains(id)) ordered.add(id);
    }

    final dueSelectedIds = {
      for (final task in reviewDue)
        if (selectedIds.contains(task.id)) task.id,
    };
    final startsSelectedIds = {
      for (final task in reviewStarts)
        if (selectedIds.contains(task.id)) task.id,
    };
    final focusSelectedIds = {
      for (final task in suggested)
        if (selectedIds.contains(task.id)) task.id,
    };

    final nowUtc = _nowService.nowUtc();
    final tasksById = {for (final task in _tasks) task.id: task};

    final suggestedById = <String, SuggestedTask>{
      for (final entry
          in _suggestionSnapshot?.suggested ?? const <SuggestedTask>[])
        entry.task.id: entry,
    };

    my_day.MyDayPickBucket bucketForTaskId(String taskId) {
      if (focusSelectedIds.contains(taskId)) {
        return my_day.MyDayPickBucket.focus;
      }
      if (dueSelectedIds.contains(taskId)) return my_day.MyDayPickBucket.due;
      if (startsSelectedIds.contains(taskId)) {
        return my_day.MyDayPickBucket.starts;
      }
      return my_day.MyDayPickBucket.planned;
    }

    final picks = <my_day.MyDayPick>[];
    for (var i = 0; i < ordered.length; i++) {
      final taskId = ordered[i];
      final bucket = bucketForTaskId(taskId);

      final suggestedInfo = suggestedById[taskId];
      final task = tasksById[taskId];

      final qualifyingValueId = switch (bucket) {
        my_day.MyDayPickBucket.focus => suggestedInfo?.qualifyingValueId,
        _ => task?.effectivePrimaryValueId,
      };

      final reasonCodes = switch (bucket) {
        my_day.MyDayPickBucket.focus =>
          suggestedInfo == null
              ? const <String>[]
              : suggestedInfo.reasonCodes
                    .map((AllocationReasonCode c) => c.name)
                    .toList(),
        _ => const <String>[],
      };

      final suggestionRank = switch (bucket) {
        my_day.MyDayPickBucket.focus => suggestedInfo?.rank,
        _ => null,
      };

      picks.add(
        my_day.MyDayPick(
          taskId: taskId,
          bucket: bucket,
          sortIndex: i,
          pickedAtUtc: nowUtc,
          suggestionRank: suggestionRank,
          qualifyingValueId: qualifyingValueId,
          reasonCodes: reasonCodes,
        ),
      );
    }

    final context = _contextFactory.create(
      feature: 'my_day',
      screen: 'plan_my_day',
      intent: 'confirm',
      operation: 'my_day.set_picks',
      entityType: 'my_day_day',
      entityId: encodeDateOnly(_dayKeyUtc),
      extraFields: <String, Object?>{
        'pickedCount': picks.length,
      },
    );

    try {
      await _myDayRepository.setDayPicks(
        dayKeyUtc: _dayKeyUtc,
        ritualCompletedAtUtc: nowUtc,
        picks: picks,
        context: context,
      );

      _dayPicks = my_day.MyDayDayPicks(
        dayKeyUtc: dateOnly(_dayKeyUtc),
        ritualCompletedAtUtc: nowUtc,
        picks: picks,
      );

      if (event.closeOnSuccess && state is PlanMyDayReady) {
        final ready = state as PlanMyDayReady;
        emit(
          ready.copyWith(
            nav: PlanMyDayNav.closePage,
            navRequestId: ready.navRequestId + 1,
          ),
        );
      }
      add(const _PlanMyDayInputsChanged());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _onSnoozeTaskRequested(
    PlanMyDaySnoozeTaskRequested event,
    Emitter<PlanMyDayState> emit,
  ) async {
    final task = _tasks.cast<Task?>().firstWhere(
      (t) => t?.id == event.taskId,
      orElse: () => null,
    );
    if (task == null) return;

    final context = _contextFactory.create(
      feature: 'my_day',
      screen: 'plan_my_day',
      intent: 'snooze_task',
      operation: 'task.set_my_day_snoozed_until',
      entityType: 'task',
      entityId: task.id,
      extraFields: <String, Object?>{
        'untilUtc': event.untilUtc?.toIso8601String(),
      },
    );

    // If the task is being snoozed, ensure it is not still counted as selected.
    if (event.untilUtc != null && _selectedTaskIds.contains(task.id)) {
      _hasUserSelection = true;
      _selectedTaskIds = {..._selectedTaskIds}..remove(task.id);
      if (state is PlanMyDayReady) {
        emit(
          (state as PlanMyDayReady).copyWith(
            selectedTaskIds: _selectedTaskIds,
          ),
        );
      }
    }

    await _taskRepository.setMyDaySnoozedUntil(
      id: task.id,
      untilUtc: event.untilUtc,
      context: context,
    );

    await _refreshSnapshots(resetSelection: false);
    add(const _PlanMyDayInputsChanged());
  }

  Future<void> _onAppendToToday(
    PlanMyDayAppendToToday event,
    Emitter<PlanMyDayState> emit,
  ) async {
    if (_dayPicks.ritualCompletedAtUtc == null) return;
    if (_dayPicks.selectedTaskIds.contains(event.taskId)) return;

    final bucket = switch (event.bucket) {
      PlanMyDayAppendBucket.due => my_day.MyDayPickBucket.due,
      PlanMyDayAppendBucket.starts => my_day.MyDayPickBucket.starts,
      PlanMyDayAppendBucket.focus => my_day.MyDayPickBucket.focus,
    };

    final context = _contextFactory.create(
      feature: 'my_day',
      screen: 'plan_my_day',
      intent: 'append_to_today',
      operation: 'my_day.append_pick',
      entityType: 'my_day_day',
      entityId: encodeDateOnly(_dayKeyUtc),
      extraFields: <String, Object?>{
        'bucket': bucket.name,
        'taskId': event.taskId,
      },
    );

    await _myDayRepository.appendPick(
      dayKeyUtc: _dayKeyUtc,
      taskId: event.taskId,
      bucket: bucket,
      context: context,
    );

    _dayPicks = await _myDayRepository.loadDay(_dayKeyUtc);
    add(const _PlanMyDayInputsChanged());
  }

  Future<void> _onMoreSuggestionsRequested(
    PlanMyDayMoreSuggestionsRequested event,
    Emitter<PlanMyDayState> emit,
  ) async {
    _suggestionBatchCount += 1;
    await _refreshSnapshots(resetSelection: false);
    add(const _PlanMyDayInputsChanged());
  }

  bool _isSameDayUtc(DateTime a, DateTime b) {
    return dateOnly(a).isAtSameMomentAs(dateOnly(b));
  }
}

final class _PlanMyDayInputsChanged extends PlanMyDayEvent {
  const _PlanMyDayInputsChanged();
}
