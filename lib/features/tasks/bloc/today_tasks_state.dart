part of 'today_tasks_bloc.dart';

@freezed
class TodayTasksState with _$TodayTasksState {
  const factory TodayTasksState.initial() = TodayTasksInitial;
  const factory TodayTasksState.loading() = TodayTasksLoading;
  const factory TodayTasksState.loaded({
    required List<Task> tasks,
    required int incompleteCount,
  }) = TodayTasksLoaded;
  const factory TodayTasksState.error({
    required Object error,
    required StackTrace stackTrace,
  }) = TodayTasksError;
}
