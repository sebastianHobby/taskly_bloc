import 'package:taskly_domain/time.dart';

/// Deterministic [Clock] for unit tests.
final class FixedClock implements Clock {
  const FixedClock(this._now);

  final DateTime _now;

  @override
  DateTime nowLocal() => _now;

  @override
  DateTime nowUtc() => _now.toUtc();
}
