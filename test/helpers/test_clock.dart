/// Simple deterministic time helpers for tests.
///
/// Widget tests already run in a fake-async zone, but many unit/integration
/// tests still need deterministic timestamps for fixtures and assertions.
class TestClock {
  TestClock([DateTime? initial]) : now = initial ?? DateTime(2025, 1, 15, 12);

  DateTime now;

  void advance(Duration delta) {
    now = now.add(delta);
  }
}
