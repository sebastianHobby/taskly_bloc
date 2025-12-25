import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/core/utils/app_logger.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/task.dart';

part 'today_tasks_event.dart';
part 'today_tasks_state.dart';
part 'today_tasks_bloc.freezed.dart';

/// App-level bloc for today's tasks with badge count.
///
/// Uses factory pattern for dynamic config (DateTime.now()) to avoid
/// temporal coupling. The nowFactory is called during event processing,
/// ensuring fresh timestamps.
///
/// Architecture:
/// - Repository: Pure data access with watchAll(TaskQuery) API
/// - Bloc: Configuration provider (what query, when to apply)
class TodayTasksBloc extends Bloc<TodayTasksEvent, TodayTasksState> {
  TodayTasksBloc({
    required TaskRepositoryContract taskRepository,
    required DateTime Function() nowFactory,
  }) : _taskRepository = taskRepository,
       _nowFactory = nowFactory,
       super(const TodayTasksState.initial()) {
    on<TodayTasksSubscriptionRequested>(_onSubscriptionRequested);
  }

  final TaskRepositoryContract _taskRepository;
  final DateTime Function() _nowFactory;
  final _logger = AppLogger.forBloc('TodayTasks');

  Future<void> _onSubscriptionRequested(
    TodayTasksSubscriptionRequested event,
    Emitter<TodayTasksState> emit,
  ) async {
    emit(const TodayTasksState.loading());

    // Get fresh timestamp for query
    final now = _nowFactory();

    await emit.forEach<List<Task>>(
      _taskRepository.watchAll(TaskQuery.today(now: now)),
      onData: (tasks) {
        // Count incomplete tasks for badge
        final incompleteCount = tasks.where((t) => !t.completed).length;

        return TodayTasksState.loaded(
          tasks: tasks,
          incompleteCount: incompleteCount,
        );
      },
      onError: (error, stackTrace) {
        _logger.error('Failed to load today tasks', error, stackTrace);
        return TodayTasksState.error(
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
  }
}
