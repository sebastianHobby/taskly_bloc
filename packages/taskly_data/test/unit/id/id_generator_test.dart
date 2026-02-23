@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:taskly_data/id.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('IdGenerator', () {
    testSafe('v4 ids do not require userId', () async {
      var userIdCalls = 0;
      final gen = IdGenerator(() {
        userIdCalls++;
        throw StateError('no user');
      });

      final id1 = gen.taskId();
      final id2 = gen.taskId();

      expect(id1, isNotEmpty);
      expect(id2, isNotEmpty);
      expect(id1, isNot(id2));
      expect(userIdCalls, 0);
    });

    testSafe('v5 ids require userId lazily', () async {
      var userIdCalls = 0;
      final gen = IdGenerator(() {
        userIdCalls++;
        return 'user-123';
      });

      final id1 = gen.valueId(name: 'Health');
      final id2 = gen.valueId(name: 'Health');
      final id3 = gen.valueId(name: 'Work');

      expect(id1, equals(id2));
      expect(id1, isNot(equals(id3)));
      expect(userIdCalls, greaterThanOrEqualTo(1));
    });

    testSafe('deterministic completion ids vary by date key', () async {
      final gen = IdGenerator.withUserId('u');

      final a = gen.taskCompletionId(
        taskId: 't1',
        occurrenceDate: DateTime(2025, 1, 10, 12, 30),
      );
      final b = gen.taskCompletionId(
        taskId: 't1',
        occurrenceDate: DateTime(2025, 1, 10, 1),
      );
      final c = gen.taskCompletionId(taskId: 't1', occurrenceDate: null);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    testSafe('table strategy registry matches expected sets', () async {
      expect(IdGenerator.isDeterministic('values'), isTrue);
      expect(IdGenerator.isDeterministic('tasks'), isFalse);

      expect(IdGenerator.isRandom('tasks'), isTrue);
      expect(IdGenerator.isRandom('values'), isFalse);
    });

    testSafe('covers v4 id factories', () async {
      final gen = IdGenerator.withUserId('u1');

      final ids = <String>[
        gen.taskId(),
        gen.projectId(),
        gen.journalEntryId(),
        gen.trackerGroupId(),
        gen.userProfileId(),
        gen.pendingNotificationId(),
        gen.syncIssueId(),
        gen.analyticsCorrelationId(),
        gen.analyticsInsightId(),
        gen.taskSnoozeEventId(),
        gen.routineId(),
        gen.routineCompletionId(),
        gen.routineSkipId(),
        gen.taskChecklistItemId(),
        gen.routineChecklistItemId(),
        gen.checklistEventId(),
        gen.trackerEventId(),
        gen.attentionResolutionId(),
      ];

      expect(ids.every((id) => id.isNotEmpty), isTrue);
      expect(ids.toSet().length, ids.length);
    });

    testSafe('covers deterministic id factories', () async {
      final gen = IdGenerator.withUserId('user-1');
      final day = DateTime.utc(2026, 2, 1);

      final valueId = gen.valueId(name: 'Health');
      expect(gen.valueId(name: 'Health'), valueId);
      expect(gen.valueId(name: 'Career'), isNot(valueId));

      expect(
        gen.trackerDefinitionId(name: 'Mood'),
        gen.trackerDefinitionId(name: 'Mood'),
      );
      expect(
        gen.trackerPreferenceId(trackerId: 't1'),
        gen.trackerPreferenceId(trackerId: 't1'),
      );
      expect(
        gen.trackerDefinitionChoiceId(trackerId: 't1', choiceKey: 'good'),
        gen.trackerDefinitionChoiceId(trackerId: 't1', choiceKey: 'good'),
      );

      expect(
        gen.projectCompletionId(projectId: 'p1', occurrenceDate: day),
        gen.projectCompletionId(
          projectId: 'p1',
          occurrenceDate: DateTime.utc(2026, 2, 1, 23, 59),
        ),
      );
      expect(
        gen.taskRecurrenceExceptionId(taskId: 't1', originalDate: day),
        gen.taskRecurrenceExceptionId(
          taskId: 't1',
          originalDate: DateTime.utc(2026, 2, 1, 10),
        ),
      );
      expect(
        gen.projectRecurrenceExceptionId(projectId: 'p1', originalDate: day),
        gen.projectRecurrenceExceptionId(
          projectId: 'p1',
          originalDate: DateTime.utc(2026, 2, 1, 10),
        ),
      );
      expect(
        gen.screenDefinitionId(screenKey: 'inbox'),
        gen.screenDefinitionId(screenKey: 'inbox'),
      );
      expect(
        gen.analyticsSnapshotId(
          entityType: 'value',
          entityId: 'v1',
          snapshotDate: day,
        ),
        gen.analyticsSnapshotId(
          entityType: 'value',
          entityId: 'v1',
          snapshotDate: DateTime.utc(2026, 2, 1, 22),
        ),
      );
      expect(gen.myDayDayId(dayUtc: day), gen.myDayDayId(dayUtc: day));
      expect(
        gen.myDayPickId(dayId: 'd1', targetType: 'task', targetId: 't1'),
        gen.myDayPickId(dayId: 'd1', targetType: 'task', targetId: 't1'),
      );
      expect(
        gen.attentionRuleId(ruleKey: 'stale'),
        gen.attentionRuleId(ruleKey: 'stale'),
      );
      expect(
        gen.projectAnchorStateIdForProject(projectId: 'p1'),
        gen.projectAnchorStateIdForProject(projectId: 'p1'),
      );
      expect(
        gen.taskChecklistItemStateId(
          taskId: 't1',
          checklistItemId: 'c1',
          occurrenceDate: day,
        ),
        gen.taskChecklistItemStateId(
          taskId: 't1',
          checklistItemId: 'c1',
          occurrenceDate: DateTime.utc(2026, 2, 1, 5),
        ),
      );
      expect(
        gen.routineChecklistItemStateId(
          routineId: 'r1',
          checklistItemId: 'c1',
          periodType: 'week',
          windowKey: day,
        ),
        gen.routineChecklistItemStateId(
          routineId: 'r1',
          checklistItemId: 'c1',
          periodType: 'week',
          windowKey: DateTime.utc(2026, 2, 1, 5),
        ),
      );
      expect(
        gen.valueWeeklyRatingId(valueId: 'v1', weekStartUtc: day),
        gen.valueWeeklyRatingId(
          valueId: 'v1',
          weekStartUtc: DateTime.utc(2026, 2, 1, 7),
        ),
      );
    });
  });
}
