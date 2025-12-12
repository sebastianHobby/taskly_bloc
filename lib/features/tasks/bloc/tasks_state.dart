part of 'tasks_bloc.dart';

@freezed
sealed class TasksState with _$TasksState {
  const factory TasksState.initial() = TasksInitial;
  const factory TasksState.loading() = TasksLoading;
  const factory TasksState.loaded({
    required List<TaskModel> tasks,
  }) = TasksLoaded;
  const factory TasksState.error({required String message}) = TasksError;


}
