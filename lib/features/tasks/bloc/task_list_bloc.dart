import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/core/mixins/list_bloc_mixin.dart';
import 'package:taskly_bloc/core/shared/models/sort_preferences.dart';
import 'package:taskly_bloc/data/adapters/page_sort_adapter.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';

import 'package:taskly_bloc/features/tasks/utils/task_selector.dart';
part 'task_list_bloc.freezed.dart';

@freezed
sealed class TaskOverviewEvent with _$TaskOverviewEvent {
  const factory TaskOverviewEvent.subscriptionRequested() =
      TaskOverviewSubscriptionRequested;

  const factory TaskOverviewEvent.configChanged({
    required TaskSelectorConfig config,
  }) = TaskOverviewConfigChanged;

  /// Sort changed event that also persists to settings.
  const factory TaskOverviewEvent.sortChanged({
    required SortPreferences preferences,
  }) = TaskOverviewSortChanged;

  const factory TaskOverviewEvent.toggleTaskCompletion({
    required Task task,
  }) = TaskOverviewToggleTaskCompletion;

  const factory TaskOverviewEvent.deleteTask({
    required Task task,
  }) = TaskOverviewDeleteTask;
}

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

class TaskOverviewBloc extends Bloc<TaskOverviewEvent, TaskOverviewState>
    with
        ListBlocMixin<TaskOverviewEvent, TaskOverviewState, Task>,
        CachedListBlocMixin<TaskOverviewEvent, TaskOverviewState, Task> {
  TaskOverviewBloc({
    required TaskRepositoryContract taskRepository,
    PageSortAdapter? sortAdapter,
    TaskSelectorConfig initialConfig = const TaskSelectorConfig(
      ruleSets: [],
      sortCriteria: TaskSelector.defaultSortCriteria,
    ),
    bool withRelated = false,
  }) : _taskRepository = taskRepository,
       _sortAdapter = sortAdapter,
       _config = initialConfig,
       _withRelated = withRelated,
       _selector = TaskSelector(),
       super(const TaskOverviewState.initial()) {
    on<TaskOverviewSubscriptionRequested>(_onSubscriptionRequested);
    on<TaskOverviewConfigChanged>(_onConfigChanged);
    on<TaskOverviewSortChanged>(_onSortChanged);
    on<TaskOverviewToggleTaskCompletion>(_onToggleTaskCompletion);
    on<TaskOverviewDeleteTask>(_onDeleteTask);
  }

  final TaskRepositoryContract _taskRepository;
  final PageSortAdapter? _sortAdapter;
  final bool _withRelated;
  final TaskSelector _selector;

  TaskSelectorConfig _config;

  // ListBlocMixin implementation
  @override
  TaskOverviewState createLoadingState() => const TaskOverviewLoading();

  @override
  TaskOverviewState createErrorState(Object error) =>
      TaskOverviewState.error(error: error, stacktrace: StackTrace.current);

  @override
  TaskOverviewState createLoadedState(List<Task> items) =>
      TaskOverviewLoaded(tasks: items, config: _config);

  List<Task> _applyConfig(List<Task> tasks) {
    return _selector.filter(
      tasks: tasks,
      ruleSets: _config.ruleSets,
      sortCriteria: _config.sortCriteria,
      now: DateTime.now(),
    );
  }

  @override
  Future<void> close() {
    // emit.forEach subscriptions are automatically cancelled by framework
    return super.close();
  }

  Future<void> _onSubscriptionRequested(
    TaskOverviewSubscriptionRequested event,
    Emitter<TaskOverviewState> emit,
  ) async {
    emit(const TaskOverviewState.loading());

    // Load sort preferences from adapter if available
    if (_sortAdapter != null) {
      final savedSort = await _sortAdapter.load();
      if (savedSort != null) {
        _config = _config.copyWith(sortCriteria: savedSort.criteria);
      }
    }

    await emit.forEach<List<Task>>(
      _taskRepository.watchAll(withRelated: _withRelated),
      onData: (tasks) {
        updateCache(tasks);
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
    if (!hasSnapshot) return;

    emit(
      TaskOverviewState.loaded(
        tasks: _applyConfig(cachedItems),
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

  Future<void> _onSortChanged(
    TaskOverviewSortChanged event,
    Emitter<TaskOverviewState> emit,
  ) async {
    // Update local config
    _config = _config.copyWith(sortCriteria: event.preferences.criteria);
    _emitLoadedFromSnapshot(emit);

    // Persist to settings
    await _sortAdapter?.save(event.preferences);
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
      );
    } catch (error, stacktrace) {
      emit(TaskOverviewState.error(error: error, stacktrace: stacktrace));
    }
  }

  Future<void> _onDeleteTask(
    TaskOverviewDeleteTask event,
    Emitter<TaskOverviewState> emit,
  ) async {
    try {
      await _taskRepository.delete(event.task.id);
    } catch (error, stacktrace) {
      emit(TaskOverviewState.error(error: error, stacktrace: stacktrace));
    }
  }
}
