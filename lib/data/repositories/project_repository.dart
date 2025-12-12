// Todo make a barrel/library file with export like other data repositories
import 'package:powersync/powersync.dart';
import 'package:taskly_bloc/data/models/projects/project_model.dart';
import 'package:taskly_bloc/data/powersync/powersync.dart';

class ProjectRepository {
  /// If [syncDb] is null, fall back to the global PowerSync [db].
  ProjectRepository({PowerSyncDatabase? syncDb}) : _syncDb = syncDb ?? db;

  final PowerSyncDatabase _syncDb;

  Stream<List<ProjectModel>> getProjects() {
    // Note this returns generated Project class created by drift
    // Future<List<Project>> results = driftDb.managers.projects.get();
    return _syncDb.watch('SELECT * FROM projects').map((resultSet) {
      return resultSet.map(ProjectModel.fromJson).toList();
    });
  }

  Future<void> updateProject(
    ProjectModel initialProject,
    ProjectModel updatedProject,
  ) async {
    const String updateQuery =
        'UPDATE projects SET name = ?, description = ?, completed = ? WHERE id = ?';

    await _syncDb.execute(updateQuery, [
      updatedProject.name,
      updatedProject.description,
      if (updatedProject.completed) 1 else 0,
      initialProject.id,
    ]);
  }

  Future<void> deleteProject(
    ProjectModel project,
  ) async {
    const String deleteQuery = 'DELETE FROM projects WHERE id = ?';
    await _syncDb.execute(deleteQuery, [project.id]);
  }

  Future<void> createProject(
    ProjectModel project,
  ) async {
    const String insertQuery =
        'INSERT INTO projects (id, name, description, completed) VALUES (?, ?, ?, ?)';
    await _syncDb.execute(insertQuery, [
      project.id,
      project.name,
      project.description,
      if (project.completed) 1 else 0,
    ]);
  }
}
