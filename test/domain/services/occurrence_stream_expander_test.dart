@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/time.dart';

class FixedClock implements Clock {
  FixedClock(this.now);

  DateTime now;

  @override
  DateTime nowLocal() => now;

  @override
  DateTime nowUtc() => now.toUtc();
}

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('OccurrenceStreamExpander', () {
    testSafe('expands non-repeating tasks within range', () async {
      final expander = OccurrenceStreamExpander(clock: FixedClock(DateTime(2025, 1, 1)));
      final task = TestData.task(
        id: 't1',
        startDate: DateTime(2025, 1, 10),
      );
      final completion = CompletionHistoryData(
        id: 'c1',
        entityId: 't1',
        completedAt: DateTime(2025, 1, 11),
        occurrenceDate: null,
      );

      final result = expander.expandTaskOccurrencesSync(
        tasks: [task],
        completions: [completion],
        exceptions: const [],
        rangeStart: DateTime(2025, 1, 1),
        rangeEnd: DateTime(2025, 1, 31),
      );

      expect(result, hasLength(1));
      expect(result.first.occurrence, isNotNull);
      expect(result.first.occurrence?.completedAt, completion.completedAt);
    });

    testSafe('expands repeating tasks with exceptions', () async {
      final expander = OccurrenceStreamExpander(clock: FixedClock(DateTime(2025, 1, 20)));
      final task = TestData.task(
        id: 't2',
        startDate: DateTime(2025, 1, 10),
        repeatIcalRrule: 'FREQ=DAILY;COUNT=3',
      );

      final exception = RecurrenceExceptionData(
        id: 'e1',
        entityId: 't2',
        originalDate: DateTime(2025, 1, 11),
        exceptionType: RecurrenceExceptionType.reschedule,
        newDate: DateTime(2025, 1, 15),
      );

      final result = expander.expandTaskOccurrencesSync(
        tasks: [task],
        completions: const [],
        exceptions: [exception],
        rangeStart: DateTime(2025, 1, 10),
        rangeEnd: DateTime(2025, 1, 20),
      );

      expect(result, isNotEmpty);
      expect(result.any((t) => t.occurrence?.isRescheduled == true), isTrue);
    });
  });
}
