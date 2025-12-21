import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/features/tasks/bloc/task_list_query.dart';

void main() {
  group('TaskListQuery.today', () {
    test('sets onOrBeforeDate to midnight of today', () {
      final now = DateTime(2025, 1, 15, 10, 30);
      final query = TaskListQuery.today(now: now);

      expect(query.onOrBeforeDate, DateTime(2025, 1, 15));
      expect(query.onOrAfterDate, isNull);
    });
  });

  group('TaskListQuery.upcoming', () {
    test('sets onOrAfterDate to midnight of tomorrow', () {
      final now = DateTime(2025, 1, 15, 10, 30);
      final query = TaskListQuery.upcoming(now: now);

      expect(query.onOrAfterDate, DateTime(2025, 1, 16));
      expect(query.onOrBeforeDate, isNull);
    });

    test('handles month boundaries', () {
      final now = DateTime(2025, 1, 31, 10, 30);
      final query = TaskListQuery.upcoming(now: now);

      expect(query.onOrAfterDate, DateTime(2025, 2));
    });
  });

  test('copyWith preserves unspecified fields', () {
    final initial = TaskListQuery(
      completion: TaskCompletionFilter.active,
      sort: TaskSort.deadline,
      onlyWithoutProject: true,
      projectId: 'p1',
      labelId: 'l1',
      onOrBeforeDate: DateTime(2025),
      onOrAfterDate: DateTime(2025, 1, 2),
    );

    final updated = initial.copyWith(sort: TaskSort.name);

    expect(updated.sort, TaskSort.name);
    expect(updated.completion, initial.completion);
    expect(updated.onlyWithoutProject, initial.onlyWithoutProject);
    expect(updated.projectId, initial.projectId);
    expect(updated.labelId, initial.labelId);
    expect(updated.onOrBeforeDate, initial.onOrBeforeDate);
    expect(updated.onOrAfterDate, initial.onOrAfterDate);
  });

  test('supports value equality', () {
    const a = TaskListQuery(onlyWithoutProject: true);
    const b = TaskListQuery(onlyWithoutProject: true);
    const c = TaskListQuery();

    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(c));
  });
}
