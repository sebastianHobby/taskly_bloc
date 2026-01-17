/// Time source abstraction used across domain/data/presentation.
///
/// Domain logic must not call `DateTime.now()` directly. Inject a [Clock]
/// (or pass explicit `now`/`today` values) so behavior is deterministic and
/// testable.
library;

abstract interface class Clock {
  DateTime nowLocal();
  DateTime nowUtc();
}

/// Production clock implementation.
class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime nowLocal() => DateTime.now();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}

/// Default runtime clock.
const Clock systemClock = SystemClock();
