import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';
import 'package:taskly_bloc/features/tasks/bloc/task_action_request.dart';
part 'task_detail_bloc.freezed.dart';

//Events (the input to bloc)
@freezed
sealed class TaskDetailEvent with _$TaskDetailEvent {
  const factory TaskDetailEvent.updateTask({
    required TaskActionRequestUpdate updateRequest,
  }) = _TaskDetailUpdate;

  const factory TaskDetailEvent.deleteTask({
    required TaskActionRequestDelete deleteRequest,
  }) = _TaskDetailDelete;

  const factory TaskDetailEvent.createTask({
    required TaskActionRequestCreate createRequest,
  }) = _TaskDetailCreate;
}

// State (output of bloc which UI responds to)
@freezed
sealed class TaskDetailState with _$TaskDetailState {
  const factory TaskDetailState.initial() = _TaskDetailInitial;
  const factory TaskDetailState.error({
    required String message,
    required StackTrace stacktrace,
  }) = _TaskDetailError;
}

class TaskDetailBloc extends Bloc<TaskDetailEvent, TaskDetailState> {
  TaskDetailBloc({
    required TaskRepository taskRepository,
  }) : _taskRepository = taskRepository,
       super(TaskDetailState.initial()) {
    // use `when` to map union cases to handlers
    on<TaskDetailEvent>((event, emit) async {
      await event.when(
        updateTask: (updateRequest) async => _onUpdate(updateRequest, emit),
        deleteTask: (deleteRequest) async => _onDelete(deleteRequest, emit),
        createTask: (createRequest) async => _onCreate(createRequest, emit),
      );
    });
  }

  final TaskRepository _taskRepository;

  Future<void> _onUpdate(
    TaskActionRequestUpdate updateRequest,
    Emitter<TaskDetailState> emit,
  ) async {
    try {
      await _taskRepository.updateTask(updateRequest);
    } catch (error, stacktrace) {
      emit(
        TaskDetailState.error(
          message: error.toString(),
          stacktrace: stacktrace,
        ),
      );
    }
  }

  Future<void> _onDelete(
    TaskActionRequestDelete deleteRequest,
    Emitter<TaskDetailState> emit,
  ) async {
    try {
      await _taskRepository.deleteTask(deleteRequest);
    } catch (error, stacktrace) {
      emit(
        TaskDetailState.error(
          message: error.toString(),
          stacktrace: stacktrace,
        ),
      );
    }
  }

  Future<void> _onCreate(
    TaskActionRequestCreate createRequest,
    Emitter<TaskDetailState> emit,
  ) async {
    try {
      await _taskRepository.createTask(createRequest);
    } catch (error, stacktrace) {
      emit(
        TaskDetailState.error(
          message: error.toString(),
          stacktrace: stacktrace,
        ),
      );
    }
  }
}
