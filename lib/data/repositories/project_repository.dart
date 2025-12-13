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

  Stream<List<ProjectDto>> getProjects() {
    // Note this returns generated Project class created by drift
    // Future<List<Project>> results = driftDb.managers.projects.get();
    return _syncDb.watch('SELECT * FROM projects').map((resultSet) {
      return resultSet.map(ProjectDto.fromJson).toList();
    });
  }

  Future<void> updateProject(
    ProjectUpdateRequest updateRequest,
  ) async {
    const String updateQuery =
        'UPDATE projects SET name = ?, description = ?, completed = ? WHERE id = ?';

    await _syncDb.execute(updateQuery, [
      updateRequest.name,
      updateRequest.description ?? '',
      updateRequest.completed,
      updateRequest.id,
    ]);
  }

  Future<void> deleteProject(
    ProjectDeleteRequest deleteRequest,
  ) async {
    const String deleteQuery = 'DELETE FROM projects WHERE id = ?';
    await _syncDb.execute(deleteQuery, [deleteRequest.id]);
  }

  Future<void> createProject(
    ProjectCreateRequest createRequest,
  ) async {
    const String insertQuery =
        'INSERT INTO projects (id, name, description, completed) VALUES (?, ?, ?, ?)';

    await _syncDb.execute(insertQuery, [
      _uuid.v4(),
      createRequest.name,
      createRequest.description ?? '',
      createRequest.completed ?? false,
    ]);
  }
}
