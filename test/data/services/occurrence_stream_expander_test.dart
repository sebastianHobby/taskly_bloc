import '../../helpers/test_imports.dart';

import 'package:taskly_bloc/data/services/occurrence_stream_expander.dart';
import 'package:taskly_bloc/domain/interfaces/occurrence_stream_expander_contract.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  const expander = OccurrenceStreamExpander();

  group('OccurrenceStreamExpander.expandTaskOccurrencesSync', () {
    testSafe(
      'non-repeating task expands to single occurrence in range',
      () async {
        final start = DateTime.utc(2026, 1, 1);
        final end = DateTime.utc(2026, 1, 31);

        final task = TestData.task(
          id: 't1',
          name: 'One',
          createdAt: start,
          updatedAt: start,
          startDate: start,
          deadlineDate: null,
          repeatIcalRrule: null,
        );

        final expanded = expander.expandTaskOccurrencesSync(
          tasks: [task],
          completions: const [],
          exceptions: const [],
          rangeStart: start,
          rangeEnd: end,
        );

        expect(expanded, hasLength(1));
        expect(expanded.single.id, 't1');
        expect(expanded.single.occurrence, isNotNull);
        expect(expanded.single.occurrence!.date, DateTime.utc(2026, 1, 1));
        expect(expanded.single.completed, isFalse);
      },
    );

    testSafe(
      'non-repeating task merges completion by null occurrenceDate',
      () async {
        final start = DateTime.utc(2026, 1, 1);
        final end = DateTime.utc(2026, 1, 31);

        final task = TestData.task(
          id: 't2',
          name: 'Done',
          createdAt: start,
          updatedAt: start,
          startDate: start,
          repeatIcalRrule: null,
        );

        final completion = CompletionHistoryData(
          id: 'c1',
          entityId: 't2',
          completedAt: DateTime.utc(2026, 1, 2),
          notes: 'ok',
        );

        final expanded = expander.expandTaskOccurrencesSync(
          tasks: [task],
          completions: [completion],
          exceptions: const [],
          rangeStart: start,
          rangeEnd: end,
        );

        expect(expanded, hasLength(1));
        expect(expanded.single.completed, isTrue);
        expect(
          expanded.single.occurrence!.completedAt,
          DateTime.utc(2026, 1, 2),
        );
        expect(expanded.single.occurrence!.completionNotes, 'ok');
      },
    );

    testSafe(
      'repeating task expands daily occurrences and applies skip exception',
      () async {
        final start = DateTime.utc(2026, 1, 1);
        final end = DateTime.utc(2026, 1, 4);

        final task = TestData.task(
          id: 't3',
          name: 'Repeat',
          createdAt: start,
          updatedAt: start,
          startDate: start,
          repeatIcalRrule: 'FREQ=DAILY;COUNT=10',
        );

        final skip = RecurrenceExceptionData(
          id: 'e1',
          entityId: 't3',
          originalDate: DateTime.utc(2026, 1, 2),
          exceptionType: RecurrenceExceptionType.skip,
          newDate: null,
          newDeadline: null,
        );

        final expanded = expander.expandTaskOccurrencesSync(
          tasks: [task],
          completions: const [],
          exceptions: [skip],
          rangeStart: start,
          rangeEnd: end,
        );

        // Range includes 1,2,3,4 but 2 is skipped.
        expect(expanded.map((t) => t.occurrence!.date), [
          DateTime.utc(2026, 1, 1),
          DateTime.utc(2026, 1, 3),
          DateTime.utc(2026, 1, 4),
        ]);
      },
    );

    testSafe(
      'reschedule exception moves occurrence to newDate and adjusts deadline',
      () async {
        final start = DateTime.utc(2026, 1, 1);
        final end = DateTime.utc(2026, 1, 10);

        final task = TestData.task(
          id: 't4',
          name: 'Resched',
          createdAt: start,
          updatedAt: start,
          startDate: start,
          deadlineDate: DateTime.utc(2026, 1, 1),
          repeatIcalRrule: 'FREQ=DAILY;COUNT=10',
        );

        final reschedule = RecurrenceExceptionData(
          id: 'e2',
          entityId: 't4',
          originalDate: DateTime.utc(2026, 1, 2),
          exceptionType: RecurrenceExceptionType.reschedule,
          newDate: DateTime.utc(2026, 1, 7),
          newDeadline: DateTime.utc(2026, 1, 8),
        );

        final expanded = expander.expandTaskOccurrencesSync(
          tasks: [task],
          completions: const [],
          exceptions: [reschedule],
          rangeStart: start,
          rangeEnd: end,
        );

        final dates = expanded.map((t) => t.occurrence!.date).toList();
        expect(dates, contains(DateTime.utc(2026, 1, 7)));
        expect(dates, isNot(contains(DateTime.utc(2026, 1, 2))));

        final moved = expanded.singleWhere(
          (t) => t.occurrence!.date == DateTime.utc(2026, 1, 7),
        );
        expect(moved.occurrence!.deadline, DateTime.utc(2026, 1, 8));
      },
    );

    testSafe('invalid RRULE falls back to non-repeating behavior', () async {
      final start = DateTime.utc(2026, 1, 1);
      final end = DateTime.utc(2026, 1, 31);

      final task = TestData.task(
        id: 't5',
        name: 'Bad RRULE',
        createdAt: start,
        updatedAt: start,
        startDate: start,
        repeatIcalRrule: 'not-a-valid-rrule',
      );

      final expanded = expander.expandTaskOccurrencesSync(
        tasks: [task],
        completions: const [],
        exceptions: const [],
        rangeStart: start,
        rangeEnd: end,
      );

      expect(expanded, hasLength(1));
      expect(expanded.single.occurrence!.date, DateTime.utc(2026, 1, 1));
    });

    testSafe('repeatFromCompletion anchors from last completion', () async {
      final start = DateTime.utc(2026, 1, 1);

      final task = TestData.task(
        id: 't6',
        name: 'Rolling',
        createdAt: start,
        updatedAt: start,
        startDate: start,
        repeatIcalRrule: 'FREQ=DAILY;COUNT=10',
        repeatFromCompletion: true,
      );

      final lastCompletionAt = DateTime.utc(2026, 1, 4, 12, 0);
      final completions = [
        CompletionHistoryData(
          id: 'c-old',
          entityId: 't6',
          completedAt: DateTime.utc(2026, 1, 2, 12, 0),
        ),
        CompletionHistoryData(
          id: 'c-last',
          entityId: 't6',
          completedAt: lastCompletionAt,
        ),
      ];

      final rangeStart = DateTime.utc(2026, 1, 4);
      final rangeEnd = DateTime.utc(2026, 1, 6);

      final expanded = expander.expandTaskOccurrencesSync(
        tasks: [task],
        completions: completions,
        exceptions: const [],
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      );

      expect(expanded.map((t) => t.occurrence!.date), [
        DateTime.utc(2026, 1, 4),
        DateTime.utc(2026, 1, 5),
        DateTime.utc(2026, 1, 6),
      ]);
    });

    testSafe('seriesEnded filters out future occurrences', () async {
      final nowUtc = DateTime.now().toUtc();
      final todayUtc = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day);
      final yesterdayUtc = todayUtc.subtract(const Duration(days: 1));
      final tomorrowUtc = todayUtc.add(const Duration(days: 1));

      final task = TestData.task(
        id: 't7',
        name: 'Ended',
        createdAt: yesterdayUtc,
        updatedAt: yesterdayUtc,
        startDate: yesterdayUtc,
        repeatIcalRrule: 'FREQ=DAILY;COUNT=10',
        seriesEnded: true,
      );

      final expanded = expander.expandTaskOccurrencesSync(
        tasks: [task],
        completions: const [],
        exceptions: const [],
        rangeStart: yesterdayUtc,
        rangeEnd: tomorrowUtc,
      );

      final dates = expanded.map((t) => t.occurrence!.date).toList();
      expect(dates, contains(yesterdayUtc));
      expect(dates, contains(todayUtc));
      expect(dates, isNot(contains(tomorrowUtc)));
    });

    testSafe('reschedule moves occurrence into range from outside', () async {
      final start = DateTime.utc(2026, 1, 1);
      final rangeStart = DateTime.utc(2026, 1, 10);
      final rangeEnd = DateTime.utc(2026, 1, 12);

      final task = TestData.task(
        id: 't8',
        name: 'Move in',
        createdAt: start,
        updatedAt: start,
        startDate: start,
        repeatIcalRrule: 'FREQ=DAILY;COUNT=40',
      );

      final exception = RecurrenceExceptionData(
        id: 'e-move',
        entityId: 't8',
        originalDate: DateTime.utc(2026, 1, 5),
        exceptionType: RecurrenceExceptionType.reschedule,
        newDate: DateTime.utc(2026, 1, 11),
        newDeadline: null,
      );

      final expanded = expander.expandTaskOccurrencesSync(
        tasks: [task],
        completions: const [],
        exceptions: [exception],
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      );

      final moved = expanded.singleWhere(
        (t) => t.occurrence!.date == DateTime.utc(2026, 1, 11),
      );
      expect(moved.occurrence!.isRescheduled, isTrue);
      expect(moved.occurrence!.originalDate, DateTime.utc(2026, 1, 5));
    });

    testSafe(
      'repeating task merges completion by originalOccurrenceDate',
      () async {
        final start = DateTime.utc(2026, 1, 1);
        final end = DateTime.utc(2026, 1, 3);

        final task = TestData.task(
          id: 't9',
          name: 'Complete overlay',
          createdAt: start,
          updatedAt: start,
          startDate: start,
          repeatIcalRrule: 'FREQ=DAILY;COUNT=10',
        );

        final completion = CompletionHistoryData(
          id: 'c9',
          entityId: 't9',
          occurrenceDate: DateTime.utc(2026, 1, 2),
          originalOccurrenceDate: DateTime.utc(2026, 1, 2),
          completedAt: DateTime.utc(2026, 1, 2, 8, 0),
          notes: 'ok',
        );

        final expanded = expander.expandTaskOccurrencesSync(
          tasks: [task],
          completions: [completion],
          exceptions: const [],
          rangeStart: start,
          rangeEnd: end,
        );

        final onDay2 = expanded.singleWhere(
          (t) => t.occurrence!.date == DateTime.utc(2026, 1, 2),
        );
        expect(onDay2.completed, isTrue);
        expect(onDay2.occurrence!.completionId, 'c9');
        expect(onDay2.occurrence!.completionNotes, 'ok');
      },
    );

    testSafe('postExpansionFilter is applied after expansion', () async {
      final start = DateTime.utc(2026, 1, 1);
      final end = DateTime.utc(2026, 1, 3);

      final task = TestData.task(
        id: 't10',
        name: 'Filter',
        createdAt: start,
        updatedAt: start,
        startDate: start,
        repeatIcalRrule: 'FREQ=DAILY;COUNT=10',
      );

      final expanded = expander.expandTaskOccurrencesSync(
        tasks: [task],
        completions: const [],
        exceptions: const [],
        rangeStart: start,
        rangeEnd: end,
        postExpansionFilter: (t) =>
            t.occurrence!.date != DateTime.utc(2026, 1, 2),
      );

      expect(expanded.map((t) => t.occurrence!.date), [
        DateTime.utc(2026, 1, 1),
        DateTime.utc(2026, 1, 3),
      ]);
    });
  });

  group('OccurrenceStreamExpander.expandProjectOccurrencesSync', () {
    testSafe(
      'repeating project expands and applies reschedule into range',
      () async {
        final start = DateTime.utc(2026, 1, 1);
        final rangeStart = DateTime.utc(2026, 1, 10);
        final rangeEnd = DateTime.utc(2026, 1, 12);

        final project = TestData.project(
          id: 'p1',
          name: 'Proj',
          createdAt: start,
          updatedAt: start,
          startDate: start,
          repeatIcalRrule: 'FREQ=DAILY;COUNT=40',
        );

        final exception = RecurrenceExceptionData(
          id: 'ep1',
          entityId: 'p1',
          originalDate: DateTime.utc(2026, 1, 5),
          exceptionType: RecurrenceExceptionType.reschedule,
          newDate: DateTime.utc(2026, 1, 11),
          newDeadline: DateTime.utc(2026, 1, 11),
        );

        final expanded = expander.expandProjectOccurrencesSync(
          projects: [project],
          completions: const [],
          exceptions: [exception],
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
        );

        expect(expanded.map((p) => p.occurrence!.date), [
          DateTime.utc(2026, 1, 11),
        ]);
        expect(expanded.single.occurrence!.isRescheduled, isTrue);
      },
    );
  });
}
