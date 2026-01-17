import '../../time/date_only.dart';
import '../task_predicate.dart'
    show DateOperator, RelativeComparison;

/// Type-based date comparison logic.
///
/// All date comparisons across all entities use this single implementation.
/// Behavior is determined solely by the data type (DateTime), not by
/// which entity the field belongs to.
///
/// This ensures parity between in-memory evaluation and SQL queries
/// by providing a canonical definition of each comparison operation.
sealed class DateComparison {
  const DateComparison._();

  /// Evaluates an absolute date comparison in memory.
  ///
  /// All comparisons use date-only granularity (time components ignored).
  static bool evaluate({
    required DateTime? fieldValue,
    required DateOperator operator,
    DateTime? date,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return switch (operator) {
      DateOperator.isNull => fieldValue == null,
      DateOperator.isNotNull => fieldValue != null,
      DateOperator.on => _isOn(fieldValue, date!),
      DateOperator.before => _isBefore(fieldValue, date!),
      DateOperator.after => _isAfter(fieldValue, date!),
      DateOperator.onOrBefore => _isOnOrBefore(fieldValue, date!),
      DateOperator.onOrAfter => _isOnOrAfter(fieldValue, date!),
      DateOperator.between => _isBetween(fieldValue, startDate!, endDate!),
      DateOperator.relative => false, // Use evaluateRelative() instead
    };
  }

  /// Evaluates a relative date comparison in memory.
  ///
  /// [pivot] should be pre-calculated as (today + relativeDays).
  static bool evaluateRelative({
    required DateTime? fieldValue,
    required RelativeComparison comparison,
    required DateTime pivot,
  }) {
    if (fieldValue == null) return false;

    final target = dateOnly(fieldValue);
    final pivotDate = dateOnly(pivot);

    return switch (comparison) {
      RelativeComparison.on => target.isAtSameMomentAs(pivotDate),
      RelativeComparison.before => target.isBefore(pivotDate),
      RelativeComparison.after => target.isAfter(pivotDate),
      RelativeComparison.onOrBefore => !target.isAfter(pivotDate),
      RelativeComparison.onOrAfter => !target.isBefore(pivotDate),
    };
  }

  // ===========================================================================
  // Private helpers with consistent date-only semantics
  // ===========================================================================

  static bool _isOn(DateTime? v, DateTime d) =>
      v != null && dateOnly(v).isAtSameMomentAs(dateOnly(d));

  static bool _isBefore(DateTime? v, DateTime d) =>
      v != null && dateOnly(v).isBefore(dateOnly(d));

  static bool _isAfter(DateTime? v, DateTime d) =>
      v != null && dateOnly(v).isAfter(dateOnly(d));

  static bool _isOnOrBefore(DateTime? v, DateTime d) =>
      v != null && !dateOnly(v).isAfter(dateOnly(d));

  static bool _isOnOrAfter(DateTime? v, DateTime d) =>
      v != null && !dateOnly(v).isBefore(dateOnly(d));

  static bool _isBetween(DateTime? v, DateTime s, DateTime e) =>
      v != null &&
      !dateOnly(v).isBefore(dateOnly(s)) &&
      !dateOnly(v).isAfter(dateOnly(e));
}
