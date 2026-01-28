@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';

import '../../helpers/fixed_clock.dart';

void main() {
  group('OccurrenceStreamExpander.expandTaskOccurrencesSync', () {
    testSafe(
      'expands non-repeating task into a single occurrence in range',
      () async {
        final expander = OccurrenceStreamExpander(
          clock: FixedClock(DateTime.utc(2025, 1, 1)),
        );

        final task = Task(
          id: 't1',
          createdAt: DateTime.utc(2025, 1, 1, 12),
          updatedAt: DateTime.utc(2025, 1, 1, 12),
          name: 'Task',
          completed: false,
          startDate: DateTime.utc(2025, 1, 5, 20),
        );

        final completions = <CompletionHistoryData>[
          CompletionHistoryData(
            id: 'c1',
            entityId: 't1',
            occurrenceDate: null,
            originalOccurrenceDate: null,
            completedAt: DateTime.utc(2025, 1, 6, 9),
            notes: 'done',
          ),
        ];

        final out = expander.expandTaskOccurrencesSync(
          tasks: [task],
          completions: completions,
          exceptions: const <RecurrenceExceptionData>[],
          rangeStart: DateTime.utc(2025, 1, 1),
          rangeEnd: DateTime.utc(2025, 1, 31),
        );

        expect(out.length, equals(1));
        final occ = out.single.occurrence;
        expect(occ, isNot(equals(null)));
        expect(occ!.date, equals(DateTime.utc(2025, 1, 5)));
        expect(occ.completionId, equals('c1'));
        expect(occ.completedAt, equals(DateTime.utc(2025, 1, 6, 9)));
        expect(occ.completionNotes, equals('done'));
      },
    );

    testSafe('does not emit non-repeating task outside range', () async {
      final expander = OccurrenceStreamExpander(
        clock: FixedClock(DateTime.utc(2025, 1, 1)),
      );

      final task = Task(
        id: 't1',
        createdAt: DateTime.utc(2025, 1, 1, 12),
        updatedAt: DateTime.utc(2025, 1, 1, 12),
        name: 'Task',
        completed: false,
        startDate: DateTime.utc(2025, 2, 1),
      );

      final out = expander.expandTaskOccurrencesSync(
        tasks: [task],
        completions: const <CompletionHistoryData>[],
        exceptions: const <RecurrenceExceptionData>[],
        rangeStart: DateTime.utc(2025, 1, 1),
        rangeEnd: DateTime.utc(2025, 1, 31),
      );

      expect(out, isEmpty);
    });

    testSafe('skips non-repeating task with no start or deadline', () async {
      final expander = OccurrenceStreamExpander(
        clock: FixedClock(DateTime.utc(2025, 1, 1)),
      );

      final task = Task(
        id: 't1',
        createdAt: DateTime.utc(2025, 1, 1, 12),
        updatedAt: DateTime.utc(2025, 1, 1, 12),
        name: 'Task',
        completed: false,
      );

      final out = expander.expandTaskOccurrencesSync(
        tasks: [task],
        completions: const <CompletionHistoryData>[],
        exceptions: const <RecurrenceExceptionData>[],
        rangeStart: DateTime.utc(2025, 1, 1),
        rangeEnd: DateTime.utc(2025, 1, 31),
      );

      expect(out, isEmpty);
    });

    testSafe('treats invalid RRULE as non-repeating', () async {
      final expander = OccurrenceStreamExpander(
        clock: FixedClock(DateTime.utc(2025, 1, 1)),
      );

      final task = Task(
        id: 't1',
        createdAt: DateTime.utc(2025, 1, 1, 12),
        updatedAt: DateTime.utc(2025, 1, 1, 12),
        name: 'Task',
        completed: false,
        startDate: DateTime.utc(2025, 1, 10),
        repeatIcalRrule: 'not a rule',
      );

      final out = expander.expandTaskOccurrencesSync(
        tasks: [task],
        completions: const <CompletionHistoryData>[],
        exceptions: const <RecurrenceExceptionData>[],
        rangeStart: DateTime.utc(2025, 1, 1),
        rangeEnd: DateTime.utc(2025, 1, 31),
      );

      expect(out.length, equals(1));
      expect(out.single.occurrence!.date, equals(DateTime.utc(2025, 1, 10)));
    });

    testSafe('expands daily RRULE and includes anchor date', () async {
      final expander = OccurrenceStreamExpander(
        clock: FixedClock(DateTime.utc(2025, 1, 10)),
      );

      final task = Task(
        id: 't1',
        createdAt: DateTime.utc(2025, 1, 1),
        updatedAt: DateTime.utc(2025, 1, 1),
        name: 'Task',
        completed: false,
        startDate: DateTime.utc(2025, 1, 1, 8),
        repeatIcalRrule: 'FREQ=DAILY;COUNT=3',
      );

      final out = expander.expandTaskOccurrencesSync(
        tasks: [task],
        completions: const <CompletionHistoryData>[],
        exceptions: const <RecurrenceExceptionData>[],
        rangeStart: DateTime.utc(2025, 1, 1),
        rangeEnd: DateTime.utc(2025, 1, 3),
      );

      expect(
        out.map((t) => t.occurrence!.date).toList(),
        equals([
          DateTime.utc(2025, 1, 1),
          DateTime.utc(2025, 1, 2),
          DateTime.utc(2025, 1, 3),
        ]),
      );
    });

    testSafe('skips occurrences when exceptionType=skip', () async {
      final expander = OccurrenceStreamExpander(
        clock: FixedClock(DateTime.utc(2025, 1, 10)),
      );

      final task = Task(
        id: 't1',
        createdAt: DateTime.utc(2025, 1, 1),
        updatedAt: DateTime.utc(2025, 1, 1),
        name: 'Task',
        completed: false,
        startDate: DateTime.utc(2025, 1, 1),
        repeatIcalRrule: 'FREQ=DAILY;COUNT=3',
      );

      final out = expander.expandTaskOccurrencesSync(
        tasks: [task],
        completions: const <CompletionHistoryData>[],
        exceptions: <RecurrenceExceptionData>[
          RecurrenceExceptionData(
            id: 'e1',
            entityId: 't1',
            originalDate: DateTime.utc(2025, 1, 2),
            exceptionType: RecurrenceExceptionType.skip,
          ),
        ],
        rangeStart: DateTime.utc(2025, 1, 1),
        rangeEnd: DateTime.utc(2025, 1, 3),
      );

      expect(
        out.map((t) => t.occurrence!.date).toList(),
        equals([DateTime.utc(2025, 1, 1), DateTime.utc(2025, 1, 3)]),
      );
    });

    testSafe(
      'reschedules occurrence date when exceptionType=reschedule',
      () async {
        final expander = OccurrenceStreamExpander(
          clock: FixedClock(DateTime.utc(2025, 1, 10)),
        );

        final task = Task(
          id: 't1',
          createdAt: DateTime.utc(2025, 1, 1),
          updatedAt: DateTime.utc(2025, 1, 1),
          name: 'Task',
          completed: false,
          startDate: DateTime.utc(2025, 1, 1),
          repeatIcalRrule: 'FREQ=DAILY;COUNT=3',
        );

        final out = expander.expandTaskOccurrencesSync(
          tasks: [task],
          completions: const <CompletionHistoryData>[],
          exceptions: <RecurrenceExceptionData>[
            RecurrenceExceptionData(
              id: 'e1',
              entityId: 't1',
              originalDate: DateTime.utc(2025, 1, 2),
              exceptionType: RecurrenceExceptionType.reschedule,
              newDate: DateTime.utc(2025, 1, 10),
            ),
          ],
          rangeStart: DateTime.utc(2025, 1, 1),
          rangeEnd: DateTime.utc(2025, 1, 3),
        );

        final dates = out.map((t) => t.occurrence!.date).toList();
        expect(dates, contains(DateTime.utc(2025, 1, 10)));

        final rescheduled = out.firstWhere(
          (t) => t.occurrence!.isRescheduled,
        );
        expect(
          rescheduled.occurrence!.originalDate,
          equals(DateTime.utc(2025, 1, 2)),
        );
        expect(rescheduled.occurrence!.date, equals(DateTime.utc(2025, 1, 10)));
      },
    );

    testSafe('attaches completion details by originalOccurrenceDate', () async {
      final expander = OccurrenceStreamExpander(
        clock: FixedClock(DateTime.utc(2025, 1, 10)),
      );

      final task = Task(
        id: 't1',
        createdAt: DateTime.utc(2025, 1, 1),
        updatedAt: DateTime.utc(2025, 1, 1),
        name: 'Task',
        completed: false,
        startDate: DateTime.utc(2025, 1, 1),
        repeatIcalRrule: 'FREQ=DAILY;COUNT=2',
      );

      final out = expander.expandTaskOccurrencesSync(
        tasks: [task],
        completions: <CompletionHistoryData>[
          CompletionHistoryData(
            id: 'c1',
            entityId: 't1',
            completedAt: DateTime.utc(2025, 1, 2, 9),
            originalOccurrenceDate: DateTime.utc(2025, 1, 1),
            occurrenceDate: DateTime.utc(2025, 1, 1),
          ),
        ],
        exceptions: const <RecurrenceExceptionData>[],
        rangeStart: DateTime.utc(2025, 1, 1),
        rangeEnd: DateTime.utc(2025, 1, 2),
      );

      final first = out.firstWhere(
        (t) => t.occurrence!.originalDate == DateTime.utc(2025, 1, 1),
      );
      expect(first.occurrence!.completionId, equals('c1'));
      expect(
        first.occurrence!.completedAt,
        equals(DateTime.utc(2025, 1, 2, 9)),
      );
    });

    testSafe(
      'seriesEnded stops future occurrences based on injected clock',
      () async {
        final expander = OccurrenceStreamExpander(
          clock: FixedClock(DateTime.utc(2025, 1, 2, 12)),
        );

        final task = Task(
          id: 't1',
          createdAt: DateTime.utc(2025, 1, 1),
          updatedAt: DateTime.utc(2025, 1, 1),
          name: 'Task',
          completed: false,
          startDate: DateTime.utc(2025, 1, 1),
          repeatIcalRrule: 'FREQ=DAILY;COUNT=3',
          seriesEnded: true,
        );

        final out = expander.expandTaskOccurrencesSync(
          tasks: [task],
          completions: const <CompletionHistoryData>[],
          exceptions: const <RecurrenceExceptionData>[],
          rangeStart: DateTime.utc(2025, 1, 1),
          rangeEnd: DateTime.utc(2025, 1, 3),
        );

        // seriesEnded keeps only occurrences strictly before clock.nowLocal()
        expect(
          out.map((t) => t.occurrence!.date).toList(),
          equals([
            DateTime.utc(2025, 1, 1),
            DateTime.utc(2025, 1, 2),
          ]),
        );
      },
    );
  });

  group('OccurrenceStreamExpander.expandProjectOccurrencesSync', () {
    testSafe(
      'expands non-repeating project into a single occurrence in range',
      () async {
        final expander = OccurrenceStreamExpander(
          clock: FixedClock(DateTime.utc(2025, 1, 1)),
        );

        final project = Project(
          id: 'p1',
          createdAt: DateTime.utc(2025, 1, 1, 12),
          updatedAt: DateTime.utc(2025, 1, 1, 12),
          name: 'Project',
          completed: false,
          startDate: DateTime.utc(2025, 1, 5, 20),
        );

        final out = expander.expandProjectOccurrencesSync(
          projects: [project],
          completions: const <CompletionHistoryData>[],
          exceptions: const <RecurrenceExceptionData>[],
          rangeStart: DateTime.utc(2025, 1, 1),
          rangeEnd: DateTime.utc(2025, 1, 31),
        );

        expect(out.length, equals(1));
        expect(out.single.occurrence?.date, equals(DateTime.utc(2025, 1, 5)));
      },
    );

    testSafe(
      'skips non-repeating project with no start or deadline',
      () async {
        final expander = OccurrenceStreamExpander(
          clock: FixedClock(DateTime.utc(2025, 1, 1)),
        );

        final project = Project(
          id: 'p1',
          createdAt: DateTime.utc(2025, 1, 1, 12),
          updatedAt: DateTime.utc(2025, 1, 1, 12),
          name: 'Project',
          completed: false,
        );

        final out = expander.expandProjectOccurrencesSync(
          projects: [project],
          completions: const <CompletionHistoryData>[],
          exceptions: const <RecurrenceExceptionData>[],
          rangeStart: DateTime.utc(2025, 1, 1),
          rangeEnd: DateTime.utc(2025, 1, 31),
        );

        expect(out, isEmpty);
      },
    );
  });
}
