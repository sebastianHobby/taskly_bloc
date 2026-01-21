import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/my_day.dart' as my_day;
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/preferences.dart';
import 'package:taskly_domain/settings.dart' as settings;
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/time.dart';

sealed class MyDayEvent {
  const MyDayEvent();
}

final class MyDayStarted extends MyDayEvent {
  const MyDayStarted();
}

sealed class MyDayState {
  const MyDayState();
}

final class MyDayLoading extends MyDayState {
  const MyDayLoading();
}

final class MyDayLoaded extends MyDayState {
  const MyDayLoaded({
    required this.summary,
    required this.mix,
    required this.tasks,
    required this.acceptedDue,
    required this.acceptedStarts,
    required this.acceptedFocus,
    required this.dueAcceptedTotalCount,
    required this.startsAcceptedTotalCount,
    required this.focusAcceptedTotalCount,
    required this.selectedTotalCount,
    required this.missingDueCount,
    required this.missingStartsCount,
    required this.missingDueTasks,
    required this.missingStartsTasks,
    required this.todaySelectedTaskIds,
  });

  final MyDaySummary summary;
  final MyDayMixVm mix;
  final List<Task> tasks;

  /// Tasks accepted from the ritual "Overdue & due" section.
  final List<Task> acceptedDue;

  /// Tasks accepted from the ritual "Starts today" section.
  final List<Task> acceptedStarts;

  /// Tasks accepted from the ritual "Suggestions" section.
  final List<Task> acceptedFocus;

  /// Total counts as persisted by the ritual (includes already-completed
  /// accepted tasks).
  final int dueAcceptedTotalCount;
  final int startsAcceptedTotalCount;
  final int focusAcceptedTotalCount;
  final int selectedTotalCount;

  /// Count of bucket candidates that were not selected during the ritual.
  final int missingDueCount;
  final int missingStartsCount;

  /// Tasks (from frozen ritual candidates) that were not selected.
  final List<Task> missingDueTasks;
  final List<Task> missingStartsTasks;

  /// Full set of task ids selected for today (from ritual persistence).
  final Set<String> todaySelectedTaskIds;
}

final class MyDayError extends MyDayState {
  const MyDayError(this.message);

  final String message;
}

final class MyDaySummary {
  const MyDaySummary({required this.doneCount, required this.totalCount});

  final int doneCount;
  final int totalCount;
}

final class MyDayBloc extends Bloc<MyDayEvent, MyDayState> {
  MyDayBloc({
    required AllocationOrchestrator allocationOrchestrator,
    required TaskRepositoryContract taskRepository,
    required ValueRepositoryContract valueRepository,
    required SettingsRepositoryContract settingsRepository,
    required MyDayRepositoryContract myDayRepository,
    required HomeDayKeyService dayKeyService,
    required TemporalTriggerService temporalTriggerService,
  }) : _allocationOrchestrator = allocationOrchestrator,
       _taskRepository = taskRepository,
       _valueRepository = valueRepository,
       _settingsRepository = settingsRepository,
       _myDayRepository = myDayRepository,
       _dayKeyService = dayKeyService,
       _temporalTriggerService = temporalTriggerService,
       super(const MyDayLoading()) {
    on<MyDayStarted>(_onStarted, transformer: restartable());
    add(const MyDayStarted());
  }

  final AllocationOrchestrator _allocationOrchestrator;
  final TaskRepositoryContract _taskRepository;
  final ValueRepositoryContract _valueRepository;
  final SettingsRepositoryContract _settingsRepository;
  final MyDayRepositoryContract _myDayRepository;
  final HomeDayKeyService _dayKeyService;
  final TemporalTriggerService _temporalTriggerService;

  Future<void> _onStarted(MyDayStarted event, Emitter<MyDayState> emit) async {
    await emit.forEach<MyDayState>(
      _watchState(),
      onData: (state) => state,
      onError: (error, stackTrace) => MyDayError(
        'Failed to load My Day: $error',
      ),
    );
  }

  Stream<MyDayState> _watchState() {
    return _watchViewModel().map(
      (vm) => MyDayLoaded(
        summary: vm.summary,
        mix: vm.mix,
        tasks: vm.tasks,
        acceptedDue: vm.acceptedDue,
        acceptedStarts: vm.acceptedStarts,
        acceptedFocus: vm.acceptedFocus,
        dueAcceptedTotalCount: vm.dueAcceptedTotalCount,
        startsAcceptedTotalCount: vm.startsAcceptedTotalCount,
        focusAcceptedTotalCount: vm.focusAcceptedTotalCount,
        selectedTotalCount: vm.selectedTotalCount,
        missingDueCount: vm.missingDueCount,
        missingStartsCount: vm.missingStartsCount,
        missingDueTasks: vm.missingDueTasks,
        missingStartsTasks: vm.missingStartsTasks,
        todaySelectedTaskIds: vm.todaySelectedTaskIds,
      ),
    );
  }

  Stream<_MyDayViewModel> _watchViewModel() {
    final triggers = Rx.merge([
      Stream<void>.value(null),
      _temporalTriggerService.events
          .where((e) => e is HomeDayBoundaryCrossed || e is AppResumed)
          .map((_) => null),
    ]);

    return triggers
        .map((_) => _dayKeyService.todayDayKeyUtc())
        .distinct((a, b) => a.isAtSameMomentAs(b))
        .switchMap(_watchForDay);
  }

  Stream<_MyDayViewModel> _watchForDay(DateTime dayKeyUtc) {
    final values$ = Rx.concat([
      Stream.fromFuture(_valueRepository.getAll()),
      _valueRepository.watchAll(),
    ]);

    final global$ = Rx.concat([
      Stream.fromFuture(
        _settingsRepository.load<settings.GlobalSettings>(SettingsKey.global),
      ),
      _settingsRepository.watch<settings.GlobalSettings>(SettingsKey.global),
    ]);

    final dayPicks$ = Rx.concat([
      Stream.fromFuture(_myDayRepository.loadDay(dayKeyUtc)),
      _myDayRepository.watchDay(dayKeyUtc),
    ]);

    return dayPicks$.switchMap((dayPicks) {
      if (dayPicks.ritualCompletedAtUtc != null) {
        final tasks$ = Rx.concat([
          Stream.fromFuture(_taskRepository.getAll(TaskQuery.incomplete())),
          _taskRepository.watchAll(TaskQuery.incomplete()),
        ]);

        return Rx.combineLatest3<
          List<Task>,
          List<Value>,
          settings.GlobalSettings,
          _MyDayViewModel
        >(
          tasks$,
          values$,
          global$,
          (tasks, values, global) => _buildFromDailyPicks(
            dayPicks,
            dayKeyUtc,
            tasks,
            values,
            global,
          ),
        );
      }

      return Stream.fromFuture(_loadAllocationViewModel());
    });
  }

  Future<_MyDayViewModel> _loadAllocationViewModel() async {
    final results = await Future.wait([
      _allocationOrchestrator.getAllocationSnapshot(),
      _valueRepository.getAll(),
    ]);

    final allocation = results[0] as AllocationResult;
    final values = results[1] as List<Value>;
    return _buildFromAllocation(allocation, values);
  }

  _MyDayViewModel _buildFromAllocation(
    AllocationResult allocation,
    List<Value> values,
  ) {
    final tasks = allocation.allocatedTasks
        .map((entry) => entry.task)
        .toList(growable: false);

    final qualifyingByTaskId = {
      for (final entry in allocation.allocatedTasks)
        entry.task.id: entry.qualifyingValueId,
    };

    return _buildViewModel(
      tasks: tasks,
      values: values,
      qualifyingByTaskId: qualifyingByTaskId,
    );
  }

  _MyDayViewModel _buildFromDailyPicks(
    my_day.MyDayDayPicks dayPicks,
    DateTime dayKeyUtc,
    List<Task> tasks,
    List<Value> values,
    settings.GlobalSettings globalSettings,
  ) {
    final tasksById = {for (final task in tasks) task.id: task};

    final orderedPickIds = dayPicks.picks.toList(growable: false)
      ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

    final selectedIds = orderedPickIds
        .map((p) => p.taskId)
        .toList(growable: false);

    final orderedTasks = selectedIds
        .map((id) => tasksById[id])
        .whereType<Task>()
        .where((task) => !_isCompleted(task))
        .toList(growable: false);

    Iterable<String> idsForBucket(my_day.MyDayPickBucket bucket) {
      return orderedPickIds
          .where((p) => p.bucket == bucket)
          .map((p) => p.taskId);
    }

    final acceptedDueIds = idsForBucket(
      my_day.MyDayPickBucket.due,
    ).toList(growable: false);
    final acceptedStartsIds = idsForBucket(
      my_day.MyDayPickBucket.starts,
    ).toList(growable: false);
    final acceptedFocusIds = idsForBucket(
      my_day.MyDayPickBucket.focus,
    ).toList(growable: false);

    final acceptedDueTasks = _resolveAcceptedTasks(acceptedDueIds, tasksById);
    final acceptedStartsTasks = _resolveAcceptedTasks(
      acceptedStartsIds,
      tasksById,
    );
    final acceptedFocusTasks = _resolveAcceptedTasks(
      acceptedFocusIds,
      tasksById,
    );

    final todaySelectedTaskIds = selectedIds.toSet();

    final today = dateOnly(dayKeyUtc);
    final dueLimit = _dueLimit(today, globalSettings.myDayDueWindowDays);

    final planned = _buildPlanned(
      tasks,
      today,
      globalSettings.myDayDueWindowDays,
    );
    final candidateDueIds = <String>[];
    final candidateStartsIds = <String>[];
    for (final task in planned) {
      if (_isDueWithinWindow(task, dueLimit)) {
        candidateDueIds.add(task.id);
        continue;
      }
      if (_isAvailableToStart(task, today)) {
        candidateStartsIds.add(task.id);
      }
    }

    final missingDueIds = candidateDueIds
        .where((id) => !todaySelectedTaskIds.contains(id))
        .toList(growable: false);
    final missingStartsIds = candidateStartsIds
        .where((id) => !todaySelectedTaskIds.contains(id))
        .toList(growable: false);

    final missingDueTasks = missingDueIds
        .map((id) => tasksById[id])
        .whereType<Task>()
        .where((t) => !_isCompleted(t))
        .toList(growable: false);
    final missingStartsTasks = missingStartsIds
        .map((id) => tasksById[id])
        .whereType<Task>()
        .where((t) => !_isCompleted(t))
        .toList(growable: false);

    final qualifyingByTaskId = <String, String?>{};
    for (final pick in dayPicks.picks) {
      qualifyingByTaskId[pick.taskId] = pick.qualifyingValueId;
    }
    for (final task in orderedTasks) {
      qualifyingByTaskId.putIfAbsent(
        task.id,
        () => task.effectivePrimaryValueId,
      );
    }

    return _buildViewModel(
      tasks: orderedTasks,
      values: values,
      qualifyingByTaskId: qualifyingByTaskId,
      acceptedDue: acceptedDueTasks,
      acceptedStarts: acceptedStartsTasks,
      acceptedFocus: acceptedFocusTasks,
      dueAcceptedTotalCount: acceptedDueIds.length,
      startsAcceptedTotalCount: acceptedStartsIds.length,
      focusAcceptedTotalCount: acceptedFocusIds.length,
      selectedTotalCount: selectedIds.length,
      missingDueCount: missingDueIds.length,
      missingStartsCount: missingStartsIds.length,
      missingDueTasks: missingDueTasks,
      missingStartsTasks: missingStartsTasks,
      todaySelectedTaskIds: todaySelectedTaskIds,
    );
  }

  List<Task> _buildPlanned(
    List<Task> tasks,
    DateTime today,
    int dueWindowDays,
  ) {
    final dueSoonLimit = today.add(
      Duration(days: dueWindowDays.clamp(1, 30) - 1),
    );

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

  _MyDayViewModel _buildViewModel({
    required List<Task> tasks,
    required List<Value> values,
    required Map<String, String?> qualifyingByTaskId,
    List<Task> acceptedDue = const <Task>[],
    List<Task> acceptedStarts = const <Task>[],
    List<Task> acceptedFocus = const <Task>[],
    int dueAcceptedTotalCount = 0,
    int startsAcceptedTotalCount = 0,
    int focusAcceptedTotalCount = 0,
    int selectedTotalCount = 0,
    int missingDueCount = 0,
    int missingStartsCount = 0,
    List<Task> missingDueTasks = const <Task>[],
    List<Task> missingStartsTasks = const <Task>[],
    Set<String> todaySelectedTaskIds = const <String>{},
  }) {
    final valueById = {for (final value in values) value.id: value};

    for (final task in tasks) {
      for (final value in task.effectiveValues) {
        valueById.putIfAbsent(value.id, () => value);
      }
    }

    final doneCount = tasks.where(_isCompleted).length;
    final totalCount = tasks.length;

    return _MyDayViewModel(
      tasks: tasks,
      summary: MyDaySummary(
        doneCount: doneCount,
        totalCount: totalCount,
      ),
      mix: MyDayMixVm.from(
        tasks: tasks,
        qualifyingByTaskId: qualifyingByTaskId,
        valueById: valueById,
      ),
      acceptedDue: acceptedDue,
      acceptedStarts: acceptedStarts,
      acceptedFocus: acceptedFocus,
      dueAcceptedTotalCount: dueAcceptedTotalCount,
      startsAcceptedTotalCount: startsAcceptedTotalCount,
      focusAcceptedTotalCount: focusAcceptedTotalCount,
      selectedTotalCount: selectedTotalCount,
      missingDueCount: missingDueCount,
      missingStartsCount: missingStartsCount,
      missingDueTasks: missingDueTasks,
      missingStartsTasks: missingStartsTasks,
      todaySelectedTaskIds: todaySelectedTaskIds,
    );
  }

  List<Task> _resolveAcceptedTasks(
    Iterable<String> ids,
    Map<String, Task> tasksById,
  ) {
    return ids
        .map((id) => tasksById[id])
        .whereType<Task>()
        .where((task) => !_isCompleted(task))
        .toList(growable: false);
  }

  bool _isCompleted(Task task) {
    return task.occurrence?.isCompleted ?? task.completed;
  }
}

final class _MyDayViewModel {
  const _MyDayViewModel({
    required this.tasks,
    required this.summary,
    required this.mix,
    required this.acceptedDue,
    required this.acceptedStarts,
    required this.acceptedFocus,
    required this.dueAcceptedTotalCount,
    required this.startsAcceptedTotalCount,
    required this.focusAcceptedTotalCount,
    required this.selectedTotalCount,
    required this.missingDueCount,
    required this.missingStartsCount,
    required this.missingDueTasks,
    required this.missingStartsTasks,
    required this.todaySelectedTaskIds,
  });

  final List<Task> tasks;
  final MyDaySummary summary;
  final MyDayMixVm mix;

  final List<Task> acceptedDue;
  final List<Task> acceptedStarts;
  final List<Task> acceptedFocus;

  final int dueAcceptedTotalCount;
  final int startsAcceptedTotalCount;
  final int focusAcceptedTotalCount;
  final int selectedTotalCount;

  final int missingDueCount;
  final int missingStartsCount;
  final List<Task> missingDueTasks;
  final List<Task> missingStartsTasks;
  final Set<String> todaySelectedTaskIds;
}

final class MyDayMixVm {
  const MyDayMixVm({
    required this.summarySegments,
    required this.remainingCount,
    required this.expandedRows,
    required this.totalTasks,
  });

  factory MyDayMixVm.from({
    required List<Task> tasks,
    required Map<String, String?> qualifyingByTaskId,
    required Map<String, Value> valueById,
  }) {
    if (tasks.isEmpty) return empty;

    final counts = <String?, int>{};

    for (final task in tasks) {
      String? valueId = qualifyingByTaskId[task.id];
      valueId ??= task.effectivePrimaryValueId;
      valueId ??= task.effectiveValues.isNotEmpty
          ? task.effectiveValues.first.id
          : null;

      counts.update(valueId, (v) => v + 1, ifAbsent: () => 1);
    }

    final rows =
        counts.entries
            .map(
              (e) {
                final valueId = e.key;
                final count = e.value;
                final percent = ((count / tasks.length) * 100).round();

                if (valueId == null) {
                  return MyDayMixRowVm(
                    valueId: null,
                    label: 'Unaligned',
                    dotColorHex: null,
                    count: count,
                    percent: percent,
                  );
                }

                final value = valueById[valueId];
                return MyDayMixRowVm(
                  valueId: valueId,
                  label: value?.name ?? 'Unknown value',
                  dotColorHex: value?.color,
                  count: count,
                  percent: percent,
                );
              },
            )
            .toList(growable: false)
          ..sort(
            (a, b) {
              final byCount = b.count.compareTo(a.count);
              if (byCount != 0) return byCount;

              int priorityWeightFor(MyDayMixRowVm row) {
                final valueId = row.valueId;
                if (valueId == null) return -1;
                return valueById[valueId]?.priority.weight ?? 0;
              }

              final byPriority = priorityWeightFor(b).compareTo(
                priorityWeightFor(a),
              );
              if (byPriority != 0) return byPriority;

              return a.label.toLowerCase().compareTo(b.label.toLowerCase());
            },
          );

    final summary = rows
        .take(2)
        .map(
          (r) => MyDayMixSegmentVm(
            label: r.label,
            dotColorHex: r.dotColorHex,
            percent: r.percent,
          ),
        )
        .toList(growable: false);

    final remaining = (rows.length - summary.length).clamp(0, 999);
    final expanded = rows.take(3).toList(growable: false);

    return MyDayMixVm(
      summarySegments: summary,
      remainingCount: remaining,
      expandedRows: expanded,
      totalTasks: tasks.length,
    );
  }

  final List<MyDayMixSegmentVm> summarySegments;
  final int remainingCount;
  final List<MyDayMixRowVm> expandedRows;
  final int totalTasks;

  static const empty = MyDayMixVm(
    summarySegments: <MyDayMixSegmentVm>[],
    remainingCount: 0,
    expandedRows: <MyDayMixRowVm>[],
    totalTasks: 0,
  );
}

final class MyDayMixSegmentVm {
  const MyDayMixSegmentVm({
    required this.label,
    required this.dotColorHex,
    required this.percent,
  });

  final String label;
  final String? dotColorHex;
  final int percent;
}

final class MyDayMixRowVm {
  const MyDayMixRowVm({
    required this.valueId,
    required this.label,
    required this.dotColorHex,
    required this.count,
    required this.percent,
  });

  final String? valueId;
  final String label;
  final String? dotColorHex;
  final int count;
  final int percent;
}
