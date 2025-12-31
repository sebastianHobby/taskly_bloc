import 'package:drift/drift.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';

/// Mixin providing shared query building capabilities for repositories.
///
/// Provides common functionality for:
/// - Converting QueryFilter to SQL expressions
/// - Date calculations for relative date predicates
mixin QueryBuilderMixin {
  /// Calculates an absolute date from relative days offset.
  ///
  /// A positive [days] value means days in the future,
  /// a negative value means days in the past.
  DateTime relativeToAbsolute(int days) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(Duration(days: days));
  }

  /// Converts a [QueryFilter] to a Drift WHERE expression.
  ///
  /// Returns null if the filter matches all items (no filtering needed).
  /// Uses [predicateToExpression] to convert individual predicates.
  Expression<bool>? whereExpressionFromDnf<P>({
    required QueryFilter<P> filter,
    required Expression<bool> Function(P predicate) predicateToExpression,
  }) {
    final terms = filter.toDnfTerms();
    if (terms.isEmpty) return null;

    Expression<bool> andTerm(List<P> predicates) {
      if (predicates.isEmpty) return const Constant(true);
      return predicates.map(predicateToExpression).reduce((a, b) => a & b);
    }

    final exprs = terms.map(andTerm).toList(growable: false);
    return exprs.reduce((a, b) => a | b);
  }

  /// Converts a [QueryFilter] to a Drift WHERE expression.
  ///
  /// Alternative implementation that handles shared predicates separately
  /// from OR groups for cases where that distinction matters.
  Expression<bool>? whereExpressionFromFilter<P>({
    required QueryFilter<P> filter,
    required Expression<bool> Function(P predicate) predicateToExpression,
  }) {
    if (filter.isMatchAll) return null;

    Expression<bool> sharedExpr;
    if (filter.shared.isEmpty) {
      sharedExpr = const Constant(true);
    } else {
      final expressions = filter.shared
          .map(predicateToExpression)
          .toList(growable: false);
      sharedExpr = expressions.reduce((a, b) => a & b);
    }

    if (filter.orGroups.isEmpty) return sharedExpr;

    final orExprs = filter.orGroups
        .map((group) {
          if (group.isEmpty) return const Constant(true);
          final groupExprs = group
              .map(predicateToExpression)
              .toList(growable: false);
          return groupExprs.reduce((a, b) => a & b);
        })
        .toList(growable: false);

    final orExpr = orExprs.reduce((a, b) => a | b);
    return sharedExpr & orExpr;
  }
}
