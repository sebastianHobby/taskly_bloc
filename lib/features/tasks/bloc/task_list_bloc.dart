// ...existing code...
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/data/dtos/tasks/task_dto.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';
import 'package:taskly_bloc/features/tasks/bloc/task_action_request.dart';
part 'task_list_bloc.freezed.dart';

//Events (the input to bloc)
@freezed
sealed class TaskListEvent with _$TaskListEvent {
  const factory TaskListEvent.subscriptionRequested() =
      TaskListSubscriptionRequested;

  const factory TaskListEvent.toggleTaskCompletion({required TaskDto taskDto}) =
      TaskListToggleTaskCompletion;
}

// State (output of bloc which UI responds to)
@freezed
sealed class TaskListState with _$TaskListState {
  const factory TaskListState.initial() = _TaskListInitial;
  const factory TaskListState.loading() = _TaskListLoading;
  const factory TaskListState.loaded({
    required List<TaskDto> tasks,
  }) = _TaskListLoaded;
  const factory TaskListState.error({
    required String message,
    required StackTrace stacktrace,
  }) = _TaskListError;
}

// The bloc itself - consumed events from UI and outputs state for UI to react to
class TaskListBloc extends Bloc<TaskListEvent, TaskListState> {
  TaskListBloc({required this.taskRepository})
    : super(const TaskListState.initial()) {
    // map union cases using `when` and delegate to _onX handlers
    on<TaskListEvent>((event, emit) async {
      await event.when(
        subscriptionRequested: () async => _onSubscriptionRequested(emit),
        toggleTaskCompletion: (TaskDto taskDto) async =>
            _onToggleTaskCompletion(taskDto, emit),
      );
    });
  }

  final TaskRepository taskRepository;

  Future<void> _onSubscriptionRequested(
    Emitter<TaskListState> emit,
  ) async {
    emit(const TaskListState.loading());

    await emit.forEach<List<TaskDto>>(
      taskRepository.getTasks(),
      onData: (tasks) => TaskListState.loaded(tasks: tasks),
      onError: (error, stackTrace) => TaskListState.error(
        message: error.toString(),
        stacktrace: stackTrace,
      ),
    );
  }

  Future<void> _onToggleTaskCompletion(
    TaskDto taskDto,
    Emitter<TaskListState> emit,
  ) async {
    bool taskFound = false;
    // Confirm the ID actually exists before proceeding
    state.maybeWhen(
      loaded: (tasks) => taskFound = tasks.contains(taskDto),
      orElse: () {
        taskFound = false;
      },
    );

    if (!taskFound) {
      emit(
        TaskListState.error(
          message: 'No task found with Id: $taskDto.id ',
          stacktrace: StackTrace.current,
        ),
      );
      return;
    }

    final updateRequest = TaskActionRequestUpdate(
      taskToUpdate: taskDto,
      name: taskDto.name,
      completed: !taskDto.completed,
      description: taskDto.description,
    );

    try {
      await taskRepository.updateTask(updateRequest);
    } catch (error, stacktrace) {
      emit(
        TaskListState.error(
          message: error.toString(),
          stacktrace: stacktrace,
        ),
      );
    }
  }
}
