import 'package:bloc/bloc.dart';
import 'package:drift/drift.dart' hide JsonKey;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';

part 'task_detail_bloc.freezed.dart';

// Events
@freezed
sealed class TaskDetailEvent with _$TaskDetailEvent {
  const factory TaskDetailEvent.update({
    required String id,
    required String name,
    required String? description,
    required bool completed,
  }) = _TaskDetailUpdate;
  const factory TaskDetailEvent.delete({
    required String id,
  }) = _TaskDetailDelete;

  const factory TaskDetailEvent.create({
    required String name,
    required String? description,
  }) = _TaskDetailCreate;

  const factory TaskDetailEvent.get({required String taskId}) = _TaskDetailGet;
}

@freezed
abstract class TaskDetailError with _$TaskDetailError {
  const factory TaskDetailError({
    required String message,
    StackTrace? stackTrace,
  }) = _TaskDetailError;
}

// State
@freezed
class TaskDetailState with _$TaskDetailState {
  const factory TaskDetailState.initial() = TaskDetailInitial;

  const factory TaskDetailState.operationSuccess({required String message}) =
      TaskDetailOperationSuccess;
  const factory TaskDetailState.operationFailure({
    required TaskDetailError errorDetails,
  }) = TaskDetailOperationFailure;

  const factory TaskDetailState.loadInProgress() = TaskDetailLoadInProgress;
  const factory TaskDetailState.loadSuccess({
    required TaskTableData task,
  }) = TaskDetailLoadSuccess;
}

class TaskDetailBloc extends Bloc<TaskDetailEvent, TaskDetailState> {
  TaskDetailBloc({
    required TaskRepository taskRepository,
    String? taskId,
  }) : _taskRepository = taskRepository,
       super(const TaskDetailState.initial()) {
    on<TaskDetailEvent>((event, emit) async {
      await event.when(
        get: (taskId) async => _onGet(taskId, emit),
        update: (id, name, description, completed) async =>
            _onUpdate(id, name, description, completed, emit),
        delete: (id) async => _onDelete(id, emit),
        create: (name, description) async => _onCreate(name, description, emit),
      );
    });

    if (taskId != null && taskId.isNotEmpty) {
      add(TaskDetailEvent.get(taskId: taskId));
    }
  }

  final TaskRepository _taskRepository;

  Future _onGet(
    String taskId,
    Emitter<TaskDetailState> emit,
  ) async {
    emit(const TaskDetailState.loadInProgress());
    try {
      final task = await _taskRepository.getTaskById(taskId);
      if (task == null) {
        emit(
          const TaskDetailState.operationFailure(
            errorDetails: TaskDetailError(message: 'Task not found'),
          ),
        );
      } else {
        emit(TaskDetailState.loadSuccess(task: task));
      }
    } catch (error, stacktrace) {
      emit(
        TaskDetailState.operationFailure(
          errorDetails: TaskDetailError(
            message: error.toString(),
            stackTrace: stacktrace,
          ),
        ),
      );
    }
  }

  Future<void> _onUpdate(
    String id,
    String name,
    String? description,
    bool completed,
    Emitter<TaskDetailState> emit,
  ) async {
    final updateCompanion = TaskTableCompanion(
      id: Value(id),
      name: Value(name),
      description: Value(description),
      updatedAt: Value(DateTime.now()),
    );

    try {
      await _taskRepository.updateTask(updateCompanion);
      emit(
        TaskDetailState.operationSuccess(message: 'Task updated successfully.'),
      );
    } catch (error, stacktrace) {
      emit(
        TaskDetailState.operationFailure(
          errorDetails: TaskDetailError(
            message: error.toString(),
            stackTrace: stacktrace,
          ),
        ),
      );
    }
  }

  Future<void> _onDelete(
    String id,
    Emitter<TaskDetailState> emit,
  ) async {
    final deleteCompanion = TaskTableCompanion(id: Value(id));
    try {
      await _taskRepository.deleteTask(deleteCompanion);
      emit(
        const TaskDetailState.operationSuccess(
          message: 'Task deleted successfully.',
        ),
      );
    } catch (error, stacktrace) {
      emit(
        TaskDetailState.operationFailure(
          errorDetails: TaskDetailError(
            message: error.toString(),
            stackTrace: stacktrace,
          ),
        ),
      );
    }
  }

  Future<void> _onCreate(
    String name,
    String? description,
    Emitter<TaskDetailState> emit,
  ) async {
    final createCompanion = TaskTableCompanion(
      name: Value(name),
      description: Value(description),
      completed: Value(false),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    );

    try {
      await _taskRepository.createTask(createCompanion);
      emit(
        const TaskDetailState.operationSuccess(
          message: 'Task created successfully.',
        ),
      );
    } catch (error, stacktrace) {
      emit(
        TaskDetailState.operationFailure(
          errorDetails: TaskDetailError(
            message: error.toString(),
            stackTrace: stacktrace,
          ),
        ),
      );
    }
  }
}
