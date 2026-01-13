import 'package:flutter_test/flutter_test.dart';

import '../../mocks/fake_id_generator.dart';

void main() {
  group('FakeIdGenerator', () {
    late FakeIdGenerator idGenerator;

    setUp(() {
      idGenerator = FakeIdGenerator();
    });

    group('v4 random IDs', () {
      test('taskId generates sequential IDs', () {
        expect(idGenerator.taskId(), 'task-0');
        expect(idGenerator.taskId(), 'task-1');
        expect(idGenerator.taskId(), 'task-2');
      });

      test('projectId generates sequential IDs', () {
        expect(idGenerator.projectId(), 'project-0');
        expect(idGenerator.projectId(), 'project-1');
      });

      test('journalEntryId generates sequential IDs', () {
        expect(idGenerator.journalEntryId(), 'journal-0');
        expect(idGenerator.journalEntryId(), 'journal-1');
      });

      test('userProfileId generates sequential IDs', () {
        expect(idGenerator.userProfileId(), 'user-profile-0');
        expect(idGenerator.userProfileId(), 'user-profile-1');
      });

      test('pendingNotificationId generates sequential IDs', () {
        expect(idGenerator.pendingNotificationId(), 'notification-0');
        expect(idGenerator.pendingNotificationId(), 'notification-1');
      });

      test('analyticsCorrelationId generates sequential IDs', () {
        expect(idGenerator.analyticsCorrelationId(), 'correlation-0');
        expect(idGenerator.analyticsCorrelationId(), 'correlation-1');
      });

      test('analyticsInsightId generates sequential IDs', () {
        expect(idGenerator.analyticsInsightId(), 'insight-0');
        expect(idGenerator.analyticsInsightId(), 'insight-1');
      });
    });

    group('v5 deterministic IDs', () {
      test('valueId generates based on name', () {
        final id = idGenerator.valueId(
          name: 'My Value',
        );
        expect(id, 'value-my-value');
      });

      test('trackerDefinitionId generates based on name', () {
        final id = idGenerator.trackerDefinitionId(name: 'Mood');
        expect(id, 'tracker-def-mood');
      });

      test('trackerPreferenceId generates based on trackerId', () {
        final id = idGenerator.trackerPreferenceId(trackerId: 'tracker-1');
        expect(id, 'tracker-pref-tracker-1');
      });

      test(
        'trackerDefinitionChoiceId generates based on trackerId and key',
        () {
          final id = idGenerator.trackerDefinitionChoiceId(
            trackerId: 'tracker-1',
            choiceKey: 'good',
          );
          expect(id, 'tracker-choice-tracker-1-good');
        },
      );

      test('taskValueId generates based on task and value', () {
        final id = idGenerator.taskValueId(
          taskId: 'task-1',
          valueId: 'value-1',
        );
        expect(id, 'task-value-task-1-value-1');
      });

      test('projectValueId generates based on project and value', () {
        final id = idGenerator.projectValueId(
          projectId: 'project-1',
          valueId: 'value-1',
        );
        expect(id, 'project-value-project-1-value-1');
      });

      test('taskValueId generates based on task and value', () {
        final id = idGenerator.taskValueId(
          taskId: 'task-1',
          valueId: 'value-1',
        );
        expect(id, 'task-value-task-1-value-1');
      });

      test('projectValueId generates based on project and value', () {
        final id = idGenerator.projectValueId(
          projectId: 'project-1',
          valueId: 'value-1',
        );
        expect(id, 'project-value-project-1-value-1');
      });

      test('taskCompletionId with null date', () {
        final id = idGenerator.taskCompletionId(
          taskId: 'task-1',
          occurrenceDate: null,
        );
        expect(id, 'task-completion-task-1-null');
      });

      test('projectCompletionId generates based on project and date', () {
        final id = idGenerator.projectCompletionId(
          projectId: 'project-1',
          occurrenceDate: DateTime(2025, 6, 15),
        );
        expect(id, 'project-completion-project-1-2025-06-15');
      });

      test('taskRecurrenceExceptionId generates based on task and date', () {
        final id = idGenerator.taskRecurrenceExceptionId(
          taskId: 'task-1',
          originalDate: DateTime(2025, 6, 15),
        );
        expect(id, 'task-exception-task-1-2025-06-15');
      });

      test(
        'projectRecurrenceExceptionId generates based on project and date',
        () {
          final id = idGenerator.projectRecurrenceExceptionId(
            projectId: 'project-1',
            originalDate: DateTime(2025, 6, 15),
          );
          expect(id, 'project-exception-project-1-2025-06-15');
        },
      );

      test('screenDefinitionId generates based on screen key', () {
        final id = idGenerator.screenDefinitionId(screenKey: 'inbox');
        expect(id, 'screen-inbox');
      });

      test('trackerEventId generates sequential IDs', () {
        expect(idGenerator.trackerEventId(), 'tracker-event-0');
        expect(idGenerator.trackerEventId(), 'tracker-event-1');
      });

      test('analyticsSnapshotId generates based on entity and date', () {
        final id = idGenerator.analyticsSnapshotId(
          entityType: 'task',
          entityId: 'task-1',
          snapshotDate: DateTime(2025, 6, 15),
        );
        expect(id, 'snapshot-task-task-1-2025-06-15');
      });
    });

    group('userId', () {
      test('returns default test-user', () {
        expect(idGenerator.userId, 'test-user');
      });

      test('accepts custom userId in constructor', () {
        final customGenerator = FakeIdGenerator('custom-user-123');
        expect(customGenerator.userId, 'custom-user-123');
      });
    });

    group('call counts', () {
      test('tracks taskId call count', () {
        expect(idGenerator.taskIdCallCount, 0);
        idGenerator.taskId();
        expect(idGenerator.taskIdCallCount, 1);
        idGenerator.taskId();
        expect(idGenerator.taskIdCallCount, 2);
      });

      test('tracks projectId call count', () {
        expect(idGenerator.projectIdCallCount, 0);
        idGenerator.projectId();
        expect(idGenerator.projectIdCallCount, 1);
      });

      test('tracks journalEntryId call count', () {
        expect(idGenerator.journalEntryIdCallCount, 0);
        idGenerator.journalEntryId();
        expect(idGenerator.journalEntryIdCallCount, 1);
      });
    });

    group('utilities', () {
      test('reset clears all counters', () {
        idGenerator.taskId();
        idGenerator.projectId();
        idGenerator.journalEntryId();

        idGenerator.reset();

        expect(idGenerator.taskIdCallCount, 0);
        expect(idGenerator.projectIdCallCount, 0);
        expect(idGenerator.journalEntryIdCallCount, 0);
      });

      test('peekNextTaskId shows next ID without incrementing', () {
        expect(idGenerator.peekNextTaskId(), 'task-0');
        expect(idGenerator.peekNextTaskId(), 'task-0');
        expect(idGenerator.taskIdCallCount, 0);

        idGenerator.taskId();

        expect(idGenerator.peekNextTaskId(), 'task-1');
        expect(idGenerator.taskIdCallCount, 1);
      });

      test('peekNextProjectId shows next ID without incrementing', () {
        expect(idGenerator.peekNextProjectId(), 'project-0');
        expect(idGenerator.peekNextProjectId(), 'project-0');
        expect(idGenerator.projectIdCallCount, 0);
      });
    });
  });
}
