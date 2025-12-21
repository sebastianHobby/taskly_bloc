import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';

import 'package:taskly_bloc/features/tasks/bloc/task_list_query.dart';
part 'task_list_bloc.freezed.dart';

//Events (the input to bloc)
@freezed
sealed class TaskOverviewEvent with _$TaskOverviewEvent {
  const factory TaskOverviewEvent.subscriptionRequested() =
      TaskOverviewSubscriptionRequested;

  const factory TaskOverviewEvent.queryChanged({
    required TaskListQuery query,
  }) = TaskOverviewQueryChanged;

  const factory TaskOverviewEvent.toggleTaskCompletion({
    required Task task,
  }) = TaskOverviewToggleTaskCompletion;
}

// State (output of bloc which UI responds to)
@freezed
sealed class TaskOverviewState with _$TaskOverviewState {
  const factory TaskOverviewState.initial() = TaskOverviewInitial;
  const factory TaskOverviewState.loading() = TaskOverviewLoading;
  const factory TaskOverviewState.loaded({
    required List<Task> tasks,
    required TaskListQuery query,
  }) = TaskOverviewLoaded;
  const factory TaskOverviewState.error({
    required Object error,
    required StackTrace stacktrace,
  }) = TaskOverviewError;
}

// The bloc itself - consumed events from UI and outputs state for UI to react to
class TaskOverviewBloc extends Bloc<TaskOverviewEvent, TaskOverviewState> {
  TaskOverviewBloc({
    required TaskRepositoryContract taskRepository,
    TaskListQuery initialQuery = TaskListQuery.all,
  }) : _taskRepository = taskRepository,
       _query = initialQuery,
       super(const TaskOverviewState.initial()) {
    on<TaskOverviewSubscriptionRequested>(_onSubscriptionRequested);
    on<TaskOverviewQueryChanged>(_onQueryChanged);
    on<TaskOverviewToggleTaskCompletion>(_onToggleTaskCompletion);
  }

  final TaskRepositoryContract _taskRepository;

  TaskListQuery _query;
  var _hasTaskSnapshot = false;
  List<Task> _allTasks = const [];

  static List<Task> _applyQuery({
    required List<Task> tasks,
    required TaskListQuery query,
  }) {
    Iterable<Task> filtered = tasks;

    DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

    if (query.onlyWithoutProject) {
      filtered = filtered.where((t) => t.projectId == null);
    }

    final projectId = query.projectId;
    if (projectId != null && projectId.isNotEmpty) {
      filtered = filtered.where((t) => t.projectId == projectId);
    }

    final onOrBeforeDate = query.onOrBeforeDate;
    if (onOrBeforeDate != null) {
      final cutoff = dateOnly(onOrBeforeDate);
      filtered = filtered.where((t) {
        final start = t.startDate;
        final deadline = t.deadlineDate;
        final startOk = start != null && !dateOnly(start).isAfter(cutoff);
        final deadlineOk =
            deadline != null && !dateOnly(deadline).isAfter(cutoff);
        return startOk || deadlineOk;
      });
    }

    final onOrAfterDate = query.onOrAfterDate;
    if (onOrAfterDate != null) {
      final cutoff = dateOnly(onOrAfterDate);
      filtered = filtered.where((t) {
        final start = t.startDate;
        final deadline = t.deadlineDate;
        final startOk = start != null && !dateOnly(start).isBefore(cutoff);
        final deadlineOk =
            deadline != null && !dateOnly(deadline).isBefore(cutoff);
        return startOk || deadlineOk;
      });
    }

    switch (query.completion) {
      case TaskCompletionFilter.all:
        break;
      case TaskCompletionFilter.active:
        filtered = filtered.where((t) => !t.completed);
      case TaskCompletionFilter.completed:
        filtered = filtered.where((t) => t.completed);
    }

    final result = filtered.toList(growable: false);

    int compareNullableDate(DateTime? a, DateTime? b) {
      if (a == null && b == null) return 0;
      if (a == null) return 1;
      if (b == null) return -1;
      return a.compareTo(b);
    }

    switch (query.sort) {
      case TaskSort.name:
        result.sort((a, b) => a.name.compareTo(b.name));
      case TaskSort.deadline:
        result.sort((a, b) {
          final primary = compareNullableDate(a.deadlineDate, b.deadlineDate);
          if (primary != 0) return primary;
          return a.name.compareTo(b.name);
        });
    }

    return result;
  }

  Future<void> _onSubscriptionRequested(
    TaskOverviewSubscriptionRequested event,
    Emitter<TaskOverviewState> emit,
  ) async {
    emit(const TaskOverviewState.loading());
    // Subscribe to task stream
    await emit.forEach<List<Task>>(
      _taskRepository.watchAll(),
      onData: (tasks) {
        _hasTaskSnapshot = true;
        _allTasks = tasks;
        return TaskOverviewState.loaded(
          tasks: _applyQuery(tasks: tasks, query: _query),
          query: _query,
        );
      },
      onError: (error, stackTrace) => TaskOverviewState.error(
        error: error,
        stacktrace: stackTrace,
      ),
    );
  }

  void _emitLoadedFromSnapshot(Emitter<TaskOverviewState> emit) {
    if (!_hasTaskSnapshot) return;

    emit(
      TaskOverviewState.loaded(
        tasks: _applyQuery(tasks: _allTasks, query: _query),
        query: _query,
      ),
    );
  }

  void _onQueryChanged(
    TaskOverviewQueryChanged event,
    Emitter<TaskOverviewState> emit,
  ) {
    _query = event.query;
    _emitLoadedFromSnapshot(emit);
  }

  Future<void> _onToggleTaskCompletion(
    TaskOverviewToggleTaskCompletion event,
    Emitter<TaskOverviewState> emit,
  ) async {
    final task = event.task;

    try {
      await _taskRepository.update(
        id: task.id,
        name: task.name,
        description: task.description,
        completed: !task.completed,
        startDate: task.startDate,
        deadlineDate: task.deadlineDate,
        projectId: task.projectId,
        repeatIcalRrule: task.repeatIcalRrule,
        // Don't touch links on quick toggle.
      );
    } catch (error, stacktrace) {
      emit(
        TaskOverviewState.error(
          error: error,
          stacktrace: stacktrace,
        ),
      );
    }
  }
}
