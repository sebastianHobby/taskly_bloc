import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:taskly_domain/taskly_domain.dart';
class MockTemporalTriggerService extends Mock
    implements TemporalTriggerService {}

void main() {
  test('emits invalidations on start, resume, and day boundary', () async {
    final temporal = MockTemporalTriggerService();

    final events = StreamController<TemporalTriggerEvent>.broadcast();
    addTearDown(events.close);

    when(() => temporal.events).thenAnswer((_) => events.stream);

    final service = AttentionTemporalInvalidationService(
      temporalTriggerService: temporal,
    );

    final pulses = <int>[];
    final sub = service.invalidations.listen((_) => pulses.add(pulses.length));
    addTearDown(sub.cancel);

    service.start();

    // Initial pulse
    await Future<void>.delayed(Duration.zero);
    expect(pulses.length, 1);

    events.add(const AppResumed());
    await Future<void>.delayed(Duration.zero);
    expect(pulses.length, 2);

    events.add(
      HomeDayBoundaryCrossed(newDayKeyUtc: DateTime.utc(2026, 1, 2)),
    );
    await Future<void>.delayed(Duration.zero);
    expect(pulses.length, 3);

    await service.dispose();
  });
}
