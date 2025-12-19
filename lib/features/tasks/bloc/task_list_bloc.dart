import 'package:bloc/bloc.dart';
import 'package:drift/drift.dart' hide JsonKey;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';
part 'task_list_bloc.freezed.dart';

//Events (the input to bloc)
@freezed
sealed class TaskOverviewEvent with _$TaskOverviewEvent {
  const factory TaskOverviewEvent.subscriptionRequested() =
      TaskOverviewSubscriptionRequested;

  const factory TaskOverviewEvent.toggleTaskCompletion({
    required TaskTableData taskData,
  }) = TaskOverviewToggleTaskCompletion;
}

// State (output of bloc which UI responds to)
@freezed
sealed class TaskOverviewState with _$TaskOverviewState {
  const factory TaskOverviewState.initial() = TaskOverviewInitial;
  const factory TaskOverviewState.loading() = TaskOverviewLoading;
  const factory TaskOverviewState.loaded({
    required List<TaskTableData> tasks,
  }) = TaskOverviewLoaded;
  const factory TaskOverviewState.error({
    required String message,
    required StackTrace stacktrace,
  }) = TaskOverviewError;
}

// The bloc itself - consumed events from UI and outputs state for UI to react to
class TaskOverviewBloc extends Bloc<TaskOverviewEvent, TaskOverviewState> {
  TaskOverviewBloc({required TaskRepository taskRepository})
    : _taskRepository = taskRepository,
      super(const TaskOverviewState.initial()) {
    on<TaskOverviewSubscriptionRequested>(_onSubscriptionRequested);
    on<TaskOverviewToggleTaskCompletion>(_onToggleTaskCompletion);
  }

  final TaskRepository _taskRepository;

  Future<void> _onSubscriptionRequested(
    TaskOverviewSubscriptionRequested event,
    Emitter<TaskOverviewState> emit,
  ) async {
    emit(const TaskOverviewState.loading());

    await emit.forEach<List<TaskTableData>>(
      _taskRepository.getTasks,
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
        TaskOverviewState.error(
          message: error.toString(),
          stacktrace: stacktrace,
        ),
      );
    }
  }
}
