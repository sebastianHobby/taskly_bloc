import 'package:taskly_domain/src/time/date_only.dart';

/// Context for evaluating task filters.
///
/// Provides the current date (normalized to midnight) for date-based rules
/// to evaluate against.
class EvaluationContext {
  /// Creates an evaluation context.
  ///
  /// Call sites must supply the current home-day key (UTC midnight) explicitly
  /// to avoid relying on `DateTime.now()` and to keep behavior testable.
  EvaluationContext({required DateTime today}) : today = _dateOnly(today);

  /// Creates an evaluation context for a specific date.
  factory EvaluationContext.forDate(DateTime date) =>
      EvaluationContext(today: _dateOnly(date));

  /// The reference date for evaluation, normalized to midnight.
  final DateTime today;

  /// Normalizes a DateTime to midnight (date-only).
  static DateTime _dateOnly(DateTime dt) => dateOnly(dt);
}
