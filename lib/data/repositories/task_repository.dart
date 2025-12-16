import 'package:taskly_bloc/data/drift/drift_database.dart';

class TaskRepository {
  TaskRepository({required this.driftDb});
  final AppDatabase driftDb;

  Stream<List<TaskTableData>> get getTasks =>
      driftDb.select(driftDb.taskTable).watch();

  Future<TaskTableData?> getTaskById(String id) {
    return (driftDb.select(
      driftDb.taskTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> updateTask(TaskTableCompanion updateCompanion) {
    return driftDb.update(driftDb.taskTable).write(updateCompanion);
  }

  Future<int> deleteTask(TaskTableCompanion deleteCompanion) async {
    return driftDb.delete(driftDb.taskTable).delete(deleteCompanion);
  }

  Future<int> createTask(TaskTableCompanion createCompanion) {
    return driftDb.into(driftDb.taskTable).insert(createCompanion);
  }
}
