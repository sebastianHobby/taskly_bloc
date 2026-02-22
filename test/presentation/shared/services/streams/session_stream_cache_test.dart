import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/presentation/shared/services/streams/session_stream_cache.dart';
import 'package:taskly_domain/services.dart';

import '../../../../helpers/test_helpers.dart';

@Tags(['unit'])
class _FakeAppLifecycleEvents implements AppLifecycleEvents {
  _FakeAppLifecycleEvents(this._controller);

  final StreamController<AppLifecycleEvent> // ignore-stream-controller
  _controller;

  @override
  Stream<AppLifecycleEvent> get events => _controller.stream;
}

Future<void> _waitForLength<T>(
  List<T> items,
  int length, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final stopwatch = Stopwatch()..start();
  while (stopwatch.elapsed < timeout) {
    if (items.length >= length) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  throw TimeoutException(
    'Timed out waiting for list length $length (got ${items.length}).',
    timeout,
  );
}

Future<void> _waitForListener(
  StreamController<dynamic> controller, { // ignore-stream-controller
  Duration timeout = const Duration(seconds: 2),
}) async {
  final stopwatch = Stopwatch()..start();
  while (stopwatch.elapsed < timeout) {
    if (controller.hasListener) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  throw TimeoutException(
    'Timed out waiting for controller listener.',
    timeout,
  );
}

void main() {
  testSafe('does not pause streams on inactive', () async {
    final StreamController<AppLifecycleEvent> // ignore-stream-controller
    lifecycleController = StreamController.broadcast();
    final appLifecycle = _FakeAppLifecycleEvents(lifecycleController);
    final cache = SessionStreamCacheManager(appLifecycleService: appLifecycle);

    addTearDown(lifecycleController.close);
    addTearDown(cache.dispose);

    final StreamController<int> // ignore-stream-controller
    sourceController = StreamController.broadcast();
    addTearDown(sourceController.close);

    final emitted = <int>[];
    final stream = cache.getOrCreate<int>(
      key: 'test',
      source: () => sourceController.stream,
    );
    final sub = stream.listen(emitted.add);
    addTearDown(sub.cancel);

    sourceController.add(1);
    await _waitForLength(emitted, 1);
    expect(emitted, [1]);

    lifecycleController.add(AppLifecycleEvent.inactive);
    sourceController.add(2);
    await _waitForLength(emitted, 2);
    expect(emitted, [1, 2]);
  });

  testSafe('pauses on paused/detached and resumes on resumed', () async {
    final StreamController<AppLifecycleEvent> // ignore-stream-controller
    lifecycleController = StreamController.broadcast();
    final appLifecycle = _FakeAppLifecycleEvents(lifecycleController);
    final cache = SessionStreamCacheManager(appLifecycleService: appLifecycle);

    addTearDown(lifecycleController.close);
    addTearDown(cache.dispose);

    final StreamController<int> // ignore-stream-controller
    sourceController = StreamController.broadcast();
    addTearDown(sourceController.close);

    final emitted = <int>[];
    final stream = cache.getOrCreate<int>(
      key: 'test',
      source: () => sourceController.stream,
    );
    final sub = stream.listen(emitted.add);
    addTearDown(sub.cancel);

    sourceController.add(1);
    await _waitForLength(emitted, 1);
    expect(emitted, [1]);

    lifecycleController.add(AppLifecycleEvent.paused);
    sourceController.add(2);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(emitted, [1]);

    lifecycleController.add(AppLifecycleEvent.resumed);
    await _waitForListener(sourceController);
    sourceController.add(3);
    await _waitForLength(emitted, 2);
    expect(emitted, [1, 3]);

    lifecycleController.add(AppLifecycleEvent.detached);
    sourceController.add(4);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(emitted, [1, 3]);
  });
}
