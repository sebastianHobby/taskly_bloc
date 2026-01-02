import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/project_task_counts.dart';

void main() {
  group('ProjectTaskCounts', () {
    group('constructor', () {
      test('creates with required parameters', () {
        const counts = ProjectTaskCounts(
          projectId: 'project-123',
          totalCount: 10,
          completedCount: 5,
        );

        expect(counts.projectId, 'project-123');
        expect(counts.totalCount, 10);
        expect(counts.completedCount, 5);
      });
    });

    group('incompleteCount', () {
      test('returns difference between total and completed', () {
        const counts = ProjectTaskCounts(
          projectId: 'project-123',
          totalCount: 10,
          completedCount: 3,
        );

        expect(counts.incompleteCount, 7);
      });

      test('returns 0 when all completed', () {
        const counts = ProjectTaskCounts(
          projectId: 'project-123',
          totalCount: 5,
          completedCount: 5,
        );

        expect(counts.incompleteCount, 0);
      });

      test('returns total when none completed', () {
        const counts = ProjectTaskCounts(
          projectId: 'project-123',
          totalCount: 8,
          completedCount: 0,
        );

        expect(counts.incompleteCount, 8);
      });
    });

    group('progressRatio', () {
      test('returns null when no tasks', () {
        const counts = ProjectTaskCounts(
          projectId: 'project-123',
          totalCount: 0,
          completedCount: 0,
        );

        expect(counts.progressRatio, isNull);
      });

      test('returns 0.0 when none completed', () {
        const counts = ProjectTaskCounts(
          projectId: 'project-123',
          totalCount: 10,
          completedCount: 0,
        );

        expect(counts.progressRatio, 0.0);
      });

      test('returns 1.0 when all completed', () {
        const counts = ProjectTaskCounts(
          projectId: 'project-123',
          totalCount: 5,
          completedCount: 5,
        );

        expect(counts.progressRatio, 1.0);
      });

      test('returns correct ratio for partial completion', () {
        const counts = ProjectTaskCounts(
          projectId: 'project-123',
          totalCount: 10,
          completedCount: 7,
        );

        expect(counts.progressRatio, 0.7);
      });

      test('returns 0.5 for half completed', () {
        const counts = ProjectTaskCounts(
          projectId: 'project-123',
          totalCount: 8,
          completedCount: 4,
        );

        expect(counts.progressRatio, 0.5);
      });
    });

    group('isComplete', () {
      test('returns false when no tasks', () {
        const counts = ProjectTaskCounts(
          projectId: 'project-123',
          totalCount: 0,
          completedCount: 0,
        );

        expect(counts.isComplete, false);
      });

      test('returns false when incomplete tasks remain', () {
        const counts = ProjectTaskCounts(
          projectId: 'project-123',
          totalCount: 10,
          completedCount: 9,
        );

        expect(counts.isComplete, false);
      });

      test('returns true when all tasks completed', () {
        const counts = ProjectTaskCounts(
          projectId: 'project-123',
          totalCount: 5,
          completedCount: 5,
        );

        expect(counts.isComplete, true);
      });
    });

    group('copyWith', () {
      const original = ProjectTaskCounts(
        projectId: 'project-123',
        totalCount: 10,
        completedCount: 5,
      );

      test('updates projectId only', () {
        final copy = original.copyWith(projectId: 'new-project');

        expect(copy.projectId, 'new-project');
        expect(copy.totalCount, original.totalCount);
        expect(copy.completedCount, original.completedCount);
      });

      test('updates totalCount only', () {
        final copy = original.copyWith(totalCount: 20);

        expect(copy.projectId, original.projectId);
        expect(copy.totalCount, 20);
        expect(copy.completedCount, original.completedCount);
      });

      test('updates completedCount only', () {
        final copy = original.copyWith(completedCount: 8);

        expect(copy.projectId, original.projectId);
        expect(copy.totalCount, original.totalCount);
        expect(copy.completedCount, 8);
      });

      test('updates multiple fields', () {
        final copy = original.copyWith(
          totalCount: 15,
          completedCount: 10,
        );

        expect(copy.totalCount, 15);
        expect(copy.completedCount, 10);
      });

      test('returns equivalent when no parameters', () {
        final copy = original.copyWith();

        expect(copy, original);
      });
    });

    group('equality', () {
      test('equal instances are equal', () {
        const a = ProjectTaskCounts(
          projectId: 'project-123',
          totalCount: 10,
          completedCount: 5,
        );
        const b = ProjectTaskCounts(
          projectId: 'project-123',
          totalCount: 10,
          completedCount: 5,
        );

        expect(a, b);
        expect(a.hashCode, b.hashCode);
      });

      test('different projectId produces different instance', () {
        const a = ProjectTaskCounts(
          projectId: 'project-123',
          totalCount: 10,
          completedCount: 5,
        );
        const b = ProjectTaskCounts(
          projectId: 'project-456',
          totalCount: 10,
          completedCount: 5,
        );

        expect(a, isNot(b));
      });

      test('different totalCount produces different instance', () {
        const a = ProjectTaskCounts(
          projectId: 'project-123',
          totalCount: 10,
          completedCount: 5,
        );
        const b = ProjectTaskCounts(
          projectId: 'project-123',
          totalCount: 15,
          completedCount: 5,
        );

        expect(a, isNot(b));
      });

      test('different completedCount produces different instance', () {
        const a = ProjectTaskCounts(
          projectId: 'project-123',
          totalCount: 10,
          completedCount: 5,
        );
        const b = ProjectTaskCounts(
          projectId: 'project-123',
          totalCount: 10,
          completedCount: 7,
        );

        expect(a, isNot(b));
      });

      test('identical returns true for same instance', () {
        const a = ProjectTaskCounts(
          projectId: 'project-123',
          totalCount: 10,
          completedCount: 5,
        );

        expect(a == a, isTrue);
      });

      test('equals returns false for different type', () {
        const a = ProjectTaskCounts(
          projectId: 'project-123',
          totalCount: 10,
          completedCount: 5,
        );

        // ignore: unrelated_type_equality_checks
        expect(a == 'not a ProjectTaskCounts', isFalse);
      });
    });

    group('toString', () {
      test('returns string representation', () {
        const counts = ProjectTaskCounts(
          projectId: 'project-123',
          totalCount: 10,
          completedCount: 5,
        );

        final str = counts.toString();

        expect(str, contains('ProjectTaskCounts'));
        expect(str, contains('projectId: project-123'));
        expect(str, contains('total: 10'));
        expect(str, contains('completed: 5'));
      });
    });
  });
}
