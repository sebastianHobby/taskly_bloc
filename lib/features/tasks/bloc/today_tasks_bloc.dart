import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';
import 'package:taskly_bloc/domain/task.dart';
import 'package:taskly_bloc/features/tasks/utils/task_selector.dart';

part 'today_tasks_event.dart';
part 'today_tasks_state.dart';
part 'today_tasks_bloc.freezed.dart';

/// App-level bloc for today's tasks with badge count.
///
/// Uses factory pattern for dynamic config (DateTime.now()) to avoid
/// temporal coupling. The configFactory is called during event processing,
/// ensuring fresh timestamps.
///
/// Architecture:
/// - Repository: Pure data access (shared stream via RxDart)
/// - TaskSelector: Business logic (filtering rules)
/// - Bloc: Configuration provider (what filter, when to apply)
class TodayTasksBloc extends Bloc<TodayTasksEvent, TodayTasksState> {
  TodayTasksBloc({
    required TaskRepositoryContract taskRepository,
    required TaskSelectorConfig Function() configFactory,
  }) : _taskRepository = taskRepository,
       _configFactory = configFactory,
       super(const TodayTasksState.initial()) {
    on<TodayTasksSubscriptionRequested>(_onSubscriptionRequested);
  }

  final TaskRepositoryContract _taskRepository;
  final TaskSelectorConfig Function() _configFactory;
  final TaskSelector _selector = TaskSelector();

  Future<void> _onSubscriptionRequested(
    TodayTasksSubscriptionRequested event,
    Emitter<TodayTasksState> emit,
  ) async {
    emit(const TodayTasksState.loading());

    await emit.forEach<List<Task>>(
      _taskRepository.watchAll(withRelated: true),
      onData: (tasks) {
        // Get fresh config on each data update
        final config = _configFactory();

        // Filter tasks using TaskSelector
        final filteredTasks = _selector.filter(
          tasks: tasks,
          ruleSets: config.ruleSets,
          now: DateTime.now(),
        );

        // Count incomplete tasks for badge
        final incompleteCount = filteredTasks.where((t) => !t.completed).length;

        return TodayTasksState.loaded(
          tasks: filteredTasks,
          incompleteCount: incompleteCount,
        );
      },
      onError: (error, stackTrace) => TodayTasksState.error(
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }
}
