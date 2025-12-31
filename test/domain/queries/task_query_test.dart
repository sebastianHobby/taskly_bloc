import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/sort_preferences.dart';
import 'package:taskly_bloc/core/utils/date_only.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/queries/occurrence_expansion.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';

void main() {
  group('TaskQuery factories', () {
    group('inbox', () {
      test('creates query with completed=false and project is null', () {
        final query = TaskQuery.inbox();

        expect(query.filter.orGroups, isEmpty);
        expect(query.filter.shared, hasLength(2));

        final completed = query.filter.shared
            .whereType<TaskBoolPredicate>()
            .first;
        expect(completed.field, TaskBoolField.completed);
        expect(completed.operator, BoolOperator.isFalse);

        final project = query.filter.shared
            .whereType<TaskProjectPredicate>()
            .first;
        expect(project.operator, ProjectOperator.isNull);
      });

      test('uses default sort criteria', () {
        final query = TaskQuery.inbox();

        expect(query.sortCriteria.isNotEmpty, isTrue);
        expect(query.sortCriteria.first.field, SortField.deadlineDate);
      });

      test('accepts custom sort criteria', () {
        final customSort = [
          const SortCriterion(field: SortField.name),
        ];
        final query = TaskQuery.inbox(sortCriteria: customSort);

        expect(query.sortCriteria, customSort);
      });
    });

    group('today', () {
      test('creates query with completed=false and deadline<=today rules', () {
        final now = DateTime(2025, 12, 25, 14, 30);
        final query = TaskQuery.today(now: now);

        expect(query.filter.shared, hasLength(2));

        final completed = query.filter.shared
            .whereType<TaskBoolPredicate>()
            .first;
        expect(completed.field, TaskBoolField.completed);
        expect(completed.operator, BoolOperator.isFalse);

        final deadline = query.filter.shared
            .whereType<TaskDatePredicate>()
            .first;
        expect(deadline.field, TaskDateField.deadlineDate);
        expect(deadline.operator, DateOperator.onOrBefore);
        expect(deadline.date, dateOnly(now));
      });

      test('normalizes date to midnight', () {
        final now = DateTime(2025, 12, 25, 14, 30, 45);
        final query = TaskQuery.today(now: now);

        final predicate = query.filter.shared
            .whereType<TaskDatePredicate>()
            .first;
        expect(predicate.date?.hour, 0);
        expect(predicate.date?.minute, 0);
        expect(predicate.date?.second, 0);
      });
    });

    group('upcoming', () {
      test('creates query with completed=false and deadline!=null rules', () {
        final query = TaskQuery.upcoming();

        expect(query.filter.shared, hasLength(2));

        final completed = query.filter.shared
            .whereType<TaskBoolPredicate>()
            .first;
        expect(completed.operator, BoolOperator.isFalse);

        final deadline = query.filter.shared
            .whereType<TaskDatePredicate>()
            .first;
        expect(deadline.field, TaskDateField.deadlineDate);
        expect(deadline.operator, DateOperator.isNotNull);
      });
    });

    group('forProject', () {
      test('creates query with project filter', () {
        final query = TaskQuery.forProject(projectId: 'proj-123');

        expect(query.filter.shared, hasLength(1));
        expect(query.filter.shared.first, isA<TaskProjectPredicate>());

        final predicate = query.filter.shared.first as TaskProjectPredicate;
        expect(predicate.operator, ProjectOperator.matches);
        expect(predicate.projectId, 'proj-123');
      });
    });

    group('forLabel', () {
      test('creates query with label filter', () {
        final query = TaskQuery.forLabel(labelId: 'label-456');

        expect(query.filter.shared, hasLength(1));
        expect(query.filter.shared.first, isA<TaskLabelPredicate>());

        final predicate = query.filter.shared.first as TaskLabelPredicate;
        expect(predicate.operator, LabelOperator.hasAll);
        expect(predicate.labelIds, ['label-456']);
      });

      test('accepts custom label type', () {
        final query = TaskQuery.forLabel(
          labelId: 'value-789',
          labelType: LabelType.value,
        );

        final predicate = query.filter.shared.first as TaskLabelPredicate;
        expect(predicate.labelType, LabelType.value);
      });
    });

    group('schedule', () {
      test('creates query with date range and occurrence expansion', () {
        final start = DateTime(2025, 12);
        final end = DateTime(2025, 12, 31);
        final query = TaskQuery.schedule(rangeStart: start, rangeEnd: end);

        expect(query.filter.shared, hasLength(2));
        expect(query.occurrenceExpansion, isNotNull);
        expect(query.occurrenceExpansion?.rangeStart, start);
        expect(query.occurrenceExpansion?.rangeEnd, end);
      });
    });

    group('all', () {
      test('creates query with no rules', () {
        final query = TaskQuery.all();

        expect(query.filter, const QueryFilter<TaskPredicate>.matchAll());
      });

      test('uses default sort criteria', () {
        final query = TaskQuery.all();

        expect(query.sortCriteria.isNotEmpty, isTrue);
      });
    });
  });

  group('TaskQuery helper properties', () {
    test('needsLabels returns true when label predicate present', () {
      final query = TaskQuery.forLabel(labelId: 'label-1');
      expect(query.needsLabels, isTrue);
    });

    test('needsLabels returns false when no label predicate', () {
      final query = TaskQuery.inbox();
      expect(query.needsLabels, isFalse);
    });

    test('shouldExpandOccurrences returns true when expansion configured', () {
      final query = TaskQuery.schedule(
        rangeStart: DateTime(2025),
        rangeEnd: DateTime(2025, 1, 31),
      );
      expect(query.shouldExpandOccurrences, isTrue);
    });

    test('shouldExpandOccurrences returns false when no expansion', () {
      final query = TaskQuery.inbox();
      expect(query.shouldExpandOccurrences, isFalse);
    });

    test('hasProjectFilter returns true when project predicate present', () {
      final query = TaskQuery.forProject(projectId: 'p1');
      expect(query.hasProjectFilter, isTrue);
    });

    test('hasDateFilter returns true when date predicate present', () {
      final query = TaskQuery.today(now: DateTime.now());
      expect(query.hasDateFilter, isTrue);
    });
  });

  group('TaskQuery modification methods', () {
    test('copyWith creates new instance with modified filter', () {
      final original = TaskQuery.inbox();
      const modifiedFilter = QueryFilter<TaskPredicate>(
        shared: [
          TaskProjectPredicate(operator: ProjectOperator.isNull),
        ],
      );

      final modified = original.copyWith(filter: modifiedFilter);

      expect(modified.filter, modifiedFilter);
      expect(original.filter.shared, isNotEmpty); // Original unchanged
    });

    test('withAdditionalPredicates appends shared predicates', () {
      final original = TaskQuery.inbox();
      final modified = original.withAdditionalPredicates(const [
        TaskLabelPredicate(
          operator: LabelOperator.hasAny,
          labelIds: ['l1'],
          labelType: LabelType.label,
        ),
      ]);

      expect(modified.filter.shared.length, original.filter.shared.length + 1);
      expect(modified.filter.shared.last, isA<TaskLabelPredicate>());
    });

    test('withSortCriteria replaces sort criteria', () {
      final original = TaskQuery.inbox();
      final newSort = [const SortCriterion(field: SortField.name)];
      final modified = original.withSortCriteria(newSort);

      expect(modified.sortCriteria, newSort);
      expect(modified.filter, original.filter); // Filter unchanged
    });

    test('withOccurrenceExpansion adds expansion', () {
      final original = TaskQuery.inbox();
      final expansion = OccurrenceExpansion(
        rangeStart: DateTime(2025),
        rangeEnd: DateTime(2025, 1, 31),
      );
      final modified = original.withOccurrenceExpansion(expansion);

      expect(modified.occurrenceExpansion, expansion);
      expect(original.occurrenceExpansion, isNull);
    });

    test('copyWith with clearOccurrenceExpansion removes expansion', () {
      final withExpansion = TaskQuery.schedule(
        rangeStart: DateTime(2025),
        rangeEnd: DateTime(2025, 1, 31),
      );
      final withoutExpansion = withExpansion.copyWith(
        clearOccurrenceExpansion: true,
      );

      expect(withExpansion.occurrenceExpansion, isNotNull);
      expect(withoutExpansion.occurrenceExpansion, isNull);
    });
  });

  group('TaskQuery equality', () {
    test('equal queries have same hashCode', () {
      final query1 = TaskQuery.inbox();
      final query2 = TaskQuery.inbox();

      expect(query1, equals(query2));
      expect(query1.hashCode, query2.hashCode);
    });

    test('different rules produce different queries', () {
      final inbox = TaskQuery.inbox();
      final upcoming = TaskQuery.upcoming();

      expect(inbox, isNot(equals(upcoming)));
    });

    test('different sort criteria produce different queries', () {
      final query1 = TaskQuery.inbox();
      final query2 = TaskQuery.inbox(
        sortCriteria: const [SortCriterion(field: SortField.name)],
      );

      expect(query1, isNot(equals(query2)));
    });

    test('different occurrence expansion produce different queries', () {
      final query1 = TaskQuery.all();
      final query2 = query1.withOccurrenceExpansion(
        OccurrenceExpansion(
          rangeStart: DateTime(2025),
          rangeEnd: DateTime(2025, 1, 31),
        ),
      );

      expect(query1, isNot(equals(query2)));
    });
  });

  group('TaskQuery toString', () {
    test('produces readable output', () {
      final query = TaskQuery.inbox();
      final str = query.toString();

      expect(str, contains('TaskQuery'));
      expect(str, contains('filter'));
      expect(str, contains('sortCriteria'));
    });
  });
}
