import 'package:taskly_bloc/domain/domain.dart';

abstract class ProjectRepositoryContract {
  Stream<List<Project>> watchAll({bool withRelated = false});
  Future<List<Project>> getAll({bool withRelated = false});
  Stream<Project?> watch(String id, {bool withRelated = false});
  Future<Project?> get(String id, {bool withRelated = false});

  Future<void> create({
    required String name,
    bool completed = false,
    List<String>? valueIds,
    List<String>? labelIds,
  });
  Future<void> update({
    required String id,
    required String name,
    required bool completed,
    List<String>? valueIds,
    List<String>? labelIds,
  });
  Future<void> delete(String id);
}
