import '../time/date_only.dart';

/// Context for evaluating task filters.
///
/// Provides the current date (normalized to midnight) for date-based rules
/// to evaluate against.
class EvaluationContext {
  /// Creates an evaluation context with the current date.
  ///
  /// If [today] is not provided, uses the current date normalized to midnight.
  EvaluationContext({DateTime? today})
    : today = today ?? _dateOnly(DateTime.now());

  /// Creates an evaluation context for a specific date.
  factory EvaluationContext.forDate(DateTime date) =>
      EvaluationContext(today: _dateOnly(date));

  /// The reference date for evaluation, normalized to midnight.
  final DateTime today;

  /// Normalizes a DateTime to midnight (date-only).
  static DateTime _dateOnly(DateTime dt) => dateOnly(dt);
}
