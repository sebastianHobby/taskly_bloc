import 'package:taskly_bloc/domain/domain.dart';

abstract class ValueRepositoryContract {
  Stream<List<ValueModel>> watchAll({bool withRelated = false});
  Future<List<ValueModel>> getAll({bool withRelated = false});
  Stream<ValueModel?> watch(String id, {bool withRelated = false});
  Future<ValueModel?> get(String id, {bool withRelated = false});

  Future<void> create({required String name});
  Future<void> update({required String id, required String name});
  Future<void> delete(String id);
}
