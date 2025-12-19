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
        .getSingle();
  }

  Future<int> updateTask(
    TaskTableCompanion updateCompanion,
  ) async {
    final int impactedRowCnt = await driftDb
        .update(driftDb.taskTable)
        .write(updateCompanion);
    if (impactedRowCnt == 0) {
      throw RepositoryNotFoundException('No task found to update');
    }
    return impactedRowCnt;
  }

  Future<int> deleteTask(TaskTableCompanion deleteCompanion) async {
    return driftDb.delete(driftDb.taskTable).delete(deleteCompanion);
  }

  Future<int> createTask(TaskTableCompanion createCompanion) {
    return driftDb.into(driftDb.taskTable).insert(createCompanion);
  }
}
