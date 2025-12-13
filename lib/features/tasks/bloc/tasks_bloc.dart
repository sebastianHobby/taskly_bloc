import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/data/dtos/tasks/task_dto.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';
import 'package:taskly_bloc/features/tasks/models/task_models.dart';

part 'tasks_event.dart';
part 'tasks_state.dart';
part 'tasks_bloc.freezed.dart';

class TasksBloc extends Bloc<TasksEvent, TasksState> {
  TasksBloc({required TaskRepository taskRepository})
    : _taskRepository = taskRepository,
      super(const TasksInitial()) {
    on<TasksSubscriptionRequested>(onSubscriptionRequested);
    on<TasksUpdateTask>(onTaskUpdate);
    on<TasksDeleteTask>(onTaskDelete);
    on<TasksCreateTask>(onTaskCreate);
  }

  final TaskRepository _taskRepository;

  Future<void> onSubscriptionRequested(
    TasksSubscriptionRequested event,
    Emitter<TasksState> emit,
  ) async {
    // // Send state indicating loading is in progress for UI
    emit(const TasksLoading());

    // For each TaskModel we receive in the stream emit the data loaded
    // state so UI can update or error state if there is an error
    await emit.forEach<List<TaskDto>>(
      _taskRepository.getTasks(),
      onData: (tasks) => TasksLoaded(tasks: tasks),
      onError: (error, stackTrace) =>
          const TasksError(message: 'todo error handling'),
    );
  }

  Future<void> onTaskUpdate(
    TasksUpdateTask event,
    Emitter<TasksState> emit,
  ) async {
    _taskRepository.updateTask(event.updateRequest);
    // No need to call refresh as the stream subscription will handle it
  }

  Future<void> onTaskDelete(
    TasksDeleteTask event,
    Emitter<TasksState> emit,
  ) async {
    _taskRepository.deleteTask(event.deleteRequest);
    // No need to call refresh as the stream subscription will handle it
  }

  Future<void> onTaskCreate(
    TasksCreateTask event,
    Emitter<TasksState> emit,
  ) async {
    _taskRepository.createTask(event.createRequest);
    // No need to call refresh as the stream subscription will handle it
  }
}
