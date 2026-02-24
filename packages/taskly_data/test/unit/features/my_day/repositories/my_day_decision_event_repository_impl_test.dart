@Tags(['unit'])
library;

import 'package:drift/drift.dart' as drift;
import 'package:taskly_data/db.dart';
import 'package:taskly_data/id.dart';
import 'package:taskly_data/src/features/my_day/repositories/my_day_decision_event_repository_impl.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/my_day.dart';
import 'package:taskly_domain/time.dart';

import '../../../../helpers/test_db.dart';
import '../../../../helpers/test_imports.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('MyDayDecisionEventRepositoryImpl', () {
    testSafe('append and aggregate shelf rates and entity counts', () async {
      final db = createAutoClosingDb();
      final ids = IdGenerator.withUserId('user-1');
      final repo = MyDayDecisionEventRepositoryImpl(driftDb: db, ids: ids);

      await repo.appendAll([
        MyDayDecisionEvent(
          id: ids.myDayDecisionEventId(),
          dayKeyUtc: DateTime.utc(2026, 2, 24),
          entityType: MyDayDecisionEntityType.task,
          entityId: 'task-1',
          shelf: MyDayDecisionShelf.planned,
          action: MyDayDecisionAction.kept,
          actionAtUtc: DateTime.utc(2026, 2, 24, 8),
        ),
        MyDayDecisionEvent(
          id: ids.myDayDecisionEventId(),
          dayKeyUtc: DateTime.utc(2026, 2, 24),
          entityType: MyDayDecisionEntityType.task,
          entityId: 'task-1',
          shelf: MyDayDecisionShelf.planned,
          action: MyDayDecisionAction.deferred,
          actionAtUtc: DateTime.utc(2026, 2, 24, 9),
          deferKind: MyDayDecisionDeferKind.startReschedule,
          fromDayKey: DateTime.utc(2026, 2, 24),
          toDayKey: DateTime.utc(2026, 2, 25),
        ),
        MyDayDecisionEvent(
          id: ids.myDayDecisionEventId(),
          dayKeyUtc: DateTime.utc(2026, 2, 24),
          entityType: MyDayDecisionEntityType.task,
          entityId: 'task-2',
          shelf: MyDayDecisionShelf.planned,
          action: MyDayDecisionAction.snoozed,
          actionAtUtc: DateTime.utc(2026, 2, 24, 10),
          deferKind: MyDayDecisionDeferKind.snooze,
          fromDayKey: DateTime.utc(2026, 2, 24),
          toDayKey: DateTime.utc(2026, 2, 25),
        ),
      ]);

      final range = DateRange(
        start: DateTime.utc(2026, 2, 20),
        end: DateTime.utc(2026, 2, 28),
      );
      final keepRates = await repo.getKeepRateByShelf(range: range);
      final deferRates = await repo.getDeferRateByShelf(range: range);
      final entityCounts = await repo.getEntityDeferCounts(
        range: range,
        entityType: MyDayDecisionEntityType.task,
      );

      final plannedKeep = keepRates.singleWhere(
        (r) => r.shelf == MyDayDecisionShelf.planned,
      );
      final plannedDefer = deferRates.singleWhere(
        (r) => r.shelf == MyDayDecisionShelf.planned,
      );

      expect(plannedKeep.numerator, 1);
      expect(plannedKeep.denominator, 3);
      expect(plannedDefer.numerator, 2);
      expect(plannedDefer.denominator, 3);
      expect(
        entityCounts.firstWhere((c) => c.entityId == 'task-1').deferCount,
        1,
      );
      expect(
        entityCounts.firstWhere((c) => c.entityId == 'task-2').snoozeCount,
        1,
      );
    });

    testSafe('routine weekday and deferred->completed lag queries', () async {
      final db = createAutoClosingDb();
      final ids = IdGenerator.withUserId('user-1');
      final repo = MyDayDecisionEventRepositoryImpl(driftDb: db, ids: ids);

      await db
          .into(db.projectTable)
          .insert(
            ProjectTableCompanion(
              id: const drift.Value('project-1'),
              name: const drift.Value('P'),
              completed: const drift.Value(false),
            ),
          );
      await db
          .into(db.routinesTable)
          .insert(
            RoutinesTableCompanion.insert(
              id: 'routine-1',
              name: 'Gym',
              projectId: 'project-1',
              periodType: 'week',
              scheduleMode: 'flexible',
              targetCount: 2,
            ),
          );
      await db
          .into(db.routineCompletionsTable)
          .insert(
            RoutineCompletionsTableCompanion.insert(
              id: ids.routineCompletionId(),
              routineId: 'routine-1',
              completedAt: DateTime.utc(2026, 2, 24, 8),
              completedDayLocal: drift.Value(DateTime.utc(2026, 2, 24)),
              completedWeekdayLocal: const drift.Value(2),
            ),
          );
      await db
          .into(db.routineCompletionsTable)
          .insert(
            RoutineCompletionsTableCompanion.insert(
              id: ids.routineCompletionId(),
              routineId: 'routine-1',
              completedAt: DateTime.utc(2026, 2, 26, 8),
              completedDayLocal: drift.Value(DateTime.utc(2026, 2, 26)),
              completedWeekdayLocal: const drift.Value(4),
            ),
          );

      await repo.appendAll([
        MyDayDecisionEvent(
          id: ids.myDayDecisionEventId(),
          dayKeyUtc: DateTime.utc(2026, 2, 24),
          entityType: MyDayDecisionEntityType.task,
          entityId: 'task-1',
          shelf: MyDayDecisionShelf.due,
          action: MyDayDecisionAction.deferred,
          actionAtUtc: DateTime.utc(2026, 2, 24, 8),
        ),
        MyDayDecisionEvent(
          id: ids.myDayDecisionEventId(),
          dayKeyUtc: DateTime.utc(2026, 2, 25),
          entityType: MyDayDecisionEntityType.task,
          entityId: 'task-1',
          shelf: MyDayDecisionShelf.due,
          action: MyDayDecisionAction.completed,
          actionAtUtc: DateTime.utc(2026, 2, 25, 8),
        ),
      ]);

      final range = DateRange(
        start: DateTime.utc(2026, 2, 20),
        end: DateTime.utc(2026, 2, 28),
      );

      final weekdays = await repo.getRoutineTopCompletionWeekdays(range: range);
      final lag = await repo.getDeferredThenCompletedLag(range: range);

      expect(weekdays, isNotEmpty);
      expect(weekdays.first.routineId, 'routine-1');
      expect(weekdays.first.weekdayLocal, anyOf(2, 4));
      expect(lag, hasLength(1));
      expect(lag.first.entityId, 'task-1');
      expect(lag.first.sampleSize, 1);
      expect(lag.first.medianLagHours, closeTo(24, 0.01));
    });
  });
}
