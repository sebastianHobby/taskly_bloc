import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/core/mixins/list_bloc_mixin.dart';
import 'package:taskly_bloc/core/shared/models/sort_preferences.dart';
import 'package:taskly_bloc/core/utils/app_logger.dart';
import 'package:taskly_bloc/data/adapters/page_sort_adapter.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
part 'task_list_bloc.freezed.dart';

@freezed
sealed class TaskOverviewEvent with _$TaskOverviewEvent {
  const factory TaskOverviewEvent.subscriptionRequested() =
      TaskOverviewSubscriptionRequested;

  const factory TaskOverviewEvent.configChanged({
    required TaskQuery query,
  }) = TaskOverviewConfigChanged;

  /// Sort changed event that also persists to settings.
  const factory TaskOverviewEvent.sortChanged({
    required SortPreferences preferences,
  }) = TaskOverviewSortChanged;

  /// Display settings changed event that persists to settings.
  const factory TaskOverviewEvent.displaySettingsChanged({
    required PageDisplaySettings settings,
  }) = TaskOverviewDisplaySettingsChanged;

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
    required TaskQuery query,
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
    required TaskQuery query,
    PageSortAdapter? sortAdapter,
  }) : _taskRepository = taskRepository,
       _query = query,
       _sortAdapter = sortAdapter,
       super(const TaskOverviewState.initial()) {
    on<TaskOverviewSubscriptionRequested>(_onSubscriptionRequested);
    on<TaskOverviewSortChanged>(_onSortChanged);
    on<TaskOverviewDisplaySettingsChanged>(_onDisplaySettingsChanged);
    on<TaskOverviewToggleTaskCompletion>(_onToggleTaskCompletion);
    on<TaskOverviewDeleteTask>(_onDeleteTask);
  }

  final TaskRepositoryContract _taskRepository;
  final TaskQuery _query;
  final PageSortAdapter? _sortAdapter;
  final _logger = AppLogger.forBloc('TaskOverview');

  /// Load display settings for this page.
  Future<PageDisplaySettings> loadDisplaySettings() async {
    if (_sortAdapter == null) return const PageDisplaySettings();
    return _sortAdapter.loadDisplaySettings();
  }

  // ListBlocMixin implementation
  @override
  TaskOverviewState createLoadingState() => const TaskOverviewLoading();

  @override
  TaskOverviewState createErrorState(Object error) =>
      TaskOverviewState.error(error: error, stacktrace: StackTrace.current);

  @override
  TaskOverviewState createLoadedState(List<Task> items) =>
      TaskOverviewLoaded(tasks: items, query: _query);

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

    await emit.forEach<List<Task>>(
      _taskRepository.watchAll(_query),
      onData: (tasks) {
        updateCache(tasks);
        return TaskOverviewState.loaded(
          tasks: tasks,
          query: _query,
        );
      },
      onError: (error, stackTrace) => TaskOverviewState.error(
        error: error,
        stacktrace: stackTrace,
      ),
    );
  }

  Future<void> _onSortChanged(
    TaskOverviewSortChanged event,
    Emitter<TaskOverviewState> emit,
  ) async {
    // Persist to settings
    await _sortAdapter?.save(event.preferences);
    // Note: Sort changes require bloc recreation with new filterConfig
  }

  Future<void> _onDisplaySettingsChanged(
    TaskOverviewDisplaySettingsChanged event,
    Emitter<TaskOverviewState> emit,
  ) async {
    // Persist to settings via adapter
    await _sortAdapter?.saveDisplaySettings(event.settings);
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
      _logger.error('Failed to toggle task completion', error, stacktrace);
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
      _logger.error('Failed to delete task', error, stacktrace);
      emit(TaskOverviewState.error(error: error, stacktrace: stacktrace));
    }
  }
}
