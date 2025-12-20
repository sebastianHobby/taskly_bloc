import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/core/domain/domain.dart';
import 'package:taskly_bloc/data/repositories/contracts/task_repository_contract.dart';
part 'task_list_bloc.freezed.dart';

//Events (the input to bloc)
@freezed
sealed class TaskOverviewEvent with _$TaskOverviewEvent {
  const factory TaskOverviewEvent.subscriptionRequested() =
      TaskOverviewSubscriptionRequested;

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
  }) = TaskOverviewLoaded;
  const factory TaskOverviewState.error({
    required String message,
    required StackTrace stacktrace,
  }) = TaskOverviewError;
}

// The bloc itself - consumed events from UI and outputs state for UI to react to
class TaskOverviewBloc extends Bloc<TaskOverviewEvent, TaskOverviewState> {
  TaskOverviewBloc({required TaskRepositoryContract taskRepository})
    : _taskRepository = taskRepository,
      super(const TaskOverviewState.initial()) {
    on<TaskOverviewSubscriptionRequested>(_onSubscriptionRequested);
    on<TaskOverviewToggleTaskCompletion>(_onToggleTaskCompletion);
  }

  final TaskRepositoryContract _taskRepository;

  Future<void> _onSubscriptionRequested(
    TaskOverviewSubscriptionRequested event,
    Emitter<TaskOverviewState> emit,
  ) async {
    emit(const TaskOverviewState.loading());
    // Subscribe to task stream
    await emit.forEach<List<Task>>(
      _taskRepository.watchAll(),
      onData: (tasks) => TaskOverviewState.loaded(tasks: tasks),
      onError: (error, stackTrace) => TaskOverviewState.error(
        message: error.toString(),
        stacktrace: stackTrace,
      ),
    );
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
        valueIds: null,
        labelIds: null,
      );
    } catch (error, stacktrace) {
      emit(
        TaskOverviewState.error(
          message: error.toString(),
          stacktrace: stacktrace,
        ),
      );
    }
  }
}
