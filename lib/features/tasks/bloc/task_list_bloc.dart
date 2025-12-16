// ...existing code...
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:drift/drift.dart' hide JsonKey;
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';
part 'task_list_bloc.freezed.dart';

//Events (the input to bloc)
@freezed
sealed class TaskListEvent with _$TaskListEvent {
  const factory TaskListEvent.subscriptionRequested() =
      TaskListSubscriptionRequested;

  const factory TaskListEvent.toggleTaskCompletion({
    required TaskTableData taskData,
  }) = TaskListToggleTaskCompletion;
}

// State (output of bloc which UI responds to)
@freezed
sealed class TaskListState with _$TaskListState {
  const factory TaskListState.initial() = _TaskListInitial;
  const factory TaskListState.loading() = _TaskListLoading;
  const factory TaskListState.loaded({
    required List<TaskTableData> tasks,
  }) = _TaskListLoaded;
  const factory TaskListState.error({
    required String message,
    required StackTrace stacktrace,
  }) = _TaskListError;
}

// The bloc itself - consumed events from UI and outputs state for UI to react to
class TaskListBloc extends Bloc<TaskListEvent, TaskListState> {
  TaskListBloc({required TaskRepository taskRepository})
    : _taskRepository = taskRepository,
      super(const TaskListState.initial()) {
    on<TaskListSubscriptionRequested>(_onSubscriptionRequested);
    on<TaskListToggleTaskCompletion>(_onToggleTaskCompletion);
  }

  final TaskRepository _taskRepository;

  Future<void> _onSubscriptionRequested(
    TaskListSubscriptionRequested event,
    Emitter<TaskListState> emit,
  ) async {
    emit(const TaskListState.loading());

    await emit.forEach<List<TaskTableData>>(
      _taskRepository.getTasks,
      onData: (tasks) => TaskListState.loaded(tasks: tasks),
      onError: (error, stackTrace) => TaskListState.error(
        message: error.toString(),
        stacktrace: stackTrace,
      ),
    );
  }

  Future<void> _onToggleTaskCompletion(
    TaskListToggleTaskCompletion event,
    Emitter<TaskListState> emit,
  ) async {
    final taskData = event.taskData;

    // Build companion from the existing row and flip completed
    TaskTableCompanion updateCompanion = taskData.toCompanion(true);
    updateCompanion = updateCompanion.copyWith(
      completed: Value(!taskData.completed),
      updatedAt: Value(DateTime.now()),
    );

    try {
      await _taskRepository.updateTask(updateCompanion);
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
