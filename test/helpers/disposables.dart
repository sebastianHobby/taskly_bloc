import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// Registers cleanup for [value] using `addTearDown`, returning [value].
///
/// This is a small ergonomics helper so resources are cleaned up immediately
/// after allocation (even if the test fails early).
T autoTearDown<T>(
  T value,
  FutureOr<void> Function(T value) dispose,
) {
  addTearDown(() => dispose(value));
  return value;
}

/// Registers `cancel()` on the subscription via `addTearDown`.
StreamSubscription<T> autoCancel<T>(StreamSubscription<T> subscription) {
  return autoTearDown(subscription, (s) => s.cancel());
}

/// Registers `close()` via `addTearDown`.
///
/// Intended for objects like `BlocBase`/`Cubit` that expose a `close()` method.
T autoClose<T extends Object>(T closeable) {
  return autoTearDown<T>(closeable, (c) async {
    final dynamic dyn = c;
    await dyn.close();
  });
}

/// A minimal disposable bag that can be used by test contexts.
class DisposableBag {
  final List<FutureOr<void> Function()> _disposers = [];

  /// Adds a disposer that will be executed when [dispose] is called.
  void add(FutureOr<void> Function() disposer) {
    _disposers.add(disposer);
  }

  /// Disposes all tracked resources in reverse creation order.
  Future<void> dispose() async {
    for (final disposer in _disposers.reversed) {
      await disposer();
    }
    _disposers.clear();
  }
}
