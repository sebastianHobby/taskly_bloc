@Tags(['unit'])
library;

import '../../../helpers/test_imports.dart';

import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/time.dart';

class _FakeLifecycleService extends Fake implements AppLifecycleService {
  _FakeLifecycleService(this._controller);

  final StreamController<AppLifecycleEvent> _controller;

  @override
  Stream<AppLifecycleEvent> get events => _controller.stream;
}

class _FakeDayKeyService extends Fake implements HomeDayKeyService {
  _FakeDayKeyService(this._clock);

  final _MutableClock _clock;

  @override
  DateTime todayDayKeyUtc({DateTime? nowUtc}) {
    return dateOnly(nowUtc ?? _clock.nowUtc());
  }

  @override
  DateTime nextHomeDayBoundaryUtc({DateTime? nowUtc}) {
    final base = nowUtc ?? _clock.nowUtc();
    return base.add(const Duration(days: 1));
  }
}

class _MutableClock implements Clock {
  _MutableClock(this._nowUtc);

  DateTime _nowUtc;

  void setNow(DateTime value) {
    _nowUtc = value;
  }

  @override
  DateTime nowLocal() => _nowUtc.toLocal();

  @override
  DateTime nowUtc() => _nowUtc;
}

void main() {
  setUpAll(initializeLoggingForTest);

  testSafe('start emits resume and boundary event when day advances', () async {
    final lifecycleController = StreamController<AppLifecycleEvent>.broadcast();
    addTearDown(lifecycleController.close);

    final clock = _MutableClock(DateTime.utc(2026, 1, 1, 10));
    final dayKeyService = _FakeDayKeyService(clock);
    final lifecycleService = _FakeLifecycleService(lifecycleController);

    final service = TemporalTriggerService(
      dayKeyService: dayKeyService,
      lifecycleService: lifecycleService,
      clock: clock,
    );

    final eventsFuture = service.events.take(2).toList();

    service.start();
    clock.setNow(DateTime.utc(2026, 1, 2, 10));
    lifecycleController.add(AppLifecycleEvent.resumed);

    final events = await eventsFuture;

    expect(events.first, isA<AppResumed>());
    expect(events.last, isA<HomeDayBoundaryCrossed>());
    final boundary = events.last as HomeDayBoundaryCrossed;
    expect(boundary.newDayKeyUtc, DateTime.utc(2026, 1, 2));
  });

  testSafe('stop cancels lifecycle listening', () async {
    final lifecycleController = StreamController<AppLifecycleEvent>.broadcast();
    addTearDown(lifecycleController.close);

    final clock = _MutableClock(DateTime.utc(2026, 1, 1, 10));
    final dayKeyService = _FakeDayKeyService(clock);
    final lifecycleService = _FakeLifecycleService(lifecycleController);

    final service = TemporalTriggerService(
      dayKeyService: dayKeyService,
      lifecycleService: lifecycleService,
      clock: clock,
    );

    final received = <TemporalTriggerEvent>[];
    final sub = service.events.listen(received.add);
    addTearDown(sub.cancel);

    service.start();
    service.stop();

    lifecycleController.add(AppLifecycleEvent.resumed);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(received, isEmpty);
  });
}
