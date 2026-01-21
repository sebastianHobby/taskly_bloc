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
  const MyDayRitualConfirm({this.closeOnSuccess = false});

  final bool closeOnSuccess;
}

final class MyDayRitualSnoozeTaskRequested extends MyDayRitualEvent {
  const MyDayRitualSnoozeTaskRequested({
    required this.taskId,
    required this.newStartDate,
  });

  final String taskId;
  final DateTime newStartDate;
}

final class MyDayRitualMoreSuggestionsRequested extends MyDayRitualEvent {
  const MyDayRitualMoreSuggestionsRequested();
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
  closeWizard,
}

@immutable
final class MyDayRitualReady extends MyDayRitualState {
  const MyDayRitualReady({
    required this.needsRitual,
    required this.focusMode,
    required this.dueWindowDays,
    required this.planned,
    required this.curated,
    required this.completedPicks,
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
  final List<Task> completedPicks;
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
    List<Task>? completedPicks,
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
      completedPicks: completedPicks ?? this.completedPicks,
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
    on<MyDayRitualMoreSuggestionsRequested>(_onMoreSuggestionsRequested);
    on<_MyDayRitualInputsChanged>(_onInputsChanged);
    add(const MyDayRitualStarted());
  }

  bool? _lastObservedNeedsRitual;

  final SettingsRepositoryContract _settingsRepository;
  final MyDayRepositoryContract _myDayRepository;
  final AllocationOrchestrator _allocationOrchestrator;
  final TaskRepositoryContract _taskRepository;
  final HomeDayKeyService _dayKeyService;
  final TemporalTriggerService _temporalTriggerService;
  final NowService _nowService;
  final OperationContextFactory _contextFactory =
      const OperationContextFactory();
  final my_day.MyDayRitualComposer _composer =
      const my_day.MyDayRitualComposer();

  StreamSubscription? _daySub;

  AllocationResult? _allocationResult;
  List<Task> _tasks = const <Task>[];
  AllocationConfig _allocationConfig = const AllocationConfig();
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
    MyDayRitualStarted event,
    Emitter<MyDayRitualState> emit,
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

    emit(const MyDayRitualLoading());
    await _refreshSnapshots(resetSelection: true);
    add(const _MyDayRitualInputsChanged());

    _daySub = _temporalTriggerService.events
        .where((e) => e is HomeDayBoundaryCrossed || e is AppResumed)
        .listen((event) async {
          final nextDay = _dayKeyService.todayDayKeyUtc();
          final isDayChange = !_isSameDayUtc(nextDay, _dayKeyUtc);

          if (isDayChange) {
            _dayKeyUtc = nextDay;
            await _refreshSnapshots(resetSelection: true);
            add(const _MyDayRitualInputsChanged());
            return;
          }

          // Optional refresh on app resume, but avoid clobbering in-progress
          // ritual selection.
          if (event is AppResumed && !_hasUserSelection) {
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
      _suggestionBatchCount = 1;
    }

    try {
      final results = await Future.wait([
        _settingsRepository.load<AllocationConfig>(SettingsKey.allocation),
        _settingsRepository.load<settings.GlobalSettings>(SettingsKey.global),
        _myDayRepository.loadDay(_dayKeyUtc),
        _taskRepository.getAll(TaskQuery.incomplete()),
      ]);

      _allocationConfig = results[0] as AllocationConfig;
      _globalSettings = results[1] as settings.GlobalSettings;

      final picks = results[2] as my_day.MyDayDayPicks;
      final before = _dayPicks.ritualCompletedAtUtc;
      _dayPicks = picks;
      if (before != _dayPicks.ritualCompletedAtUtc) {}

      final incompleteTasks = results[3] as List<Task>;

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

      _allocationResult = await _allocationOrchestrator.getSuggestedSnapshot(
        batchCount: _suggestionBatchCount,
      );
    } finally {
      _refreshCompleter = null;
      completer.complete();
    }
  }

  void _onInputsChanged(
    _MyDayRitualInputsChanged event,
    Emitter<MyDayRitualState> emit,
  ) {
    if (!_hasUserSelection) {
      _selectedTaskIds = _dayPicks.ritualCompletedAtUtc == null
          ? <String>{}
          : _dayPicks.selectedTaskIds;
    }

    final composition = _composer.compose(
      tasks: _tasks,
      dayKeyUtc: _dayKeyUtc,
      dueWindowDays: _globalSettings.myDayDueWindowDays,
      dayPicks: _dayPicks,
      selectedTaskIds: _selectedTaskIds,
      allocation: _allocationResult,
    );

    final planned = composition.planned;
    final curated = composition.curated;

    final needsRitual = _dayPicks.ritualCompletedAtUtc == null;

    final previousNeedsRitual = _lastObservedNeedsRitual;
    if (previousNeedsRitual == null || previousNeedsRitual != needsRitual) {
      _lastObservedNeedsRitual = needsRitual;
    }

    emit(
      MyDayRitualReady(
        needsRitual: needsRitual,
        focusMode: _allocationConfig.focusMode,
        dueWindowDays: _globalSettings.myDayDueWindowDays,
        planned: planned,
        curated: curated,
        completedPicks: _completedPicks,
        curatedReasons: composition.curatedReasonLineByTaskId,
        curatedReasonTooltips: composition.curatedTooltipByTaskId,
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

    if (selectedIds.isEmpty && !event.closeOnSuccess) return;

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

      if (event.closeOnSuccess && state is MyDayRitualReady) {
        final ready = state as MyDayRitualReady;
        emit(
          ready.copyWith(
            nav: MyDayRitualNav.closeWizard,
            navRequestId: ready.navRequestId + 1,
          ),
        );
      }
      add(const _MyDayRitualInputsChanged());
    } catch (e) {
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

  Future<void> _onMoreSuggestionsRequested(
    MyDayRitualMoreSuggestionsRequested event,
    Emitter<MyDayRitualState> emit,
  ) async {
    _suggestionBatchCount += 1;
    await _refreshSnapshots(resetSelection: false);
    add(const _MyDayRitualInputsChanged());
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

  bool _isSameDayUtc(DateTime a, DateTime b) {
    return dateOnly(a).isAtSameMomentAs(dateOnly(b));
  }
}

final class _MyDayRitualInputsChanged extends MyDayRitualEvent {
  const _MyDayRitualInputsChanged();
}
