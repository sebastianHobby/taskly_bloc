import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/preferences.dart';
import 'package:taskly_domain/settings.dart' as settings;
import 'package:taskly_domain/services.dart';

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
    required AllocationSnapshotRepositoryContract allocationSnapshotRepository,
    required AllocationOrchestrator allocationOrchestrator,
    required TaskRepositoryContract taskRepository,
    required ValueRepositoryContract valueRepository,
    required SettingsRepositoryContract settingsRepository,
    required HomeDayKeyService dayKeyService,
    required TemporalTriggerService temporalTriggerService,
  }) : _allocationSnapshotRepository = allocationSnapshotRepository,
       _allocationOrchestrator = allocationOrchestrator,
       _taskRepository = taskRepository,
       _valueRepository = valueRepository,
       _settingsRepository = settingsRepository,
       _dayKeyService = dayKeyService,
       _temporalTriggerService = temporalTriggerService,
       super(const MyDayLoading()) {
    on<MyDayStarted>(_onStarted, transformer: restartable());
    add(const MyDayStarted());
  }

  final AllocationSnapshotRepositoryContract _allocationSnapshotRepository;
  final AllocationOrchestrator _allocationOrchestrator;
  final TaskRepositoryContract _taskRepository;
  final ValueRepositoryContract _valueRepository;
  final SettingsRepositoryContract _settingsRepository;
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
    final values$ = _valueRepository.watchAll().startWith(const <Value>[]);
    final ritual$ = _settingsRepository
        .watch<settings.MyDayRitualState>(SettingsKey.myDayRitual)
        .startWith(const settings.MyDayRitualState());

    return ritual$.switchMap((ritual) {
      final selectedIds = ritual.isCompletedFor(dayKeyUtc)
          ? ritual.selectedTaskIds
          : const <String>[];

      if (selectedIds.isNotEmpty) {
        final tasks$ = _taskRepository
            .watchAll(TaskQuery.incomplete())
            .startWith(const <Task>[]);
        return Rx.combineLatest2<List<Task>, List<Value>, _MyDayViewModel>(
          tasks$,
          values$,
          (tasks, values) => _buildFromRitualSelection(
            ritual,
            dayKeyUtc,
            tasks,
            values,
          ),
        );
      }

      return _allocationSnapshotRepository
          .watchLatestForUtcDay(dayKeyUtc)
          .switchMap((snapshot) {
            if (snapshot == null) {
              return Rx.combineLatest2<
                AllocationResult,
                List<Value>,
                _MyDayViewModel
              >(
                _allocationOrchestrator.watchAllocation(),
                values$,
                _buildFromAllocation,
              );
            }

            final refs$ = _allocationSnapshotRepository
                .watchLatestTaskRefsForUtcDay(dayKeyUtc)
                .startWith(const <AllocationSnapshotTaskRef>[]);
            final tasks$ = _taskRepository.watchAll().startWith(const <Task>[]);

            return Rx.combineLatest3<
              List<AllocationSnapshotTaskRef>,
              List<Task>,
              List<Value>,
              _MyDayViewModel
            >(
              refs$,
              tasks$,
              values$,
              _buildFromSnapshot,
            );
          });
    });
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

  _MyDayViewModel _buildFromSnapshot(
    List<AllocationSnapshotTaskRef> refs,
    List<Task> tasks,
    List<Value> values,
  ) {
    final tasksById = {
      for (final task in tasks) task.id: task,
    };

    final orderedTasks = refs
        .map((ref) => tasksById[ref.taskId])
        .whereType<Task>()
        .toList(growable: false);

    final qualifyingByTaskId = {
      for (final ref in refs)
        ref.taskId: ref.qualifyingValueId ?? ref.effectivePrimaryValueId,
    };

    return _buildViewModel(
      tasks: orderedTasks,
      values: values,
      qualifyingByTaskId: qualifyingByTaskId,
    );
  }

  _MyDayViewModel _buildFromRitualSelection(
    settings.MyDayRitualState ritual,
    DateTime dayKeyUtc,
    List<Task> tasks,
    List<Value> values,
  ) {
    final tasksById = {for (final task in tasks) task.id: task};

    final selectedIds = ritual.selectedTaskIds;

    final orderedTasks = selectedIds
        .map((id) => tasksById[id])
        .whereType<Task>()
        .where((task) => !_isCompleted(task))
        .toList(growable: false);

    final acceptedFocusTasks = _resolveAcceptedTasks(
      ritual.acceptedFocusTaskIds,
      tasksById,
    );
    final acceptedFocusIds = acceptedFocusTasks.map((t) => t.id).toSet();

    final acceptedDueTasks = _resolveAcceptedTasks(
      ritual.acceptedDueTaskIds.where((id) => !acceptedFocusIds.contains(id)),
      tasksById,
    );
    final acceptedDueIds = acceptedDueTasks.map((t) => t.id).toSet();

    final acceptedStartsTasks = _resolveAcceptedTasks(
      ritual.acceptedStartsTaskIds.where(
        (id) => !acceptedFocusIds.contains(id) && !acceptedDueIds.contains(id),
      ),
      tasksById,
    );

    final todaySelectedTaskIds = ritual.selectedTaskIds.toSet();

    final missingDueIds = ritual.candidateDueTaskIds
        .where((id) => !todaySelectedTaskIds.contains(id))
        .toList(growable: false);
    final missingStartsIds = ritual.candidateStartsTaskIds
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

    final qualifyingByTaskId = {
      for (final task in orderedTasks) task.id: task.effectivePrimaryValueId,
    };

    return _buildViewModel(
      tasks: orderedTasks,
      values: values,
      qualifyingByTaskId: qualifyingByTaskId,
      acceptedDue: acceptedDueTasks,
      acceptedStarts: acceptedStartsTasks,
      acceptedFocus: acceptedFocusTasks,
      dueAcceptedTotalCount: ritual.acceptedDueTaskIds.length,
      startsAcceptedTotalCount: ritual.acceptedStartsTaskIds.length,
      focusAcceptedTotalCount: ritual.acceptedFocusTaskIds.length,
      selectedTotalCount: ritual.selectedTaskIds.length,
      missingDueCount: missingDueIds.length,
      missingStartsCount: missingStartsIds.length,
      missingDueTasks: missingDueTasks,
      missingStartsTasks: missingStartsTasks,
      todaySelectedTaskIds: todaySelectedTaskIds,
    );
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
