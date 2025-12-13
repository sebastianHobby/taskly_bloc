// Todo make a barrel/library file with export like other data repositories
import 'package:powersync/powersync.dart';
import 'package:taskly_bloc/data/dtos/tasks/task_dto.dart';
import 'package:taskly_bloc/data/powersync/powersync.dart';
import 'package:taskly_bloc/features/tasks/models/task_models.dart';
import 'package:uuid/uuid.dart';

class TaskRepository {
  /// If [syncDb] is null, fall back to the global PowerSync [db].
  TaskRepository({PowerSyncDatabase? syncDb}) : _syncDb = syncDb ?? db;

  final _uuid = Uuid();
  final PowerSyncDatabase _syncDb;

  Stream<List<TaskDto>> getTasks() {
    // Note this returns generated Task class created by drift
    // Future<List<Task>> results = driftDb.managers.tasks.get();
    return _syncDb.watch('SELECT * FROM tasks').map((resultSet) {
      return resultSet.map(TaskDto.fromJson).toList();
    });
  }

  Future<void> updateTask(
    TaskUpdateRequest updateRequest,
  ) async {
    const String updateQuery =
        'UPDATE tasks SET name = ?, description = ?, completed = ? WHERE id = ?';

    await _syncDb.execute(updateQuery, [
      updateRequest.name,
      updateRequest.description ?? '',
      updateRequest.completed ?? false,
      updateRequest.id,
    ]);
  }

  Future<void> deleteTask(
    TaskDeleteRequest deleteRequest,
  ) async {
    const String deleteQuery = 'DELETE FROM tasks WHERE id = ?';
    await _syncDb.execute(deleteQuery, [deleteRequest.id]);
  }

  Future<void> createTask(
    TaskCreateRequest createRequest,
  ) async {
    const String insertQuery =
        'INSERT INTO tasks (id, name, description, completed,created_at,updated_at) VALUES (?, ?, ?, ?, ?, ?)';

    await _syncDb.execute(insertQuery, [
      _uuid.v4(),
      createRequest.name,
      createRequest.description ?? '',
      createRequest.completed ?? false,
      DateTime.now().toIso8601String(),
      DateTime.now().toIso8601String(),
    ]);
  }
}
