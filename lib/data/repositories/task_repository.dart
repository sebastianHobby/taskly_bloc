import 'package:taskly_bloc/data/drift/drift_database.dart';

class TaskRepository {
  TaskRepository({required this.driftDb});
  final AppDatabase driftDb;

  Stream<List<TaskTableData>> get getTasks =>
      driftDb.select(driftDb.taskTable).watch();

  Future<TaskTableData?> getTaskById(String id) async {
    return driftDb.managers.taskTable
        .filter((f) => f.id.equals(id))
        .getSingle();
  }

  Future<bool> updateTask(
    TaskTableCompanion updateCompanion,
  ) async {
    return driftDb.update(driftDb.taskTable).replace(updateCompanion);
  }

  Future<int> deleteTask(TaskTableCompanion deleteCompanion) async {
    return driftDb.delete(driftDb.taskTable).delete(deleteCompanion);
  }

  Future<int> createTask(TaskTableCompanion createCompanion) {
    return driftDb.into(driftDb.taskTable).insert(createCompanion);
  }
}
