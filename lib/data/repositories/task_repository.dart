// Todo make a barrel/library file with export like other data repositories
import 'package:powersync/powersync.dart';
import 'package:taskly_bloc/data/dtos/tasks/task_dto.dart';
import 'package:taskly_bloc/data/powersync/powersync.dart';
import 'package:taskly_bloc/features/tasks/bloc/task_action_request.dart';
import 'package:uuid/uuid.dart';

class TaskRepository {
  /// If [syncDb] is null, fall back to the global PowerSync [db].
  TaskRepository({PowerSyncDatabase? syncDb}) : _syncDb = syncDb ?? db;

  final _uuid = Uuid();
  final PowerSyncDatabase _syncDb;

  Stream<List<TaskDto>> getTasks() {
    return _syncDb.watch('SELECT * FROM tasks').map((resultSet) {
      return resultSet.map(TaskDto.fromJson).toList();
    });
  }

  Future<void> updateTask(
    TaskActionRequestUpdate updateRequest,
  ) async {
    // Create updated TaskDto based on provided fields and existing data
    final taskToUpdate = TaskDto(
      id: updateRequest.taskToUpdate.id,
      name: updateRequest.name ?? updateRequest.taskToUpdate.name,
      description:
          updateRequest.description ??
          updateRequest.taskToUpdate.description ??
          '',
      completed:
          updateRequest.completed ?? updateRequest.taskToUpdate.completed,
      createdAt: updateRequest.taskToUpdate.createdAt,
      updatedAt: DateTime.now(),
    );

    try {
      const String updateQuery =
          'UPDATE tasks SET name = ?, description = ?, completed = ? WHERE id = ?';
      await _syncDb.execute(updateQuery, [
        taskToUpdate.name,
        taskToUpdate.description,
        taskToUpdate.completed,
        taskToUpdate.id,
      ]);
    } catch (error) {
      rethrow;
    }
  }

  Future<void> deleteTask(TaskActionRequestDelete deleteRequest) async {
    // validate input similar to updateTask: ensure a task to delete with a valid id
    final taskToDelete = deleteRequest.taskToDelete;
    if (taskToDelete.id.isEmpty) {
      throw ArgumentError.value(
        deleteRequest,
        'deleteRequest',
        'taskToDelete must be provided and contain a valid id.',
      );
    }

    try {
      const String deleteQuery = 'DELETE FROM tasks WHERE id = ?';
      await _syncDb.execute(deleteQuery, [taskToDelete.id]);
    } catch (error) {
      rethrow;
    }
  }

  Future<void> createTask(
    TaskActionRequestCreate createRequest,
  ) async {
    try {
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
    } catch (error) {
      rethrow;
    }
  }
}
