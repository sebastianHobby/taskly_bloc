import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/project_task_counts.dart';

void main() {
  group('ProjectTaskCounts', () {
    test('creates instance with required fields', () {
      final counts = ProjectTaskCounts(
        projectId: 'project-1',
        totalCount: 10,
        completedCount: 5,
      );

      expect(counts.projectId, 'project-1');
      expect(counts.totalCount, 10);
      expect(counts.completedCount, 5);
    });

    group('incompleteCount', () {
      test('calculates incomplete tasks correctly', () {
        final counts = ProjectTaskCounts(
          projectId: 'project-1',
          totalCount: 10,
          completedCount: 3,
        );

        expect(counts.incompleteCount, 7);
      });

      test('returns 0 when all tasks completed', () {
        final counts = ProjectTaskCounts(
          projectId: 'project-1',
          totalCount: 5,
          completedCount: 5,
        );

        expect(counts.incompleteCount, 0);
      });

      test('returns totalCount when no tasks completed', () {
        final counts = ProjectTaskCounts(
          projectId: 'project-1',
          totalCount: 8,
          completedCount: 0,
        );

        expect(counts.incompleteCount, 8);
      });
    });

    group('progressRatio', () {
      test('calculates progress ratio correctly', () {
        final counts = ProjectTaskCounts(
          projectId: 'project-1',
          totalCount: 10,
          completedCount: 3,
        );

        expect(counts.progressRatio, 0.3);
      });

      test('returns 1.0 when all tasks completed', () {
        final counts = ProjectTaskCounts(
          projectId: 'project-1',
          totalCount: 5,
          completedCount: 5,
        );

        expect(counts.progressRatio, 1.0);
      });

      test('returns 0.0 when no tasks completed', () {
        final counts = ProjectTaskCounts(
          projectId: 'project-1',
          totalCount: 8,
          completedCount: 0,
        );

        expect(counts.progressRatio, 0.0);
      });

      test('returns null when no tasks exist', () {
        final counts = ProjectTaskCounts(
          projectId: 'project-1',
          totalCount: 0,
          completedCount: 0,
        );

        expect(counts.progressRatio, isNull);
      });

      test('calculates correct ratio for partial completion', () {
        final counts = ProjectTaskCounts(
          projectId: 'project-1',
          totalCount: 3,
          completedCount: 2,
        );

        expect(counts.progressRatio, closeTo(0.6667, 0.0001));
      });
    });

    group('isComplete', () {
      test('returns true when all tasks completed and tasks exist', () {
        final counts = ProjectTaskCounts(
          projectId: 'project-1',
          totalCount: 5,
          completedCount: 5,
        );

        expect(counts.isComplete, isTrue);
      });

      test('returns false when some tasks incomplete', () {
        final counts = ProjectTaskCounts(
          projectId: 'project-1',
          totalCount: 10,
          completedCount: 5,
        );

        expect(counts.isComplete, isFalse);
      });

      test('returns false when no tasks completed', () {
        final counts = ProjectTaskCounts(
          projectId: 'project-1',
          totalCount: 5,
          completedCount: 0,
        );

        expect(counts.isComplete, isFalse);
      });

      test('returns false when no tasks exist', () {
        final counts = ProjectTaskCounts(
          projectId: 'project-1',
          totalCount: 0,
          completedCount: 0,
        );

        expect(counts.isComplete, isFalse);
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        final original = ProjectTaskCounts(
          projectId: 'project-1',
          totalCount: 10,
          completedCount: 5,
        );

        final updated = original.copyWith(
          completedCount: 8,
        );

        expect(updated.projectId, 'project-1');
        expect(updated.totalCount, 10);
        expect(updated.completedCount, 8);
      });

      test(
        'creates copy without changing fields when no parameters provided',
        () {
          final original = ProjectTaskCounts(
            projectId: 'project-1',
            totalCount: 10,
            completedCount: 5,
          );

          final copy = original.copyWith();

          expect(copy.projectId, original.projectId);
          expect(copy.totalCount, original.totalCount);
          expect(copy.completedCount, original.completedCount);
        },
      );

      test('can update projectId', () {
        final original = ProjectTaskCounts(
          projectId: 'project-1',
          totalCount: 10,
          completedCount: 5,
        );

        final updated = original.copyWith(projectId: 'project-2');

        expect(updated.projectId, 'project-2');
        expect(updated.totalCount, 10);
        expect(updated.completedCount, 5);
      });

      test('can update totalCount', () {
        final original = ProjectTaskCounts(
          projectId: 'project-1',
          totalCount: 10,
          completedCount: 5,
        );

        final updated = original.copyWith(totalCount: 15);

        expect(updated.projectId, 'project-1');
        expect(updated.totalCount, 15);
        expect(updated.completedCount, 5);
      });

      test('can update all fields', () {
        final original = ProjectTaskCounts(
          projectId: 'project-1',
          totalCount: 10,
          completedCount: 5,
        );

        final updated = original.copyWith(
          projectId: 'project-2',
          totalCount: 20,
          completedCount: 15,
        );

        expect(updated.projectId, 'project-2');
        expect(updated.totalCount, 20);
        expect(updated.completedCount, 15);
      });
    });

    group('equality', () {
      test('two instances with same values are equal', () {
        final counts1 = ProjectTaskCounts(
          projectId: 'project-1',
          totalCount: 10,
          completedCount: 5,
        );

        final counts2 = ProjectTaskCounts(
          projectId: 'project-1',
          totalCount: 10,
          completedCount: 5,
        );

        expect(counts1, equals(counts2));
        expect(counts1.hashCode, equals(counts2.hashCode));
      });

      test('two instances with different projectIds are not equal', () {
        final counts1 = ProjectTaskCounts(
          projectId: 'project-1',
          totalCount: 10,
          completedCount: 5,
        );

        final counts2 = ProjectTaskCounts(
          projectId: 'project-2',
          totalCount: 10,
          completedCount: 5,
        );

        expect(counts1, isNot(equals(counts2)));
      });

      test('two instances with different totalCounts are not equal', () {
        final counts1 = ProjectTaskCounts(
          projectId: 'project-1',
          totalCount: 10,
          completedCount: 5,
        );

        final counts2 = ProjectTaskCounts(
          projectId: 'project-1',
          totalCount: 15,
          completedCount: 5,
        );

        expect(counts1, isNot(equals(counts2)));
      });

      test('two instances with different completedCounts are not equal', () {
        final counts1 = ProjectTaskCounts(
          projectId: 'project-1',
          totalCount: 10,
          completedCount: 5,
        );

        final counts2 = ProjectTaskCounts(
          projectId: 'project-1',
          totalCount: 10,
          completedCount: 8,
        );

        expect(counts1, isNot(equals(counts2)));
      });

      test('identical instances are equal', () {
        final counts = ProjectTaskCounts(
          projectId: 'project-1',
          totalCount: 10,
          completedCount: 5,
        );

        expect(counts, equals(counts));
      });
    });

    test('toString returns formatted string', () {
      final counts = ProjectTaskCounts(
        projectId: 'project-1',
        totalCount: 10,
        completedCount: 5,
      );

      final string = counts.toString();

      expect(string, contains('ProjectTaskCounts'));
    });
  });
}
