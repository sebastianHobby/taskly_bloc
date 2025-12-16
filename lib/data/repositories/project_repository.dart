import 'package:taskly_bloc/data/drift/drift_database.dart';

class ProjectRepository {
  ProjectRepository({required this.driftDb});
  final AppDatabase driftDb;

  Stream<List<ProjectTableData>> get getProjects =>
      driftDb.select(driftDb.projectTable).watch();

  Future<ProjectTableData?> getProjectById(String id) async {
    return driftDb.managers.projectTable
        .filter((f) => f.id.equals(id))
        .getSingle();
  }

  Future<int> updateProject(
    ProjectTableCompanion updateCompanion,
  ) {
    // Ensure the project exists first
    return driftDb.update(driftDb.projectTable).write(updateCompanion);
  }

  Future<int> deleteProject(ProjectTableCompanion deleteCompanion) async {
    // validate input similar to update project: ensure a  project to delete with a valid id
    return driftDb.delete(driftDb.projectTable).delete(deleteCompanion);
  }

  Future<int> createProject(
    ProjectTableCompanion createCompanion,
  ) {
    return driftDb.into(driftDb.projectTable).insert(createCompanion);
  }
}
