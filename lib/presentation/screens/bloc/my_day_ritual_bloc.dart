import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter/foundation.dart';
import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
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
    required this.planned,
    required this.curated,
    required this.curatedReasons,
    required this.selectedTaskIds,
    required this.dayKeyUtc,
    this.nav,
    this.navRequestId = 0,
  });

  final bool needsRitual;
  final FocusMode focusMode;
  final List<Task> planned;
  final List<Task> curated;
  final Map<String, String> curatedReasons;
  final Set<String> selectedTaskIds;
  final DateTime dayKeyUtc;
  final MyDayRitualNav? nav;
  final int navRequestId;

  MyDayRitualReady copyWith({
    bool? needsRitual,
    FocusMode? focusMode,
    List<Task>? planned,
    List<Task>? curated,
    Map<String, String>? curatedReasons,
    Set<String>? selectedTaskIds,
    DateTime? dayKeyUtc,
    MyDayRitualNav? nav,
    int? navRequestId,
  }) {
    return MyDayRitualReady(
      needsRitual: needsRitual ?? this.needsRitual,
      focusMode: focusMode ?? this.focusMode,
      planned: planned ?? this.planned,
      curated: curated ?? this.curated,
      curatedReasons: curatedReasons ?? this.curatedReasons,
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
    required AllocationOrchestrator allocationOrchestrator,
    required TaskRepositoryContract taskRepository,
    required HomeDayKeyService dayKeyService,
    required TemporalTriggerService temporalTriggerService,
  }) : _settingsRepository = settingsRepository,
       _allocationOrchestrator = allocationOrchestrator,
       _taskRepository = taskRepository,
       _dayKeyService = dayKeyService,
       _temporalTriggerService = temporalTriggerService,
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
    on<_MyDayRitualInputsChanged>(_onInputsChanged);
    add(const MyDayRitualStarted());
  }

  final SettingsRepositoryContract _settingsRepository;
  final AllocationOrchestrator _allocationOrchestrator;
  final TaskRepositoryContract _taskRepository;
  final HomeDayKeyService _dayKeyService;
  final TemporalTriggerService _temporalTriggerService;

  StreamSubscription? _allocationSub;
  StreamSubscription? _tasksSub;
  StreamSubscription? _settingsSub;
  StreamSubscription? _allocationConfigSub;
  StreamSubscription? _daySub;

  AllocationResult? _allocationResult;
  List<Task> _tasks = const <Task>[];
  AllocationConfig _allocationConfig = const AllocationConfig();
  settings.MyDayRitualState _ritualState = const settings.MyDayRitualState();
  DateTime _dayKeyUtc = DateTime.now().toUtc();

  bool _hasUserSelection = false;
  Set<String> _selectedTaskIds = <String>{};

  @override
  Future<void> close() async {
    await _allocationSub?.cancel();
    await _tasksSub?.cancel();
    await _settingsSub?.cancel();
    await _allocationConfigSub?.cancel();
    await _daySub?.cancel();
    return super.close();
  }

  Future<void> _onStarted(
    MyDayRitualStarted event,
    Emitter<MyDayRitualState> emit,
  ) async {
    _dayKeyUtc = _dayKeyService.todayDayKeyUtc();

    await _allocationSub?.cancel();
    await _tasksSub?.cancel();
    await _settingsSub?.cancel();
    await _allocationConfigSub?.cancel();
    await _daySub?.cancel();

    _allocationSub = _allocationOrchestrator.watchAllocation().listen((result) {
      _allocationResult = result;
      add(const _MyDayRitualInputsChanged());
    });

    _tasksSub = _taskRepository.watchAll(TaskQuery.incomplete()).listen((
      tasks,
    ) {
      _tasks = tasks;
      add(const _MyDayRitualInputsChanged());
    });

    _settingsSub = _settingsRepository
        .watch<settings.MyDayRitualState>(SettingsKey.myDayRitual)
        .listen((ritual) {
          _ritualState = ritual;
          add(const _MyDayRitualInputsChanged());
        });

    _allocationConfigSub = _settingsRepository
        .watch<AllocationConfig>(SettingsKey.allocation)
        .listen((config) {
          _allocationConfig = config;
          add(const _MyDayRitualInputsChanged());
        });

    _daySub = _temporalTriggerService.events
        .where((e) => e is HomeDayBoundaryCrossed || e is AppResumed)
        .listen((_) {
          final nextDay = _dayKeyService.todayDayKeyUtc();
          if (!_isSameDayUtc(nextDay, _dayKeyUtc)) {
            _dayKeyUtc = nextDay;
            _hasUserSelection = false;
            _selectedTaskIds = <String>{};
            add(const _MyDayRitualInputsChanged());
          }
        });
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

    final needsRitual = !_ritualState.isCompletedFor(_dayKeyUtc);

    emit(
      MyDayRitualReady(
        needsRitual: needsRitual,
        focusMode: _allocationConfig.focusMode,
        planned: planned,
        curated: curated,
        curatedReasons: _buildCuratedReasonText(
          curated,
          allocation: _allocationResult,
          dayKeyUtc: _dayKeyUtc,
        ),
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
    final dueIds = current.planned
        .where((task) {
          final deadline = _deadlineDateOnly(task);
          return deadline != null && !deadline.isAfter(today);
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
    final startsIds = current.planned
        .where((task) {
          final deadline = _deadlineDateOnly(task);
          return deadline == null || deadline.isAfter(today);
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
    final dueIds = {
      for (final task in planned)
        if (selectedIds.contains(task.id) &&
            _deadlineDateOnly(task) != null &&
            !_deadlineDateOnly(task)!.isAfter(today))
          task.id,
    };
    final startsIds = {
      for (final task in planned)
        if (selectedIds.contains(task.id) &&
            (_deadlineDateOnly(task) == null ||
                _deadlineDateOnly(task)!.isAfter(today)))
          task.id,
    };
    final focusIds = {
      for (final task in curated)
        if (selectedIds.contains(task.id)) task.id,
    };

    final acceptedDueOrdered = [
      for (final id in ordered)
        if (dueIds.contains(id) && !focusIds.contains(id)) id,
    ];
    final acceptedStartsOrdered = [
      for (final id in ordered)
        if (startsIds.contains(id) &&
            !focusIds.contains(id) &&
            !dueIds.contains(id))
          id,
    ];
    final acceptedFocusOrdered = [
      for (final id in ordered)
        if (focusIds.contains(id)) id,
    ];

    final updated = settings.MyDayRitualState(
      completedDayUtc: encodeDateOnly(_dayKeyUtc),
      selectedTaskIds: ordered,
      acceptedDueTaskIds: acceptedDueOrdered,
      acceptedStartsTaskIds: acceptedStartsOrdered,
      acceptedFocusTaskIds: acceptedFocusOrdered,
    );

    await _settingsRepository.save(SettingsKey.myDayRitual, updated);
  }

  List<Task> _buildPlanned(List<Task> tasks, DateTime dayKeyUtc) {
    final today = dateOnly(dayKeyUtc);
    final dueSoonLimit = today.add(const Duration(days: 3));

    bool isPlanned(Task task) {
      if (_isCompleted(task)) return false;
      final start = dateOnlyOrNull(task.startDate);
      final deadline = dateOnlyOrNull(task.deadlineDate);
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

  Map<String, String> _buildCuratedReasonText(
    List<Task> curated, {
    required AllocationResult? allocation,
    required DateTime dayKeyUtc,
  }) {
    if (allocation == null) return const {};

    final reasonsByTaskId = <String, List<AllocationReasonCode>>{};
    for (final entry in allocation.allocatedTasks) {
      reasonsByTaskId[entry.task.id] = entry.reasonCodes;
    }

    return {
      for (final task in curated)
        task.id: _reasonTextForTask(task, reasonsByTaskId[task.id] ?? const []),
    }..removeWhere((_, value) => value.isEmpty);
  }

  String _reasonTextForTask(
    Task task,
    List<AllocationReasonCode> reasonCodes,
  ) {
    final valueName = task.effectivePrimaryValue?.name;
    final hasValue = valueName != null && valueName.isNotEmpty;

    final buffer = StringBuffer('Chosen because ');
    if (hasValue) {
      buffer.write('it supports $valueName');
    }

    final hasNeglect = reasonCodes.contains(
      AllocationReasonCode.neglectBalance,
    );
    if (hasNeglect) {
      if (hasValue) {
        buffer.write('; restoring balance across your values');
      } else {
        buffer.write('it is restoring balance across your values');
      }
    }

    final urgencyPhrase = _urgencyOrPriorityPhrase(task, reasonCodes);
    if (urgencyPhrase.isNotEmpty) {
      if (hasValue || hasNeglect) {
        buffer.write(' and $urgencyPhrase');
      } else {
        buffer.write('it $urgencyPhrase');
      }
    }

    final text = buffer.toString().trim();
    return text == 'Chosen because' ? '' : '$text.';
  }

  String _urgencyOrPriorityPhrase(
    Task task,
    List<AllocationReasonCode> reasonCodes,
  ) {
    if (reasonCodes.contains(AllocationReasonCode.urgency)) {
      return _deadlinePhrase(task);
    }

    if (reasonCodes.contains(AllocationReasonCode.priority)) {
      return 'is high priority';
    }

    return '';
  }

  String _deadlinePhrase(Task task) {
    final deadline = dateOnlyOrNull(task.deadlineDate);
    if (deadline == null) return 'is due soon';

    final today = dateOnly(_dayKeyUtc);
    final diff = deadline.difference(today).inDays;

    if (diff < 0) return 'is overdue';
    if (diff == 0) return 'is due today';
    if (diff == 1) return 'is due tomorrow';
    return 'is due in $diff days';
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
