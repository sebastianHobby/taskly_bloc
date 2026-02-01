import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/presentation/shared/telemetry/operation_context_factory.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/utils/routine_day_policy.dart';
import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/my_day.dart' as my_day;
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/preferences.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/settings.dart' as settings;
import 'package:taskly_domain/time.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_data_provider.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_mode_service.dart';

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

final class PlanMyDayToggleRoutine extends PlanMyDayEvent {
  const PlanMyDayToggleRoutine(this.routineId, {required this.selected});

  final String routineId;
  final bool selected;
}

final class PlanMyDaySwapSuggestionRequested extends PlanMyDayEvent {
  const PlanMyDaySwapSuggestionRequested({
    required this.fromTaskId,
    required this.toTaskId,
  });

  final String fromTaskId;
  final String toTaskId;
}

final class PlanMyDayPauseRoutineRequested extends PlanMyDayEvent {
  const PlanMyDayPauseRoutineRequested({
    required this.routineId,
    required this.pausedUntilUtc,
  });

  final String routineId;
  final DateTime pausedUntilUtc;
}

final class PlanMyDayConfirm extends PlanMyDayEvent {
  const PlanMyDayConfirm({this.closeOnSuccess = false});

  final bool closeOnSuccess;
}

final class PlanMyDayMoreSuggestionsRequested extends PlanMyDayEvent {
  const PlanMyDayMoreSuggestionsRequested();
}

final class PlanMyDayValueSortChanged extends PlanMyDayEvent {
  const PlanMyDayValueSortChanged(this.sort);

  final PlanMyDayValueSort sort;
}

final class PlanMyDaySwitchToBehaviorSuggestionsRequested
    extends PlanMyDayEvent {
  const PlanMyDaySwitchToBehaviorSuggestionsRequested();
}

final class PlanMyDayDailyLimitChanged extends PlanMyDayEvent {
  const PlanMyDayDailyLimitChanged(this.limit);

  final int limit;
}

final class PlanMyDayBulkRescheduleDueRequested extends PlanMyDayEvent {
  const PlanMyDayBulkRescheduleDueRequested({required this.newDayUtc});

  final DateTime newDayUtc;
}

final class PlanMyDayRescheduleDueTaskRequested extends PlanMyDayEvent {
  const PlanMyDayRescheduleDueTaskRequested({
    required this.taskId,
    required this.newDayUtc,
  });

  final String taskId;
  final DateTime newDayUtc;
}

final class PlanMyDayBulkReschedulePlannedRequested extends PlanMyDayEvent {
  const PlanMyDayBulkReschedulePlannedRequested({required this.newDayUtc});

  final DateTime newDayUtc;
}

final class PlanMyDayReschedulePlannedTaskRequested extends PlanMyDayEvent {
  const PlanMyDayReschedulePlannedTaskRequested({
    required this.taskId,
    required this.newDayUtc,
  });

  final String taskId;
  final DateTime newDayUtc;
}

final class PlanMyDaySnoozeTaskRequested extends PlanMyDayEvent {
  const PlanMyDaySnoozeTaskRequested({
    required this.taskId,
    required this.untilUtc,
  });

  final String taskId;
  final DateTime untilUtc;
}

enum PlanMyDayValueSort {
  attentionFirst,
  priorityFirst,
  mostSuggested,
  alphabetical,
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
final class PlanMyDayRoutineItem {
  const PlanMyDayRoutineItem({
    required this.routine,
    required this.snapshot,
    required this.selected,
    required this.completedToday,
    required this.isCatchUpDay,
    required this.isScheduled,
    required this.isEligibleToday,
    required this.lastScheduledDayUtc,
    required this.completionsInPeriod,
  });

  final Routine routine;
  final RoutineCadenceSnapshot snapshot;
  final bool selected;
  final bool completedToday;
  final bool isCatchUpDay;
  final bool isScheduled;
  final bool isEligibleToday;
  final DateTime? lastScheduledDayUtc;
  final List<RoutineCompletion> completionsInPeriod;
}

@immutable
final class PlanMyDayValueSuggestionGroup {
  const PlanMyDayValueSuggestionGroup({
    required this.valueId,
    required this.value,
    required this.tasks,
    required this.attentionNeeded,
    required this.neglectScore,
    required this.visibleCount,
    required this.expanded,
  });

  final String valueId;
  final Value value;
  final List<Task> tasks;
  final bool attentionNeeded;
  final double neglectScore;
  final int visibleCount;
  final bool expanded;

  int get totalCount => tasks.length;
}

@immutable
final class PlanMyDayToast {
  const PlanMyDayToast({required this.message});

  static const updated = PlanMyDayToast(message: 'Updated');

  final String message;
}

sealed class _PlanMyDayStreamEvent {
  const _PlanMyDayStreamEvent();
}

final class _PlanMyDayDemoModeChanged extends _PlanMyDayStreamEvent {
  const _PlanMyDayDemoModeChanged(this.enabled);

  final bool enabled;
}

final class _PlanMyDayTemporalTrigger extends _PlanMyDayStreamEvent {
  const _PlanMyDayTemporalTrigger(this.trigger);

  final TemporalTriggerEvent trigger;
}

final class _PlanMyDayTasksUpdated extends _PlanMyDayStreamEvent {
  const _PlanMyDayTasksUpdated(this.tasks);

  final List<Task> tasks;
}

@immutable
final class PlanMyDayReady extends PlanMyDayState {
  const PlanMyDayReady({
    required this.needsPlan,
    required this.dayKeyUtc,
    required this.globalSettings,
    required this.suggestionSignal,
    required this.dailyLimit,
    required this.requiresValueSetup,
    required this.requiresRatings,
    required this.dueTodayTasks,
    required this.plannedTasks,
    required this.suggested,
    required this.valueSuggestionGroups,
    required this.scheduledRoutines,
    required this.flexibleRoutines,
    required this.allRoutines,
    required this.selectedTaskIds,
    required this.selectedRoutineIds,
    required this.allTasks,
    required this.routineSelectionsByValue,
    required this.overCapacity,
    required this.valueSort,
    required this.spotlightTaskId,
    required this.toastRequestId,
    this.nav,
    this.navRequestId = 0,
    this.toast,
  });

  final bool needsPlan;
  final DateTime dayKeyUtc;
  final settings.GlobalSettings globalSettings;
  final SuggestionSignal suggestionSignal;
  final int dailyLimit;
  final bool requiresValueSetup;
  final bool requiresRatings;
  final List<Task> dueTodayTasks;
  final List<Task> plannedTasks;
  final List<Task> suggested;
  final List<PlanMyDayValueSuggestionGroup> valueSuggestionGroups;
  final List<PlanMyDayRoutineItem> scheduledRoutines;
  final List<PlanMyDayRoutineItem> flexibleRoutines;
  final List<PlanMyDayRoutineItem> allRoutines;
  final Set<String> selectedTaskIds;
  final Set<String> selectedRoutineIds;
  final List<Task> allTasks;
  final Map<String, int> routineSelectionsByValue;
  final bool overCapacity;
  final PlanMyDayValueSort valueSort;
  final String? spotlightTaskId;
  final int toastRequestId;
  final PlanMyDayNav? nav;
  final int navRequestId;
  final PlanMyDayToast? toast;

  int get plannedCount => selectedTaskIds.length + selectedRoutineIds.length;

  PlanMyDayReady copyWith({
    bool? needsPlan,
    DateTime? dayKeyUtc,
    settings.GlobalSettings? globalSettings,
    SuggestionSignal? suggestionSignal,
    int? dailyLimit,
    bool? requiresValueSetup,
    bool? requiresRatings,
    List<Task>? dueTodayTasks,
    List<Task>? plannedTasks,
    List<Task>? suggested,
    List<PlanMyDayValueSuggestionGroup>? valueSuggestionGroups,
    List<PlanMyDayRoutineItem>? scheduledRoutines,
    List<PlanMyDayRoutineItem>? flexibleRoutines,
    List<PlanMyDayRoutineItem>? allRoutines,
    Set<String>? selectedTaskIds,
    Set<String>? selectedRoutineIds,
    List<Task>? allTasks,
    Map<String, int>? routineSelectionsByValue,
    bool? overCapacity,
    PlanMyDayValueSort? valueSort,
    String? spotlightTaskId,
    int? toastRequestId,
    PlanMyDayNav? nav,
    int? navRequestId,
    PlanMyDayToast? toast,
  }) {
    return PlanMyDayReady(
      needsPlan: needsPlan ?? this.needsPlan,
      dayKeyUtc: dayKeyUtc ?? this.dayKeyUtc,
      globalSettings: globalSettings ?? this.globalSettings,
      suggestionSignal: suggestionSignal ?? this.suggestionSignal,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      requiresValueSetup: requiresValueSetup ?? this.requiresValueSetup,
      requiresRatings: requiresRatings ?? this.requiresRatings,
      dueTodayTasks: dueTodayTasks ?? this.dueTodayTasks,
      plannedTasks: plannedTasks ?? this.plannedTasks,
      suggested: suggested ?? this.suggested,
      valueSuggestionGroups:
          valueSuggestionGroups ?? this.valueSuggestionGroups,
      scheduledRoutines: scheduledRoutines ?? this.scheduledRoutines,
      flexibleRoutines: flexibleRoutines ?? this.flexibleRoutines,
      allRoutines: allRoutines ?? this.allRoutines,
      selectedTaskIds: selectedTaskIds ?? this.selectedTaskIds,
      selectedRoutineIds: selectedRoutineIds ?? this.selectedRoutineIds,
      allTasks: allTasks ?? this.allTasks,
      routineSelectionsByValue:
          routineSelectionsByValue ?? this.routineSelectionsByValue,
      overCapacity: overCapacity ?? this.overCapacity,
      valueSort: valueSort ?? this.valueSort,
      spotlightTaskId: spotlightTaskId ?? this.spotlightTaskId,
      toastRequestId: toastRequestId ?? this.toastRequestId,
      nav: nav ?? this.nav,
      navRequestId: navRequestId ?? this.navRequestId,
      toast: toast ?? this.toast,
    );
  }
}

class PlanMyDayBloc extends Bloc<PlanMyDayEvent, PlanMyDayState> {
  PlanMyDayBloc({
    required SettingsRepositoryContract settingsRepository,
    required MyDayRepositoryContract myDayRepository,
    required TaskSuggestionService taskSuggestionService,
    required TaskRepositoryContract taskRepository,
    required RoutineRepositoryContract routineRepository,
    required TaskWriteService taskWriteService,
    required RoutineWriteService routineWriteService,
    required HomeDayKeyService dayKeyService,
    required TemporalTriggerService temporalTriggerService,
    required NowService nowService,
    required DemoModeService demoModeService,
    required DemoDataProvider demoDataProvider,
    RoutineScheduleService scheduleService = const RoutineScheduleService(),
  }) : _settingsRepository = settingsRepository,
       _myDayRepository = myDayRepository,
       _taskSuggestionService = taskSuggestionService,
       _taskRepository = taskRepository,
       _routineRepository = routineRepository,
       _taskWriteService = taskWriteService,
       _routineWriteService = routineWriteService,
       _dayKeyService = dayKeyService,
       _temporalTriggerService = temporalTriggerService,
       _nowService = nowService,
       _demoModeService = demoModeService,
       _demoDataProvider = demoDataProvider,
       _scheduleService = scheduleService,
       _dayKeyUtc = dayKeyService.todayDayKeyUtc(),
       super(const PlanMyDayLoading()) {
    on<PlanMyDayStarted>(_onStarted, transformer: restartable());
    on<PlanMyDayToggleTask>(_onToggleTask);
    on<PlanMyDayToggleRoutine>(_onToggleRoutine);
    on<PlanMyDaySwapSuggestionRequested>(_onSwapSuggestionRequested);
    on<PlanMyDayPauseRoutineRequested>(_onPauseRoutineRequested);
    on<PlanMyDayConfirm>(_onConfirm);
    on<PlanMyDayMoreSuggestionsRequested>(_onMoreSuggestionsRequested);
    on<PlanMyDayValueSortChanged>(_onValueSortChanged);
    on<PlanMyDaySwitchToBehaviorSuggestionsRequested>(
      _onSwitchToBehaviorSuggestionsRequested,
    );
    on<PlanMyDayDailyLimitChanged>(_onDailyLimitChanged);
    on<PlanMyDayBulkRescheduleDueRequested>(_onBulkRescheduleDue);
    on<PlanMyDayRescheduleDueTaskRequested>(_onRescheduleDueTask);
    on<PlanMyDayBulkReschedulePlannedRequested>(_onBulkReschedulePlanned);
    on<PlanMyDayReschedulePlannedTaskRequested>(_onReschedulePlannedTask);
    on<PlanMyDaySnoozeTaskRequested>(_onSnoozeTaskRequested);
    add(const PlanMyDayStarted());
  }

  final SettingsRepositoryContract _settingsRepository;
  final MyDayRepositoryContract _myDayRepository;
  final TaskSuggestionService _taskSuggestionService;
  final TaskRepositoryContract _taskRepository;
  final RoutineRepositoryContract _routineRepository;
  final TaskWriteService _taskWriteService;
  final RoutineWriteService _routineWriteService;
  final HomeDayKeyService _dayKeyService;
  final TemporalTriggerService _temporalTriggerService;
  final NowService _nowService;
  final DemoModeService _demoModeService;
  final DemoDataProvider _demoDataProvider;
  final RoutineScheduleService _scheduleService;

  final OperationContextFactory _contextFactory =
      const OperationContextFactory();

  static const double _attentionDeficitThreshold = 0.20;
  static const int _poolExtraCount = 6;
  static const int _maxVisibleSuggestionsPerValue = 3;

  settings.GlobalSettings _globalSettings = const settings.GlobalSettings();
  AllocationConfig _allocationConfig = const AllocationConfig();
  DateTime _dayKeyUtc;

  TaskSuggestionSnapshot? _suggestionSnapshot;
  Map<String, double> _lastNeglectDeficits = const {};
  List<Task> _tasks = const <Task>[];
  List<Task> _incompleteTasks = const <Task>[];
  List<Routine> _routines = const <Routine>[];
  List<RoutineCompletion> _routineCompletions = const <RoutineCompletion>[];
  List<RoutineSkip> _routineSkips = const <RoutineSkip>[];
  late my_day.MyDayDayPicks _dayPicks;

  int _suggestionBatchCount = 1;
  int _dailyLimit = 8;

  bool _hasUserSelection = false;
  Set<String> _selectedTaskIds = <String>{};
  Set<String> _selectedRoutineIds = <String>{};
  Set<String> _autoIncludedTaskIds = const <String>{};
  Set<String> _autoIncludedRoutineIds = const <String>{};
  Set<String> _dueTodayTaskIds = const <String>{};
  Set<String> _plannedTaskIds = const <String>{};
  Set<String> _lockedCompletedPickIds = const <String>{};
  Set<String> _lockedCompletedRoutineIds = const <String>{};

  PlanMyDayValueSort _valuesSort = PlanMyDayValueSort.attentionFirst;
  String _taskRevisionStamp = '';

  Completer<void>? _refreshCompleter;
  bool _isDemoMode = false;
  int _toastRequestId = 0;
  PlanMyDayToast? _pendingToast;

  Future<void> _onStarted(
    PlanMyDayStarted event,
    Emitter<PlanMyDayState> emit,
  ) async {
    _isDemoMode = _demoModeService.enabled.valueOrNull ?? false;
    if (_isDemoMode) {
      emit(_demoDataProvider.buildPlanMyDayReady());
    } else {
      await _initializeRealMode(emit);
    }

    final updates = Rx.merge<_PlanMyDayStreamEvent>([
      _demoModeService.enabled.distinct().map(_PlanMyDayDemoModeChanged.new),
      _temporalTriggerService.events
          .where((e) => e is HomeDayBoundaryCrossed || e is AppResumed)
          .map(_PlanMyDayTemporalTrigger.new),
      _taskRepository
          .watchAll(TaskQuery.incomplete())
          .map(_PlanMyDayTasksUpdated.new),
    ]);

    await emit.onEach<_PlanMyDayStreamEvent>(
      updates,
      onData: (event) async {
        switch (event) {
          case _PlanMyDayDemoModeChanged(:final enabled):
            if (enabled == _isDemoMode) return;
            _isDemoMode = enabled;
            if (_isDemoMode) {
              emit(_demoDataProvider.buildPlanMyDayReady());
              return;
            }

            await _initializeRealMode(emit);
          case _PlanMyDayTemporalTrigger(:final trigger):
            if (_isDemoMode) return;
            final nextDay = _dayKeyService.todayDayKeyUtc();
            final isDayChange = !_isSameDayUtc(nextDay, _dayKeyUtc);

            if (isDayChange) {
              _dayKeyUtc = nextDay;
              await _refreshSnapshots(resetSelection: true);
              if (emit.isDone || _isDemoMode) return;
              _emitReady(emit);
              return;
            }

            if (trigger is AppResumed && !_hasUserSelection) {
              await _refreshSnapshots(resetSelection: false);
              if (emit.isDone || _isDemoMode) return;
              _emitReady(emit);
            }
          case _PlanMyDayTasksUpdated(:final tasks):
            if (_isDemoMode) return;
            final revision = _buildTaskRevision(tasks);
            if (revision == _taskRevisionStamp) return;
            _taskRevisionStamp = revision;
            await _refreshSnapshots(resetSelection: false);
            if (emit.isDone || _isDemoMode) return;
            _emitReady(emit);
        }
      },
    );
  }

  Future<void> _initializeRealMode(Emitter<PlanMyDayState> emit) async {
    _dayKeyUtc = _dayKeyService.todayDayKeyUtc();
    _suggestionBatchCount = 1;
    _dayPicks = my_day.MyDayDayPicks(
      dayKeyUtc: dateOnly(_dayKeyUtc),
      ritualCompletedAtUtc: null,
      picks: const <my_day.MyDayPick>[],
    );

    emit(const PlanMyDayLoading());
    await _refreshSnapshots(resetSelection: true);
    if (emit.isDone || _isDemoMode) return;
    _emitReady(emit);
  }

  Future<void> _onToggleTask(
    PlanMyDayToggleTask event,
    Emitter<PlanMyDayState> emit,
  ) async {
    if (state is! PlanMyDayReady) return;
    if (_isDemoMode) {
      final ready = state as PlanMyDayReady;
      final selected = Set<String>.from(ready.selectedTaskIds);
      if (event.selected) {
        selected.add(event.taskId);
      } else {
        selected.remove(event.taskId);
      }
      emit(ready.copyWith(selectedTaskIds: selected));
      return;
    }

    if (!event.selected &&
        (_lockedCompletedPickIds.contains(event.taskId) ||
            _autoIncludedTaskIds.contains(event.taskId))) {
      return;
    }

    _hasUserSelection = true;
    if (event.selected) {
      _selectedTaskIds = {..._selectedTaskIds, event.taskId};
    } else {
      _selectedTaskIds = {..._selectedTaskIds}..remove(event.taskId);
    }

    _emitReady(emit);
  }

  Future<void> _onToggleRoutine(
    PlanMyDayToggleRoutine event,
    Emitter<PlanMyDayState> emit,
  ) async {
    if (state is! PlanMyDayReady) return;
    if (_isDemoMode) {
      final ready = state as PlanMyDayReady;
      final selected = Set<String>.from(ready.selectedRoutineIds);
      if (event.selected) {
        selected.add(event.routineId);
      } else {
        selected.remove(event.routineId);
      }
      emit(ready.copyWith(selectedRoutineIds: selected));
      return;
    }

    if (!event.selected &&
        (_lockedCompletedRoutineIds.contains(event.routineId) ||
            _autoIncludedRoutineIds.contains(event.routineId))) {
      return;
    }

    _hasUserSelection = true;
    if (event.selected) {
      _selectedRoutineIds = {..._selectedRoutineIds, event.routineId};
    } else {
      _selectedRoutineIds = {..._selectedRoutineIds}..remove(event.routineId);
    }

    _emitReady(emit);
  }

  Future<void> _onSwapSuggestionRequested(
    PlanMyDaySwapSuggestionRequested event,
    Emitter<PlanMyDayState> emit,
  ) async {
    if (state is! PlanMyDayReady) return;
    if (event.fromTaskId == event.toTaskId) return;
    if (_autoIncludedTaskIds.contains(event.fromTaskId)) return;
    if (_autoIncludedTaskIds.contains(event.toTaskId)) return;

    if (_isDemoMode) {
      final ready = state as PlanMyDayReady;
      final selected = Set<String>.from(ready.selectedTaskIds);
      if (!selected.contains(event.fromTaskId)) return;
      if (selected.contains(event.toTaskId)) return;
      selected
        ..remove(event.fromTaskId)
        ..add(event.toTaskId);
      emit(ready.copyWith(selectedTaskIds: selected));
      return;
    }

    if (!_selectedTaskIds.contains(event.fromTaskId)) return;
    if (_selectedTaskIds.contains(event.toTaskId)) return;

    _hasUserSelection = true;
    _selectedTaskIds = {..._selectedTaskIds}
      ..remove(event.fromTaskId)
      ..add(event.toTaskId);

    _emitReady(emit);
  }

  Future<void> _onPauseRoutineRequested(
    PlanMyDayPauseRoutineRequested event,
    Emitter<PlanMyDayState> emit,
  ) async {
    if (_isDemoMode) return;
    final routine = _findRoutine(event.routineId);
    if (routine == null) return;

    final context = _contextFactory.create(
      feature: 'routines',
      screen: 'plan_my_day',
      intent: 'pause',
      operation: 'routine.pause',
      entityType: 'routine',
      entityId: routine.id,
      extraFields: <String, Object?>{
        'pausedUntilUtc': event.pausedUntilUtc.toIso8601String(),
      },
    );

    await _routineWriteService.setPausedUntil(
      routine.id,
      pausedUntilUtc: event.pausedUntilUtc,
      context: context,
    );

    _selectedRoutineIds = {..._selectedRoutineIds}..remove(routine.id);
    await _refreshSnapshots(resetSelection: false);
    if (emit.isDone) return;
    _emitReady(emit);
  }

  Future<void> _onConfirm(
    PlanMyDayConfirm event,
    Emitter<PlanMyDayState> emit,
  ) async {
    if (state is! PlanMyDayReady) return;
    if (_isDemoMode) return;
    final current = state as PlanMyDayReady;

    final selectedTaskIds = current.selectedTaskIds;
    final selectedRoutineIds = current.selectedRoutineIds;

    if (selectedTaskIds.isEmpty && selectedRoutineIds.isEmpty) {
      if (!event.closeOnSuccess) return;
    }

    final suggested = current.suggested;
    final dueToday = current.dueTodayTasks;
    final planned = current.plannedTasks;

    final orderedTaskIds = <String>[];
    for (final task in dueToday) {
      if (selectedTaskIds.contains(task.id)) orderedTaskIds.add(task.id);
    }
    for (final task in planned) {
      if (selectedTaskIds.contains(task.id) &&
          !orderedTaskIds.contains(task.id)) {
        orderedTaskIds.add(task.id);
      }
    }
    for (final task in suggested) {
      if (selectedTaskIds.contains(task.id) &&
          !orderedTaskIds.contains(task.id)) {
        orderedTaskIds.add(task.id);
      }
    }
    for (final taskId in selectedTaskIds) {
      if (!orderedTaskIds.contains(taskId)) orderedTaskIds.add(taskId);
    }

    final orderedRoutineIds = <String>[];
    for (final item in current.scheduledRoutines) {
      if (selectedRoutineIds.contains(item.routine.id)) {
        orderedRoutineIds.add(item.routine.id);
      }
    }
    for (final item in current.flexibleRoutines) {
      if (selectedRoutineIds.contains(item.routine.id)) {
        orderedRoutineIds.add(item.routine.id);
      }
    }
    for (final routineId in selectedRoutineIds) {
      if (!orderedRoutineIds.contains(routineId)) {
        orderedRoutineIds.add(routineId);
      }
    }

    final dueSelectedIds = {
      for (final task in dueToday)
        if (selectedTaskIds.contains(task.id)) task.id,
    };
    final startsSelectedIds = {
      for (final task in planned)
        if (selectedTaskIds.contains(task.id)) task.id,
    };
    final valuesSelectedIds = {
      for (final task in suggested)
        if (selectedTaskIds.contains(task.id)) task.id,
    };

    final nowUtc = _nowService.nowUtc();
    final tasksById = {for (final task in _tasks) task.id: task};
    final routinesById = {for (final routine in _routines) routine.id: routine};

    final suggestedById = <String, SuggestedTask>{
      for (final entry
          in _suggestionSnapshot?.suggested ?? const <SuggestedTask>[])
        entry.task.id: entry,
    };

    my_day.MyDayPickBucket bucketForTaskId(String taskId) {
      if (valuesSelectedIds.contains(taskId)) {
        return my_day.MyDayPickBucket.valueSuggestions;
      }
      if (dueSelectedIds.contains(taskId)) {
        return my_day.MyDayPickBucket.due;
      }
      if (startsSelectedIds.contains(taskId)) {
        return my_day.MyDayPickBucket.starts;
      }
      return my_day.MyDayPickBucket.manual;
    }

    final picks = <my_day.MyDayPick>[];
    var sortIndex = 0;

    for (final routineId in orderedRoutineIds) {
      final routine = routinesById[routineId];
      if (routine == null) continue;
      picks.add(
        my_day.MyDayPick.routine(
          routineId: routineId,
          bucket: my_day.MyDayPickBucket.routine,
          sortIndex: sortIndex,
          pickedAtUtc: nowUtc,
          qualifyingValueId: routine.valueId,
        ),
      );
      sortIndex += 1;
    }

    for (final taskId in orderedTaskIds) {
      final bucket = bucketForTaskId(taskId);
      final suggestedInfo = suggestedById[taskId];
      final task = tasksById[taskId];

      final qualifyingValueId = switch (bucket) {
        my_day.MyDayPickBucket.valueSuggestions =>
          suggestedInfo?.qualifyingValueId,
        _ => task?.effectivePrimaryValueId,
      };

      final reasonCodes = switch (bucket) {
        my_day.MyDayPickBucket.valueSuggestions =>
          suggestedInfo == null
              ? const <String>[]
              : suggestedInfo.reasonCodes
                    .map((AllocationReasonCode c) => c.name)
                    .toList(),
        _ => const <String>[],
      };

      final suggestionRank = switch (bucket) {
        my_day.MyDayPickBucket.valueSuggestions => suggestedInfo?.rank,
        _ => null,
      };

      picks.add(
        my_day.MyDayPick.task(
          taskId: taskId,
          bucket: bucket,
          sortIndex: sortIndex,
          pickedAtUtc: nowUtc,
          suggestionRank: suggestionRank,
          qualifyingValueId: qualifyingValueId,
          reasonCodes: reasonCodes,
        ),
      );
      sortIndex += 1;
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

    if (emit.isDone) return;
    _emitReady(emit);
  }

  Future<void> _onMoreSuggestionsRequested(
    PlanMyDayMoreSuggestionsRequested event,
    Emitter<PlanMyDayState> emit,
  ) async {
    if (_isDemoMode) return;
    _suggestionBatchCount += 1;
    await _refreshSnapshots(resetSelection: false);
    if (emit.isDone) return;
    _emitReady(emit);
  }

  void _onValueSortChanged(
    PlanMyDayValueSortChanged event,
    Emitter<PlanMyDayState> emit,
  ) {
    if (state is! PlanMyDayReady) return;
    if (_isDemoMode) return;
    _valuesSort = event.sort;
    _emitReady(emit);
  }

  Future<void> _onSwitchToBehaviorSuggestionsRequested(
    PlanMyDaySwitchToBehaviorSuggestionsRequested event,
    Emitter<PlanMyDayState> emit,
  ) async {
    if (_isDemoMode) return;
    final allocation = await _settingsRepository.load(
      SettingsKey.allocation,
    );
    final updated = allocation.copyWith(
      suggestionSignal: SuggestionSignal.behaviorBased,
    );

    final context = _contextFactory.create(
      feature: 'my_day',
      screen: 'plan_my_day',
      intent: 'switch_suggestion_signal',
      operation: 'settings.allocation.save',
      entityType: 'settings',
      extraFields: <String, Object?>{
        'suggestionSignal': SuggestionSignal.behaviorBased.name,
      },
    );

    await _settingsRepository.save(
      SettingsKey.allocation,
      updated,
      context: context,
    );

    _allocationConfig = updated;

    await _refreshSuggestions();
    if (emit.isDone) return;
    _emitReady(emit);
  }

  Future<void> _onSnoozeTaskRequested(
    PlanMyDaySnoozeTaskRequested event,
    Emitter<PlanMyDayState> emit,
  ) async {
    if (_isDemoMode) return;
    final context = _contextFactory.create(
      feature: 'my_day',
      screen: 'plan_my_day',
      intent: 'snooze_task',
      operation: 'task_snooze',
      entityType: 'task',
      entityId: event.taskId,
      extraFields: <String, Object?>{
        'until_utc': event.untilUtc.toIso8601String(),
      },
    );

    await _taskWriteService.setMyDaySnoozedUntil(
      event.taskId,
      untilUtc: event.untilUtc,
      context: context,
    );

    _hasUserSelection = true;
    _selectedTaskIds = {..._selectedTaskIds}..remove(event.taskId);
    await _refreshSnapshots(resetSelection: false);
    if (emit.isDone) return;
    _emitReady(emit);
  }

  void _onDailyLimitChanged(
    PlanMyDayDailyLimitChanged event,
    Emitter<PlanMyDayState> emit,
  ) {
    if (state is! PlanMyDayReady) return;
    final next = event.limit.clamp(1, 50);
    if (next == _dailyLimit) return;
    _dailyLimit = next;
    _emitReady(emit);
  }

  Future<void> _onBulkRescheduleDue(
    PlanMyDayBulkRescheduleDueRequested event,
    Emitter<PlanMyDayState> emit,
  ) async {
    if (_isDemoMode) return;
    final taskIds = _dueTodayTaskIds.toList(growable: false);
    if (taskIds.isEmpty) return;

    final newDeadlineDay = dateOnly(event.newDayUtc);
    final context = _contextFactory.create(
      feature: 'my_day',
      screen: 'plan_my_day',
      intent: 'bulk_reschedule_due',
      operation: 'task_update_deadline',
      entityType: 'task',
      extraFields: <String, Object?>{
        'task_count': taskIds.length,
        'new_deadline_day': newDeadlineDay.toIso8601String(),
      },
    );

    await _taskWriteService.bulkRescheduleDeadlines(
      taskIds,
      newDeadlineDay,
      context: context,
    );

    _hasUserSelection = true;
    _selectedTaskIds = _selectedTaskIds.difference(_dueTodayTaskIds);
    _queueToast(PlanMyDayToast.updated);
    await _refreshSnapshots(resetSelection: false);
    if (emit.isDone) return;
    _emitReady(emit);
  }

  Future<void> _onRescheduleDueTask(
    PlanMyDayRescheduleDueTaskRequested event,
    Emitter<PlanMyDayState> emit,
  ) async {
    if (_isDemoMode) return;
    final newDeadlineDay = dateOnly(event.newDayUtc);
    final context = _contextFactory.create(
      feature: 'my_day',
      screen: 'plan_my_day',
      intent: 'reschedule_due',
      operation: 'task_update_deadline',
      entityType: 'task',
      entityId: event.taskId,
      extraFields: <String, Object?>{
        'new_deadline_day': newDeadlineDay.toIso8601String(),
      },
    );

    await _taskWriteService.bulkRescheduleDeadlines(
      [event.taskId],
      newDeadlineDay,
      context: context,
    );

    _hasUserSelection = true;
    _selectedTaskIds = {..._selectedTaskIds}..remove(event.taskId);
    _queueToast(PlanMyDayToast.updated);
    await _refreshSnapshots(resetSelection: false);
    if (emit.isDone) return;
    _emitReady(emit);
  }

  Future<void> _onBulkReschedulePlanned(
    PlanMyDayBulkReschedulePlannedRequested event,
    Emitter<PlanMyDayState> emit,
  ) async {
    if (_isDemoMode) return;
    final taskIds = _plannedTaskIds.toList(growable: false);
    if (taskIds.isEmpty) return;

    final newStartDay = dateOnly(event.newDayUtc);
    final context = _contextFactory.create(
      feature: 'my_day',
      screen: 'plan_my_day',
      intent: 'bulk_reschedule_planned',
      operation: 'task_update_start',
      entityType: 'task',
      extraFields: <String, Object?>{
        'task_count': taskIds.length,
        'new_start_day': newStartDay.toIso8601String(),
      },
    );

    await _taskWriteService.bulkRescheduleStarts(
      taskIds,
      newStartDay,
      context: context,
    );

    _hasUserSelection = true;
    _selectedTaskIds = _selectedTaskIds.difference(_plannedTaskIds);
    _queueToast(PlanMyDayToast.updated);
    await _refreshSnapshots(resetSelection: false);
    if (emit.isDone) return;
    _emitReady(emit);
  }

  Future<void> _onReschedulePlannedTask(
    PlanMyDayReschedulePlannedTaskRequested event,
    Emitter<PlanMyDayState> emit,
  ) async {
    if (_isDemoMode) return;
    final newStartDay = dateOnly(event.newDayUtc);
    final context = _contextFactory.create(
      feature: 'my_day',
      screen: 'plan_my_day',
      intent: 'reschedule_planned',
      operation: 'task_update_start',
      entityType: 'task',
      entityId: event.taskId,
      extraFields: <String, Object?>{
        'new_start_day': newStartDay.toIso8601String(),
      },
    );

    await _taskWriteService.bulkRescheduleStarts(
      [event.taskId],
      newStartDay,
      context: context,
    );

    _hasUserSelection = true;
    _selectedTaskIds = {..._selectedTaskIds}..remove(event.taskId);
    _queueToast(PlanMyDayToast.updated);
    await _refreshSnapshots(resetSelection: false);
    if (emit.isDone) return;
    _emitReady(emit);
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
      _selectedRoutineIds = <String>{};
      _suggestionBatchCount = 1;
    }

    try {
      final results = await Future.wait([
        _settingsRepository.load<settings.GlobalSettings>(SettingsKey.global),
        _settingsRepository.load<AllocationConfig>(SettingsKey.allocation),
        _myDayRepository.loadDay(_dayKeyUtc),
        _taskRepository.getAll(TaskQuery.incomplete()),
        _routineRepository.getAll(includeInactive: true),
        _routineRepository.getCompletions(),
        _routineRepository.getSkips(),
      ]);

      _globalSettings = results[0] as settings.GlobalSettings;
      _allocationConfig = results[1] as AllocationConfig;

      final picks = results[2] as my_day.MyDayDayPicks;
      _dayPicks = picks;

      final incompleteTasks = results[3] as List<Task>;
      _incompleteTasks = incompleteTasks;
      _taskRevisionStamp = _buildTaskRevision(incompleteTasks);

      final routines = results[4] as List<Routine>;
      final completions = results[5] as List<RoutineCompletion>;
      final skips = results[6] as List<RoutineSkip>;

      _routines = routines;
      _routineCompletions = completions;
      _routineSkips = skips;

      final pickedTaskIds = _dayPicks.selectedTaskIds;
      final incompleteIds = incompleteTasks.map((t) => t.id).toSet();
      final missingPickIds = pickedTaskIds.difference(incompleteIds);

      final missingPickTasks = missingPickIds.isEmpty
          ? const <Task>[]
          : await _taskRepository.getByIds(missingPickIds);

      final completedPickTasks = missingPickTasks
          .where((task) => task.completed)
          .toList(growable: false);

      _lockedCompletedPickIds = Set.unmodifiable(
        completedPickTasks.map((task) => task.id),
      );

      final completedRoutineIds = _routineCompletions
          .where(
            (completion) => dateOnly(
              completion.completedAtUtc,
            ).isAtSameMomentAs(dateOnly(_dayKeyUtc)),
          )
          .map((completion) => completion.routineId)
          .toSet();

      _lockedCompletedRoutineIds = Set.unmodifiable(
        _dayPicks.selectedRoutineIds
            .where(completedRoutineIds.contains)
            .toSet(),
      );

      _tasks = [...incompleteTasks, ...missingPickTasks];

      if (!_hasUserSelection) {
        if (_dayPicks.ritualCompletedAtUtc == null) {
          _selectedTaskIds = <String>{};
          _selectedRoutineIds = <String>{};
        } else {
          _selectedTaskIds = _dayPicks.selectedTaskIds;
          _selectedRoutineIds = _dayPicks.selectedRoutineIds;
        }
      }

      await _refreshSuggestions();
    } finally {
      _refreshCompleter = null;
      completer.complete();
    }
  }

  Future<void> _refreshSuggestions() async {
    final showRoutines = _globalSettings.myDayShowRoutines;

    final routineSelections = showRoutines
        ? _routineSelectionsByValue()
        : const <String, int>{};
    final triageSelections = _triageSelectionsByValue();
    final selectionCounts = _mergeSelectionCounts(
      routineSelections,
      triageSelections,
    );

    final targetCount = _suggestionPoolTargetCount();

    _suggestionSnapshot = await _taskSuggestionService.getSnapshot(
      batchCount: _suggestionBatchCount,
      suggestedTargetCount: targetCount,
      tasksOverride: _incompleteTasks,
      routineSelectionsByValue: selectionCounts,
      nowUtc: _nowService.nowUtc(),
    );
    _lastNeglectDeficits = _suggestionSnapshot?.neglectDeficits ?? const {};
  }

  void _emitReady(Emitter<PlanMyDayState> emit) {
    final snapshot = _suggestionSnapshot;
    final suggestedEntries = snapshot?.suggested ?? const <SuggestedTask>[];
    final valueGroups = _buildValueSuggestionGroups(
      suggestedEntries,
      deficits: snapshot?.neglectDeficits ?? const {},
    );
    final suggested = valueGroups
        .expand((group) => group.tasks)
        .toList(growable: false);

    final showRoutines = _globalSettings.myDayShowRoutines;

    final snoozedIds =
        snapshot?.snoozed.map((task) => task.id).toSet() ?? const <String>{};
    final activeTasks = _incompleteTasks
        .where((task) => !snoozedIds.contains(task.id))
        .toList(growable: false);

    final today = dateOnly(_dayKeyUtc);
    final dueTodayTasks = activeTasks
        .where((task) => _isDueTodayOrOverdue(task, today))
        .toList(growable: false);
    final dueIds = dueTodayTasks.map((task) => task.id).toSet();
    final plannedTasks = activeTasks
        .where((task) => _isPlannedTodayOrEarlier(task, today))
        .where((task) => !dueIds.contains(task.id))
        .toList(growable: false);

    final routineItems = showRoutines
        ? _buildRoutineItems()
        : _RoutineItemBuildResult.empty;
    final scheduledRoutines = routineItems.scheduledEligible;
    final flexibleRoutines = routineItems.flexibleEligible;
    final allRoutines = routineItems.allItems;

    _dueTodayTaskIds = dueTodayTasks.map((task) => task.id).toSet();
    _plannedTaskIds = plannedTasks.map((task) => task.id).toSet();
    _autoIncludedTaskIds = {
      ..._dueTodayTaskIds,
      ..._plannedTaskIds,
    };
    _autoIncludedRoutineIds = scheduledRoutines
        .map((item) => item.routine.id)
        .toSet();

    if (!_hasUserSelection) {
      final baseTaskIds = _dayPicks.ritualCompletedAtUtc == null
          ? <String>{}
          : {..._dayPicks.selectedTaskIds};
      final baseRoutineIds = _dayPicks.ritualCompletedAtUtc == null
          ? <String>{}
          : {..._dayPicks.selectedRoutineIds};

      _selectedTaskIds = {...baseTaskIds, ..._autoIncludedTaskIds};
      _selectedRoutineIds = {...baseRoutineIds, ..._autoIncludedRoutineIds};

      final currentCount = _selectedTaskIds.length + _selectedRoutineIds.length;
      final remaining = (_dailyLimit - currentCount).clamp(0, 999);
      if (remaining > 0) {
        var added = 0;
        for (final task in suggested) {
          if (_selectedTaskIds.contains(task.id)) continue;
          _selectedTaskIds.add(task.id);
          added += 1;
          if (added >= remaining) break;
        }
      }
    } else {
      _selectedTaskIds = {
        ..._selectedTaskIds,
        ..._autoIncludedTaskIds,
      };
      _selectedRoutineIds = {
        ..._selectedRoutineIds,
        ..._autoIncludedRoutineIds,
      };
    }

    final selectedTaskIds = _filteredSelectedTaskIds(
      suggested: suggested,
      dueToday: dueTodayTasks,
      planned: plannedTasks,
    );
    final selectedRoutineIds = showRoutines
        ? _selectedRoutineIds
        : const <String>{};
    final overCapacity =
        (selectedTaskIds.length + selectedRoutineIds.length) > _dailyLimit;
    final toast = _pendingToast;
    final toastRequestId = _toastRequestId;

    emit(
      PlanMyDayReady(
        needsPlan: _dayPicks.ritualCompletedAtUtc == null,
        dayKeyUtc: _dayKeyUtc,
        globalSettings: _globalSettings,
        suggestionSignal: _allocationConfig.suggestionSignal,
        dailyLimit: _dailyLimit,
        requiresValueSetup: snapshot?.requiresValueSetup ?? false,
        requiresRatings: snapshot?.requiresRatings ?? false,
        dueTodayTasks: dueTodayTasks,
        plannedTasks: plannedTasks,
        suggested: suggested,
        valueSuggestionGroups: valueGroups,
        scheduledRoutines: scheduledRoutines,
        flexibleRoutines: flexibleRoutines,
        allRoutines: allRoutines,
        selectedTaskIds: selectedTaskIds,
        selectedRoutineIds: selectedRoutineIds,
        allTasks: activeTasks,
        routineSelectionsByValue: _routineSelectionsByValue(),
        overCapacity: overCapacity,
        valueSort: _valuesSort,
        spotlightTaskId: suggested.isEmpty ? null : suggested.first.id,
        toastRequestId: toastRequestId,
        toast: toast,
      ),
    );
    _pendingToast = null;
  }

  _RoutineItemBuildResult _buildRoutineItems() {
    final todayKey = dateOnly(_dayKeyUtc);
    final completedToday = _routineCompletions
        .where(
          (completion) =>
              dateOnly(completion.completedAtUtc).isAtSameMomentAs(todayKey),
        )
        .map((completion) => completion.routineId)
        .toSet();
    final scheduledEligible = <PlanMyDayRoutineItem>[];
    final flexibleEligible = <PlanMyDayRoutineItem>[];
    final allItems = <PlanMyDayRoutineItem>[];

    for (final routine in _routines.where((routine) => routine.isActive)) {
      if (routine.isPausedOn(todayKey)) continue;

      final snapshot = _scheduleService.buildSnapshot(
        routine: routine,
        dayKeyUtc: _dayKeyUtc,
        completions: _routineCompletions,
        skips: _routineSkips,
      );
      if (snapshot.remainingCount <= 0) continue;

      final policy = evaluateRoutineDayPolicy(
        routine: routine,
        snapshot: snapshot,
        dayKeyUtc: _dayKeyUtc,
        completions: _routineCompletions,
      );
      final isCompletedToday = completedToday.contains(routine.id);
      final completionsInPeriod = _completionsForPeriod(routine, snapshot);
      final item = PlanMyDayRoutineItem(
        routine: routine,
        snapshot: snapshot,
        selected: _selectedRoutineIds.contains(routine.id),
        completedToday: isCompletedToday,
        isCatchUpDay: policy.isCatchUpDay,
        isScheduled: policy.cadenceKind == RoutineCadenceKind.scheduled,
        isEligibleToday: policy.isEligibleToday && !isCompletedToday,
        lastScheduledDayUtc: policy.lastScheduledDayUtc,
        completionsInPeriod: completionsInPeriod,
      );

      if (item.isEligibleToday) {
        if (item.isScheduled) {
          scheduledEligible.add(item);
        } else {
          flexibleEligible.add(item);
        }
      }

      if (item.isEligibleToday ||
          _selectedRoutineIds.contains(routine.id) ||
          _lockedCompletedRoutineIds.contains(routine.id)) {
        allItems.add(item);
      }
    }

    scheduledEligible.sort(_compareScheduledRoutines);
    flexibleEligible.sort(_compareFlexibleRoutines);

    return _RoutineItemBuildResult(
      allItems: allItems,
      scheduledEligible: scheduledEligible,
      flexibleEligible: flexibleEligible,
    );
  }

  int _compareScheduledRoutines(
    PlanMyDayRoutineItem a,
    PlanMyDayRoutineItem b,
  ) {
    if (a.isCatchUpDay != b.isCatchUpDay) {
      return a.isCatchUpDay ? -1 : 1;
    }
    if (a.isCatchUpDay && b.isCatchUpDay) {
      final byValuePriority = _valuePriorityRank(
        a.routine.value?.priority,
      ).compareTo(_valuePriorityRank(b.routine.value?.priority));
      if (byValuePriority != 0) return byValuePriority;
    }

    final byLastScheduled = _compareLastScheduledDay(a, b);
    if (byLastScheduled != 0) return byLastScheduled;

    return a.routine.name.compareTo(b.routine.name);
  }

  int _compareFlexibleRoutines(
    PlanMyDayRoutineItem a,
    PlanMyDayRoutineItem b,
  ) {
    final byDaysLeft = a.snapshot.daysLeft.compareTo(b.snapshot.daysLeft);
    if (byDaysLeft != 0) return byDaysLeft;

    final byRemaining = b.snapshot.remainingCount.compareTo(
      a.snapshot.remainingCount,
    );
    if (byRemaining != 0) return byRemaining;

    final byValuePriority = _valuePriorityRank(
      a.routine.value?.priority,
    ).compareTo(_valuePriorityRank(b.routine.value?.priority));
    if (byValuePriority != 0) return byValuePriority;

    return a.routine.name.compareTo(b.routine.name);
  }

  int _compareLastScheduledDay(
    PlanMyDayRoutineItem a,
    PlanMyDayRoutineItem b,
  ) {
    final aDay = a.lastScheduledDayUtc;
    final bDay = b.lastScheduledDayUtc;
    if (aDay == null && bDay == null) return 0;
    if (aDay == null) return 1;
    if (bDay == null) return -1;
    return aDay.compareTo(bDay);
  }

  int _valuePriorityRank(ValuePriority? priority) {
    return switch (priority) {
      ValuePriority.high => 0,
      ValuePriority.medium => 1,
      ValuePriority.low => 2,
      null => 1,
    };
  }

  Map<String, int> _routineSelectionsByValue() {
    if (!_globalSettings.myDayShowRoutines) {
      return const <String, int>{};
    }

    final routinesById = {for (final routine in _routines) routine.id: routine};
    final counts = <String, int>{};
    for (final routineId in _selectedRoutineIds) {
      final routine = routinesById[routineId];
      if (routine == null) continue;
      counts[routine.valueId] = (counts[routine.valueId] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, int> _triageSelectionsByValue() {
    final triageIds = _triageTaskIdsFromSnapshot();
    if (triageIds.isEmpty) return const <String, int>{};

    final tasksById = {for (final task in _tasks) task.id: task};
    final counts = <String, int>{};

    for (final taskId in _selectedTaskIds) {
      if (!triageIds.contains(taskId)) continue;
      final valueId = tasksById[taskId]?.effectivePrimaryValueId;
      if (valueId == null || valueId.isEmpty) continue;
      counts[valueId] = (counts[valueId] ?? 0) + 1;
    }

    return counts;
  }

  Set<String> _triageTaskIdsFromSnapshot() {
    return {..._dueTodayTaskIds, ..._plannedTaskIds};
  }

  Map<String, int> _mergeSelectionCounts(
    Map<String, int> routineCounts,
    Map<String, int> triageCounts,
  ) {
    if (routineCounts.isEmpty) return triageCounts;
    if (triageCounts.isEmpty) return routineCounts;

    final merged = Map<String, int>.from(routineCounts);
    for (final entry in triageCounts.entries) {
      merged[entry.key] = (merged[entry.key] ?? 0) + entry.value;
    }
    return merged;
  }

  Set<String> _filteredSelectedTaskIds({
    required List<Task> suggested,
    required List<Task> dueToday,
    required List<Task> planned,
  }) {
    final visibleIds = <String>{
      for (final task in suggested) task.id,
      for (final task in dueToday) task.id,
      for (final task in planned) task.id,
    };

    if (visibleIds.isEmpty) return const <String>{};

    return _selectedTaskIds.where(visibleIds.contains).toSet();
  }

  int _suggestionPoolTargetCount() {
    final valuesById = <String, Value>{};
    for (final task in _incompleteTasks) {
      final value = task.effectivePrimaryValue;
      if (value != null) {
        valuesById[value.id] = value;
      }
    }

    if (valuesById.isEmpty) return 0;

    var total = 0;
    final hasDeficitData = _lastNeglectDeficits.isNotEmpty;
    for (final value in valuesById.values) {
      final deficit = _lastNeglectDeficits[value.id] ?? 0.0;
      final attentionNeeded =
          !hasDeficitData || deficit >= _attentionDeficitThreshold;
      final defaultVisible = _defaultVisibleCount(
        value.priority,
        attentionNeeded: attentionNeeded,
      );
      total += defaultVisible + _poolExtraCount;
    }

    return total * _suggestionBatchCount;
  }

  List<PlanMyDayValueSuggestionGroup> _buildValueSuggestionGroups(
    List<SuggestedTask> suggested, {
    required Map<String, double> deficits,
  }) {
    if (suggested.isEmpty) return const [];

    final groupsById = <String, List<Task>>{};
    final valueById = <String, Value>{};
    final deficitById = <String, double>{};

    for (final entry in suggested) {
      final valueId = entry.qualifyingValueId?.trim().isNotEmpty ?? false
          ? entry.qualifyingValueId!.trim()
          : entry.task.effectivePrimaryValueId;
      if (valueId == null || valueId.isEmpty) continue;

      final value = _resolveValueForTask(entry.task, valueId);
      if (value == null) continue;

      groupsById.putIfAbsent(valueId, () => []).add(entry.task);
      valueById[valueId] = value;
      deficitById[valueId] = deficits[valueId] ?? 0.0;
    }

    final groups = <PlanMyDayValueSuggestionGroup>[];
    for (final entry in groupsById.entries) {
      final valueId = entry.key;
      final value = valueById[valueId];
      if (value == null) continue;

      final deficit = deficitById[valueId] ?? 0.0;
      final attentionNeeded = deficit >= _attentionDeficitThreshold;
      final visibleCount = entry.value.length > _maxVisibleSuggestionsPerValue
          ? _maxVisibleSuggestionsPerValue
          : entry.value.length;

      groups.add(
        PlanMyDayValueSuggestionGroup(
          valueId: valueId,
          value: value,
          tasks: entry.value,
          attentionNeeded: attentionNeeded,
          neglectScore: deficit,
          visibleCount: visibleCount,
          expanded: true,
        ),
      );
    }

    groups.sort((a, b) {
      switch (_valuesSort) {
        case PlanMyDayValueSort.attentionFirst:
          if (a.attentionNeeded != b.attentionNeeded) {
            return a.attentionNeeded ? -1 : 1;
          }
          final byPriority = _valuePriorityRank(
            a.value.priority,
          ).compareTo(_valuePriorityRank(b.value.priority));
          if (byPriority != 0) return byPriority;
          final byDeficit = b.neglectScore.compareTo(a.neglectScore);
          if (byDeficit != 0) return byDeficit;
          return a.value.name.compareTo(b.value.name);
        case PlanMyDayValueSort.priorityFirst:
          final byPriority = _valuePriorityRank(
            a.value.priority,
          ).compareTo(_valuePriorityRank(b.value.priority));
          if (byPriority != 0) return byPriority;
          if (a.attentionNeeded != b.attentionNeeded) {
            return a.attentionNeeded ? -1 : 1;
          }
          final byDeficit = b.neglectScore.compareTo(a.neglectScore);
          if (byDeficit != 0) return byDeficit;
          return a.value.name.compareTo(b.value.name);
        case PlanMyDayValueSort.mostSuggested:
          final byCount = b.totalCount.compareTo(a.totalCount);
          if (byCount != 0) return byCount;
          return a.value.name.compareTo(b.value.name);
        case PlanMyDayValueSort.alphabetical:
          return a.value.name.compareTo(b.value.name);
      }
    });

    return groups;
  }

  int _defaultVisibleCount(
    ValuePriority priority, {
    required bool attentionNeeded,
  }) {
    final base = switch (priority) {
      ValuePriority.high => attentionNeeded ? 4 : 3,
      ValuePriority.medium => attentionNeeded ? 3 : 2,
      ValuePriority.low => attentionNeeded ? 2 : 1,
    };
    return base > _maxVisibleSuggestionsPerValue
        ? _maxVisibleSuggestionsPerValue
        : base;
  }

  Value? _resolveValueForTask(Task task, String valueId) {
    for (final value in task.effectiveValues) {
      if (value.id == valueId) return value;
    }
    return null;
  }

  List<RoutineCompletion> _completionsForPeriod(
    Routine routine,
    RoutineCadenceSnapshot snapshot,
  ) {
    final periodStart = dateOnly(snapshot.periodStartUtc);
    final periodEnd = dateOnly(snapshot.periodEndUtc);
    final completions = <RoutineCompletion>[];

    for (final completion in _routineCompletions) {
      if (completion.routineId != routine.id) continue;
      final day = dateOnly(completion.completedAtUtc);
      if (day.isBefore(periodStart) || day.isAfter(periodEnd)) continue;
      completions.add(completion);
    }

    return completions;
  }

  DateTime? _deadlineDateOnly(Task task) {
    final raw = task.occurrence?.deadline ?? task.deadlineDate;
    return dateOnlyOrNull(raw);
  }

  DateTime? _startDateOnly(Task task) {
    final raw = task.occurrence?.date ?? task.startDate;
    return dateOnlyOrNull(raw);
  }

  bool _isDueTodayOrOverdue(Task task, DateTime today) {
    final deadline = _deadlineDateOnly(task);
    return deadline != null && !deadline.isAfter(today);
  }

  bool _isPlannedTodayOrEarlier(Task task, DateTime today) {
    final start = _startDateOnly(task);
    return start != null && !start.isAfter(today);
  }

  bool _isSameDayUtc(DateTime a, DateTime b) {
    return dateOnly(a).isAtSameMomentAs(dateOnly(b));
  }

  String _buildTaskRevision(List<Task> tasks) {
    if (tasks.isEmpty) return '';
    final entries =
        tasks
            .map((task) => '${task.id}:${task.updatedAt.toIso8601String()}')
            .toList()
          ..sort();
    return entries.join('|');
  }

  void _queueToast(PlanMyDayToast toast) {
    _pendingToast = toast;
    _toastRequestId += 1;
  }

  Routine? _findRoutine(String routineId) {
    for (final routine in _routines) {
      if (routine.id == routineId) return routine;
    }
    return null;
  }
}

@immutable
final class _RoutineItemBuildResult {
  const _RoutineItemBuildResult({
    required this.allItems,
    required this.scheduledEligible,
    required this.flexibleEligible,
  });

  final List<PlanMyDayRoutineItem> allItems;
  final List<PlanMyDayRoutineItem> scheduledEligible;
  final List<PlanMyDayRoutineItem> flexibleEligible;

  static const empty = _RoutineItemBuildResult(
    allItems: <PlanMyDayRoutineItem>[],
    scheduledEligible: <PlanMyDayRoutineItem>[],
    flexibleEligible: <PlanMyDayRoutineItem>[],
  );
}
