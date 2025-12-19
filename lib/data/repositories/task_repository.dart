import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/repository_exceptions.dart';

class TaskRepository {
  TaskRepository({required this.driftDb});
  final AppDatabase driftDb;

  Stream<List<TaskTableData>> get getTasks =>
      driftDb.select(driftDb.taskTable).watch();

  Future<TaskTableData?> getTaskById(String id) async {
    return driftDb.managers.taskTable
        .filter((f) => f.id.equals(id))
        .getSingleOrNull();
  }

  Future<bool> updateTask(
    TaskTableCompanion updateCompanion,
  ) async {
    final bool success = await driftDb
        .update(driftDb.taskTable)
        .replace(updateCompanion);
    if (!success) {
      throw RepositoryNotFoundException('No task found to update');
    }
    return success;
  }

  Future<int> deleteTask(TaskTableCompanion deleteCompanion) async {
    return driftDb.delete(driftDb.taskTable).delete(deleteCompanion);
  }

  Future<int> createTask(TaskTableCompanion createCompanion) {
    return driftDb.into(driftDb.taskTable).insert(createCompanion);
  }
}
