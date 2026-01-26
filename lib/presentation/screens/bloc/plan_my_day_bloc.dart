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

final class PlanMyDaySkipRoutineRequested extends PlanMyDayEvent {
  const PlanMyDaySkipRoutineRequested(this.routineId);

  final String routineId;
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

enum PlanMyDayStep {
  values,
  routines,
  triage,
  summary,
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
  });

  final Routine routine;
  final RoutineCadenceSnapshot snapshot;
  final bool selected;
  final bool completedToday;
}

@immutable
final class PlanMyDayReady extends PlanMyDayState {
  const PlanMyDayReady({
    required this.needsPlan,
    required this.dayKeyUtc,
    required this.flow,
    required this.steps,
    required this.currentStep,
    required this.dueWindowDays,
    required this.showAvailableToStart,
    required this.showDueSoon,
    required this.requiresValueSetup,
    required this.countRoutinesAgainstValues,
    required this.suggested,
    required this.triageDue,
    required this.triageStarts,
    required this.routines,
    required this.selectedTaskIds,
    required this.selectedRoutineIds,
    required this.allTasks,
    required this.routineSelectionsByValue,
    this.nav,
    this.navRequestId = 0,
  });

  final bool needsPlan;
  final DateTime dayKeyUtc;
  final MyDayPlanFlow flow;
  final List<PlanMyDayStep> steps;
  final PlanMyDayStep currentStep;
  final int dueWindowDays;
  final bool showAvailableToStart;
  final bool showDueSoon;
  final bool requiresValueSetup;
  final bool countRoutinesAgainstValues;
  final List<Task> suggested;
  final List<Task> triageDue;
  final List<Task> triageStarts;
  final List<PlanMyDayRoutineItem> routines;
  final Set<String> selectedTaskIds;
  final Set<String> selectedRoutineIds;
  final List<Task> allTasks;
  final Map<String, int> routineSelectionsByValue;
  final PlanMyDayNav? nav;
  final int navRequestId;

  int get currentStepIndex => steps.indexOf(currentStep);

  PlanMyDayReady copyWith({
    bool? needsPlan,
    DateTime? dayKeyUtc,
    MyDayPlanFlow? flow,
    List<PlanMyDayStep>? steps,
    PlanMyDayStep? currentStep,
    int? dueWindowDays,
    bool? showAvailableToStart,
    bool? showDueSoon,
    bool? requiresValueSetup,
    bool? countRoutinesAgainstValues,
    List<Task>? suggested,
    List<Task>? triageDue,
    List<Task>? triageStarts,
    List<PlanMyDayRoutineItem>? routines,
    Set<String>? selectedTaskIds,
    Set<String>? selectedRoutineIds,
    List<Task>? allTasks,
    Map<String, int>? routineSelectionsByValue,
    PlanMyDayNav? nav,
    int? navRequestId,
  }) {
    return PlanMyDayReady(
      needsPlan: needsPlan ?? this.needsPlan,
      dayKeyUtc: dayKeyUtc ?? this.dayKeyUtc,
      flow: flow ?? this.flow,
      steps: steps ?? this.steps,
      currentStep: currentStep ?? this.currentStep,
      dueWindowDays: dueWindowDays ?? this.dueWindowDays,
      showAvailableToStart: showAvailableToStart ?? this.showAvailableToStart,
      showDueSoon: showDueSoon ?? this.showDueSoon,
      requiresValueSetup: requiresValueSetup ?? this.requiresValueSetup,
      countRoutinesAgainstValues:
          countRoutinesAgainstValues ?? this.countRoutinesAgainstValues,
      suggested: suggested ?? this.suggested,
      triageDue: triageDue ?? this.triageDue,
      triageStarts: triageStarts ?? this.triageStarts,
      routines: routines ?? this.routines,
      selectedTaskIds: selectedTaskIds ?? this.selectedTaskIds,
      selectedRoutineIds: selectedRoutineIds ?? this.selectedRoutineIds,
      allTasks: allTasks ?? this.allTasks,
      routineSelectionsByValue:
          routineSelectionsByValue ?? this.routineSelectionsByValue,
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
    required HomeDayKeyService dayKeyService,
    required TemporalTriggerService temporalTriggerService,
    required NowService nowService,
    RoutineScheduleService scheduleService = const RoutineScheduleService(),
  }) : _settingsRepository = settingsRepository,
       _myDayRepository = myDayRepository,
       _taskSuggestionService = taskSuggestionService,
       _taskRepository = taskRepository,
       _routineRepository = routineRepository,
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
    on<PlanMyDaySkipRoutineRequested>(_onSkipRoutineRequested);
    on<PlanMyDayPauseRoutineRequested>(_onPauseRoutineRequested);
    on<PlanMyDayConfirm>(_onConfirm);
    on<PlanMyDaySnoozeTaskRequested>(_onSnoozeTaskRequested);
    on<PlanMyDayMoreSuggestionsRequested>(_onMoreSuggestionsRequested);
    add(const PlanMyDayStarted());
  }

  final SettingsRepositoryContract _settingsRepository;
  final MyDayRepositoryContract _myDayRepository;
  final TaskSuggestionService _taskSuggestionService;
  final TaskRepositoryContract _taskRepository;
  final RoutineRepositoryContract _routineRepository;
  final HomeDayKeyService _dayKeyService;
  final TemporalTriggerService _temporalTriggerService;
  final NowService _nowService;
  final RoutineScheduleService _scheduleService;

  final OperationContextFactory _contextFactory =
      const OperationContextFactory();

  settings.GlobalSettings _globalSettings = const settings.GlobalSettings();
  settings.AllocationConfig _allocationConfig =
      const settings.AllocationConfig();
  DateTime _dayKeyUtc;

  TaskSuggestionSnapshot? _suggestionSnapshot;
  List<Task> _tasks = const <Task>[];
  List<Task> _incompleteTasks = const <Task>[];
  List<Routine> _routines = const <Routine>[];
  List<RoutineCompletion> _routineCompletions =
      const <RoutineCompletion>[];
  List<RoutineSkip> _routineSkips = const <RoutineSkip>[];
  late my_day.MyDayDayPicks _dayPicks;

  int _suggestionBatchCount = 1;

  bool _hasUserSelection = false;
  Set<String> _selectedTaskIds = <String>{};
  Set<String> _selectedRoutineIds = <String>{};
  Set<String> _lockedCompletedPickIds = const <String>{};
  Set<String> _lockedCompletedRoutineIds = const <String>{};

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

  void _onToggleTask(
    PlanMyDayToggleTask event,
    Emitter<PlanMyDayState> emit,
  ) {
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

    emit(
      (state as PlanMyDayReady).copyWith(
        selectedTaskIds: _selectedTaskIds,
      ),
    );
  }

  Future<void> _onToggleRoutine(
    PlanMyDayToggleRoutine event,
    Emitter<PlanMyDayState> emit,
  ) async {
    if (state is! PlanMyDayReady) return;

    if (!event.selected && _lockedCompletedRoutineIds.contains(event.routineId)) {
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

  Future<void> _onSkipRoutineRequested(
    PlanMyDaySkipRoutineRequested event,
    Emitter<PlanMyDayState> emit,
  ) async {
    final routine = _findRoutine(event.routineId);
    if (routine == null) return;

    final snapshot = _scheduleService.buildSnapshot(
      routine: routine,
      dayKeyUtc: _dayKeyUtc,
      completions: _routineCompletions,
      skips: _routineSkips,
    );

    final context = _contextFactory.create(
      feature: 'routines',
      screen: 'plan_my_day',
      intent: 'skip_target',
      operation: 'routine.record_skip',
      entityType: 'routine',
      entityId: routine.id,
      extraFields: <String, Object?>{
        'periodType': snapshot.periodType.name,
        'periodKeyUtc': snapshot.periodStartUtc.toIso8601String(),
      },
    );

    await _routineRepository.recordSkip(
      routineId: routine.id,
      periodType: snapshot.periodType,
      periodKeyUtc: snapshot.periodStartUtc,
      context: context,
    );

    _selectedRoutineIds = {..._selectedRoutineIds}..remove(routine.id);
    await _refreshSnapshots(resetSelection: false);
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

    await _routineRepository.update(
      id: routine.id,
      name: routine.name,
      valueId: routine.valueId,
      projectId: routine.projectId,
      routineType: routine.routineType,
      targetCount: routine.targetCount,
      scheduleDays: routine.scheduleDays,
      minSpacingDays: routine.minSpacingDays,
      restDayBuffer: routine.restDayBuffer,
      preferredWeeks: routine.preferredWeeks,
      fixedDayOfMonth: routine.fixedDayOfMonth,
      fixedWeekday: routine.fixedWeekday,
      fixedWeekOfMonth: routine.fixedWeekOfMonth,
      isActive: routine.isActive,
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

    final selectedTaskIds = _selectedTaskIds;
    final selectedRoutineIds = _selectedRoutineIds;

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
    for (final item in current.routines) {
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
      for (final entry in _suggestionSnapshot?.suggested ?? const [])
        entry.task.id: entry,
    };

    my_day.MyDayPickBucket bucketForTaskId(String taskId) {
      if (valuesSelectedIds.contains(taskId)) {
        return my_day.MyDayPickBucket.values;
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
        my_day.MyDayPickBucket.values => suggestedInfo?.qualifyingValueId,
        _ => task?.effectivePrimaryValueId,
      };

      final reasonCodes = switch (bucket) {
        my_day.MyDayPickBucket.values =>
          suggestedInfo == null
              ? const <String>[]
              : suggestedInfo.reasonCodes
                    .map((AllocationReasonCode c) => c.name)
                    .toList(),
        _ => const <String>[],
      };

      final suggestionRank = switch (bucket) {
        my_day.MyDayPickBucket.values => suggestedInfo?.rank,
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

    await _taskRepository.setMyDaySnoozedUntil(
      id: task.id,
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
        _settingsRepository.load<settings.AllocationConfig>(
          SettingsKey.allocation,
        ),
        _myDayRepository.loadDay(_dayKeyUtc),
        _taskRepository.getAll(TaskQuery.incomplete()),
        _routineRepository.getAll(includeInactive: true),
        _routineRepository.getCompletions(),
        _routineRepository.getSkips(),
      ]);

      _globalSettings = results[0] as settings.GlobalSettings;
      _allocationConfig = results[1] as settings.AllocationConfig;

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

      _lockedCompletedPickIds =
          Set.unmodifiable(completedPickTasks.map((task) => task.id));

      final completedRoutineIds = _routineCompletions
          .where(
            (completion) =>
                dateOnly(completion.completedAtUtc)
                    .isAtSameMomentAs(dateOnly(_dayKeyUtc)),
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
    final countRoutines =
        _allocationConfig.strategySettings.countRoutineSelectionsAgainstValueQuotas;

    final routineSelections =
        countRoutines ? _routineSelectionsByValue() : const <String, int>{};

    _suggestionSnapshot = await _taskSuggestionService.getSnapshot(
      dueWindowDays: _globalSettings.myDayDueWindowDays,
      includeDueSoon: _globalSettings.myDayDueSoonEnabled,
      includeAvailableToStart: _globalSettings.myDayShowAvailableToStart,
      batchCount: _suggestionBatchCount,
      tasksOverride: _incompleteTasks,
      routineSelectionsByValue: routineSelections,
      nowUtc: _nowService.nowUtc(),
    );
  }

  void _emitReady(Emitter<PlanMyDayState> emit) {
    final snapshot = _suggestionSnapshot;
    final suggested = snapshot == null
        ? const <Task>[]
        : snapshot.suggested.map((entry) => entry.task).toList(growable: false);

    final dueRaw = snapshot?.dueSoonNotSuggested ?? const <Task>[];
    final startsRaw = snapshot?.availableToStartNotSuggested ?? const <Task>[];

    final triageDue = _globalSettings.myDayDueSoonEnabled
        ? dueRaw.where((task) => !_selectedTaskIds.contains(task.id)).toList(
            growable: false,
          )
        : const <Task>[];

    final triageStarts = _globalSettings.myDayShowAvailableToStart
        ? startsRaw
            .where((task) => !_selectedTaskIds.contains(task.id))
            .toList(growable: false)
        : const <Task>[];

    final routines = _buildRoutineItems();

    final steps = _buildSteps(
      flow: _globalSettings.myDayPlanFlow,
      hasValues: suggested.isNotEmpty || snapshot?.requiresValueSetup == true,
      hasRoutines: routines.isNotEmpty,
      hasTriage: triageDue.isNotEmpty || triageStarts.isNotEmpty,
    );

    final currentStep = _resolveCurrentStep(steps);
    _currentStep = currentStep;

    emit(
      PlanMyDayReady(
        needsPlan: _dayPicks.ritualCompletedAtUtc == null,
        dayKeyUtc: _dayKeyUtc,
        flow: _globalSettings.myDayPlanFlow,
        steps: steps,
        currentStep: currentStep,
        dueWindowDays: _globalSettings.myDayDueWindowDays,
        showAvailableToStart: _globalSettings.myDayShowAvailableToStart,
        showDueSoon: _globalSettings.myDayDueSoonEnabled,
        requiresValueSetup: snapshot?.requiresValueSetup ?? false,
        countRoutinesAgainstValues:
            _allocationConfig.strategySettings.countRoutineSelectionsAgainstValueQuotas,
        suggested: suggested,
        triageDue: triageDue,
        triageStarts: triageStarts,
        routines: routines,
        selectedTaskIds: _selectedTaskIds,
        selectedRoutineIds: _selectedRoutineIds,
        allTasks: _tasks,
        routineSelectionsByValue: _routineSelectionsByValue(),
      ),
    );
  }

  List<PlanMyDayRoutineItem> _buildRoutineItems() {
    final todayKey = dateOnly(_dayKeyUtc);
    final completedToday = _routineCompletions
        .where(
          (completion) =>
              dateOnly(completion.completedAtUtc).isAtSameMomentAs(todayKey),
        )
        .map((completion) => completion.routineId)
        .toSet();

    return _routines
        .where((routine) => routine.isActive)
        .where((routine) => !routine.isPausedOn(todayKey))
        .map((routine) {
          final snapshot = _scheduleService.buildSnapshot(
            routine: routine,
            dayKeyUtc: _dayKeyUtc,
            completions: _routineCompletions,
            skips: _routineSkips,
          );

          return PlanMyDayRoutineItem(
            routine: routine,
            snapshot: snapshot,
            selected: _selectedRoutineIds.contains(routine.id),
            completedToday: completedToday.contains(routine.id),
          );
        })
        .toList(growable: false);
  }

  List<PlanMyDayStep> _buildSteps({
    required MyDayPlanFlow flow,
    required bool hasValues,
    required bool hasRoutines,
    required bool hasTriage,
  }) {
    final ordered = switch (flow) {
      MyDayPlanFlow.valuesFirst => [
        PlanMyDayStep.values,
        PlanMyDayStep.routines,
        PlanMyDayStep.triage,
        PlanMyDayStep.summary,
      ],
      MyDayPlanFlow.routinesFirst => [
        PlanMyDayStep.routines,
        PlanMyDayStep.values,
        PlanMyDayStep.triage,
        PlanMyDayStep.summary,
      ],
      MyDayPlanFlow.triageFirst => [
        PlanMyDayStep.triage,
        PlanMyDayStep.values,
        PlanMyDayStep.routines,
        PlanMyDayStep.summary,
      ],
    };

    return ordered.where((step) {
      return switch (step) {
        PlanMyDayStep.values => hasValues,
        PlanMyDayStep.routines => hasRoutines,
        PlanMyDayStep.triage => hasTriage,
        PlanMyDayStep.summary => true,
      };
    }).toList(growable: false);
  }

  PlanMyDayStep _resolveCurrentStep(List<PlanMyDayStep> steps) {
    final current = _currentStep;
    if (current != null && steps.contains(current)) return current;
    return steps.first;
  }

  Map<String, int> _routineSelectionsByValue() {
    if (!_allocationConfig.strategySettings.countRoutineSelectionsAgainstValueQuotas) {
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
