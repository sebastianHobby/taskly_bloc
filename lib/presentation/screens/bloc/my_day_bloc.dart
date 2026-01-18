import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
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
  });

  final MyDaySummary summary;
  final MyDayMixVm mix;
  final List<Task> tasks;
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
    required AllocationSnapshotRepositoryContract
    allocationSnapshotRepository,
    required AllocationOrchestrator allocationOrchestrator,
    required TaskRepositoryContract taskRepository,
    required ValueRepositoryContract valueRepository,
    required HomeDayKeyService dayKeyService,
    required TemporalTriggerService temporalTriggerService,
  }) : _allocationSnapshotRepository = allocationSnapshotRepository,
       _allocationOrchestrator = allocationOrchestrator,
       _taskRepository = taskRepository,
       _valueRepository = valueRepository,
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

    return _allocationSnapshotRepository
        .watchLatestForUtcDay(dayKeyUtc)
        .switchMap((snapshot) {
          if (snapshot == null) {
            return _allocationOrchestrator
                .watchAllocation()
                .combineLatest(
                  values$,
                  (allocation, values) => _buildFromAllocation(
                    allocation,
                    values,
                  ),
                );
          }

          final refs$ = _allocationSnapshotRepository
              .watchLatestTaskRefsForUtcDay(dayKeyUtc)
              .startWith(const <AllocationSnapshotTaskRef>[]);
          final tasks$ = _taskRepository
              .watchAll()
              .startWith(const <Task>[]);

          return Rx.combineLatest3<
            List<AllocationSnapshotTaskRef>,
            List<Task>,
            List<Value>,
            _MyDayViewModel
          >(
            refs$,
            tasks$,
            values$,
            (refs, tasks, values) => _buildFromSnapshot(refs, tasks, values),
          );
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

  _MyDayViewModel _buildViewModel({
    required List<Task> tasks,
    required List<Value> values,
    required Map<String, String?> qualifyingByTaskId,
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
    );
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
  });

  final List<Task> tasks;
  final MyDaySummary summary;
  final MyDayMixVm mix;
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
