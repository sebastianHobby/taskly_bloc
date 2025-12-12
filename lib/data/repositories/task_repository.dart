// Todo make a barrel/library file with export like other data repositories
import 'package:powersync/powersync.dart';
import 'package:taskly_bloc/data/models/tasks/task_model.dart';
import 'package:taskly_bloc/data/powersync/powersync.dart';

class TaskRepository {
  /// If [syncDb] is null, fall back to the global PowerSync [db].
  TaskRepository({PowerSyncDatabase? syncDb}) : _syncDb = syncDb ?? db;

  final PowerSyncDatabase _syncDb;

  Stream<List<TaskModel>> getTasks() {
    // Note this returns generated Task class created by drift
    // Future<List<Task>> results = driftDb.managers.tasks.get();
    return _syncDb.watch('SELECT * FROM tasks').map((resultSet) {
      return resultSet.map(TaskModel.fromJson).toList();
    });
  }

  Future<void> updateTask(
    TaskModel initialTask,
    TaskModel updatedTask,
  ) async {
    // todo add task fields not in project model
    const String updateQuery =
        'UPDATE tasks SET name = ?, description = ?, completed = ? WHERE id = ?';

    await _syncDb.execute(updateQuery, [
      updatedTask.name,
      updatedTask.description,
      if (updatedTask.completed) 1 else 0,
      initialTask.id,
    ]);
  }

  Future<void> deleteTask(
    TaskModel task,
  ) async {
    const String deleteQuery = 'DELETE FROM tasks WHERE id = ?';
    await _syncDb.execute(deleteQuery, [task.id]);
  }

  Future<void> createTask(
    TaskModel task,
  ) async {
    // todo add task fields not in project model

    const String insertQuery =
        'INSERT INTO tasks (id, name, description, completed) VALUES (?, ?, ?, ?)';
    await _syncDb.execute(insertQuery, [
      task.id,
      task.name,
      task.description,
      if (task.completed) 1 else 0,
    ]);
  }
}
