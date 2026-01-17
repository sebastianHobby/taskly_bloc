import '../task_predicate.dart'
    show ValueOperator;

/// Type-based value set comparison logic.
///
/// All value comparisons across all entities use this single implementation.
sealed class ValueComparison {
  const ValueComparison._();

  /// Evaluates value membership comparisons in memory.
  ///
  /// [entityValueIds] - the IDs of values attached to the entity
  /// [predicateValueIds] - the IDs specified in the predicate
  static bool evaluate({
    required Set<String> entityValueIds,
    required List<String> predicateValueIds,
    required ValueOperator operator,
  }) {
    return switch (operator) {
      ValueOperator.hasAny => predicateValueIds.any(entityValueIds.contains),
      ValueOperator.hasAll => predicateValueIds.every(entityValueIds.contains),
      ValueOperator.isNull => entityValueIds.isEmpty,
      ValueOperator.isNotNull => entityValueIds.isNotEmpty,
    };
  }
}
