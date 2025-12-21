import 'package:taskly_bloc/domain/domain.dart';

abstract class ProjectRepositoryContract {
  Stream<List<Project>> watchAll({bool withRelated = false});
  Future<List<Project>> getAll({bool withRelated = false});
  Stream<Project?> watch(String id, {bool withRelated = false});
  Future<Project?> get(String id, {bool withRelated = false});

  Future<void> create({
    required String name,
    String? description,
    bool completed = false,
    DateTime? startDate,
    DateTime? deadlineDate,
    String? repeatIcalRrule,
    List<String>? valueIds,
    List<String>? labelIds,
  });
  Future<void> update({
    required String id,
    required String name,
    required bool completed,
    String? description,
    DateTime? startDate,
    DateTime? deadlineDate,
    String? repeatIcalRrule,
    List<String>? valueIds,
    List<String>? labelIds,
  });
  Future<void> delete(String id);
}
