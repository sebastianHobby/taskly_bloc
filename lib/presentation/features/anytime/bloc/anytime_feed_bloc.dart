import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:taskly_bloc/presentation/feeds/rows/list_row_ui_model.dart';
import 'package:taskly_bloc/presentation/feeds/rows/row_key.dart';
import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/services.dart';

sealed class AnytimeFeedEvent {
  const AnytimeFeedEvent();
}

final class AnytimeFeedStarted extends AnytimeFeedEvent {
  const AnytimeFeedStarted();
}

final class AnytimeFeedRetryRequested extends AnytimeFeedEvent {
  const AnytimeFeedRetryRequested();
}

final class AnytimeFeedFocusOnlyChanged extends AnytimeFeedEvent {
  const AnytimeFeedFocusOnlyChanged({required this.enabled});

  final bool enabled;
}

sealed class AnytimeFeedState {
  const AnytimeFeedState();
}

final class AnytimeFeedLoading extends AnytimeFeedState {
  const AnytimeFeedLoading();
}

final class AnytimeFeedLoaded extends AnytimeFeedState {
  const AnytimeFeedLoaded({required this.rows});

  final List<ListRowUiModel> rows;
}

final class AnytimeFeedError extends AnytimeFeedState {
  const AnytimeFeedError({required this.message});

  final String message;
}

class AnytimeFeedBloc extends Bloc<AnytimeFeedEvent, AnytimeFeedState> {
  AnytimeFeedBloc({
    required TaskRepositoryContract taskRepository,
    required AllocationSnapshotRepositoryContract allocationSnapshotRepository,
    required HomeDayKeyService dayKeyService,
    required TemporalTriggerService temporalTriggerService,
  }) : _taskRepository = taskRepository,
       _allocationSnapshotRepository = allocationSnapshotRepository,
       _dayKeyService = dayKeyService,
       _temporalTriggerService = temporalTriggerService,
       super(const AnytimeFeedLoading()) {
    on<AnytimeFeedStarted>(_onStarted);
    on<AnytimeFeedRetryRequested>(_onRetryRequested);
    on<AnytimeFeedFocusOnlyChanged>(_onFocusOnlyChanged);

    add(const AnytimeFeedStarted());
  }

  final TaskRepositoryContract _taskRepository;
  final AllocationSnapshotRepositoryContract _allocationSnapshotRepository;
  final HomeDayKeyService _dayKeyService;
  final TemporalTriggerService _temporalTriggerService;

  StreamSubscription<List<Task>>? _tasksSub;
  StreamSubscription<List<AllocationSnapshotTaskRef>>? _allocatedSub;
  StreamSubscription<dynamic>? _triggersSub;

  List<Task> _latestTasks = const <Task>[];
  Set<String> _allocatedTaskIds = const <String>{};
  bool _focusOnly = false;
  DateTime? _dayKeyUtc;

  Future<void> _onStarted(
    AnytimeFeedStarted event,
    Emitter<AnytimeFeedState> emit,
  ) async {
    await _subscribe(emit);
  }

  Future<void> _onRetryRequested(
    AnytimeFeedRetryRequested event,
    Emitter<AnytimeFeedState> emit,
  ) async {
    emit(const AnytimeFeedLoading());
    await _subscribe(emit);
  }

  void _onFocusOnlyChanged(
    AnytimeFeedFocusOnlyChanged event,
    Emitter<AnytimeFeedState> emit,
  ) {
    _focusOnly = event.enabled;
    _emitRows(emit);
  }

  Future<void> _subscribe(Emitter<AnytimeFeedState> emit) async {
    await _tasksSub?.cancel();
    await _allocatedSub?.cancel();
    await _triggersSub?.cancel();

    _tasksSub = _taskRepository
        .watchAll(TaskQuery.incomplete())
        .listen(
          (tasks) {
            _latestTasks = tasks;
            _emitRows(emit);
          },
          onError: (Object e, StackTrace s) {
            emit(AnytimeFeedError(message: e.toString()));
          },
        );

    _triggersSub = _temporalTriggerService.events.listen((event) {
      if (event is HomeDayBoundaryCrossed || event is AppResumed) {
        _setDayKeyAndResubscribeAllocated(emit);
      }
    });

    _setDayKeyAndResubscribeAllocated(emit);
  }

  void _setDayKeyAndResubscribeAllocated(Emitter<AnytimeFeedState> emit) {
    final nextDayKeyUtc = _dayKeyService.todayDayKeyUtc();

    if (_dayKeyUtc != null && _dayKeyUtc!.isAtSameMomentAs(nextDayKeyUtc)) {
      return;
    }

    _dayKeyUtc = nextDayKeyUtc;

    _allocatedSub?.cancel();
    _allocatedSub = _allocationSnapshotRepository
        .watchLatestTaskRefsForUtcDay(nextDayKeyUtc)
        .listen(
          (refs) {
            _allocatedTaskIds = {
              for (final r in refs)
                if (r.taskId.trim().isNotEmpty) r.taskId,
            };
            _emitRows(emit);
          },
          onError: (Object e, StackTrace s) {
            emit(AnytimeFeedError(message: e.toString()));
          },
        );
  }

  void _emitRows(Emitter<AnytimeFeedState> emit) {
    try {
      final tasks = _focusOnly
          ? _latestTasks.where((t) => _allocatedTaskIds.contains(t.id)).toList()
          : _latestTasks;

      final rows = _mapToRows(tasks);
      emit(AnytimeFeedLoaded(rows: rows));
    } catch (e) {
      emit(AnytimeFeedError(message: e.toString()));
    }
  }

  List<ListRowUiModel> _mapToRows(List<Task> tasks) {
    if (tasks.isEmpty) return const <ListRowUiModel>[];

    final groups = <String, _ValueGroup>{};

    for (final task in tasks) {
      final valueId = task.effectivePrimaryValueId;
      final key = valueId ?? '__none__';

      final group = groups.putIfAbsent(
        key,
        () => _ValueGroup(
          valueId: valueId,
          value: task.effectivePrimaryValue,
        ),
      );

      group.addTask(task);
    }

    final sortedGroups = groups.values.toList(growable: false)
      ..sort(_compareValueGroups);

    final rows = <ListRowUiModel>[];

    for (final group in sortedGroups) {
      final valueTitle = group.value?.name ?? 'No Value Assigned';
      rows.add(
        ValueHeaderRowUiModel(
          rowKey: RowKey.v1(
            screen: 'anytime',
            rowType: 'group_header',
            params: <String, String>{
              'kind': 'value',
              'valueId': group.valueId ?? 'none',
            },
          ),
          depth: 0,
          title: valueTitle,
          valueId: group.valueId,
          priority: group.value?.priority,
          isTappableToScope: false,
        ),
      );

      final projectGroups = group.projectGroups.toList(growable: false)
        ..sort(_compareProjectGroups);

      for (final pg in projectGroups) {
        rows.add(
          ProjectHeaderRowUiModel(
            rowKey: RowKey.v1(
              screen: 'anytime',
              rowType: 'group_header',
              params: <String, String>{
                'kind': 'project',
                'valueId': group.valueId ?? 'none',
                'project': pg.isInbox ? 'inbox' : (pg.projectId ?? 'unknown'),
              },
            ),
            depth: 1,
            title: pg.title,
            projectId: pg.projectId,
            isInbox: pg.isInbox,
          ),
        );

        for (final task in pg.tasks) {
          rows.add(
            TaskRowUiModel(
              rowKey: RowKey.v1(
                screen: 'anytime',
                rowType: 'task',
                params: <String, String>{'id': task.id},
              ),
              depth: 2,
              task: task,
            ),
          );
        }
      }
    }

    return rows;
  }

  int _compareValueGroups(_ValueGroup a, _ValueGroup b) {
    final aNone = a.valueId == null;
    final bNone = b.valueId == null;
    if (aNone != bNone) return aNone ? 1 : -1;

    final ap = a.value?.priority ?? ValuePriority.medium;
    final bp = b.value?.priority ?? ValuePriority.medium;
    final byP = _priorityRank(ap).compareTo(_priorityRank(bp));
    if (byP != 0) return byP;

    final an = (a.value?.name ?? '').toLowerCase();
    final bn = (b.value?.name ?? '').toLowerCase();
    final byN = an.compareTo(bn);
    if (byN != 0) return byN;

    return (a.valueId ?? '').compareTo(b.valueId ?? '');
  }

  int _priorityRank(ValuePriority p) {
    return switch (p) {
      ValuePriority.high => 0,
      ValuePriority.medium => 1,
      ValuePriority.low => 2,
    };
  }

  int _compareProjectGroups(_ProjectGroup a, _ProjectGroup b) {
    if (a.isInbox != b.isInbox) return a.isInbox ? -1 : 1;

    final byName = a.title.toLowerCase().compareTo(b.title.toLowerCase());
    if (byName != 0) return byName;

    return (a.projectId ?? '').compareTo(b.projectId ?? '');
  }

  @override
  Future<void> close() async {
    await _tasksSub?.cancel();
    await _allocatedSub?.cancel();
    await _triggersSub?.cancel();
    return super.close();
  }
}

class _ValueGroup {
  _ValueGroup({required this.valueId, required this.value});

  final String? valueId;
  final Value? value;

  final Map<String, _ProjectGroup> _projectGroupsByKey =
      <String, _ProjectGroup>{};

  Iterable<_ProjectGroup> get projectGroups => _projectGroupsByKey.values;

  void addTask(Task task) {
    final isInbox = task.projectId == null || task.projectId!.trim().isEmpty;
    final key = isInbox ? '__inbox__' : task.projectId!;

    final group = _projectGroupsByKey.putIfAbsent(
      key,
      () => _ProjectGroup(
        isInbox: isInbox,
        projectId: isInbox ? null : task.projectId,
        title: isInbox ? 'Inbox' : (task.project?.name ?? 'Project'),
      ),
    );

    group.tasks.add(task);
  }
}

class _ProjectGroup {
  _ProjectGroup({
    required this.isInbox,
    required this.projectId,
    required this.title,
  });

  final bool isInbox;
  final String? projectId;
  final String title;

  final List<Task> tasks = <Task>[];
}
