import 'package:taskly_bloc/domain/domain.dart';

abstract class LabelRepositoryContract {
  Stream<List<Label>> watchAll({bool withRelated = false});
  Future<List<Label>> getAll({bool withRelated = false});
  Stream<Label?> watch(String id, {bool withRelated = false});
  Future<Label?> get(String id, {bool withRelated = false});

  Future<void> create({required String name, required String color});
  Future<void> update({
    required String id,
    required String name,
    required String color,
  });
  Future<void> delete(String id);
}
