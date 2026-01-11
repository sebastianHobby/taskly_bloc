import 'package:drift/drift.dart';
import 'package:taskly_bloc/domain/time/date_only.dart';
import 'package:taskly_bloc/domain/queries/operators/operators.dart'
    show BoolComparison, DateComparison;
import 'package:taskly_bloc/domain/queries/task_predicate.dart'
    show BoolOperator, DateOperator, RelativeComparison;

/// Shared SQL comparison builders for use across entity predicate mappers.
///
/// This class provides type-based comparison logic for Drift SQL expressions.
/// Using these shared builders ensures parity between Task, Project, and any
/// future entity types.
///
/// The comparison semantics here must match [DateComparison], [BoolComparison],
/// and [LabelComparison] in the domain layer for SQL/in-memory parity.
class SqlComparisonBuilder {
  const SqlComparisonBuilder._();

  // ===========================================================================
  // BOOL COMPARISON
  // ===========================================================================

  /// Builds a SQL expression for boolean comparison.
  static Expression<bool> boolComparison(
    Expression<bool> column,
    BoolOperator operator,
  ) {
    return switch (operator) {
      BoolOperator.isTrue => column.equals(true),
      BoolOperator.isFalse => column.equals(false),
    };
  }

  // ===========================================================================
  // DATETIME COLUMN COMPARISON
  // ===========================================================================

  /// Builds a SQL expression for DateTime column comparison.
  ///
  /// Used for native DateTime columns like createdAt, updatedAt.
  static Expression<bool> dateTimeComparison(
    Expression<DateTime> column,
    DateOperator operator, {
    DateTime? date,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return switch (operator) {
      DateOperator.on => column.equals(date!),
      DateOperator.before => column.isSmallerThanValue(date!),
      DateOperator.after => column.isBiggerThanValue(date!),
      DateOperator.onOrBefore => column.isSmallerOrEqualValue(date!),
      DateOperator.onOrAfter => column.isBiggerOrEqualValue(date!),
      DateOperator.between => column.isBetweenValues(startDate!, endDate!),
      DateOperator.isNull => column.isNull(),
      DateOperator.isNotNull => column.isNotNull(),
      DateOperator.relative => const Constant(false), // Use relativeDateTime
    };
  }

  /// Builds a SQL expression for relative DateTime comparison.
  ///
  /// Note: This does NOT include a NULL check. The caller is responsible
  /// for adding a NULL check if needed for parity with in-memory semantics.
  static Expression<bool> relativeDateTimeComparison(
    Expression<DateTime> column,
    RelativeComparison comparison,
    DateTime pivot,
  ) {
    return switch (comparison) {
      RelativeComparison.on => column.equals(pivot),
      RelativeComparison.before => column.isSmallerThanValue(pivot),
      RelativeComparison.after => column.isBiggerThanValue(pivot),
      RelativeComparison.onOrAfter => column.isBiggerOrEqualValue(pivot),
      RelativeComparison.onOrBefore => column.isSmallerOrEqualValue(pivot),
    };
  }

  // ===========================================================================
  // TEXT DATE COLUMN COMPARISON (YYYY-MM-DD strings)
  // ===========================================================================

  /// Builds a SQL expression for text-based date column comparison.
  ///
  /// Used for YYYY-MM-DD string columns like startDate, deadlineDate.
  /// String comparison works correctly because dates are in ISO format.
  static Expression<bool> textDateComparison(
    Expression<String> column,
    DateOperator operator, {
    String? date,
    String? startDate,
    String? endDate,
  }) {
    return switch (operator) {
      DateOperator.on => column.equals(date!),
      DateOperator.before => column.isSmallerThan(Variable<String>(date)),
      DateOperator.after => column.isBiggerThan(Variable<String>(date)),
      DateOperator.onOrBefore => column.isSmallerOrEqual(
        Variable<String>(date),
      ),
      DateOperator.onOrAfter => column.isBiggerOrEqual(Variable<String>(date)),
      DateOperator.between => column.isBetween(
        Variable<String>(startDate),
        Variable<String>(endDate),
      ),
      DateOperator.isNull => column.isNull(),
      DateOperator.isNotNull => column.isNotNull(),
      DateOperator.relative => const Constant(false), // Use relativeTextDate
    };
  }

  /// Builds a SQL expression for relative text date comparison.
  ///
  /// Note: This does NOT include a NULL check. The caller is responsible
  /// for adding a NULL check if needed for parity with in-memory semantics.
  static Expression<bool> relativeTextDateComparison(
    Expression<String> column,
    RelativeComparison comparison,
    String pivot,
  ) {
    final pivotExpr = Variable<String>(pivot);
    return switch (comparison) {
      RelativeComparison.on => column.equals(pivot),
      RelativeComparison.before => column.isSmallerThan(pivotExpr),
      RelativeComparison.after => column.isBiggerThan(pivotExpr),
      RelativeComparison.onOrAfter => column.isBiggerOrEqual(pivotExpr),
      RelativeComparison.onOrBefore => column.isSmallerOrEqual(pivotExpr),
    };
  }

  // ===========================================================================
  // CONVENIENCE BUILDERS WITH DATE ENCODING
  // ===========================================================================

  /// Builds a text date comparison from DateTime values.
  ///
  /// Automatically encodes DateTime to YYYY-MM-DD strings.
  static Expression<bool> textDateComparisonFromDateTime(
    Expression<String> column,
    DateOperator operator, {
    DateTime? date,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return textDateComparison(
      column,
      operator,
      date: date != null ? encodeDateOnly(date) : null,
      startDate: startDate != null ? encodeDateOnly(startDate) : null,
      endDate: endDate != null ? encodeDateOnly(endDate) : null,
    );
  }

  /// Builds a relative text date comparison from a DateTime pivot.
  ///
  /// Automatically encodes the pivot to YYYY-MM-DD string.
  static Expression<bool> relativeTextDateComparisonFromDateTime(
    Expression<String> column,
    RelativeComparison comparison,
    DateTime pivot,
  ) {
    return relativeTextDateComparison(
      column,
      comparison,
      encodeDateOnly(pivot),
    );
  }
}
