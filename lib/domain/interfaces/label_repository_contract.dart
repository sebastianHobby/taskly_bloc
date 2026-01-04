import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/queries/label_query.dart';

abstract class LabelRepositoryContract {
  /// Watch labels with optional filtering.
  ///
  /// If [query] is null, returns all labels.
  Stream<List<Label>> watchAll([LabelQuery? query]);

  /// Get labels with optional filtering.
  ///
  /// If [query] is null, returns all labels.
  Future<List<Label>> getAll([LabelQuery? query]);

  Stream<List<Label>> watchByType(LabelType type);
  Future<List<Label>> getAllByType(LabelType type);
  Stream<Label?> watchById(String id);
  Future<Label?> getById(String id);

  /// Get labels by IDs.
  Future<List<Label>> getLabelsByIds(List<String> ids);

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
