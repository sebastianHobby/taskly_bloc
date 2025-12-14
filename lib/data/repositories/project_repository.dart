// Todo make a barrel/library file with export like other data repositories
import 'package:powersync/powersync.dart';
import 'package:taskly_bloc/data/dtos/projects/project_dto.dart';
import 'package:taskly_bloc/data/powersync/powersync.dart';
import 'package:taskly_bloc/features/projects/models/project_models.dart';
import 'package:uuid/uuid.dart';

class ProjectRepository {
  /// If [syncDb] is null, fall back to the global PowerSync [db].
  ProjectRepository({PowerSyncDatabase? syncDb}) : _syncDb = syncDb ?? db;

  final _uuid = Uuid();
  final PowerSyncDatabase _syncDb;

  /// Stream of all projects in the database. Live updates.
  Stream<List<ProjectDto>> getProjects() {
    return _syncDb.watch('SELECT * FROM  projects').map((resultSet) {
      return resultSet.map(ProjectDto.fromJson).toList();
    });
  }

  Future<ProjectDto?> getProjectById(String id) async {
    final resultSet = await _syncDb.execute(
      'SELECT * FROM  projects WHERE id = ?',
      [id],
    );
    if (resultSet.isEmpty) {
      return null;
    }
    return ProjectDto.fromJson(resultSet.first);
  }

  Future<void> updateProject(
    ProjectActionRequestUpdate updateRequest,
  ) async {
    // Ensure the project exists first
    final existing = await getProjectById(updateRequest.projectToUpdate.id);
    if (existing == null) {
      throw StateError(
        'Project not found: ${updateRequest.projectToUpdate.id}',
      );
    }
    // Create updated  projectDto based on provided fields and existing data
    // Note: only fields provided in updateRequest will be changed
    final projectToUpdate = existing.copyWith(
      name: updateRequest.name ?? existing.name,
      description: updateRequest.description ?? existing.description,
      completed: updateRequest.completed ?? existing.completed,
      updatedAt: DateTime.now(),
    );

    try {
      const String updateQuery =
          'UPDATE  projects SET name = ?, description = ?, completed = ? WHERE id = ?';
      await _syncDb.execute(updateQuery, [
        projectToUpdate.name,
        projectToUpdate.description,
        projectToUpdate.completed,
        projectToUpdate.id,
      ]);
    } catch (error) {
      rethrow;
    }
  }

  Future<void> deleteProject(ProjectActionRequestDelete deleteRequest) async {
    // validate input similar to update project: ensure a  project to delete with a valid id
    final existing = await getProjectById(deleteRequest.projectToDelete.id);
    if (existing == null) {
      throw StateError(
        'Project not found: ${deleteRequest.projectToDelete.id}',
      );
    }

    try {
      const String deleteQuery = 'DELETE FROM  projects WHERE id = ?';
      await _syncDb.execute(deleteQuery, [existing.id]);
    } catch (error) {
      rethrow;
    }
  }

  Future<void> createProject(
    ProjectActionRequestCreate createRequest,
  ) async {
    try {
      const String insertQuery =
          'INSERT INTO  projects (id, name, description, completed,created_at,updated_at) VALUES (?, ?, ?, ?, ?, ?)';
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
