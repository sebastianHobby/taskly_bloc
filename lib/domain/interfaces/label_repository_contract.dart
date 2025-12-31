import 'package:taskly_bloc/domain/domain.dart';

abstract class LabelRepositoryContract {
  Stream<List<Label>> watchAll({bool withRelated = false});
  Future<List<Label>> getAll({bool withRelated = false});
  Stream<List<Label>> watchByType(LabelType type, {bool withRelated = false});
  Future<List<Label>> getAllByType(LabelType type, {bool withRelated = false});
  Stream<Label?> watch(String id, {bool withRelated = false});
  Future<Label?> get(String id, {bool withRelated = false});

  /// Get system label by type
  Future<Label?> getSystemLabel(SystemLabelType type);

  /// Get or create system label (ensures existence)
  Future<Label> getOrCreateSystemLabel(SystemLabelType type);

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

  /// Add a label to a task
  Future<void> addLabelToTask({
    required String taskId,
    required String labelId,
  });

  /// Remove a label from a task
  Future<void> removeLabelFromTask({
    required String taskId,
    required String labelId,
  });
}
