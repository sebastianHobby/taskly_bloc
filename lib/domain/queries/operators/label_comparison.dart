import 'package:taskly_bloc/domain/queries/task_predicate.dart'
    show LabelOperator;

/// Type-based label set comparison logic.
///
/// All label comparisons across all entities use this single implementation.
sealed class LabelComparison {
  const LabelComparison._();

  /// Evaluates label membership comparisons in memory.
  ///
  /// [entityLabelIds] - the IDs of labels attached to the entity
  /// [predicateLabelIds] - the IDs specified in the predicate
  static bool evaluate({
    required Set<String> entityLabelIds,
    required List<String> predicateLabelIds,
    required LabelOperator operator,
  }) {
    return switch (operator) {
      LabelOperator.hasAny => predicateLabelIds.any(entityLabelIds.contains),
      LabelOperator.hasAll => predicateLabelIds.every(entityLabelIds.contains),
      LabelOperator.isNull => entityLabelIds.isEmpty,
      LabelOperator.isNotNull => entityLabelIds.isNotEmpty,
    };
  }
}
