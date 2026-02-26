import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/presentation/shared/telemetry/operation_context_factory.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/utils/routine_completion_utils.dart';
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

final class PlanMyDaySkipRoutineInstanceRequested extends PlanMyDayEvent {
  const PlanMyDaySkipRoutineInstanceRequested({
    required this.routineId,
  });

  final String routineId;
}

final class PlanMyDaySkipRoutinePeriodRequested extends PlanMyDayEvent {
  const PlanMyDaySkipRoutinePeriodRequested({
    required this.routineId,
    required this.periodType,
    required this.periodKeyUtc,
  });

  final String routineId;
  final RoutineSkipPeriodType periodType;
  final DateTime periodKeyUtc;
}

final class PlanMyDayConfirm extends PlanMyDayEvent {
  const PlanMyDayConfirm({this.closeOnSuccess = false});

  final bool closeOnSuccess;
}

final class PlanMyDayDailyLimitChanged extends PlanMyDayEvent {
  const PlanMyDayDailyLimitChanged(this.limit);

  final int limit;
}

final class PlanMyDayValueSortChanged extends PlanMyDayEvent {
  const PlanMyDayValueSortChanged(this.sort);

  final PlanMyDayValueSort sort;
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
  lowestAverage,
  trendingDown,
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
    required this.lastCompletedAtUtc,
    required this.completionsInPeriod,
    required this.skipsInPeriod,
  });

  final Routine routine;
  final RoutineCadenceSnapshot snapshot;
  final bool selected;
  final bool completedToday;
  final bool isCatchUpDay;
  final bool isScheduled;
  final bool isEligibleToday;
  final DateTime? lastScheduledDayUtc;
  final DateTime? lastCompletedAtUtc;
  final List<RoutineCompletion> completionsInPeriod;
  final List<RoutineSkip> skipsInPeriod;

  PlanMyDayRoutineItem copyWith({
    bool? selected,
  }) {
    return PlanMyDayRoutineItem(
      routine: routine,
      snapshot: snapshot,
      selected: selected ?? this.selected,
      completedToday: completedToday,
      isCatchUpDay: isCatchUpDay,
      isScheduled: isScheduled,
      isEligibleToday: isEligibleToday,
      lastScheduledDayUtc: lastScheduledDayUtc,
      lastCompletedAtUtc: lastCompletedAtUtc,
      completionsInPeriod: completionsInPeriod,
      skipsInPeriod: skipsInPeriod,
    );
  }
}

@immutable
final class PlanMyDayValueSuggestionGroup {
  const PlanMyDayValueSuggestionGroup({
    required this.valueId,
    required this.value,
    required this.tasks,
    required this.averageRating,
    required this.trendDelta,
    required this.hasRatings,
    required this.isTrendingDown,
    required this.isLowAverage,
    required this.visibleCount,
    required this.expanded,
  });

  final String valueId;
  final Value value;
  final List<Task> tasks;
  final double? averageRating;
  final double? trendDelta;
  final bool hasRatings;
  final bool isTrendingDown;
  final bool isLowAverage;
  final int visibleCount;
  final bool expanded;

  int get totalCount => tasks.length;
}

@immutable
final class PlanMyDayValueRatingSummary {
  const PlanMyDayValueRatingSummary({
    required this.valueId,
    required this.averageRating,
    required this.trendDelta,
  });

  final String valueId;
  final double? averageRating;
  final double? trendDelta;
}

@immutable
final class PlanMyDayToast {
  const PlanMyDayToast._(this.kind, {this.error});

  const PlanMyDayToast.updated() : this._(PlanMyDayToastKind.updated);

  const PlanMyDayToast.error(Object error)
    : this._(PlanMyDayToastKind.error, error: error);

  final PlanMyDayToastKind kind;
  final Object? error;
}

enum PlanMyDayToastKind { updated, error }

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

final class _PlanMyDayRatingsUpdated extends _PlanMyDayStreamEvent {
  const _PlanMyDayRatingsUpdated(this.ratings);

  final List<ValueWeeklyRating> ratings;
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
    required this.unratedValues,
    required this.scheduledRoutines,
    required this.flexibleRoutines,
    required this.selectedTaskIds,
    required this.selectedRoutineIds,
    required this.allTasks,
    required this.routineSelectionsByValue,
    required this.overCapacity,
    required this.valueSort,
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
  final List<Value> unratedValues;
  final List<PlanMyDayRoutineItem> scheduledRoutines;
  final List<PlanMyDayRoutineItem> flexibleRoutines;
  final Set<String> selectedTaskIds;
  final Set<String> selectedRoutineIds;
  final List<Task> allTasks;
  final Map<String, int> routineSelectionsByValue;
  final bool overCapacity;
  final PlanMyDayValueSort valueSort;
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
    List<Value>? unratedValues,
    List<PlanMyDayRoutineItem>? scheduledRoutines,
    List<PlanMyDayRoutineItem>? flexibleRoutines,
    Set<String>? selectedTaskIds,
    Set<String>? selectedRoutineIds,
    List<Task>? allTasks,
    Map<String, int>? routineSelectionsByValue,
    bool? overCapacity,
    PlanMyDayValueSort? valueSort,
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
      unratedValues: unratedValues ?? this.unratedValues,
      scheduledRoutines: scheduledRoutines ?? this.scheduledRoutines,
      flexibleRoutines: flexibleRoutines ?? this.flexibleRoutines,
      selectedTaskIds: selectedTaskIds ?? this.selectedTaskIds,
      selectedRoutineIds: selectedRoutineIds ?? this.selectedRoutineIds,
      allTasks: allTasks ?? this.allTasks,
      routineSelectionsByValue:
          routineSelectionsByValue ?? this.routineSelectionsByValue,
      overCapacity: overCapacity ?? this.overCapacity,
      valueSort: valueSort ?? this.valueSort,
      toastRequestId: toastRequestId ?? this.toastRequestId,
      nav: nav ?? this.nav,
      navRequestId: navRequestId ?? this.navRequestId,
      toast: toast ?? this.toast,
    );
  }
}

@visibleForTesting
List<PlanMyDayValueSuggestionGroup> filterSuggestionGroupsForCommittedTasks({
  required List<PlanMyDayValueSuggestionGroup> groups,
  required Set<String> dueTodayTaskIds,
  required Set<String> plannedTaskIds,
}) {
  final committedTaskIds = {...dueTodayTaskIds, ...plannedTaskIds};
  if (committedTaskIds.isEmpty) {
    return groups;
  }

  final filtered = <PlanMyDayValueSuggestionGroup>[];
  for (final group in groups) {
    final tasks = group.tasks
        .where((task) => !committedTaskIds.contains(task.id))
        .toList(growable: false);
    if (tasks.isEmpty) continue;

    final visibleCount = group.visibleCount > tasks.length
        ? tasks.length
        : group.visibleCount;
    filtered.add(
      PlanMyDayValueSuggestionGroup(
        valueId: group.valueId,
        value: group.value,
        tasks: tasks,
        averageRating: group.averageRating,
        trendDelta: group.trendDelta,
        hasRatings: group.hasRatings,
        isTrendingDown: group.isTrendingDown,
        isLowAverage: group.isLowAverage,
        visibleCount: visibleCount,
        expanded: group.expanded,
      ),
    );
  }

  return filtered;
}

class PlanMyDayBloc extends Bloc<PlanMyDayEvent, PlanMyDayState> {
  PlanMyDayBloc({
    required SettingsRepositoryContract settingsRepository,
    required MyDayRepositoryContract myDayRepository,
    required TaskSuggestionService taskSuggestionService,
    required TaskRepositoryContract taskRepository,
    required ValueRatingsRepositoryContract valueRatingsRepository,
    required RoutineRepositoryContract routineRepository,
    required ProjectAnchorStateRepositoryContract projectAnchorStateRepository,
    required TaskWriteService taskWriteService,
    required RoutineWriteService routineWriteService,
    required HomeDayKeyService dayKeyService,
    required TemporalTriggerService temporalTriggerService,
    required NowService nowService,
    required OccurrenceReadService occurrenceReadService,
    required DemoModeService demoModeService,
    required DemoDataProvider demoDataProvider,
    RoutineScheduleService scheduleService = const RoutineScheduleService(),
  }) : _settingsRepository = settingsRepository,
       _myDayRepository = myDayRepository,
       _taskSuggestionService = taskSuggestionService,
       _taskRepository = taskRepository,
       _valueRatingsRepository = valueRatingsRepository,
       _routineRepository = routineRepository,
       _projectAnchorStateRepository = projectAnchorStateRepository,
       _taskWriteService = taskWriteService,
       _routineWriteService = routineWriteService,
       _dayKeyService = dayKeyService,
       _temporalTriggerService = temporalTriggerService,
       _nowService = nowService,
       _demoModeService = demoModeService,
       _demoDataProvider = demoDataProvider,
       _occurrenceReadService = occurrenceReadService,
       _scheduleService = scheduleService,
       _dayKeyUtc = dayKeyService.todayDayKeyUtc(),
       super(const PlanMyDayLoading()) {
    on<PlanMyDayStarted>(_onStarted, transformer: restartable());
    on<PlanMyDayToggleTask>(_onToggleTask);
    on<PlanMyDayToggleRoutine>(_onToggleRoutine);
    on<PlanMyDaySwapSuggestionRequested>(_onSwapSuggestionRequested);
    on<PlanMyDayPauseRoutineRequested>(_onPauseRoutineRequested);
    on<PlanMyDaySkipRoutineInstanceRequested>(_onSkipRoutineInstanceRequested);
    on<PlanMyDaySkipRoutinePeriodRequested>(_onSkipRoutinePeriodRequested);
    on<PlanMyDayConfirm>(_onConfirm);
    on<PlanMyDayDailyLimitChanged>(_onDailyLimitChanged);
    on<PlanMyDayValueSortChanged>(_onValueSortChanged);
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
  final ValueRatingsRepositoryContract _valueRatingsRepository;
  final RoutineRepositoryContract _routineRepository;
  final ProjectAnchorStateRepositoryContract _projectAnchorStateRepository;
  final TaskWriteService _taskWriteService;
  final RoutineWriteService _routineWriteService;
  final HomeDayKeyService _dayKeyService;
  final TemporalTriggerService _temporalTriggerService;
  final NowService _nowService;
  final DemoModeService _demoModeService;
  final DemoDataProvider _demoDataProvider;
  final OccurrenceReadService _occurrenceReadService;
  final RoutineScheduleService _scheduleService;

  final OperationContextFactory _contextFactory =
      const OperationContextFactory();

  static const int _poolExtraCount = 6;
  static const int _ratingsWindowWeeks = 4;
  static const int _ratingsHistoryWeeks = 8;
  static const double _trendEmphasisThreshold = -0.6;
  static const double _lowAverageThreshold = 4.5;

  settings.GlobalSettings _globalSettings = const settings.GlobalSettings();
  AllocationConfig _allocationConfig = const AllocationConfig();
  DateTime _dayKeyUtc;

  TaskSuggestionSnapshot? _suggestionSnapshot;
  List<ValueWeeklyRating> _ratingHistory = const <ValueWeeklyRating>[];
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

  PlanMyDayValueSort _valuesSort = PlanMyDayValueSort.lowestAverage;
  String _taskRevisionStamp = '';

  Completer<void>? _refreshCompleter;
  bool _isDemoMode = false;
  int _toastRequestId = 0;
  PlanMyDayToast? _pendingToast;
  String? _lastSuggestionInputHash;

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
      _watchIncompleteTasksForCurrentDay().map(_PlanMyDayTasksUpdated.new),
      _valueRatingsRepository
          .watchAll(weeks: _ratingsHistoryWeeks)
          .map(_PlanMyDayRatingsUpdated.new),
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
              final allowSuggestionRefresh =
                  _dayPicks.ritualCompletedAtUtc == null;
              await _refreshSnapshots(
                resetSelection: false,
                allowSuggestionRefresh: allowSuggestionRefresh,
              );
              if (emit.isDone || _isDemoMode) return;
              _emitReady(emit);
            }
          case _PlanMyDayTasksUpdated(:final tasks):
            if (_isDemoMode) return;
            final revision = _buildTaskRevision(tasks);
            if (revision == _taskRevisionStamp) return;
            _taskRevisionStamp = revision;
            final allowSuggestionRefresh =
                _dayPicks.ritualCompletedAtUtc == null;
            await _refreshSnapshots(
              resetSelection: false,
              allowSuggestionRefresh: allowSuggestionRefresh,
            );
            if (emit.isDone || _isDemoMode) return;
            _emitReady(emit);
          case _PlanMyDayRatingsUpdated(:final ratings):
            if (_isDemoMode) return;
            _ratingHistory = ratings;
            final allowSuggestionRefresh =
                _dayPicks.ritualCompletedAtUtc == null;
            await _refreshSnapshots(
              resetSelection: false,
              allowSuggestionRefresh: allowSuggestionRefresh,
            );
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

  Future<void> _onSkipRoutineInstanceRequested(
    PlanMyDaySkipRoutineInstanceRequested event,
    Emitter<PlanMyDayState> emit,
  ) async {
    if (_isDemoMode) return;
    final routine = _findRoutine(event.routineId);
    if (routine == null) return;

    final skipDayUtc = dateOnly(_dayKeyUtc);
    final pausedUntilUtc = skipDayUtc.add(const Duration(days: 1));
    final context = _contextFactory.create(
      feature: 'routines',
      screen: 'plan_my_day',
      intent: 'skip_instance',
      operation: 'routine.skip_instance',
      entityType: 'routine',
      entityId: routine.id,
      extraFields: <String, Object?>{
        'skipDayUtc': skipDayUtc.toIso8601String(),
        'pausedUntilUtc': pausedUntilUtc.toIso8601String(),
      },
    );

    await _routineWriteService.setPausedUntil(
      routine.id,
      pausedUntilUtc: pausedUntilUtc,
      context: context,
    );

    _selectedRoutineIds = {..._selectedRoutineIds}..remove(routine.id);
    await _refreshSnapshots(resetSelection: false);
    if (emit.isDone) return;
    _emitReady(emit);
  }

  Future<void> _onSkipRoutinePeriodRequested(
    PlanMyDaySkipRoutinePeriodRequested event,
    Emitter<PlanMyDayState> emit,
  ) async {
    if (_isDemoMode) return;
    final routine = _findRoutine(event.routineId);
    if (routine == null) return;

    final context = _contextFactory.create(
      feature: 'routines',
      screen: 'plan_my_day',
      intent: 'skip_period',
      operation: 'routine.skip_period',
      entityType: 'routine',
      entityId: routine.id,
      extraFields: <String, Object?>{
        'periodType': event.periodType.name,
        'periodKeyUtc': event.periodKeyUtc.toIso8601String(),
      },
    );

    await _routineWriteService.recordSkip(
      routineId: routine.id,
      periodType: event.periodType,
      periodKeyUtc: event.periodKeyUtc,
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
          qualifyingValueId: routine.value?.id,
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
              : suggestedInfo.reasonCodes.map((c) => c.name).toList(),
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

    final anchorProjectIds =
        _suggestionSnapshot?.anchorProjectIds ?? const <String>[];
    if (anchorProjectIds.isNotEmpty) {
      final anchorContext = context.copyWith(
        intent: 'confirm_anchors',
        operation: 'project_anchor_state.record_anchors',
        entityType: 'project_anchor_state',
        extraFields: <String, Object?>{
          ...context.extraFields,
          'anchorCount': anchorProjectIds.length,
        },
      );
      await _projectAnchorStateRepository.recordAnchors(
        projectIds: anchorProjectIds,
        anchoredAtUtc: nowUtc,
        context: anchorContext,
      );
    }

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

  void _onValueSortChanged(
    PlanMyDayValueSortChanged event,
    Emitter<PlanMyDayState> emit,
  ) {
    if (_valuesSort == event.sort) return;
    _valuesSort = event.sort;
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

    try {
      await _taskWriteService.bulkRescheduleDeadlines(
        taskIds,
        newDeadlineDay,
        context: context,
      );
    } catch (error) {
      _queueToast(PlanMyDayToast.error(error));
      if (emit.isDone) return;
      _emitReady(emit);
      return;
    }

    _hasUserSelection = true;
    _selectedTaskIds = _selectedTaskIds.difference(_dueTodayTaskIds);
    _queueToast(const PlanMyDayToast.updated());
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

    try {
      await _taskWriteService.bulkRescheduleDeadlines(
        [event.taskId],
        newDeadlineDay,
        context: context,
      );
    } catch (error) {
      _queueToast(PlanMyDayToast.error(error));
      if (emit.isDone) return;
      _emitReady(emit);
      return;
    }

    _hasUserSelection = true;
    _selectedTaskIds = {..._selectedTaskIds}..remove(event.taskId);
    _queueToast(const PlanMyDayToast.updated());
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

    try {
      await _taskWriteService.bulkRescheduleStarts(
        taskIds,
        newStartDay,
        context: context,
      );
    } catch (error) {
      _queueToast(PlanMyDayToast.error(error));
      if (emit.isDone) return;
      _emitReady(emit);
      return;
    }

    _hasUserSelection = true;
    _selectedTaskIds = _selectedTaskIds.difference(_plannedTaskIds);
    _queueToast(const PlanMyDayToast.updated());
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

    try {
      await _taskWriteService.bulkRescheduleStarts(
        [event.taskId],
        newStartDay,
        context: context,
      );
    } catch (error) {
      _queueToast(PlanMyDayToast.error(error));
      if (emit.isDone) return;
      _emitReady(emit);
      return;
    }

    _hasUserSelection = true;
    _selectedTaskIds = {..._selectedTaskIds}..remove(event.taskId);
    _queueToast(const PlanMyDayToast.updated());
    await _refreshSnapshots(resetSelection: false);
    if (emit.isDone) return;
    _emitReady(emit);
  }

  Future<void> _refreshSnapshots({
    required bool resetSelection,
    bool allowSuggestionRefresh = true,
  }) async {
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
      _lastSuggestionInputHash = null;
    }

    try {
      final results = await Future.wait([
        _settingsRepository.load<settings.GlobalSettings>(SettingsKey.global),
        _settingsRepository.load<AllocationConfig>(SettingsKey.allocation),
        _valueRatingsRepository.getAll(weeks: _ratingsHistoryWeeks),
        _myDayRepository.loadDay(_dayKeyUtc),
        _loadIncompleteTasks(),
        _routineRepository.getAll(includeInactive: true),
        _routineRepository.getCompletions(),
        _routineRepository.getSkips(),
      ]);

      _globalSettings = results[0] as settings.GlobalSettings;
      _allocationConfig = results[1] as AllocationConfig;
      _ratingHistory = results[2] as List<ValueWeeklyRating>;

      final picks = results[3] as my_day.MyDayDayPicks;
      _dayPicks = picks;

      final incompleteTasks = results[4] as List<Task>;
      _incompleteTasks = incompleteTasks;
      _taskRevisionStamp = _buildTaskRevision(incompleteTasks);

      final routines = results[5] as List<Routine>;
      final completions = results[6] as List<RoutineCompletion>;
      final skips = results[7] as List<RoutineSkip>;

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

      final shouldRefreshSuggestions =
          allowSuggestionRefresh && _shouldRefreshSuggestions();
      if (shouldRefreshSuggestions) {
        final routineSelections = _routineSelectionsByValue();
        final triageSelections = _triageSelectionsByValue();
        final selectionCounts = _mergeSelectionCounts(
          routineSelections,
          triageSelections,
        );
        final targetCount = _suggestionPoolTargetCount();
        final inputHash = _buildSuggestionInputHash(
          selectionCounts: selectionCounts,
          targetCount: targetCount,
        );
        if (inputHash != _lastSuggestionInputHash) {
          await _refreshSuggestions(
            selectionCounts: selectionCounts,
            targetCount: targetCount,
          );
          _lastSuggestionInputHash = inputHash;
        }
      }
    } finally {
      _refreshCompleter = null;
      completer.complete();
    }
  }

  Future<void> _refreshSuggestions({
    required Map<String, int> selectionCounts,
    required int targetCount,
  }) async {
    final context = _contextFactory.create(
      feature: 'plan_my_day',
      screen: 'plan_my_day',
      intent: 'refresh_suggestions',
      operation: 'getSuggestedSnapshot',
    );

    _suggestionSnapshot = await _taskSuggestionService.getSnapshot(
      batchCount: _suggestionBatchCount,
      suggestedTargetCount: targetCount,
      tasksOverride: _incompleteTasks,
      routineSelectionsByValue: selectionCounts,
      nowUtc: _nowService.nowUtc(),
      context: context,
    );
  }

  Stream<List<Task>> _watchIncompleteTasksForCurrentDay() {
    return _occurrenceReadService.watchTasksWithOccurrencePreview(
      query: TaskQuery.incomplete(),
      preview: OccurrencePolicy.projectsPreview(asOfDayKey: _dayKeyUtc),
    );
  }

  Future<List<Task>> _loadIncompleteTasks() {
    return _occurrenceReadService.getTasksWithOccurrencePreview(
      query: TaskQuery.incomplete(),
      preview: OccurrencePolicy.projectsPreview(asOfDayKey: _dayKeyUtc),
    );
  }

  void _emitReady(Emitter<PlanMyDayState> emit) {
    final snapshot = _suggestionSnapshot;
    final suggestedEntries = snapshot?.suggested ?? const <SuggestedTask>[];
    final ratingSummaries = _buildRatingSummaries(
      tasks: _incompleteTasks,
      ratings: _ratingHistory,
      nowUtc: _nowService.nowUtc(),
    );
    final unratedValues = _buildUnratedValues(
      tasks: _incompleteTasks,
      ratingSummaries: ratingSummaries,
    );

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
        .where((task) => _isPlannedForTodayOrEarlier(task, today))
        .where((task) => !dueIds.contains(task.id))
        .toList(growable: false);
    final valueGroups = filterSuggestionGroupsForCommittedTasks(
      groups: _buildValueSuggestionGroups(
        suggestedEntries,
        ratingSummaries: ratingSummaries,
      ),
      dueTodayTaskIds: dueIds,
      plannedTaskIds: plannedTasks.map((task) => task.id).toSet(),
    );
    final suggested = valueGroups
        .expand((group) => group.tasks)
        .toList(growable: false);

    final routineItems = _buildRoutineItems();
    final scheduledRoutines = routineItems.scheduledEligible;
    final flexibleRoutines = routineItems.flexibleEligible;

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
    final selectedRoutineIds = _selectedRoutineIds;
    final selectedScheduledRoutines = _withSelectedRoutineState(
      scheduledRoutines,
      selectedRoutineIds,
    );
    final selectedFlexibleRoutines = _withSelectedRoutineState(
      flexibleRoutines,
      selectedRoutineIds,
    );
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
        unratedValues: unratedValues,
        scheduledRoutines: selectedScheduledRoutines,
        flexibleRoutines: selectedFlexibleRoutines,
        selectedTaskIds: selectedTaskIds,
        selectedRoutineIds: selectedRoutineIds,
        allTasks: activeTasks,
        routineSelectionsByValue: _routineSelectionsByValue(),
        overCapacity: overCapacity,
        valueSort: _valuesSort,
        toastRequestId: toastRequestId,
        toast: toast,
      ),
    );
    _pendingToast = null;
  }

  List<PlanMyDayRoutineItem> _withSelectedRoutineState(
    List<PlanMyDayRoutineItem> items,
    Set<String> selectedRoutineIds,
  ) {
    return items
        .map((item) {
          final isSelected = selectedRoutineIds.contains(item.routine.id);
          if (item.selected == isSelected) return item;
          return item.copyWith(selected: isSelected);
        })
        .toList(growable: false);
  }

  _RoutineItemBuildResult _buildRoutineItems() {
    final todayKey = dateOnly(_dayKeyUtc);
    final scheduledEligible = <PlanMyDayRoutineItem>[];
    final flexibleEligible = <PlanMyDayRoutineItem>[];

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
      final completionsInPeriod = _completionsForPeriod(routine, snapshot);
      final isCompletedToday = isRoutineCompleteForDay(
        routine: routine,
        snapshot: snapshot,
        dayKeyUtc: _dayKeyUtc,
        completionsInPeriod: completionsInPeriod,
      );
      final item = PlanMyDayRoutineItem(
        routine: routine,
        snapshot: snapshot,
        selected: _selectedRoutineIds.contains(routine.id),
        completedToday: isCompletedToday,
        isCatchUpDay: policy.isCatchUpDay,
        isScheduled: policy.cadenceKind == RoutineCadenceKind.scheduled,
        isEligibleToday: policy.isEligibleToday && !isCompletedToday,
        lastScheduledDayUtc: policy.lastScheduledDayUtc,
        lastCompletedAtUtc: _lastCompletionForRoutine(routine.id),
        completionsInPeriod: completionsInPeriod,
        skipsInPeriod: _skipsForPeriod(routine, snapshot),
      );

      if (item.isEligibleToday) {
        if (item.isScheduled) {
          scheduledEligible.add(item);
        } else {
          flexibleEligible.add(item);
        }
      }
    }

    scheduledEligible.sort(_compareScheduledRoutines);
    flexibleEligible.sort(_compareFlexibleRoutines);

    return _RoutineItemBuildResult(
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
    if (a.isCatchUpDay && b.isCatchUpDay) {}

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

    final byLastCompleted = _compareLastCompleted(a, b);
    if (byLastCompleted != 0) return byLastCompleted;

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

  int _compareLastCompleted(
    PlanMyDayRoutineItem a,
    PlanMyDayRoutineItem b,
  ) {
    final aDay = a.lastCompletedAtUtc;
    final bDay = b.lastCompletedAtUtc;
    if (aDay == null && bDay == null) return 0;
    if (aDay == null) return -1;
    if (bDay == null) return 1;
    return aDay.compareTo(bDay);
  }

  DateTime? _lastCompletionForRoutine(String routineId) {
    DateTime? latest;
    for (final completion in _routineCompletions) {
      if (completion.routineId != routineId) continue;
      final when = completion.completedAtUtc;
      if (latest == null || when.isAfter(latest)) {
        latest = when;
      }
    }
    return latest;
  }

  Map<String, int> _routineSelectionsByValue() {
    final routinesById = {for (final routine in _routines) routine.id: routine};
    final counts = <String, int>{};
    for (final routineId in _selectedRoutineIds) {
      final routine = routinesById[routineId];
      if (routine == null) continue;
      final valueId = routine.value?.id;
      if (valueId == null || valueId.isEmpty) continue;
      counts[valueId] = (counts[valueId] ?? 0) + 1;
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
    final summaries = _buildRatingSummaries(
      tasks: _incompleteTasks,
      ratings: _ratingHistory,
      nowUtc: _nowService.nowUtc(),
    );
    if (summaries.isEmpty) return 0;

    var total = 0;
    for (final summary in summaries.values) {
      final defaultVisible = _defaultVisibleCount(summary);
      total += defaultVisible + _poolExtraCount;
    }

    return total * _suggestionBatchCount;
  }

  Map<String, Value> _valuesByIdFromTasks(List<Task> tasks) {
    final valuesById = <String, Value>{};
    for (final task in tasks) {
      for (final value in task.effectiveValues) {
        valuesById[value.id] = value;
      }
    }
    return valuesById;
  }

  Map<String, PlanMyDayValueRatingSummary> _buildRatingSummaries({
    required List<Task> tasks,
    required List<ValueWeeklyRating> ratings,
    required DateTime nowUtc,
  }) {
    final valuesById = _valuesByIdFromTasks(tasks);
    if (valuesById.isEmpty) return const {};

    final ratingsByValue = <String, Map<DateTime, int>>{};
    for (final rating in ratings) {
      final weekStart = _weekStartFor(rating.weekStartUtc);
      (ratingsByValue[rating.valueId] ??= {})[weekStart] = rating.rating.clamp(
        1,
        10,
      );
    }

    final nowWeekStart = _weekStartFor(nowUtc);
    final recentWeeks = <DateTime>[
      for (var i = _ratingsWindowWeeks - 1; i >= 0; i--)
        nowWeekStart.subtract(Duration(days: i * 7)),
    ];
    final priorWeeks = <DateTime>[
      for (var i = (_ratingsWindowWeeks * 2) - 1; i >= _ratingsWindowWeeks; i--)
        nowWeekStart.subtract(Duration(days: i * 7)),
    ];

    final summaries = <String, PlanMyDayValueRatingSummary>{};
    for (final entry in valuesById.entries) {
      final valueId = entry.key;
      final perWeek = ratingsByValue[valueId] ?? const {};
      final recentRatings = <int>[
        for (final week in recentWeeks)
          if (perWeek[week] != null) perWeek[week]!,
      ];
      final priorRatings = <int>[
        for (final week in priorWeeks)
          if (perWeek[week] != null) perWeek[week]!,
      ];

      final averageRating = recentRatings.isEmpty
          ? null
          : recentRatings.fold<int>(0, (sum, v) => sum + v) /
                recentRatings.length;
      final priorAverage = priorRatings.isEmpty
          ? null
          : priorRatings.fold<int>(0, (sum, v) => sum + v) /
                priorRatings.length;
      final trendDelta = (averageRating != null && priorAverage != null)
          ? averageRating - priorAverage
          : null;

      summaries[valueId] = PlanMyDayValueRatingSummary(
        valueId: valueId,
        averageRating: averageRating,
        trendDelta: trendDelta,
      );
    }

    return summaries;
  }

  List<Value> _buildUnratedValues({
    required List<Task> tasks,
    required Map<String, PlanMyDayValueRatingSummary> ratingSummaries,
  }) {
    final valuesById = _valuesByIdFromTasks(tasks);
    if (valuesById.isEmpty) return const <Value>[];

    final unrated = <Value>[];
    for (final entry in valuesById.entries) {
      final summary = ratingSummaries[entry.key];
      if (summary?.averageRating != null) continue;
      unrated.add(entry.value);
    }

    unrated.sort((a, b) => a.name.compareTo(b.name));
    return unrated;
  }

  bool _shouldRefreshSuggestions() {
    if (_dayPicks.ritualCompletedAtUtc == null) return true;
    if (_suggestionSnapshot == null) return true;
    return _remainingSlotCount() > 0;
  }

  int _remainingSlotCount() {
    final activeTaskIds = _dayPicks.selectedTaskIds
        .where((id) => !_lockedCompletedPickIds.contains(id))
        .toSet();
    final activeRoutineIds = _dayPicks.selectedRoutineIds
        .where((id) => !_lockedCompletedRoutineIds.contains(id))
        .toSet();
    final activeCount = activeTaskIds.length + activeRoutineIds.length;
    return _dailyLimit - activeCount;
  }

  String _buildSuggestionInputHash({
    required Map<String, int> selectionCounts,
    required int targetCount,
  }) {
    final buffer = StringBuffer()
      ..write(dateOnly(_dayKeyUtc).toIso8601String())
      ..write('|')
      ..write(_allocationConfig.hashCode)
      ..write('|')
      ..write(_suggestionBatchCount)
      ..write('|')
      ..write(_taskRevisionStamp)
      ..write('|')
      ..write(_buildRatingsSignature())
      ..write('|')
      ..write(targetCount)
      ..write('|')
      ..write(_mapSignature(selectionCounts));
    return buffer.toString();
  }

  String _mapSignature(Map<String, int> counts) {
    if (counts.isEmpty) return '';
    final entries = counts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries.map((entry) => '${entry.key}:${entry.value}').join('|');
  }

  String _buildRatingsSignature() {
    if (_ratingHistory.isEmpty) return '';
    final entries =
        _ratingHistory
            .map(
              (rating) =>
                  '${rating.valueId}:${dateOnly(rating.weekStartUtc).toIso8601String()}:${rating.rating}',
            )
            .toList()
          ..sort();
    return entries.join('|');
  }

  List<PlanMyDayValueSuggestionGroup> _buildValueSuggestionGroups(
    List<SuggestedTask> suggested, {
    required Map<String, PlanMyDayValueRatingSummary> ratingSummaries,
  }) {
    if (suggested.isEmpty) return const [];

    final groupsById = <String, List<Task>>{};
    final valueById = <String, Value>{};

    for (final entry in suggested) {
      final valueId = entry.qualifyingValueId?.trim().isNotEmpty ?? false
          ? entry.qualifyingValueId!.trim()
          : entry.task.effectivePrimaryValueId;
      if (valueId == null || valueId.isEmpty) continue;

      final value = _resolveValueForTask(entry.task, valueId);
      if (value == null) continue;

      groupsById.putIfAbsent(valueId, () => []).add(entry.task);
      valueById[valueId] = value;
    }

    final groups = <PlanMyDayValueSuggestionGroup>[];
    for (final entry in groupsById.entries) {
      final valueId = entry.key;
      final value = valueById[valueId];
      if (value == null) continue;

      final summary = ratingSummaries[valueId];
      final averageRating = summary?.averageRating;
      final trendDelta = summary?.trendDelta;
      final hasRatings = averageRating != null;
      final isTrendingDown =
          trendDelta != null && trendDelta <= _trendEmphasisThreshold;
      final isLowAverage =
          averageRating != null && averageRating <= _lowAverageThreshold;
      final defaultVisible = _defaultVisibleCount(summary);
      final visibleCount = entry.value.length < defaultVisible
          ? entry.value.length
          : defaultVisible;

      groups.add(
        PlanMyDayValueSuggestionGroup(
          valueId: valueId,
          value: value,
          tasks: entry.value,
          averageRating: averageRating,
          trendDelta: trendDelta,
          hasRatings: hasRatings,
          isTrendingDown: isTrendingDown,
          isLowAverage: isLowAverage,
          visibleCount: visibleCount,
          expanded: true,
        ),
      );
    }

    groups.sort((a, b) {
      switch (_valuesSort) {
        case PlanMyDayValueSort.lowestAverage:
          final avgA = a.averageRating ?? double.infinity;
          final avgB = b.averageRating ?? double.infinity;
          final byAvg = avgA.compareTo(avgB);
          if (byAvg != 0) return byAvg;
          final trendA = a.trendDelta ?? double.infinity;
          final trendB = b.trendDelta ?? double.infinity;
          final byTrend = trendA.compareTo(trendB);
          if (byTrend != 0) return byTrend;
          return a.value.name.compareTo(b.value.name);
        case PlanMyDayValueSort.trendingDown:
          final trendA = a.trendDelta ?? double.infinity;
          final trendB = b.trendDelta ?? double.infinity;
          final byTrend = trendA.compareTo(trendB);
          if (byTrend != 0) return byTrend;
          final avgA = a.averageRating ?? double.infinity;
          final avgB = b.averageRating ?? double.infinity;
          final byAvg = avgA.compareTo(avgB);
          if (byAvg != 0) return byAvg;
          return a.value.name.compareTo(b.value.name);
      }
    });

    return groups;
  }

  int _defaultVisibleCount(PlanMyDayValueRatingSummary? summary) {
    final averageRating = summary?.averageRating;
    if (averageRating == null) return 0;
    final trendDelta = summary?.trendDelta;
    if (trendDelta != null && trendDelta <= _trendEmphasisThreshold) {
      return 3;
    }
    if (averageRating <= _lowAverageThreshold) {
      return 2;
    }
    return 1;
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

  List<RoutineSkip> _skipsForPeriod(
    Routine routine,
    RoutineCadenceSnapshot snapshot,
  ) {
    if (routine.periodType != RoutinePeriodType.week) {
      return const <RoutineSkip>[];
    }

    final periodStart = dateOnly(snapshot.periodStartUtc);
    return _routineSkips
        .where((skip) => skip.routineId == routine.id)
        .where((skip) => skip.periodType == RoutineSkipPeriodType.week)
        .where(
          (skip) => dateOnly(skip.periodKeyUtc).isAtSameMomentAs(periodStart),
        )
        .toList(growable: false);
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

  bool _isPlannedForTodayOrEarlier(Task task, DateTime today) {
    final start = _startDateOnly(task);
    return start != null && !start.isAfter(today);
  }

  bool _isSameDayUtc(DateTime a, DateTime b) {
    return dateOnly(a).isAtSameMomentAs(dateOnly(b));
  }

  DateTime _weekStartFor(DateTime dateTime) {
    final day = dateOnly(dateTime);
    return day.subtract(Duration(days: day.weekday - 1));
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
    required this.scheduledEligible,
    required this.flexibleEligible,
  });

  final List<PlanMyDayRoutineItem> scheduledEligible;
  final List<PlanMyDayRoutineItem> flexibleEligible;
}
