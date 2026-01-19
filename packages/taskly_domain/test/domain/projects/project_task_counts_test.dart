@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:taskly_domain/src/projects/query/project_task_counts.dart';

void main() {
  testSafe('ProjectTaskCounts derived getters behave correctly', () async {
    const counts = ProjectTaskCounts(
      projectId: 'p1',
      totalCount: 10,
      completedCount: 4,
    );

    expect(counts.incompleteCount, 6);
    expect(counts.progressRatio, 0.4);
    expect(counts.isComplete, isFalse);
  });

  testSafe('ProjectTaskCounts progressRatio is null when empty', () async {
    const counts = ProjectTaskCounts(
      projectId: 'p1',
      totalCount: 0,
      completedCount: 0,
    );

    expect(counts.progressRatio, isNull);
    expect(counts.isComplete, isFalse);
  });

  testSafe('ProjectTaskCounts copyWith overrides fields', () async {
    const counts = ProjectTaskCounts(
      projectId: 'p1',
      totalCount: 10,
      completedCount: 4,
    );

    final updated = counts.copyWith(completedCount: 10);

    expect(updated.projectId, 'p1');
    expect(updated.isComplete, isTrue);
  });

  testSafe('ProjectTaskCounts equality compares all fields', () async {
    const a = ProjectTaskCounts(
      projectId: 'p1',
      totalCount: 10,
      completedCount: 4,
    );
    const b = ProjectTaskCounts(
      projectId: 'p1',
      totalCount: 10,
      completedCount: 4,
    );
    const c = ProjectTaskCounts(
      projectId: 'p1',
      totalCount: 10,
      completedCount: 5,
    );

    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
    expect(a, isNot(equals(c)));
  });
}
