/// App lifecycle events surfaced to domain services without Flutter deps.
library;

/// Coarse-grained lifecycle events that are useful for domain coordinators.
enum AppLifecycleEvent {
  resumed,
  inactive,
  paused,
  detached,
}

/// Stream of lifecycle events (broadcast).
abstract class AppLifecycleEvents {
  Stream<AppLifecycleEvent> get events;
}
