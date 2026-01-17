/// Centralized access to the current time.
///
/// This exists to avoid scattering `DateTime.now()` throughout the presentation
/// layer and to make time-dependent UI logic easier to test.
library;

abstract interface class NowService {
  DateTime nowLocal();
  DateTime nowUtc();
}

class SystemNowService implements NowService {
  const SystemNowService();

  @override
  DateTime nowLocal() => DateTime.now();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}
