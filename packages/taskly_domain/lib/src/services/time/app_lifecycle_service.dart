import 'dart:async';

import 'package:flutter/widgets.dart';

/// Coarse-grained lifecycle events that are useful for domain coordinators.
enum AppLifecycleEvent {
  resumed,
  inactive,
  paused,
  detached,
}

/// Exposes app lifecycle transitions as a stream.
///
/// Timers do not fire while the app is suspended, so coordinators should
/// re-check time-based boundaries on [AppLifecycleEvent.resumed].
class AppLifecycleService with WidgetsBindingObserver {
  AppLifecycleService();

  final StreamController<AppLifecycleEvent> _eventsController =
      StreamController<AppLifecycleEvent>.broadcast();

  /// Broadcast stream of lifecycle events.
  ///
  /// Multiple coordinators/services are expected to listen concurrently.
  Stream<AppLifecycleEvent> get events => _eventsController.stream;

  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
  }

  void stop() {
    if (!_started) return;
    WidgetsBinding.instance.removeObserver(this);
    _started = false;
  }

  Future<void> dispose() async {
    stop();
    await _eventsController.close();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _eventsController.add(AppLifecycleEvent.resumed);
      case AppLifecycleState.inactive:
        _eventsController.add(AppLifecycleEvent.inactive);
      case AppLifecycleState.paused:
        _eventsController.add(AppLifecycleEvent.paused);
      case AppLifecycleState.detached:
        _eventsController.add(AppLifecycleEvent.detached);
      case AppLifecycleState.hidden:
        // Ignore hidden for now; treat pause/resume as the primary boundary.
        break;
    }
  }
}
