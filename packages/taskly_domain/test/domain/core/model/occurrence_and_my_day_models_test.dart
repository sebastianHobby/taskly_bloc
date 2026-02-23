@Tags(['unit'])
library;

import '../../../helpers/test_imports.dart';

import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/my_day.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/src/models/scheduled/scheduled_date_tag.dart';
import 'package:taskly_domain/src/models/scheduled/scheduled_occurrence_ref.dart';

void main() {
  testSafe('OccurrencePreview json/copy/equality/toString', () async {
    final base = OccurrencePreview(
      asOfDayKey: DateTime.utc(2026, 1, 2),
      pastDays: 10,
      futureDays: 20,
    );
    final fromJson = OccurrencePreview.fromJson(<String, dynamic>{
      'asOfDayKey': '2026-01-02T00:00:00.000Z',
      'pastDays': 10,
      'futureDays': 20,
    });
    final copied = base.copyWith(futureDays: 21);

    expect(fromJson, base);
    expect(copied.futureDays, 21);
    expect(base.toJson()['pastDays'], 10);
    expect(base.toString(), contains('OccurrencePreview('));
  });

  testSafe('OccurrenceExpansion json/copy/equality/toString', () async {
    final base = OccurrenceExpansion(
      rangeStart: DateTime.utc(2026, 1, 1),
      rangeEnd: DateTime.utc(2026, 1, 31),
    );
    final fromJson = OccurrenceExpansion.fromJson(<String, dynamic>{
      'rangeStart': '2026-01-01T00:00:00.000Z',
      'rangeEnd': '2026-01-31T00:00:00.000Z',
    });
    final copied = base.copyWith(rangeEnd: DateTime.utc(2026, 2, 1));

    expect(fromJson, base);
    expect(copied.rangeEnd, DateTime.utc(2026, 2, 1));
    expect(base.toJson()['rangeStart'], '2026-01-01T00:00:00.000Z');
    expect(base.toString(), contains('OccurrenceExpansion('));
  });

  testSafe('ScheduledOccurrenceRef equality/hash/toString', () async {
    final a = ScheduledOccurrenceRef(
      entityType: EntityType.task,
      entityId: 't1',
      localDay: DateTime.utc(2026, 1, 1),
      tag: ScheduledDateTag.due,
    );
    final b = ScheduledOccurrenceRef(
      entityType: EntityType.task,
      entityId: 't1',
      localDay: DateTime.utc(2026, 1, 1),
      tag: ScheduledDateTag.due,
    );

    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a.toString(), contains('entityType: task'));
  });

  testSafe('MyDayPick constructors expose task/routine ids', () async {
    final pickedAt = DateTime.utc(2026, 1, 3, 8);
    final taskPick = MyDayPick.task(
      taskId: 't1',
      bucket: MyDayPickBucket.valueSuggestions,
      sortIndex: 0,
      pickedAtUtc: pickedAt,
      suggestionRank: 2,
      qualifyingValueId: 'v1',
      reasonCodes: const ['fit', 'urgency'],
    );
    final routinePick = MyDayPick.routine(
      routineId: 'r1',
      bucket: MyDayPickBucket.routine,
      sortIndex: 1,
      pickedAtUtc: pickedAt,
      qualifyingValueId: 'v2',
    );

    expect(taskPick.taskId, 't1');
    expect(taskPick.routineId, isNull);
    expect(routinePick.taskId, isNull);
    expect(routinePick.routineId, 'r1');
    expect(routinePick.reasonCodes, isEmpty);
    expect(routinePick.suggestionRank, isNull);
  });

  testSafe(
    'MyDayDayPicks selection helpers return immutable id sets',
    () async {
      final pickedAt = DateTime.utc(2026, 1, 3, 8);
      final picks = MyDayDayPicks(
        dayKeyUtc: DateTime.utc(2026, 1, 3),
        ritualCompletedAtUtc: null,
        picks: <MyDayPick>[
          MyDayPick.task(
            taskId: 't1',
            bucket: MyDayPickBucket.manual,
            sortIndex: 0,
            pickedAtUtc: pickedAt,
          ),
          MyDayPick.task(
            taskId: 't2',
            bucket: MyDayPickBucket.due,
            sortIndex: 1,
            pickedAtUtc: pickedAt,
          ),
          MyDayPick.routine(
            routineId: 'r1',
            bucket: MyDayPickBucket.routine,
            sortIndex: 2,
            pickedAtUtc: pickedAt,
          ),
        ],
      );

      expect(picks.hasSelection, isTrue);
      expect(picks.selectedTaskIds, <String>{'t1', 't2'});
      expect(picks.selectedRoutineIds, <String>{'r1'});
      expect(
        () => picks.selectedTaskIds.add('x'),
        throwsUnsupportedError,
      );
    },
  );
}
