part of 'tasks_bloc.dart';

@freezed
class TasksEvent with _$TasksEvent {
  const factory TasksEvent.tasksSubscriptionRequested() =
      TasksSubscriptionRequested;
  const factory TasksEvent.updateTask({
    required TaskModel initialTask,
    required TaskModel updatedTask,
  }) = TasksUpdateTask;
  const factory TasksEvent.deleteTask({
    required TaskModel task,
  }) = TasksDeleteTask;
  const factory TasksEvent.createTask({
    required TaskModel task,
  }) = TasksCreateTask;
}
