import 'package:taskly_bloc/domain/domain.dart';

abstract class TaskRepositoryContract {
  Stream<List<Task>> watchAll({bool withRelated = false});
  Future<List<Task>> getAll({bool withRelated = false});
  Stream<Task?> watch(String id, {bool withRelated = false});
  Future<Task?> get(String id, {bool withRelated = false});

  /// Watch task counts for all projects.
  /// Returns a stream of maps where keys are project IDs.
  Stream<Map<String, ProjectTaskCounts>> watchTaskCountsByProject();

  /// Get task counts for all projects.
  /// Returns a map where keys are project IDs.
  Future<Map<String, ProjectTaskCounts>> getTaskCountsByProject();

  Future<void> create({
    required String name,
    String? description,
    bool completed = false,
    DateTime? startDate,
    DateTime? deadlineDate,
    String? projectId,
    String? repeatIcalRrule,
    List<String>? labelIds,
  });

  Future<void> update({
    required String id,
    required String name,
    required bool completed,
    String? description,
    DateTime? startDate,
    DateTime? deadlineDate,
    String? projectId,
    String? repeatIcalRrule,
    List<String>? labelIds,
  });

  Future<void> delete(String id);
}
