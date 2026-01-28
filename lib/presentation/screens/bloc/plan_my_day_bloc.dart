import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter/foundation.dart';
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

sealed class PlanMyDayEvent {
  const PlanMyDayEvent();
}

final class PlanMyDayStarted extends PlanMyDayEvent {
  const PlanMyDayStarted();
}

final class PlanMyDayStepRequested extends PlanMyDayEvent {
  const PlanMyDayStepRequested(this.step);

  final PlanMyDayStep step;
}

final class PlanMyDayStepBackRequested extends PlanMyDayEvent {
  const PlanMyDayStepBackRequested();
}

final class PlanMyDayStepNextRequested extends PlanMyDayEvent {
  const PlanMyDayStepNextRequested();
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

final class PlanMyDayValueSortChanged extends PlanMyDayEvent {
  const PlanMyDayValueSortChanged(this.sort);

  final PlanMyDayValueSort sort;
}

final class PlanMyDayValueToggleExpanded extends PlanMyDayEvent {
  const PlanMyDayValueToggleExpanded(this.valueId);

  final String valueId;
}

final class PlanMyDayValueShowMore extends PlanMyDayEvent {
  const PlanMyDayValueShowMore(this.valueId);

  final String valueId;
}

final class PlanMyDaySwitchToBehaviorSuggestionsRequested
    extends PlanMyDayEvent {
  const PlanMyDaySwitchToBehaviorSuggestionsRequested();
}

enum PlanMyDayStep {
  valuesStep,
  routines,
  triage,
  summary,
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
final class PlanMyDayReady extends PlanMyDayState {
  const PlanMyDayReady({
    required this.needsPlan,
    required this.dayKeyUtc,
    required this.globalSettings,
    required this.suggestionSignal,
    required this.steps,
    required this.currentStep,
    required this.dueWindowDays,
    required this.showAvailableToStart,
    required this.showDueSoon,
    required this.requiresValueSetup,
    required this.requiresRatings,
    required this.countRoutinesAgainstValues,
    required this.suggested,
    required this.triageDue,
    required this.triageStarts,
    required this.scheduledRoutines,
    required this.flexibleRoutines,
    required this.allRoutines,
    required this.selectedTaskIds,
    required this.selectedRoutineIds,
    required this.allTasks,
    required this.routineSelectionsByValue,
    required this.valueSuggestionGroups,
    required this.valueSort,
    required this.spotlightTaskId,
    this.nav,
    this.navRequestId = 0,
  });

  final bool needsPlan;
  final DateTime dayKeyUtc;
  final settings.GlobalSettings globalSettings;
  final SuggestionSignal suggestionSignal;
  final List<PlanMyDayStep> steps;
  final PlanMyDayStep currentStep;
  final int dueWindowDays;
  final bool showAvailableToStart;
  final bool showDueSoon;
  final bool requiresValueSetup;
  final bool requiresRatings;
  final bool countRoutinesAgainstValues;
  final List<Task> suggested;
  final List<Task> triageDue;
  final List<Task> triageStarts;
  final List<PlanMyDayRoutineItem> scheduledRoutines;
  final List<PlanMyDayRoutineItem> flexibleRoutines;
  final List<PlanMyDayRoutineItem> allRoutines;
  final Set<String> selectedTaskIds;
  final Set<String> selectedRoutineIds;
  final List<Task> allTasks;
  final Map<String, int> routineSelectionsByValue;
  final List<PlanMyDayValueSuggestionGroup> valueSuggestionGroups;
  final PlanMyDayValueSort valueSort;
  final String? spotlightTaskId;
  final PlanMyDayNav? nav;
  final int navRequestId;

  int get currentStepIndex => steps.indexOf(currentStep);

  PlanMyDayReady copyWith({
    bool? needsPlan,
    DateTime? dayKeyUtc,
    settings.GlobalSettings? globalSettings,
    SuggestionSignal? suggestionSignal,
    List<PlanMyDayStep>? steps,
    PlanMyDayStep? currentStep,
    int? dueWindowDays,
    bool? showAvailableToStart,
    bool? showDueSoon,
    bool? requiresValueSetup,
    bool? requiresRatings,
    bool? countRoutinesAgainstValues,
    List<Task>? suggested,
    List<Task>? triageDue,
    List<Task>? triageStarts,
    List<PlanMyDayRoutineItem>? scheduledRoutines,
    List<PlanMyDayRoutineItem>? flexibleRoutines,
    List<PlanMyDayRoutineItem>? allRoutines,
    Set<String>? selectedTaskIds,
    Set<String>? selectedRoutineIds,
    List<Task>? allTasks,
    Map<String, int>? routineSelectionsByValue,
    List<PlanMyDayValueSuggestionGroup>? valueSuggestionGroups,
    PlanMyDayValueSort? valueSort,
    String? spotlightTaskId,
    PlanMyDayNav? nav,
    int? navRequestId,
  }) {
    return PlanMyDayReady(
      needsPlan: needsPlan ?? this.needsPlan,
      dayKeyUtc: dayKeyUtc ?? this.dayKeyUtc,
      globalSettings: globalSettings ?? this.globalSettings,
      suggestionSignal: suggestionSignal ?? this.suggestionSignal,
      steps: steps ?? this.steps,
      currentStep: currentStep ?? this.currentStep,
      dueWindowDays: dueWindowDays ?? this.dueWindowDays,
      showAvailableToStart: showAvailableToStart ?? this.showAvailableToStart,
      showDueSoon: showDueSoon ?? this.showDueSoon,
      requiresValueSetup: requiresValueSetup ?? this.requiresValueSetup,
      requiresRatings: requiresRatings ?? this.requiresRatings,
      countRoutinesAgainstValues:
          countRoutinesAgainstValues ?? this.countRoutinesAgainstValues,
      suggested: suggested ?? this.suggested,
      triageDue: triageDue ?? this.triageDue,
      triageStarts: triageStarts ?? this.triageStarts,
      scheduledRoutines: scheduledRoutines ?? this.scheduledRoutines,
      flexibleRoutines: flexibleRoutines ?? this.flexibleRoutines,
      allRoutines: allRoutines ?? this.allRoutines,
      selectedTaskIds: selectedTaskIds ?? this.selectedTaskIds,
      selectedRoutineIds: selectedRoutineIds ?? this.selectedRoutineIds,
      allTasks: allTasks ?? this.allTasks,
      routineSelectionsByValue:
          routineSelectionsByValue ?? this.routineSelectionsByValue,
      valueSuggestionGroups:
          valueSuggestionGroups ?? this.valueSuggestionGroups,
      valueSort: valueSort ?? this.valueSort,
      spotlightTaskId: spotlightTaskId ?? this.spotlightTaskId,
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
    required RoutineRepositoryContract routineRepository,
    required TaskWriteService taskWriteService,
    required RoutineWriteService routineWriteService,
    required HomeDayKeyService dayKeyService,
    required TemporalTriggerService temporalTriggerService,
    required NowService nowService,
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
       _scheduleService = scheduleService,
       _dayKeyUtc = dayKeyService.todayDayKeyUtc(),
       super(const PlanMyDayLoading()) {
    on<PlanMyDayStarted>(_onStarted, transformer: restartable());
    on<PlanMyDayStepRequested>(_onStepRequested);
    on<PlanMyDayStepBackRequested>(_onStepBackRequested);
    on<PlanMyDayStepNextRequested>(_onStepNextRequested);
    on<PlanMyDayToggleTask>(_onToggleTask);
    on<PlanMyDayToggleRoutine>(_onToggleRoutine);
    on<PlanMyDayPauseRoutineRequested>(_onPauseRoutineRequested);
    on<PlanMyDayConfirm>(_onConfirm);
    on<PlanMyDaySnoozeTaskRequested>(_onSnoozeTaskRequested);
    on<PlanMyDayMoreSuggestionsRequested>(_onMoreSuggestionsRequested);
    on<PlanMyDayValueSortChanged>(_onValueSortChanged);
    on<PlanMyDayValueToggleExpanded>(_onValueToggleExpanded);
    on<PlanMyDayValueShowMore>(_onValueShowMore);
    on<PlanMyDaySwitchToBehaviorSuggestionsRequested>(
      _onSwitchToBehaviorSuggestionsRequested,
    );
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
  final RoutineScheduleService _scheduleService;

  final OperationContextFactory _contextFactory =
      const OperationContextFactory();

  static const double _attentionDeficitThreshold = 0.20;
  static const int _showMoreIncrement = 3;
  static const int _poolExtraCount = _showMoreIncrement * 2;

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

  bool _hasUserSelection = false;
  Set<String> _selectedTaskIds = <String>{};
  Set<String> _selectedRoutineIds = <String>{};
  Set<String> _lockedCompletedPickIds = const <String>{};
  Set<String> _lockedCompletedRoutineIds = const <String>{};

  final Map<String, int> _visibleSuggestionCountsByValue = <String, int>{};
  final Set<String> _collapsedValueIds = <String>{};
  PlanMyDayValueSort _valuesSort = PlanMyDayValueSort.attentionFirst;

  PlanMyDayStep? _currentStep;
  Completer<void>? _refreshCompleter;

  Future<void> _onStarted(
    PlanMyDayStarted event,
    Emitter<PlanMyDayState> emit,
  ) async {
    _dayKeyUtc = _dayKeyService.todayDayKeyUtc();
    _suggestionBatchCount = 1;
    _dayPicks = my_day.MyDayDayPicks(
      dayKeyUtc: dateOnly(_dayKeyUtc),
      ritualCompletedAtUtc: null,
      picks: const <my_day.MyDayPick>[],
    );

    emit(const PlanMyDayLoading());
    await _refreshSnapshots(resetSelection: true);
    _emitReady(emit);

    await emit.onEach<TemporalTriggerEvent>(
      _temporalTriggerService.events.where(
        (e) => e is HomeDayBoundaryCrossed || e is AppResumed,
      ),
      onData: (event) async {
        final nextDay = _dayKeyService.todayDayKeyUtc();
        final isDayChange = !_isSameDayUtc(nextDay, _dayKeyUtc);

        if (isDayChange) {
          _dayKeyUtc = nextDay;
          await _refreshSnapshots(resetSelection: true);
          if (emit.isDone) return;
          _emitReady(emit);
          return;
        }

        if (event is AppResumed && !_hasUserSelection) {
          await _refreshSnapshots(resetSelection: false);
          if (emit.isDone) return;
          _emitReady(emit);
        }
      },
    );
  }

  void _onStepRequested(
    PlanMyDayStepRequested event,
    Emitter<PlanMyDayState> emit,
  ) {
    if (state is! PlanMyDayReady) return;
    final ready = state as PlanMyDayReady;
    if (!ready.steps.contains(event.step)) return;
    _currentStep = event.step;
    emit(ready.copyWith(currentStep: event.step));
  }

  void _onStepBackRequested(
    PlanMyDayStepBackRequested event,
    Emitter<PlanMyDayState> emit,
  ) {
    if (state is! PlanMyDayReady) return;
    final ready = state as PlanMyDayReady;
    final index = ready.currentStepIndex;
    if (index <= 0) return;
    final nextStep = ready.steps[index - 1];
    _currentStep = nextStep;
    emit(ready.copyWith(currentStep: nextStep));
  }

  void _onStepNextRequested(
    PlanMyDayStepNextRequested event,
    Emitter<PlanMyDayState> emit,
  ) {
    if (state is! PlanMyDayReady) return;
    final ready = state as PlanMyDayReady;
    final index = ready.currentStepIndex;
    if (index >= ready.steps.length - 1) return;
    final nextStep = ready.steps[index + 1];
    _currentStep = nextStep;
    emit(ready.copyWith(currentStep: nextStep));
  }

  Future<void> _onToggleTask(
    PlanMyDayToggleTask event,
    Emitter<PlanMyDayState> emit,
  ) async {
    if (state is! PlanMyDayReady) return;

    if (!event.selected && _lockedCompletedPickIds.contains(event.taskId)) {
      return;
    }

    _hasUserSelection = true;
    if (event.selected) {
      _selectedTaskIds = {..._selectedTaskIds, event.taskId};
    } else {
      _selectedTaskIds = {..._selectedTaskIds}..remove(event.taskId);
    }

    final shouldRefresh =
        _globalSettings.myDayCountTriagePicksAgainstValueQuotas &&
        _isTriageTaskId(event.taskId);
    if (shouldRefresh) {
      await _refreshSuggestions();
      if (emit.isDone) return;
    }

    _emitReady(emit);
  }

  Future<void> _onToggleRoutine(
    PlanMyDayToggleRoutine event,
    Emitter<PlanMyDayState> emit,
  ) async {
    if (state is! PlanMyDayReady) return;

    if (!event.selected &&
        _lockedCompletedRoutineIds.contains(event.routineId)) {
      return;
    }

    _hasUserSelection = true;
    if (event.selected) {
      _selectedRoutineIds = {..._selectedRoutineIds, event.routineId};
    } else {
      _selectedRoutineIds = {..._selectedRoutineIds}..remove(event.routineId);
    }

    await _refreshSuggestions();
    if (emit.isDone) return;
    _emitReady(emit);
  }

  Future<void> _onPauseRoutineRequested(
    PlanMyDayPauseRoutineRequested event,
    Emitter<PlanMyDayState> emit,
  ) async {
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
    final current = state as PlanMyDayReady;

    final selectedTaskIds = current.selectedTaskIds;
    final selectedRoutineIds = current.selectedRoutineIds;

    if (selectedTaskIds.isEmpty && selectedRoutineIds.isEmpty) {
      if (!event.closeOnSuccess) return;
    }

    final suggested = current.suggested;
    final triageDue = current.triageDue;
    final triageStarts = current.triageStarts;

    final orderedTaskIds = <String>[];
    for (final task in suggested) {
      if (selectedTaskIds.contains(task.id)) orderedTaskIds.add(task.id);
    }
    for (final task in triageDue) {
      if (selectedTaskIds.contains(task.id) &&
          !orderedTaskIds.contains(task.id)) {
        orderedTaskIds.add(task.id);
      }
    }
    for (final task in triageStarts) {
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
      for (final task in triageDue)
        if (selectedTaskIds.contains(task.id)) task.id,
    };
    final startsSelectedIds = {
      for (final task in triageStarts)
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

    await _taskWriteService.setMyDaySnoozedUntil(
      task.id,
      untilUtc: event.untilUtc,
      context: context,
    );

    await _refreshSnapshots(resetSelection: false);
    if (emit.isDone) return;
    _emitReady(emit);
  }

  Future<void> _onMoreSuggestionsRequested(
    PlanMyDayMoreSuggestionsRequested event,
    Emitter<PlanMyDayState> emit,
  ) async {
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
    _valuesSort = event.sort;
    _emitReady(emit);
  }

  void _onValueToggleExpanded(
    PlanMyDayValueToggleExpanded event,
    Emitter<PlanMyDayState> emit,
  ) {
    if (state is! PlanMyDayReady) return;
    if (_collapsedValueIds.contains(event.valueId)) {
      _collapsedValueIds.remove(event.valueId);
    } else {
      _collapsedValueIds.add(event.valueId);
    }
    _emitReady(emit);
  }

  void _onValueShowMore(
    PlanMyDayValueShowMore event,
    Emitter<PlanMyDayState> emit,
  ) {
    if (state is! PlanMyDayReady) return;
    final current = _visibleSuggestionCountsByValue[event.valueId];
    if (current == null) return;
    _visibleSuggestionCountsByValue[event.valueId] =
        current + _showMoreIncrement;
    _emitReady(emit);
  }

  Future<void> _onSwitchToBehaviorSuggestionsRequested(
    PlanMyDaySwitchToBehaviorSuggestionsRequested event,
    Emitter<PlanMyDayState> emit,
  ) async {
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
      _visibleSuggestionCountsByValue.clear();
      _collapsedValueIds.clear();
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
    final showTriage = _globalSettings.myDayDueSoonEnabled;
    final showPlanned = showTriage && _globalSettings.myDayShowAvailableToStart;
    final showRoutines = _globalSettings.myDayShowRoutines;

    final routineSelections =
        showRoutines && _globalSettings.myDayCountRoutinePicksAgainstValueQuotas
        ? _routineSelectionsByValue()
        : const <String, int>{};
    final triageSelections =
        _globalSettings.myDayCountTriagePicksAgainstValueQuotas
        ? _triageSelectionsByValue()
        : const <String, int>{};
    final selectionCounts = _mergeSelectionCounts(
      routineSelections,
      triageSelections,
    );

    final targetCount = _suggestionPoolTargetCount();

    _suggestionSnapshot = await _taskSuggestionService.getSnapshot(
      dueWindowDays: _globalSettings.myDayDueWindowDays,
      includeDueSoon: showTriage,
      includeAvailableToStart: showPlanned,
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

    final dueRaw = snapshot?.dueSoonNotSuggested ?? const <Task>[];
    final startsRaw = snapshot?.availableToStartNotSuggested ?? const <Task>[];

    final showTriage = _globalSettings.myDayDueSoonEnabled;
    final showPlanned = showTriage && _globalSettings.myDayShowAvailableToStart;
    final showRoutines = _globalSettings.myDayShowRoutines;

    final triageDue = showTriage
        ? dueRaw.toList(growable: false)
        : const <Task>[];

    final triageStarts = showPlanned
        ? startsRaw.toList(growable: false)
        : const <Task>[];

    final routineItems = showRoutines
        ? _buildRoutineItems()
        : _RoutineItemBuildResult.empty;
    final scheduledRoutines = routineItems.scheduledEligible;
    final flexibleRoutines = routineItems.flexibleEligible;
    final allRoutines = routineItems.allItems;

    final selectedTaskIds = _filteredSelectedTaskIds(
      suggested: suggested,
      triageDue: triageDue,
      triageStarts: triageStarts,
    );
    final selectedRoutineIds = showRoutines
        ? _selectedRoutineIds
        : const <String>{};

    final steps = _buildSteps(
      hasValues:
          suggested.isNotEmpty ||
          (snapshot?.requiresValueSetup ?? false) ||
          (snapshot?.requiresRatings ?? false),
      hasRoutines: scheduledRoutines.isNotEmpty || flexibleRoutines.isNotEmpty,
      hasTriage: triageDue.isNotEmpty || triageStarts.isNotEmpty,
    );

    final currentStep = _resolveCurrentStep(steps);
    _currentStep = currentStep;

    emit(
      PlanMyDayReady(
        needsPlan: _dayPicks.ritualCompletedAtUtc == null,
        dayKeyUtc: _dayKeyUtc,
        globalSettings: _globalSettings,
        suggestionSignal: _allocationConfig.suggestionSignal,
        steps: steps,
        currentStep: currentStep,
        dueWindowDays: _globalSettings.myDayDueWindowDays,
        showAvailableToStart: showPlanned,
        showDueSoon: showTriage,
        requiresValueSetup: snapshot?.requiresValueSetup ?? false,
        requiresRatings: snapshot?.requiresRatings ?? false,
        countRoutinesAgainstValues:
            _globalSettings.myDayCountRoutinePicksAgainstValueQuotas,
        suggested: suggested,
        triageDue: triageDue,
        triageStarts: triageStarts,
        scheduledRoutines: scheduledRoutines,
        flexibleRoutines: flexibleRoutines,
        allRoutines: allRoutines,
        selectedTaskIds: selectedTaskIds,
        selectedRoutineIds: selectedRoutineIds,
        allTasks: _tasks,
        routineSelectionsByValue: _routineSelectionsByValue(),
        valueSuggestionGroups: valueGroups,
        valueSort: _valuesSort,
        spotlightTaskId: snapshot?.spotlightTaskId,
      ),
    );
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

  List<PlanMyDayStep> _buildSteps({
    required bool hasValues,
    required bool hasRoutines,
    required bool hasTriage,
  }) {
    const ordered = [
      PlanMyDayStep.triage,
      PlanMyDayStep.routines,
      PlanMyDayStep.valuesStep,
      PlanMyDayStep.summary,
    ];

    return ordered
        .where((step) {
          return switch (step) {
            PlanMyDayStep.valuesStep => hasValues,
            PlanMyDayStep.routines => hasRoutines,
            PlanMyDayStep.triage => hasTriage,
            PlanMyDayStep.summary => true,
          };
        })
        .toList(growable: false);
  }

  PlanMyDayStep _resolveCurrentStep(List<PlanMyDayStep> steps) {
    final current = _currentStep;
    if (current != null && steps.contains(current)) return current;
    return steps.first;
  }

  Map<String, int> _routineSelectionsByValue() {
    if (!_globalSettings.myDayShowRoutines ||
        !_globalSettings.myDayCountRoutinePicksAgainstValueQuotas) {
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
    if (!_globalSettings.myDayDueSoonEnabled ||
        !_globalSettings.myDayCountTriagePicksAgainstValueQuotas) {
      return const <String, int>{};
    }

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
    final snapshot = _suggestionSnapshot;
    if (snapshot == null) return const <String>{};
    return {
      for (final task in snapshot.dueSoonNotSuggested) task.id,
      for (final task in snapshot.availableToStartNotSuggested) task.id,
    };
  }

  bool _isTriageTaskId(String taskId) {
    return _triageTaskIdsFromSnapshot().contains(taskId);
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
    required List<Task> triageDue,
    required List<Task> triageStarts,
  }) {
    final visibleIds = <String>{
      for (final task in suggested) task.id,
      for (final task in triageDue) task.id,
      for (final task in triageStarts) task.id,
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
      final defaultVisible = _defaultVisibleCount(
        value.priority,
        attentionNeeded: attentionNeeded,
      );
      final poolSize = entry.value.length;
      final storedVisible =
          _visibleSuggestionCountsByValue[valueId] ?? defaultVisible;
      final visibleCount = storedVisible.clamp(0, poolSize);
      _visibleSuggestionCountsByValue[valueId] = visibleCount;

      groups.add(
        PlanMyDayValueSuggestionGroup(
          valueId: valueId,
          value: value,
          tasks: entry.value,
          attentionNeeded: attentionNeeded,
          neglectScore: deficit,
          visibleCount: visibleCount,
          expanded: !_collapsedValueIds.contains(valueId),
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
    return switch (priority) {
      ValuePriority.high => attentionNeeded ? 4 : 3,
      ValuePriority.medium => attentionNeeded ? 3 : 2,
      ValuePriority.low => attentionNeeded ? 2 : 1,
    };
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

  bool _isSameDayUtc(DateTime a, DateTime b) {
    return dateOnly(a).isAtSameMomentAs(dateOnly(b));
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
