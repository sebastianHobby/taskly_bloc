@Tags(['unit'])
library;

import 'package:drift/drift.dart' as drift;
import 'package:taskly_data/db.dart';
import 'package:taskly_data/id.dart';
import 'package:taskly_data/src/features/my_day/repositories/my_day_decision_event_repository_impl.dart';
import 'package:taskly_data/src/features/my_day/repositories/my_day_repository_impl.dart';
import 'package:taskly_domain/my_day.dart';
import 'package:taskly_domain/telemetry.dart';

import '../../../../helpers/test_db.dart';
import '../../../../helpers/test_imports.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  testSafe('setDayPicks writes kept and removed decision events', () async {
    final db = createAutoClosingDb();
    final ids = IdGenerator.withUserId('user-1');
    final decisionRepo = MyDayDecisionEventRepositoryImpl(
      driftDb: db,
      ids: ids,
    );
    final repo = MyDayRepositoryImpl(
      driftDb: db,
      ids: ids,
      decisionEventsRepository: decisionRepo,
    );

    await db
        .into(db.taskTable)
        .insert(
          TaskTableCompanion(
            id: const drift.Value('task-1'),
            name: const drift.Value('T1'),
            completed: const drift.Value(false),
          ),
        );
    await db
        .into(db.taskTable)
        .insert(
          TaskTableCompanion(
            id: const drift.Value('task-2'),
            name: const drift.Value('T2'),
            completed: const drift.Value(false),
          ),
        );

    const context = OperationContext(
      correlationId: 'corr-1',
      feature: 'my_day',
      intent: 'confirm_plan',
      operation: 'my_day.setDayPicks',
      screen: 'plan_my_day',
    );

    await repo.setDayPicks(
      dayKeyUtc: DateTime.utc(2026, 2, 24),
      ritualCompletedAtUtc: DateTime.utc(2026, 2, 24, 7),
      picks: [
        MyDayPick.task(
          taskId: 'task-1',
          bucket: MyDayPickBucket.starts,
          sortIndex: 0,
          pickedAtUtc: DateTime.utc(2026, 2, 24, 7),
        ),
        MyDayPick.task(
          taskId: 'task-2',
          bucket: MyDayPickBucket.due,
          sortIndex: 1,
          pickedAtUtc: DateTime.utc(2026, 2, 24, 7),
        ),
      ],
      context: context,
    );

    await repo.setDayPicks(
      dayKeyUtc: DateTime.utc(2026, 2, 24),
      ritualCompletedAtUtc: DateTime.utc(2026, 2, 24, 8),
      picks: [
        MyDayPick.task(
          taskId: 'task-1',
          bucket: MyDayPickBucket.starts,
          sortIndex: 0,
          pickedAtUtc: DateTime.utc(2026, 2, 24, 8),
        ),
      ],
      context: context,
    );

    final events = await db.select(db.myDayDecisionEventsTable).get();
    final kept = events
        .where((e) => e.action == 'kept')
        .toList(growable: false);
    final removed = events
        .where((e) => e.action == 'removed')
        .toList(growable: false);

    expect(kept.length, 3);
    expect(removed.length, 1);
    expect(removed.single.entityId, 'task-2');
    expect(removed.single.shelf, 'due');
  });
}
