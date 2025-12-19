import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/repository_exceptions.dart';

class ProjectRepository {
  ProjectRepository({required this.driftDb});
  final AppDatabase driftDb;

  Stream<List<ProjectTableData>> get getProjects =>
      driftDb.select(driftDb.projectTable).watch();

  Future<ProjectTableData?> getProjectById(String id) async {
    return driftDb.managers.projectTable
        .filter((f) => f.id.equals(id))
        .getSingleOrNull();
  }

  Future<bool> updateProject(
    ProjectTableCompanion updateCompanion,
  ) async {
    final bool success = await driftDb
        .update(driftDb.projectTable)
        .replace(updateCompanion);
    if (!success) {
      throw RepositoryNotFoundException('No project found to update');
    }
    return success;
  }

  Future<int> deleteProject(ProjectTableCompanion deleteCompanion) async {
    return driftDb.delete(driftDb.projectTable).delete(deleteCompanion);
  }

  Future<int> createProject(
    ProjectTableCompanion createCompanion,
  ) {
    return driftDb.into(driftDb.projectTable).insert(createCompanion);
  }
}
