import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';

import 'package:taskly_bloc/features/tasks/utils/task_selector.dart';
part 'task_list_bloc.freezed.dart';

//Events (the input to bloc)
@freezed
sealed class TaskOverviewEvent with _$TaskOverviewEvent {
  const factory TaskOverviewEvent.subscriptionRequested() =
      TaskOverviewSubscriptionRequested;

  const factory TaskOverviewEvent.configChanged({
    required TaskSelectorConfig config,
  }) = TaskOverviewConfigChanged;

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
    required TaskSelectorConfig config,
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
    TaskSelectorConfig initialConfig = const TaskSelectorConfig(
      ruleSets: [],
      sortCriteria: TaskSelector.defaultSortCriteria,
    ),
    bool withRelated = false,
  }) : _taskRepository = taskRepository,
       _config = initialConfig,
       _withRelated = withRelated,
       _selector = TaskSelector(),
       super(const TaskOverviewState.initial()) {
    on<TaskOverviewSubscriptionRequested>(_onSubscriptionRequested);
    on<TaskOverviewConfigChanged>(_onConfigChanged);
    on<TaskOverviewToggleTaskCompletion>(_onToggleTaskCompletion);
  }

  final TaskRepositoryContract _taskRepository;
  final bool _withRelated;
  final TaskSelector _selector;

  TaskSelectorConfig _config;
  var _hasTaskSnapshot = false;
  List<Task> _allTasks = const [];

  Future<void> _onSubscriptionRequested(
    TaskOverviewSubscriptionRequested event,
    Emitter<TaskOverviewState> emit,
  ) async {
    emit(const TaskOverviewState.loading());
    // Subscribe to task stream
    await emit.forEach<List<Task>>(
      _taskRepository.watchAll(withRelated: _withRelated),
      onData: (tasks) {
        _hasTaskSnapshot = true;
        _allTasks = tasks;
        return TaskOverviewState.loaded(
          tasks: _applyConfig(tasks),
          config: _config,
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
        tasks: _applyConfig(_allTasks),
        config: _config,
      ),
    );
  }

  void _onConfigChanged(
    TaskOverviewConfigChanged event,
    Emitter<TaskOverviewState> emit,
  ) {
    _config = event.config;
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

  List<Task> _applyConfig(List<Task> tasks) {
    return _selector.filter(
      tasks: tasks,
      ruleSets: _config.ruleSets,
      sortCriteria: _config.sortCriteria,
      now: DateTime.now(),
    );
  }
}
