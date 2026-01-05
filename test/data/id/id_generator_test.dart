import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/id/id_generator.dart';

void main() {
  group('IdGenerator', () {
    late IdGenerator idGenerator;

    setUp(() {
      idGenerator = IdGenerator.withUserId('test-user-123');
    });

    group('lazy userId evaluation', () {
      test('can construct with getter that throws', () {
        // Should NOT throw at construction time
        final lazyGen = IdGenerator(() {
          throw StateError('Not authenticated');
        });

        // V4 methods should work without userId
        expect(lazyGen.taskId().length, 36);
        expect(lazyGen.projectId().length, 36);
      });

      test('throws when v5 method called without authenticated user', () {
        final lazyGen = IdGenerator(() {
          throw StateError('IdGenerator requires authenticated user');
        });

        // V5 methods require userId, should throw
        expect(
          () => lazyGen.valueId(name: 'Test'),
          throwsStateError,
        );
        expect(
          () => lazyGen.screenDefinitionId(screenKey: 'inbox'),
          throwsStateError,
        );
      });

      test('v5 methods work when user becomes authenticated', () {
        String? currentUserId;
        final lazyGen = IdGenerator(() {
          if (currentUserId == null) {
            throw StateError('IdGenerator requires authenticated user');
          }
          return currentUserId;
        });

        // Should throw before authentication
        expect(
          () => lazyGen.valueId(name: 'Test'),
          throwsStateError,
        );

        // Simulate authentication
        currentUserId = 'user-123';

        // Should work after authentication
        final id = lazyGen.valueId(name: 'Test');
        expect(id.length, 36);
      });
    });

    group('userId', () {
      test('returns the userId passed to constructor', () {
        expect(idGenerator.userId, 'test-user-123');
      });

      test('different users get different generators', () {
        final user1 = IdGenerator.withUserId('user-1');
        final user2 = IdGenerator.withUserId('user-2');
        expect(user1.userId, 'user-1');
        expect(user2.userId, 'user-2');
      });
    });

    group('table strategy registry', () {
      group('v5 tables (deterministic)', () {
        test('isDeterministic returns true for v5 tables', () {
          expect(IdGenerator.isDeterministic('values'), isTrue);
          expect(IdGenerator.isDeterministic('trackers'), isTrue);
          expect(IdGenerator.isDeterministic('task_values'), isTrue);
          expect(IdGenerator.isDeterministic('project_values'), isTrue);
          expect(
            IdGenerator.isDeterministic('task_completion_history'),
            isTrue,
          );
          expect(
            IdGenerator.isDeterministic('project_completion_history'),
            isTrue,
          );
          expect(
            IdGenerator.isDeterministic('task_recurrence_exceptions'),
            isTrue,
          );
          expect(
            IdGenerator.isDeterministic('project_recurrence_exceptions'),
            isTrue,
          );
          expect(IdGenerator.isDeterministic('tracker_responses'), isTrue);
          expect(
            IdGenerator.isDeterministic('daily_tracker_responses'),
            isTrue,
          );
          expect(IdGenerator.isDeterministic('screen_definitions'), isTrue);
          expect(IdGenerator.isDeterministic('workflow_definitions'), isTrue);
          expect(IdGenerator.isDeterministic('analytics_snapshots'), isTrue);
        });

        test('isDeterministic returns false for v4 tables', () {
          expect(IdGenerator.isDeterministic('tasks'), isFalse);
          expect(IdGenerator.isDeterministic('projects'), isFalse);
        });

        test('isDeterministic returns false for unknown tables', () {
          expect(IdGenerator.isDeterministic('unknown_table'), isFalse);
        });
      });

      group('v4 tables (random)', () {
        test('isRandom returns true for v4 tables', () {
          expect(IdGenerator.isRandom('tasks'), isTrue);
          expect(IdGenerator.isRandom('projects'), isTrue);
          expect(IdGenerator.isRandom('journal_entries'), isTrue);
          expect(IdGenerator.isRandom('workflows'), isTrue);
          expect(IdGenerator.isRandom('user_profiles'), isTrue);
          expect(IdGenerator.isRandom('pending_notifications'), isTrue);
          expect(IdGenerator.isRandom('analytics_correlations'), isTrue);
          expect(IdGenerator.isRandom('analytics_insights'), isTrue);
        });

        test('isRandom returns false for v5 tables', () {
          expect(IdGenerator.isRandom('labels'), isFalse);
          expect(IdGenerator.isRandom('trackers'), isFalse);
        });

        test('isRandom returns false for unknown tables', () {
          expect(IdGenerator.isRandom('unknown_table'), isFalse);
        });
      });

      test('v4Tables and v5Tables do not overlap', () {
        final intersection = IdGenerator.v4Tables.intersection(
          IdGenerator.v5Tables,
        );
        expect(intersection, isEmpty);
      });
    });

    group('v4 random IDs', () {
      test('taskId returns unique UUID format', () {
        final id1 = idGenerator.taskId();
        final id2 = idGenerator.taskId();

        expect(id1, isNotEmpty);
        expect(id2, isNotEmpty);
        expect(id1, isNot(equals(id2)));
        // UUID v4 format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
        expect(id1.length, 36);
        expect(id1.contains('-'), isTrue);
      });

      test('projectId returns unique UUID', () {
        final id1 = idGenerator.projectId();
        final id2 = idGenerator.projectId();

        expect(id1, isNot(equals(id2)));
        expect(id1.length, 36);
      });

      test('journalEntryId returns unique UUID', () {
        final id1 = idGenerator.journalEntryId();
        final id2 = idGenerator.journalEntryId();

        expect(id1, isNot(equals(id2)));
        expect(id1.length, 36);
      });

      test('workflowRunId returns unique UUID', () {
        final id1 = idGenerator.workflowRunId();
        final id2 = idGenerator.workflowRunId();

        expect(id1, isNot(equals(id2)));
        expect(id1.length, 36);
      });

      test('userProfileId returns unique UUID', () {
        final id1 = idGenerator.userProfileId();
        final id2 = idGenerator.userProfileId();

        expect(id1, isNot(equals(id2)));
        expect(id1.length, 36);
      });

      test('pendingNotificationId returns unique UUID', () {
        final id1 = idGenerator.pendingNotificationId();
        final id2 = idGenerator.pendingNotificationId();

        expect(id1, isNot(equals(id2)));
        expect(id1.length, 36);
      });

      test('analyticsCorrelationId returns unique UUID', () {
        final id1 = idGenerator.analyticsCorrelationId();
        final id2 = idGenerator.analyticsCorrelationId();

        expect(id1, isNot(equals(id2)));
        expect(id1.length, 36);
      });

      test('analyticsInsightId returns unique UUID', () {
        final id1 = idGenerator.analyticsInsightId();
        final id2 = idGenerator.analyticsInsightId();

        expect(id1, isNot(equals(id2)));
        expect(id1.length, 36);
      });
    });

    group('v5 deterministic IDs', () {
      group('valueId', () {
        test('generates deterministic ID from name', () {
          final id1 = idGenerator.valueId(
            name: 'Priority',
          );
          final id2 = idGenerator.valueId(
            name: 'Priority',
          );

          expect(id1, equals(id2));
          expect(id1.length, 36);
        });

        test('different names produce different IDs', () {
          final id1 = idGenerator.valueId(
            name: 'Priority',
          );
          final id2 = idGenerator.valueId(
            name: 'Status',
          );

          expect(id1, isNot(equals(id2)));
        });

        test('different users produce different IDs', () {
          final gen1 = IdGenerator.withUserId('user-1');
          final gen2 = IdGenerator.withUserId('user-2');

          final id1 = gen1.valueId(name: 'Priority');
          final id2 = gen2.valueId(name: 'Priority');

          expect(id1, isNot(equals(id2)));
        });
      });

      group('trackerId', () {
        test('generates deterministic ID from name', () {
          final id1 = idGenerator.trackerId(name: 'Mood');
          final id2 = idGenerator.trackerId(name: 'Mood');

          expect(id1, equals(id2));
          expect(id1.length, 36);
        });

        test('different names produce different IDs', () {
          final id1 = idGenerator.trackerId(name: 'Mood');
          final id2 = idGenerator.trackerId(name: 'Energy');

          expect(id1, isNot(equals(id2)));
        });
      });

      group('taskLabelId', () {
        test('generates deterministic ID from task and label', () {
          final id1 = idGenerator.taskLabelId(
            taskId: 'task-1',
            labelId: 'label-1',
          );
          final id2 = idGenerator.taskLabelId(
            taskId: 'task-1',
            labelId: 'label-1',
          );

          expect(id1, equals(id2));
          expect(id1.length, 36);
        });

        test('different tasks produce different IDs', () {
          final id1 = idGenerator.taskLabelId(
            taskId: 'task-1',
            labelId: 'label-1',
          );
          final id2 = idGenerator.taskLabelId(
            taskId: 'task-2',
            labelId: 'label-1',
          );
          expect(id1, isNot(equals(id2)));
        });
      });

      group('taskValueId', () {
        test('generates deterministic ID from task and value', () {
          final id1 = idGenerator.taskValueId(
            taskId: 'task-1',
            valueId: 'value-1',
          );
          final id2 = idGenerator.taskValueId(
            taskId: 'task-1',
            valueId: 'value-1',
          );

          expect(id1, equals(id2));
          expect(id1.length, 36);
        });

        test('different tasks produce different IDs', () {
          final id1 = idGenerator.taskValueId(
            taskId: 'task-1',
            valueId: 'value-1',
          );
          final id2 = idGenerator.taskValueId(
            taskId: 'task-2',
            valueId: 'value-1',
          );

          expect(id1, isNot(equals(id2)));
        });

        test('same across different users (no user in path)', () {
          final gen1 = IdGenerator.withUserId('user-1');
          final gen2 = IdGenerator.withUserId('user-2');

          final id1 = gen1.taskValueId(taskId: 'task-1', valueId: 'value-1');
          final id2 = gen2.taskValueId(taskId: 'task-1', valueId: 'value-1');

          // taskValueId uses _v5NoUser, so same IDs for same inputs
          expect(id1, equals(id2));
        });
      });

      group('projectValueId', () {
        test('generates deterministic ID from project and value', () {
          final id1 = idGenerator.projectValueId(
            projectId: 'project-1',
            valueId: 'value-1',
          );
          final id2 = idGenerator.projectValueId(
            projectId: 'project-1',
            valueId: 'value-1',
          );

          expect(id1, equals(id2));
        });

        test('different dates produce different IDs', () {
          final id1 = idGenerator.taskCompletionId(
            taskId: 'task-1',
            occurrenceDate: DateTime(2025, 6, 15),
          );
          final id2 = idGenerator.taskCompletionId(
            taskId: 'task-1',
            occurrenceDate: DateTime(2025, 6, 16),
          );

          expect(id1, isNot(equals(id2)));
        });

        test('handles null occurrenceDate for non-repeating tasks', () {
          final id1 = idGenerator.taskCompletionId(
            taskId: 'task-1',
            occurrenceDate: null,
          );
          final id2 = idGenerator.taskCompletionId(
            taskId: 'task-1',
            occurrenceDate: null,
          );

          expect(id1, equals(id2));
        });

        test('null date differs from actual date', () {
          final id1 = idGenerator.taskCompletionId(
            taskId: 'task-1',
            occurrenceDate: null,
          );
          final id2 = idGenerator.taskCompletionId(
            taskId: 'task-1',
            occurrenceDate: DateTime(2025, 6, 15),
          );

          expect(id1, isNot(equals(id2)));
        });
      });

      group('projectCompletionId', () {
        test('generates deterministic ID from project and date', () {
          final date = DateTime(2025, 6, 15);
          final id1 = idGenerator.projectCompletionId(
            projectId: 'project-1',
            occurrenceDate: date,
          );
          final id2 = idGenerator.projectCompletionId(
            projectId: 'project-1',
            occurrenceDate: date,
          );

          expect(id1, equals(id2));
        });
      });

      group('taskRecurrenceExceptionId', () {
        test('generates deterministic ID from task and original date', () {
          final date = DateTime(2025, 6, 15);
          final id1 = idGenerator.taskRecurrenceExceptionId(
            taskId: 'task-1',
            originalDate: date,
          );
          final id2 = idGenerator.taskRecurrenceExceptionId(
            taskId: 'task-1',
            originalDate: date,
          );

          expect(id1, equals(id2));
        });
      });

      group('projectRecurrenceExceptionId', () {
        test('generates deterministic ID from project and original date', () {
          final date = DateTime(2025, 6, 15);
          final id1 = idGenerator.projectRecurrenceExceptionId(
            projectId: 'project-1',
            originalDate: date,
          );
          final id2 = idGenerator.projectRecurrenceExceptionId(
            projectId: 'project-1',
            originalDate: date,
          );

          expect(id1, equals(id2));
        });
      });

      group('trackerResponseId', () {
        test('generates deterministic ID from journal and tracker', () {
          final id1 = idGenerator.trackerResponseId(
            journalEntryId: 'journal-1',
            trackerId: 'tracker-1',
          );
          final id2 = idGenerator.trackerResponseId(
            journalEntryId: 'journal-1',
            trackerId: 'tracker-1',
          );

          expect(id1, equals(id2));
        });
      });

      group('dailyTrackerResponseId', () {
        test('generates deterministic ID from tracker and date', () {
          final date = DateTime(2025, 6, 15);
          final id1 = idGenerator.dailyTrackerResponseId(
            trackerId: 'tracker-1',
            responseDate: date,
          );
          final id2 = idGenerator.dailyTrackerResponseId(
            trackerId: 'tracker-1',
            responseDate: date,
          );

          expect(id1, equals(id2));
        });

        test('includes user in path (different users = different IDs)', () {
          final gen1 = IdGenerator.withUserId('user-1');
          final gen2 = IdGenerator.withUserId('user-2');
          final date = DateTime(2025, 6, 15);

          final id1 = gen1.dailyTrackerResponseId(
            trackerId: 'tracker-1',
            responseDate: date,
          );
          final id2 = gen2.dailyTrackerResponseId(
            trackerId: 'tracker-1',
            responseDate: date,
          );

          expect(id1, isNot(equals(id2)));
        });
      });

      group('screenDefinitionId', () {
        test('generates deterministic ID from screen key', () {
          final id1 = idGenerator.screenDefinitionId(screenKey: 'inbox');
          final id2 = idGenerator.screenDefinitionId(screenKey: 'inbox');

          expect(id1, equals(id2));
        });
      });

      group('workflowDefinitionId', () {
        test('generates deterministic ID from name', () {
          final id1 = idGenerator.workflowDefinitionId(name: 'Morning Review');
          final id2 = idGenerator.workflowDefinitionId(name: 'Morning Review');

          expect(id1, equals(id2));
        });

        test('normalizes name (case insensitive)', () {
          final id1 = idGenerator.workflowDefinitionId(name: 'Morning Review');
          final id2 = idGenerator.workflowDefinitionId(name: 'morning review');

          expect(id1, equals(id2));
        });

        test('normalizes whitespace', () {
          final id1 = idGenerator.workflowDefinitionId(name: 'Morning  Review');
          final id2 = idGenerator.workflowDefinitionId(name: 'Morning Review');

          expect(id1, equals(id2));
        });

        test('trims whitespace', () {
          final id1 = idGenerator.workflowDefinitionId(
            name: '  Morning Review  ',
          );
          final id2 = idGenerator.workflowDefinitionId(name: 'Morning Review');

          expect(id1, equals(id2));
        });
      });

      group('analyticsSnapshotId', () {
        test('generates deterministic ID from entity and date', () {
          final date = DateTime(2025, 6, 15);
          final id1 = idGenerator.analyticsSnapshotId(
            entityType: 'task',
            entityId: 'task-1',
            snapshotDate: date,
          );
          final id2 = idGenerator.analyticsSnapshotId(
            entityType: 'task',
            entityId: 'task-1',
            snapshotDate: date,
          );

          expect(id1, equals(id2));
        });

        test('different entity types produce different IDs', () {
          final date = DateTime(2025, 6, 15);
          final id1 = idGenerator.analyticsSnapshotId(
            entityType: 'task',
            entityId: 'entity-1',
            snapshotDate: date,
          );
          final id2 = idGenerator.analyticsSnapshotId(
            entityType: 'project',
            entityId: 'entity-1',
            snapshotDate: date,
          );

          expect(id1, isNot(equals(id2)));
        });
      });
    });
  });
}
