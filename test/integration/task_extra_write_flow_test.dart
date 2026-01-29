@Tags(['integration'])
library;

import 'dart:convert';

import 'package:taskly_data/db.dart';
import 'package:taskly_data/repositories.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/telemetry.dart';
import 'package:taskly_domain/time.dart';

import '../helpers/test_imports.dart';
import '../helpers/test_db.dart';
import '../mocks/fake_id_generator.dart';
import '../mocks/repository_mocks.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  testSafe(
    'task repository setPinned and setMyDaySnoozedUntil persist updates',
    () async {
      final db = createTestDb();
      addTearDown(() => closeTestDb(db));

      final clock = _FixedClock(DateTime.utc(2025, 1, 15, 12));
      final idGenerator = FakeIdGenerator('user-1');
      final expander = MockOccurrenceStreamExpanderContract();
      final writeHelper = MockOccurrenceWriteHelperContract();
      final contextFactory = TestOperationContextFactory();

      final taskRepository = TaskRepository(
        driftDb: db,
        occurrenceExpander: expander,
        occurrenceWriteHelper: writeHelper,
        idGenerator: idGenerator,
        clock: clock,
      );

      await taskRepository.create(
        name: 'Task A',
        completed: false,
      );

      final taskRow = await db.select(db.taskTable).getSingle();

      final pinContext = contextFactory.create(
        feature: 'tasks',
        intent: 'test',
        operation: 'tasks.pin',
      );
      await taskRepository.setPinned(
        id: taskRow.id,
        isPinned: true,
        context: pinContext,
      );

      final pinnedRow = await db.select(db.taskTable).getSingle();
      expect(pinnedRow.isPinned, isTrue);
      final pinMeta =
          jsonDecode(pinnedRow.psMetadata ?? '{}') as Map<String, dynamic>;
      expect(pinMeta['cid'], pinContext.correlationId);

      final snoozeContext = contextFactory.create(
        feature: 'tasks',
        intent: 'test',
        operation: 'tasks.snooze',
      );
      final snoozeUntil = DateTime.utc(2025, 1, 20);
      await taskRepository.setMyDaySnoozedUntil(
        id: taskRow.id,
        untilUtc: snoozeUntil,
        context: snoozeContext,
      );

      final snoozedRow = await db.select(db.taskTable).getSingle();
      expect(snoozedRow.myDaySnoozedUntilUtc, snoozeUntil);

      final snoozeEvent = await db.select(db.taskSnoozeEventsTable).getSingle();
      final snoozeMeta =
          jsonDecode(snoozeEvent.psMetadata ?? '{}') as Map<String, dynamic>;
      expect(snoozeMeta['cid'], snoozeContext.correlationId);
    },
  );
}

final class _FixedClock implements Clock {
  _FixedClock(this._nowUtc);

  final DateTime _nowUtc;

  @override
  DateTime nowLocal() => _nowUtc.toLocal();

  @override
  DateTime nowUtc() => _nowUtc;
}
