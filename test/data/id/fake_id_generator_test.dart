import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/label.dart' show LabelType;

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

      test('workflowRunId generates sequential IDs', () {
        expect(idGenerator.workflowRunId(), 'workflow-run-0');
        expect(idGenerator.workflowRunId(), 'workflow-run-1');
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
      test('labelId generates based on name and type', () {
        final id = idGenerator.labelId(
          name: 'My Label',
          type: LabelType.label,
        );
        expect(id, 'label-my-label-label');
      });

      test('labelId with value type', () {
        final id = idGenerator.labelId(
          name: 'Priority',
          type: LabelType.value,
        );
        expect(id, 'label-priority-value');
      });

      test('trackerId generates based on name', () {
        final id = idGenerator.trackerId(name: 'Mood');
        expect(id, 'tracker-mood');
      });

      test('taskLabelId generates based on task and label', () {
        final id = idGenerator.taskLabelId(
          taskId: 'task-1',
          labelId: 'label-1',
        );
        expect(id, 'task-label-task-1-label-1');
      });

      test('projectLabelId generates based on project and label', () {
        final id = idGenerator.projectLabelId(
          projectId: 'project-1',
          labelId: 'label-1',
        );
        expect(id, 'project-label-project-1-label-1');
      });

      test('taskCompletionId generates based on task and date', () {
        final id = idGenerator.taskCompletionId(
          taskId: 'task-1',
          occurrenceDate: DateTime(2025, 6, 15),
        );
        expect(id, 'task-completion-task-1-2025-06-15');
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

      test('workflowDefinitionId generates based on name', () {
        final id = idGenerator.workflowDefinitionId(name: 'Morning Review');
        expect(id, 'workflow-def-morning-review');
      });

      test('trackerResponseId generates based on entry and tracker', () {
        final id = idGenerator.trackerResponseId(
          journalEntryId: 'journal-1',
          trackerId: 'tracker-1',
        );
        expect(id, 'tracker-response-journal-1-tracker-1');
      });

      test('dailyTrackerResponseId generates based on tracker and date', () {
        final id = idGenerator.dailyTrackerResponseId(
          trackerId: 'tracker-1',
          responseDate: DateTime(2025, 6, 15),
        );
        expect(id, 'daily-response-tracker-1-2025-06-15');
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

      test('tracks workflowRunId call count', () {
        expect(idGenerator.workflowRunIdCallCount, 0);
        idGenerator.workflowRunId();
        expect(idGenerator.workflowRunIdCallCount, 1);
      });
    });

    group('utilities', () {
      test('reset clears all counters', () {
        idGenerator.taskId();
        idGenerator.projectId();
        idGenerator.journalEntryId();
        idGenerator.workflowRunId();

        idGenerator.reset();

        expect(idGenerator.taskIdCallCount, 0);
        expect(idGenerator.projectIdCallCount, 0);
        expect(idGenerator.journalEntryIdCallCount, 0);
        expect(idGenerator.workflowRunIdCallCount, 0);
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
