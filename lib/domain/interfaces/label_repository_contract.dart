import 'package:taskly_bloc/domain/domain.dart';

abstract class LabelRepositoryContract {
  Stream<List<Label>> watchAll();
  Future<List<Label>> getAll();
  Stream<List<Label>> watchByType(LabelType type);
  Future<List<Label>> getAllByType(LabelType type);
  Stream<Label?> watchById(String id);
  Future<Label?> getById(String id);

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

  /// Update the lastReviewedAt timestamp for a label/value.
  /// Used by workflow completion to track when entities were last reviewed.
  Future<void> updateLastReviewedAt({
    required String id,
    required DateTime reviewedAt,
  });

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
