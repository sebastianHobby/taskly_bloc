import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter/foundation.dart';
import 'package:taskly_bloc/presentation/shared/telemetry/operation_context_factory.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/my_day.dart' as my_day;
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/preferences.dart';
import 'package:taskly_domain/settings.dart' as settings;
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/time.dart';

sealed class MyDayRitualEvent {
  const MyDayRitualEvent();
}

final class MyDayRitualStarted extends MyDayRitualEvent {
  const MyDayRitualStarted();
}

final class MyDayRitualToggleTask extends MyDayRitualEvent {
  const MyDayRitualToggleTask(this.taskId, {required this.selected});

  final String taskId;
  final bool selected;
}

final class MyDayRitualAcceptAllPlanned extends MyDayRitualEvent {
  const MyDayRitualAcceptAllPlanned();
}

final class MyDayRitualAcceptAllDue extends MyDayRitualEvent {
  const MyDayRitualAcceptAllDue();
}

final class MyDayRitualAcceptAllStarts extends MyDayRitualEvent {
  const MyDayRitualAcceptAllStarts();
}

final class MyDayRitualAcceptAllCurated extends MyDayRitualEvent {
  const MyDayRitualAcceptAllCurated();
}

final class MyDayRitualFocusModeChanged extends MyDayRitualEvent {
  const MyDayRitualFocusModeChanged(this.focusMode);

  final FocusMode focusMode;
}

final class MyDayRitualFocusModeWizardRequested extends MyDayRitualEvent {
  const MyDayRitualFocusModeWizardRequested();
}

final class MyDayRitualConfirm extends MyDayRitualEvent {
  const MyDayRitualConfirm();
}

final class MyDayRitualSnoozeTaskRequested extends MyDayRitualEvent {
  const MyDayRitualSnoozeTaskRequested({
    required this.taskId,
    required this.newStartDate,
  });

  final String taskId;
  final DateTime newStartDate;
}

enum MyDayRitualAppendBucket {
  due,
  starts,
  focus,
}

final class MyDayRitualAppendToToday extends MyDayRitualEvent {
  const MyDayRitualAppendToToday({required this.bucket, required this.taskId});

  final MyDayRitualAppendBucket bucket;
  final String taskId;
}

sealed class MyDayRitualState {
  const MyDayRitualState();
}

final class MyDayRitualLoading extends MyDayRitualState {
  const MyDayRitualLoading();
}

enum MyDayRitualNav {
  openFocusSetupWizard,
}

@immutable
final class MyDayRitualReady extends MyDayRitualState {
  const MyDayRitualReady({
    required this.needsRitual,
    required this.focusMode,
    required this.dueWindowDays,
    required this.planned,
    required this.curated,
    required this.curatedReasons,
    required this.curatedReasonTooltips,
    required this.selectedTaskIds,
    required this.dayKeyUtc,
    this.nav,
    this.navRequestId = 0,
  });

  final bool needsRitual;
  final FocusMode focusMode;
  final int dueWindowDays;
  final List<Task> planned;
  final List<Task> curated;
  final Map<String, String> curatedReasons;
  final Map<String, String> curatedReasonTooltips;
  final Set<String> selectedTaskIds;
  final DateTime dayKeyUtc;
  final MyDayRitualNav? nav;
  final int navRequestId;

  MyDayRitualReady copyWith({
    bool? needsRitual,
    FocusMode? focusMode,
    int? dueWindowDays,
    List<Task>? planned,
    List<Task>? curated,
    Map<String, String>? curatedReasons,
    Map<String, String>? curatedReasonTooltips,
    Set<String>? selectedTaskIds,
    DateTime? dayKeyUtc,
    MyDayRitualNav? nav,
    int? navRequestId,
  }) {
    return MyDayRitualReady(
      needsRitual: needsRitual ?? this.needsRitual,
      focusMode: focusMode ?? this.focusMode,
      dueWindowDays: dueWindowDays ?? this.dueWindowDays,
      planned: planned ?? this.planned,
      curated: curated ?? this.curated,
      curatedReasons: curatedReasons ?? this.curatedReasons,
      curatedReasonTooltips:
          curatedReasonTooltips ?? this.curatedReasonTooltips,
      selectedTaskIds: selectedTaskIds ?? this.selectedTaskIds,
      dayKeyUtc: dayKeyUtc ?? this.dayKeyUtc,
      nav: nav ?? this.nav,
      navRequestId: navRequestId ?? this.navRequestId,
    );
  }
}

class MyDayRitualBloc extends Bloc<MyDayRitualEvent, MyDayRitualState> {
  MyDayRitualBloc({
    required SettingsRepositoryContract settingsRepository,
    required MyDayRepositoryContract myDayRepository,
    required AllocationOrchestrator allocationOrchestrator,
    required TaskRepositoryContract taskRepository,
    required HomeDayKeyService dayKeyService,
    required TemporalTriggerService temporalTriggerService,
    required NowService nowService,
  }) : _settingsRepository = settingsRepository,
       _myDayRepository = myDayRepository,
       _allocationOrchestrator = allocationOrchestrator,
       _taskRepository = taskRepository,
       _dayKeyService = dayKeyService,
       _temporalTriggerService = temporalTriggerService,
       _nowService = nowService,
       _dayKeyUtc = dayKeyService.todayDayKeyUtc(),
       super(const MyDayRitualLoading()) {
    on<MyDayRitualStarted>(_onStarted, transformer: restartable());
    on<MyDayRitualToggleTask>(_onToggleTask);
    on<MyDayRitualAcceptAllPlanned>(_onAcceptAllPlanned);
    on<MyDayRitualAcceptAllDue>(_onAcceptAllDue);
    on<MyDayRitualAcceptAllStarts>(_onAcceptAllStarts);
    on<MyDayRitualAcceptAllCurated>(_onAcceptAllCurated);
    on<MyDayRitualFocusModeChanged>(_onFocusModeChanged);
    on<MyDayRitualFocusModeWizardRequested>(_onFocusModeWizardRequested);
    on<MyDayRitualConfirm>(_onConfirm);
    on<MyDayRitualSnoozeTaskRequested>(_onSnoozeTaskRequested);
    on<MyDayRitualAppendToToday>(_onAppendToToday);
    on<_MyDayRitualInputsChanged>(_onInputsChanged);
    add(const MyDayRitualStarted());
  }

  final int _instanceId = identityHashCode(Object());
  DateTime? _lastObservedRitualCompletedAtUtc;
  bool? _lastObservedNeedsRitual;
  DateTime? _lastConfirmRequestedAtUtc;
  String? _lastConfirmCorrelationId;

  final SettingsRepositoryContract _settingsRepository;
  final MyDayRepositoryContract _myDayRepository;
  final AllocationOrchestrator _allocationOrchestrator;
  final TaskRepositoryContract _taskRepository;
  final HomeDayKeyService _dayKeyService;
  final TemporalTriggerService _temporalTriggerService;
  final NowService _nowService;
  final OperationContextFactory _contextFactory =
      const OperationContextFactory();

  StreamSubscription? _daySub;

  AllocationResult? _allocationResult;
  List<Task> _tasks = const <Task>[];
  AllocationConfig _allocationConfig = const AllocationConfig();
  late my_day.MyDayDayPicks _dayPicks;
  settings.GlobalSettings _globalSettings = const settings.GlobalSettings();
  DateTime _dayKeyUtc;

  Completer<void>? _refreshCompleter;

  bool _hasUserSelection = false;
  Set<String> _selectedTaskIds = <String>{};

  @override
  Future<void> close() async {
    await _daySub?.cancel();
    return super.close();
  }

  Future<void> _onStarted(
    MyDayRitualStarted event,
    Emitter<MyDayRitualState> emit,
  ) async {
    myDayTrace(
      '[MyDayRitualBloc#$_instanceId] started '
      'dayKeyUtc=${_dayKeyService.todayDayKeyUtc().toIso8601String()}',
    );

    _dayKeyUtc = _dayKeyService.todayDayKeyUtc();
    _dayPicks = my_day.MyDayDayPicks(
      dayKeyUtc: dateOnly(_dayKeyUtc),
      ritualCompletedAtUtc: null,
      picks: const <my_day.MyDayPick>[],
    );

    await _daySub?.cancel();

    emit(const MyDayRitualLoading());
    await _refreshSnapshots(resetSelection: true);
    add(const _MyDayRitualInputsChanged());

    _daySub = _temporalTriggerService.events
        .where((e) => e is HomeDayBoundaryCrossed || e is AppResumed)
        .listen((event) async {
          final nextDay = _dayKeyService.todayDayKeyUtc();
          final isDayChange = !_isSameDayUtc(nextDay, _dayKeyUtc);

          if (isDayChange) {
            myDayTrace(
              '[MyDayRitualBloc#$_instanceId] day boundary crossed '
              'dayKeyUtc:${_dayKeyUtc.toIso8601String()} -> ${nextDay.toIso8601String()}',
            );
            _dayKeyUtc = nextDay;
            await _refreshSnapshots(resetSelection: true);
            add(const _MyDayRitualInputsChanged());
            return;
          }

          // Optional refresh on app resume, but avoid clobbering in-progress
          // ritual selection.
          if (event is AppResumed && !_hasUserSelection) {
            myDayTrace(
              '[MyDayRitualBloc#$_instanceId] app resumed; refreshing snapshots',
            );
            await _refreshSnapshots(resetSelection: false);
            add(const _MyDayRitualInputsChanged());
          }
        });
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
    }

    try {
      final results = await Future.wait([
        _settingsRepository.load<AllocationConfig>(SettingsKey.allocation),
        _settingsRepository.load<settings.GlobalSettings>(SettingsKey.global),
        _myDayRepository.loadDay(_dayKeyUtc),
        _taskRepository.getAll(TaskQuery.incomplete()),
        _allocationOrchestrator.getAllocationSnapshot(),
      ]);

      _allocationConfig = results[0] as AllocationConfig;
      _globalSettings = results[1] as settings.GlobalSettings;

      final picks = results[2] as my_day.MyDayDayPicks;
      final before = _dayPicks.ritualCompletedAtUtc;
      _dayPicks = picks;
      if (before != _dayPicks.ritualCompletedAtUtc) {
        myDayTrace(
          '[MyDayRitualBloc#$_instanceId] dayPicks loaded '
          'dayKeyUtc=${_dayPicks.dayKeyUtc.toIso8601String()} '
          'ritualCompletedAtUtc:${before?.toIso8601String() ?? "<null>"}'
          ' -> ${_dayPicks.ritualCompletedAtUtc?.toIso8601String() ?? "<null>"} '
          'pickCount=${_dayPicks.picks.length} '
          'lastConfirmAtUtc=${_lastConfirmRequestedAtUtc?.toIso8601String() ?? "<null>"} '
          'lastConfirmCorrelationId=${_lastConfirmCorrelationId ?? "<null>"}',
        );
      }

      _tasks = results[3] as List<Task>;
      _allocationResult = results[4] as AllocationResult;
    } finally {
      _refreshCompleter = null;
      completer.complete();
    }
  }

  void _onInputsChanged(
    _MyDayRitualInputsChanged event,
    Emitter<MyDayRitualState> emit,
  ) {
    final planned = _buildPlanned(_tasks, _dayKeyUtc);
    final curated = _buildCurated(
      _allocationResult,
      plannedIds: planned.map((t) => t.id).toSet(),
    );

    if (!_hasUserSelection) {
      _selectedTaskIds = <String>{};
    }

    final needsRitual = _dayPicks.ritualCompletedAtUtc == null;

    final previousNeedsRitual = _lastObservedNeedsRitual;
    final previousRitualCompletedAtUtc = _lastObservedRitualCompletedAtUtc;
    if (previousNeedsRitual == null || previousNeedsRitual != needsRitual) {
      final nowUtc = _nowService.nowUtc();
      final secondsSinceConfirm = _lastConfirmRequestedAtUtc == null
          ? null
          : nowUtc.difference(_lastConfirmRequestedAtUtc!).inMilliseconds /
                1000.0;

      final suspiciousFlipToNeedsRitual =
          needsRitual && (secondsSinceConfirm ?? 999999) < 10;

      myDayTrace(
        '[MyDayRitualBloc#$_instanceId] needsRitual '
        '${previousNeedsRitual ?? "<unset>"} -> $needsRitual '
        'dayKeyUtc=${_dayKeyUtc.toIso8601String()} '
        'ritualCompletedAtUtc:${previousRitualCompletedAtUtc?.toIso8601String() ?? "<unset>"}'
        ' -> ${_dayPicks.ritualCompletedAtUtc?.toIso8601String() ?? "<null>"} '
        'pickCount=${_dayPicks.picks.length} '
        'selectedCount=${_selectedTaskIds.length} '
        'hasUserSelection=$_hasUserSelection '
        'secondsSinceConfirm=${secondsSinceConfirm?.toStringAsFixed(2) ?? "<null>"} '
        'suspicious=$suspiciousFlipToNeedsRitual',
      );

      _lastObservedNeedsRitual = needsRitual;
      _lastObservedRitualCompletedAtUtc = _dayPicks.ritualCompletedAtUtc;
    }

    final curatedReasonDetails = _buildCuratedReasonDetails(
      curated,
      allocation: _allocationResult,
    );

    emit(
      MyDayRitualReady(
        needsRitual: needsRitual,
        focusMode: _allocationConfig.focusMode,
        dueWindowDays: _globalSettings.myDayDueWindowDays,
        planned: planned,
        curated: curated,
        curatedReasons: curatedReasonDetails.reasonLineByTaskId,
        curatedReasonTooltips: curatedReasonDetails.tooltipByTaskId,
        selectedTaskIds: _selectedTaskIds,
        dayKeyUtc: _dayKeyUtc,
        nav: null,
      ),
    );
  }

  void _onToggleTask(
    MyDayRitualToggleTask event,
    Emitter<MyDayRitualState> emit,
  ) {
    if (state is! MyDayRitualReady) return;
    _hasUserSelection = true;
    if (event.selected) {
      _selectedTaskIds = {..._selectedTaskIds, event.taskId};
    } else {
      _selectedTaskIds = {..._selectedTaskIds}..remove(event.taskId);
    }
    emit(
      (state as MyDayRitualReady).copyWith(selectedTaskIds: _selectedTaskIds),
    );
  }

  void _onAcceptAllPlanned(
    MyDayRitualAcceptAllPlanned event,
    Emitter<MyDayRitualState> emit,
  ) {
    if (state is! MyDayRitualReady) return;
    _hasUserSelection = true;
    final plannedIds = (state as MyDayRitualReady).planned
        .map((t) => t.id)
        .toSet();
    _selectedTaskIds = {..._selectedTaskIds, ...plannedIds};
    emit(
      (state as MyDayRitualReady).copyWith(selectedTaskIds: _selectedTaskIds),
    );
  }

  void _onAcceptAllCurated(
    MyDayRitualAcceptAllCurated event,
    Emitter<MyDayRitualState> emit,
  ) {
    if (state is! MyDayRitualReady) return;
    _hasUserSelection = true;
    final curatedIds = (state as MyDayRitualReady).curated
        .map((t) => t.id)
        .toSet();
    _selectedTaskIds = {..._selectedTaskIds, ...curatedIds};
    emit(
      (state as MyDayRitualReady).copyWith(selectedTaskIds: _selectedTaskIds),
    );
  }

  void _onAcceptAllDue(
    MyDayRitualAcceptAllDue event,
    Emitter<MyDayRitualState> emit,
  ) {
    if (state is! MyDayRitualReady) return;
    _hasUserSelection = true;
    final current = state as MyDayRitualReady;
    final today = dateOnly(current.dayKeyUtc);
    final dueLimit = _dueLimit(today, current.dueWindowDays);
    final dueIds = current.planned
        .where((task) {
          return _isDueWithinWindow(task, dueLimit);
        })
        .map((task) => task.id)
        .toSet();
    _selectedTaskIds = {..._selectedTaskIds, ...dueIds};
    emit(current.copyWith(selectedTaskIds: _selectedTaskIds));
  }

  void _onAcceptAllStarts(
    MyDayRitualAcceptAllStarts event,
    Emitter<MyDayRitualState> emit,
  ) {
    if (state is! MyDayRitualReady) return;
    _hasUserSelection = true;
    final current = state as MyDayRitualReady;
    final today = dateOnly(current.dayKeyUtc);
    final dueLimit = _dueLimit(today, current.dueWindowDays);
    final startsIds = current.planned
        .where((task) {
          final available = _isAvailableToStart(task, today);
          if (!available) return false;
          return !_isDueWithinWindow(task, dueLimit);
        })
        .map((task) => task.id)
        .toSet();
    _selectedTaskIds = {..._selectedTaskIds, ...startsIds};
    emit(current.copyWith(selectedTaskIds: _selectedTaskIds));
  }

  Future<void> _onFocusModeChanged(
    MyDayRitualFocusModeChanged event,
    Emitter<MyDayRitualState> emit,
  ) async {
    final updated = _allocationConfig.copyWith(focusMode: event.focusMode);
    await _settingsRepository.save(SettingsKey.allocation, updated);
  }

  void _onFocusModeWizardRequested(
    MyDayRitualFocusModeWizardRequested event,
    Emitter<MyDayRitualState> emit,
  ) {
    if (state is! MyDayRitualReady) return;
    final current = state as MyDayRitualReady;
    emit(
      current.copyWith(
        nav: MyDayRitualNav.openFocusSetupWizard,
        navRequestId: current.navRequestId + 1,
      ),
    );
  }

  Future<void> _onConfirm(
    MyDayRitualConfirm event,
    Emitter<MyDayRitualState> emit,
  ) async {
    if (state is! MyDayRitualReady) return;
    final current = state as MyDayRitualReady;

    final planned = current.planned;
    final curated = current.curated;
    final selectedIds = _selectedTaskIds;

    if (selectedIds.isEmpty) return;

    _lastConfirmRequestedAtUtc = _nowService.nowUtc();
    myDayTrace(
      '[MyDayRitualBloc#$_instanceId] confirm requested '
      'dayKeyUtc=${current.dayKeyUtc.toIso8601String()} '
      'selectedCount=${selectedIds.length} '
      'plannedCount=${planned.length} '
      'curatedCount=${curated.length}',
    );

    final ordered = <String>[];
    for (final task in planned) {
      if (selectedIds.contains(task.id)) ordered.add(task.id);
    }
    for (final task in curated) {
      if (selectedIds.contains(task.id) && !ordered.contains(task.id)) {
        ordered.add(task.id);
      }
    }
    for (final id in selectedIds) {
      if (!ordered.contains(id)) ordered.add(id);
    }

    final today = dateOnly(current.dayKeyUtc);
    final dueLimit = _dueLimit(today, current.dueWindowDays);

    final candidateDueOrdered = <String>[];
    final candidateStartsOrdered = <String>[];
    for (final task in planned) {
      if (_isDueWithinWindow(task, dueLimit)) {
        candidateDueOrdered.add(task.id);
        continue;
      }

      if (_isAvailableToStart(task, today)) {
        candidateStartsOrdered.add(task.id);
      }
    }

    final dueSelectedIds = {
      for (final id in candidateDueOrdered)
        if (selectedIds.contains(id)) id,
    };
    final startsSelectedIds = {
      for (final id in candidateStartsOrdered)
        if (selectedIds.contains(id)) id,
    };
    final focusSelectedIds = {
      for (final task in curated)
        if (selectedIds.contains(task.id)) task.id,
    };

    final nowUtc = _nowService.nowUtc();
    final tasksById = {for (final task in _tasks) task.id: task};

    final allocationByTaskId =
        <String, ({AllocatedTask allocated, int rank})>{};
    final allocated =
        _allocationResult?.allocatedTasks ?? const <AllocatedTask>[];
    for (var i = 0; i < allocated.length; i++) {
      final allocatedTask = allocated[i];
      allocationByTaskId[allocatedTask.task.id] = (
        allocated: allocatedTask,
        rank: i,
      );
    }

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

      final allocatedInfo = allocationByTaskId[taskId];
      final task = tasksById[taskId];

      final qualifyingValueId = switch (bucket) {
        my_day.MyDayPickBucket.focus =>
          allocatedInfo?.allocated.qualifyingValueId,
        _ => task?.effectivePrimaryValueId,
      };

      final reasonCodes = switch (bucket) {
        my_day.MyDayPickBucket.focus =>
          allocatedInfo == null
              ? const <String>[]
              : allocatedInfo.allocated.reasonCodes
                    .map((AllocationReasonCode c) => c.name)
                    .toList(),
        _ => const <String>[],
      };

      final suggestionRank = switch (bucket) {
        my_day.MyDayPickBucket.focus =>
          allocatedInfo == null ? null : (allocatedInfo.rank + 1),
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
      screen: 'my_day_ritual',
      intent: 'confirm',
      operation: 'my_day.set_picks',
      entityType: 'my_day_day',
      entityId: encodeDateOnly(_dayKeyUtc),
      extraFields: <String, Object?>{
        'pickedCount': picks.length,
      },
    );

    _lastConfirmCorrelationId = context.correlationId;
    myDayTrace(
      '[MyDayRitualBloc#$_instanceId] setDayPicks start '
      'correlationId=${context.correlationId} '
      'dayKeyUtc=${_dayKeyUtc.toIso8601String()} '
      'ritualCompletedAtUtc=${nowUtc.toIso8601String()} '
      'pickedCount=${picks.length} '
      'bucketCounts={due:${dueSelectedIds.length},starts:${startsSelectedIds.length},focus:${focusSelectedIds.length}}',
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
      add(const _MyDayRitualInputsChanged());

      myDayTrace(
        '[MyDayRitualBloc#$_instanceId] setDayPicks done '
        'correlationId=${context.correlationId}',
      );
    } catch (e, s) {
      myDayTrace(
        '[MyDayRitualBloc#$_instanceId] setDayPicks failed '
        'correlationId=${context.correlationId} error=$e\n$s',
      );
      rethrow;
    }
  }

  Future<void> _onSnoozeTaskRequested(
    MyDayRitualSnoozeTaskRequested event,
    Emitter<MyDayRitualState> emit,
  ) async {
    final task = _tasks.cast<Task?>().firstWhere(
      (t) => t?.id == event.taskId,
      orElse: () => null,
    );
    if (task == null) return;

    final valueIds = <String>[
      if (task.overridePrimaryValueId != null) task.overridePrimaryValueId!,
      if (task.overrideSecondaryValueId != null) task.overrideSecondaryValueId!,
    ];

    final context = _contextFactory.create(
      feature: 'my_day',
      screen: 'my_day_ritual',
      intent: 'snooze_task',
      operation: 'task.update',
      entityType: 'task',
      entityId: task.id,
      extraFields: <String, Object?>{
        'newStartDateUtc': encodeDateOnly(event.newStartDate),
      },
    );

    await _taskRepository.update(
      id: task.id,
      name: task.name,
      completed: task.completed,
      description: task.description,
      startDate: dateOnly(event.newStartDate),
      deadlineDate: task.deadlineDate,
      projectId: task.projectId,
      priority: task.priority,
      repeatIcalRrule: task.repeatIcalRrule,
      repeatFromCompletion: task.repeatFromCompletion,
      seriesEnded: task.seriesEnded,
      valueIds: valueIds,
      isPinned: task.isPinned,
      context: context,
    );
  }

  Future<void> _onAppendToToday(
    MyDayRitualAppendToToday event,
    Emitter<MyDayRitualState> emit,
  ) async {
    if (_dayPicks.ritualCompletedAtUtc == null) return;
    if (_dayPicks.selectedTaskIds.contains(event.taskId)) return;

    final bucket = switch (event.bucket) {
      MyDayRitualAppendBucket.due => my_day.MyDayPickBucket.due,
      MyDayRitualAppendBucket.starts => my_day.MyDayPickBucket.starts,
      MyDayRitualAppendBucket.focus => my_day.MyDayPickBucket.focus,
    };

    final context = _contextFactory.create(
      feature: 'my_day',
      screen: 'my_day_ritual',
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
    add(const _MyDayRitualInputsChanged());
  }

  List<Task> _buildPlanned(List<Task> tasks, DateTime dayKeyUtc) {
    final today = dateOnly(dayKeyUtc);
    final dueWindowDays = _globalSettings.myDayDueWindowDays;
    final dueSoonLimit = today.add(Duration(days: dueWindowDays - 1));

    bool isPlanned(Task task) {
      if (_isCompleted(task)) return false;
      final start = dateOnlyOrNull(task.occurrence?.date ?? task.startDate);
      final deadline = dateOnlyOrNull(
        task.occurrence?.deadline ?? task.deadlineDate,
      );
      final startEligible = start != null && !start.isAfter(today);
      final dueSoon = deadline != null && !deadline.isAfter(dueSoonLimit);
      return startEligible || dueSoon;
    }

    return tasks.where(isPlanned).toList(growable: false);
  }

  DateTime? _deadlineDateOnly(Task task) {
    final raw = task.occurrence?.deadline ?? task.deadlineDate;
    return dateOnlyOrNull(raw);
  }

  DateTime? _startDateOnly(Task task) {
    final raw = task.occurrence?.date ?? task.startDate;
    return dateOnlyOrNull(raw);
  }

  bool _isAvailableToStart(Task task, DateTime today) {
    final start = _startDateOnly(task);
    return start != null && !start.isAfter(today);
  }

  bool _isDueWithinWindow(Task task, DateTime dueLimit) {
    final deadline = _deadlineDateOnly(task);
    return deadline != null && !deadline.isAfter(dueLimit);
  }

  DateTime _dueLimit(DateTime today, int dueWindowDays) {
    final days = dueWindowDays.clamp(1, 30);
    return today.add(Duration(days: days - 1));
  }

  List<Task> _buildCurated(
    AllocationResult? allocation, {
    required Set<String> plannedIds,
  }) {
    if (allocation == null) return const <Task>[];
    final curated = <Task>[];
    for (final entry in allocation.allocatedTasks) {
      final task = entry.task;
      if (plannedIds.contains(task.id)) continue;
      curated.add(task);
      if (curated.length >= 7) break;
    }
    return curated;
  }

  ({
    Map<String, String> reasonLineByTaskId,
    Map<String, String> tooltipByTaskId,
  })
  _buildCuratedReasonDetails(
    List<Task> curated, {
    required AllocationResult? allocation,
  }) {
    if (allocation == null) {
      return (
        reasonLineByTaskId: const <String, String>{},
        tooltipByTaskId: const <String, String>{},
      );
    }

    final reasonsByTaskId = <String, List<AllocationReasonCode>>{};
    for (final entry in allocation.allocatedTasks) {
      reasonsByTaskId[entry.task.id] = entry.reasonCodes;
    }

    final reasonLineByTaskId = <String, String>{};
    final tooltipByTaskId = <String, String>{};

    for (final task in curated) {
      final reasonCodes = reasonsByTaskId[task.id] ?? const [];
      final reasonLine = _reasonLineForTask(task, reasonCodes);
      final tooltip = _reasonTooltipForTask(task, reasonCodes);

      if (reasonLine.isNotEmpty) {
        reasonLineByTaskId[task.id] = reasonLine;
      }
      if (tooltip.isNotEmpty) {
        tooltipByTaskId[task.id] = tooltip;
      }
    }

    return (
      reasonLineByTaskId: reasonLineByTaskId,
      tooltipByTaskId: tooltipByTaskId,
    );
  }

  String _reasonLineForTask(Task task, List<AllocationReasonCode> reasonCodes) {
    final whyNow = _whyNowToken(task, reasonCodes);
    final whyItMatters = _whyItMattersToken(task, reasonCodes);

    if (whyNow.isEmpty && whyItMatters.isEmpty) return '';
    if (whyNow.isEmpty) return whyItMatters;
    if (whyItMatters.isEmpty) return whyNow;
    if (whyNow == whyItMatters) return whyNow;
    return '$whyNow · $whyItMatters';
  }

  String _whyNowToken(Task task, List<AllocationReasonCode> reasonCodes) {
    if (reasonCodes.contains(AllocationReasonCode.urgency)) {
      return _deadlineLabel(task);
    }

    if (reasonCodes.contains(AllocationReasonCode.neglectBalance)) {
      final primaryValueName = task.effectivePrimaryValue?.name.trim();
      if (primaryValueName != null && primaryValueName.isNotEmpty) {
        return 'Rebalancing toward $primaryValueName';
      }
      return 'Rebalancing';
    }

    if (reasonCodes.contains(AllocationReasonCode.priority)) {
      return 'Priority';
    }

    return 'Suggested';
  }

  String _whyItMattersToken(Task task, List<AllocationReasonCode> reasonCodes) {
    if (reasonCodes.contains(AllocationReasonCode.crossValue)) {
      return 'Cross-value';
    }

    if (reasonCodes.contains(AllocationReasonCode.neglectBalance)) {
      return '';
    }

    final primaryValueName = task.effectivePrimaryValue?.name.trim();
    if (primaryValueName != null && primaryValueName.isNotEmpty) {
      return primaryValueName;
    }

    if (reasonCodes.contains(AllocationReasonCode.neglectBalance)) {
      return 'Balance';
    }

    if (reasonCodes.contains(AllocationReasonCode.priority)) {
      return 'Priority';
    }

    return '';
  }

  String _reasonTooltipForTask(
    Task task,
    List<AllocationReasonCode> reasonCodes,
  ) {
    if (reasonCodes.isEmpty && task.isEffectivelyValueless) return '';

    final bullets = <String>[];

    if (reasonCodes.contains(AllocationReasonCode.urgency)) {
      bullets.add(_deadlineLabel(task));
    }

    if (reasonCodes.contains(AllocationReasonCode.priority)) {
      bullets.add('High priority');
    }

    if (reasonCodes.contains(AllocationReasonCode.neglectBalance)) {
      final primaryValueName = task.effectivePrimaryValue?.name.trim();
      if (primaryValueName != null && primaryValueName.isNotEmpty) {
        bullets.add('Rebalancing toward $primaryValueName');
      } else {
        bullets.add('Rebalancing');
      }
    }

    if (reasonCodes.contains(AllocationReasonCode.crossValue)) {
      final valueNames = task.effectiveValues
          .map((v) => v.name.trim())
          .where((n) => n.isNotEmpty)
          .toList(growable: false);

      if (valueNames.length >= 2) {
        bullets.add(
          'Cross-value: advances ${valueNames[0]} + ${valueNames[1]}',
        );
      } else {
        bullets.add('Cross-value');
      }
    } else {
      final primaryValueName = task.effectivePrimaryValue?.name.trim();
      if (primaryValueName != null && primaryValueName.isNotEmpty) {
        bullets.add('Supports $primaryValueName');
      }
    }

    if (bullets.isEmpty) return '';

    final buffer = StringBuffer('Why suggested');
    for (final item in bullets) {
      buffer.write('\n• $item');
    }
    return buffer.toString();
  }

  String _deadlineLabel(Task task) {
    final deadline = dateOnlyOrNull(task.deadlineDate);
    if (deadline == null) return 'Due soon';

    final today = dateOnly(_dayKeyUtc);
    final diff = deadline.difference(today).inDays;

    if (diff < 0) return 'Past due';
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    return 'Due in ${diff}d';
  }

  bool _isCompleted(Task task) {
    return task.occurrence?.isCompleted ?? task.completed;
  }

  bool _isSameDayUtc(DateTime a, DateTime b) {
    return dateOnly(a).isAtSameMomentAs(dateOnly(b));
  }
}

final class _MyDayRitualInputsChanged extends MyDayRitualEvent {
  const _MyDayRitualInputsChanged();
}
