import 'package:taskly_domain/src/queries/task_predicate.dart'
    show BoolOperator;

/// Type-based boolean comparison logic.
///
/// All boolean comparisons across all entities use this single implementation.
sealed class BoolComparison {
  const BoolComparison._();

  /// Evaluates a boolean comparison in memory.
  static bool evaluate({
    required bool fieldValue,
    required BoolOperator operator,
  }) {
    return switch (operator) {
      BoolOperator.isTrue => fieldValue,
      BoolOperator.isFalse => !fieldValue,
    };
  }
}
