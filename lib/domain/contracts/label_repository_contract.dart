import 'package:taskly_bloc/domain/domain.dart';

abstract class LabelRepositoryContract {
  Stream<List<Label>> watchAll({bool withRelated = false});
  Future<List<Label>> getAll({bool withRelated = false});
  Stream<List<Label>> watchByType(LabelType type, {bool withRelated = false});
  Future<List<Label>> getAllByType(LabelType type, {bool withRelated = false});
  Stream<Label?> watch(String id, {bool withRelated = false});
  Future<Label?> get(String id, {bool withRelated = false});

  Future<void> create({
    required String name,
    required String color,
    required LabelType type,
    String? iconName,
  });
  Future<void> update({
    required String id,
    required String name,
    required String color,
    required LabelType type,
    String? iconName,
  });
  Future<void> delete(String id);
}
