part of 'tasks_bloc.dart';

@freezed
class TasksEvent with _$TasksEvent {
  const factory TasksEvent.tasksSubscriptionRequested() =
      TasksSubscriptionRequested;
  const factory TasksEvent.updateTask({
    required TaskUpdateRequest updateRequest,
  }) = TasksUpdateTask;
  const factory TasksEvent.deleteTask({
    required TaskDeleteRequest deleteRequest,
  }) = TasksDeleteTask;
  const factory TasksEvent.createTask({
    required TaskCreateRequest createRequest,
  }) = TasksCreateTask;
}
