import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/sort_preferences.dart';
import 'package:taskly_bloc/domain/queries/occurrence_expansion.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';

import '../../helpers/fallback_values.dart';

void main() {
  setUpAll(registerAllFallbackValues);

  group('TaskQuery', () {
    group('construction', () {
      test('creates with defaults', () {
        const query = TaskQuery();

        expect(query.filter.isMatchAll, isTrue);
        expect(query.sortCriteria, isEmpty);
        expect(query.occurrenceExpansion, isNull);
      });

      test('creates with custom filter', () {
        const query = TaskQuery(
          filter: QueryFilter<TaskPredicate>(
            shared: [
              TaskBoolPredicate(
                field: TaskBoolField.completed,
                operator: BoolOperator.isFalse,
              ),
            ],
          ),
        );

        expect(query.filter.shared, hasLength(1));
        expect(query.filter.isMatchAll, isFalse);
      });

      test('creates with sort criteria', () {
        const query = TaskQuery(
          sortCriteria: [
            SortCriterion(field: SortField.name),
            SortCriterion(
              field: SortField.deadlineDate,
              direction: SortDirection.descending,
            ),
          ],
        );

        expect(query.sortCriteria, hasLength(2));
      });

      test('creates with occurrence expansion', () {
        final query = TaskQuery(
          occurrenceExpansion: OccurrenceExpansion(
            rangeStart: DateTime.utc(2025, 6, 1),
            rangeEnd: DateTime.utc(2025, 6, 30),
          ),
        );

        expect(query.occurrenceExpansion, isNotNull);
        expect(query.shouldExpandOccurrences, isTrue);
      });
    });

    group('factory constructors', () {
      group('inbox', () {
        test('creates inbox query with incomplete and no project filter', () {
          final query = TaskQuery.inbox();

          expect(query.filter.shared, hasLength(2));

          // Check for completed = false predicate
          final boolPred = query.filter.shared
              .whereType<TaskBoolPredicate>()
              .first;
          expect(boolPred.field, TaskBoolField.completed);
          expect(boolPred.operator, BoolOperator.isFalse);

          // Check for project = null predicate
          final projectPred = query.filter.shared
              .whereType<TaskProjectPredicate>()
              .first;
          expect(projectPred.operator, ProjectOperator.isNull);
        });

        test('inbox uses default sort criteria', () {
          final query = TaskQuery.inbox();

          expect(query.sortCriteria, isNotEmpty);
        });

        test('inbox accepts custom sort criteria', () {
          final query = TaskQuery.inbox(
            sortCriteria: const [
              SortCriterion(field: SortField.name),
            ],
          );

          expect(query.sortCriteria, hasLength(1));
          expect(query.sortCriteria[0].field, SortField.name);
        });
      });

      group('today', () {
        test('creates today query with deadline filter', () {
          final now = DateTime.utc(2025, 6, 15, 12, 30);
          final query = TaskQuery.today(now: now);

          expect(query.filter.shared, hasLength(2));

          // Check for date predicate on deadline
          final datePred = query.filter.shared
              .whereType<TaskDatePredicate>()
              .first;
          expect(datePred.field, TaskDateField.deadlineDate);
          expect(datePred.operator, DateOperator.onOrBefore);
          // Date should be normalized to midnight UTC
          expect(datePred.date, DateTime.utc(2025, 6, 15));
        });
      });

      group('upcoming', () {
        test('creates upcoming query with deadline not null', () {
          final query = TaskQuery.upcoming();

          expect(query.filter.shared, hasLength(2));

          final datePred = query.filter.shared
              .whereType<TaskDatePredicate>()
              .first;
          expect(datePred.field, TaskDateField.deadlineDate);
          expect(datePred.operator, DateOperator.isNotNull);
        });
      });

      group('forProject', () {
        test('creates project query with project filter', () {
          final query = TaskQuery.forProject(projectId: 'project-123');

          expect(query.filter.shared, hasLength(1));

          final projectPred = query.filter.shared
              .whereType<TaskProjectPredicate>()
              .first;
          expect(projectPred.operator, ProjectOperator.matches);
          expect(projectPred.projectId, 'project-123');
        });
      });

      group('schedule', () {
        test('creates schedule query with date range', () {
          final rangeStart = DateTime.utc(2025, 6, 1);
          final rangeEnd = DateTime.utc(2025, 6, 30);
          final query = TaskQuery.schedule(
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
          );

          expect(query.filter.shared, hasLength(2));

          final datePred = query.filter.shared
              .whereType<TaskDatePredicate>()
              .first;
          expect(datePred.operator, DateOperator.between);
          expect(datePred.startDate, rangeStart);
          expect(datePred.endDate, rangeEnd);
        });

        test('schedule includes occurrence expansion', () {
          final rangeStart = DateTime.utc(2025, 6, 1);
          final rangeEnd = DateTime.utc(2025, 6, 30);
          final query = TaskQuery.schedule(
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
          );

          expect(query.occurrenceExpansion, isNotNull);
          expect(query.occurrenceExpansion!.rangeStart, rangeStart);
          expect(query.occurrenceExpansion!.rangeEnd, rangeEnd);
        });
      });

      group('all', () {
        test('creates all query with no filter', () {
          final query = TaskQuery.all();

          expect(query.filter.isMatchAll, isTrue);
        });
      });

      group('forValue', () {
        test('creates value query with value label filter', () {
          final query = TaskQuery.forValue(valueId: 'value-123');

          expect(query.filter.shared, hasLength(1));

          final valuePred = query.filter.shared
              .whereType<TaskValuePredicate>()
              .first;
          expect(valuePred.operator, ValueOperator.hasAll);
          expect(valuePred.valueIds, ['value-123']);
          expect(valuePred.includeInherited, isTrue);
        });
      });

      group('incomplete', () {
        test('creates incomplete query with completed = false filter', () {
          final query = TaskQuery.incomplete();

          expect(query.filter.shared, hasLength(1));

          final boolPred = query.filter.shared
              .whereType<TaskBoolPredicate>()
              .first;
          expect(boolPred.field, TaskBoolField.completed);
          expect(boolPred.operator, BoolOperator.isFalse);
        });

        test('incomplete uses default sort criteria', () {
          final query = TaskQuery.incomplete();

          expect(query.sortCriteria, isNotEmpty);
        });
      });

      group('withDueDate', () {
        test('creates query filtering for tasks with due date set', () {
          final query = TaskQuery.withDueDate();

          final datePred = query.filter.shared
              .whereType<TaskDatePredicate>()
              .first;
          expect(datePred.field, TaskDateField.deadlineDate);
          expect(datePred.operator, DateOperator.isNotNull);
        });
      });

      group('inProject', () {
        test('creates query filtering for tasks in any project', () {
          final query = TaskQuery.inProject();

          final projectPred = query.filter.shared
              .whereType<TaskProjectPredicate>()
              .first;
          expect(projectPred.operator, ProjectOperator.isNotNull);
        });
      });

      group('dueToday', () {
        test('creates query filtering for tasks due today', () {
          final query = TaskQuery.dueToday();

          final datePreds = query.filter.shared
              .whereType<TaskDatePredicate>()
              .toList();
          expect(datePreds.length, greaterThanOrEqualTo(1));
        });
      });

      group('dueThisWeek', () {
        test('creates query filtering for tasks due this week', () {
          final query = TaskQuery.dueThisWeek();

          final datePreds = query.filter.shared
              .whereType<TaskDatePredicate>()
              .toList();
          expect(datePreds.length, greaterThanOrEqualTo(1));
        });
      });

      group('overdue', () {
        test('creates query filtering for overdue tasks', () {
          final query = TaskQuery.overdue();

          // Should have both incomplete and past due date filter
          final boolPred = query.filter.shared
              .whereType<TaskBoolPredicate>()
              .first;
          expect(boolPred.field, TaskBoolField.completed);
          expect(boolPred.operator, BoolOperator.isFalse);

          final datePred = query.filter.shared
              .whereType<TaskDatePredicate>()
              .first;
          expect(datePred.field, TaskDateField.deadlineDate);
        });
      });

      group('byProject', () {
        test('creates query filtering by specific project ID', () {
          final query = TaskQuery.byProject('project-abc');

          final projectPred = query.filter.shared
              .whereType<TaskProjectPredicate>()
              .first;
          expect(projectPred.operator, ProjectOperator.matches);
          expect(projectPred.projectId, 'project-abc');
        });

        test('byProject accepts custom sort criteria', () {
          final query = TaskQuery.byProject(
            'project-abc',
            sortCriteria: const [
              SortCriterion(field: SortField.name),
            ],
          );

          expect(query.sortCriteria, hasLength(1));
          expect(query.sortCriteria[0].field, SortField.name);
        });
      });
    });

    group('helper properties', () {
      group('shouldExpandOccurrences', () {
        test('returns false when occurrenceExpansion is null', () {
          const query = TaskQuery();

          expect(query.shouldExpandOccurrences, isFalse);
        });

        test('returns true when occurrenceExpansion is set', () {
          final query = TaskQuery(
            occurrenceExpansion: OccurrenceExpansion(
              rangeStart: DateTime.utc(2025, 6, 1),
              rangeEnd: DateTime.utc(2025, 6, 30),
            ),
          );

          expect(query.shouldExpandOccurrences, isTrue);
        });
      });

      group('hasProjectFilter', () {
        test('returns false when no project predicates', () {
          const query = TaskQuery(
            filter: QueryFilter<TaskPredicate>(
              shared: [
                TaskBoolPredicate(
                  field: TaskBoolField.completed,
                  operator: BoolOperator.isFalse,
                ),
              ],
            ),
          );

          expect(query.hasProjectFilter, isFalse);
        });

        test('returns true when project predicate in shared', () {
          const query = TaskQuery(
            filter: QueryFilter<TaskPredicate>(
              shared: [
                TaskProjectPredicate(operator: ProjectOperator.isNull),
              ],
            ),
          );

          expect(query.hasProjectFilter, isTrue);
        });

        test('returns true when project predicate in orGroups', () {
          const query = TaskQuery(
            filter: QueryFilter<TaskPredicate>(
              orGroups: [
                [TaskProjectPredicate(operator: ProjectOperator.isNull)],
              ],
            ),
          );

          expect(query.hasProjectFilter, isTrue);
        });
      });

      group('hasDateFilter', () {
        test('returns false when no date predicates', () {
          const query = TaskQuery(
            filter: QueryFilter<TaskPredicate>(
              shared: [
                TaskBoolPredicate(
                  field: TaskBoolField.completed,
                  operator: BoolOperator.isFalse,
                ),
              ],
            ),
          );

          expect(query.hasDateFilter, isFalse);
        });

        test('returns true when date predicate in shared', () {
          final query = TaskQuery(
            filter: QueryFilter<TaskPredicate>(
              shared: [
                TaskDatePredicate(
                  field: TaskDateField.deadlineDate,
                  operator: DateOperator.onOrBefore,
                  date: DateTime.utc(2025, 6, 15),
                ),
              ],
            ),
          );

          expect(query.hasDateFilter, isTrue);
        });

        test('returns true when date predicate in orGroups', () {
          final query = TaskQuery(
            filter: QueryFilter<TaskPredicate>(
              orGroups: const [
                [
                  TaskDatePredicate(
                    field: TaskDateField.deadlineDate,
                    operator: DateOperator.isNotNull,
                  ),
                ],
              ],
            ),
          );

          expect(query.hasDateFilter, isTrue);
        });
      });
    });

    group('modification methods', () {
      group('copyWith', () {
        test('copies with filter change', () {
          const original = TaskQuery();
          final copy = original.copyWith(
            filter: const QueryFilter<TaskPredicate>(
              shared: [
                TaskBoolPredicate(
                  field: TaskBoolField.completed,
                  operator: BoolOperator.isTrue,
                ),
              ],
            ),
          );

          expect(copy.filter.shared, hasLength(1));
          expect(original.filter.isMatchAll, isTrue);
        });

        test('copies with sort criteria change', () {
          const original = TaskQuery();
          final copy = original.copyWith(
            sortCriteria: [
              const SortCriterion(field: SortField.name),
            ],
          );

          expect(copy.sortCriteria, hasLength(1));
        });

        test('copies with occurrence expansion', () {
          const original = TaskQuery();
          final copy = original.copyWith(
            occurrenceExpansion: OccurrenceExpansion(
              rangeStart: DateTime.utc(2025, 6, 1),
              rangeEnd: DateTime.utc(2025, 6, 30),
            ),
          );

          expect(copy.occurrenceExpansion, isNotNull);
        });

        test('clears occurrence expansion with flag', () {
          final original = TaskQuery(
            occurrenceExpansion: OccurrenceExpansion(
              rangeStart: DateTime.utc(2025, 6, 1),
              rangeEnd: DateTime.utc(2025, 6, 30),
            ),
          );
          final copy = original.copyWith(clearOccurrenceExpansion: true);

          expect(copy.occurrenceExpansion, isNull);
        });

        test('preserves unmodified fields', () {
          final original = TaskQuery(
            filter: const QueryFilter<TaskPredicate>(
              shared: [
                TaskBoolPredicate(
                  field: TaskBoolField.completed,
                  operator: BoolOperator.isFalse,
                ),
              ],
            ),
            sortCriteria: const [
              SortCriterion(field: SortField.name),
            ],
          );
          final copy = original.copyWith(
            sortCriteria: [
              const SortCriterion(field: SortField.deadlineDate),
            ],
          );

          expect(copy.filter.shared, hasLength(1));
          expect(copy.sortCriteria[0].field, SortField.deadlineDate);
        });
      });

      group('withAdditionalPredicates', () {
        test('adds predicates to shared', () {
          const original = TaskQuery(
            filter: QueryFilter<TaskPredicate>(
              shared: [
                TaskBoolPredicate(
                  field: TaskBoolField.completed,
                  operator: BoolOperator.isFalse,
                ),
              ],
            ),
          );

          final modified = original.withAdditionalPredicates([
            const TaskProjectPredicate(operator: ProjectOperator.isNull),
          ]);

          expect(modified.filter.shared, hasLength(2));
          expect(modified.filter.shared[0], isA<TaskBoolPredicate>());
          expect(modified.filter.shared[1], isA<TaskProjectPredicate>());
        });
      });

      group('withSortCriteria', () {
        test('replaces sort criteria', () {
          const original = TaskQuery(
            sortCriteria: [
              SortCriterion(field: SortField.name),
            ],
          );

          final modified = original.withSortCriteria([
            const SortCriterion(field: SortField.deadlineDate),
            const SortCriterion(field: SortField.createdDate),
          ]);

          expect(modified.sortCriteria, hasLength(2));
          expect(modified.sortCriteria[0].field, SortField.deadlineDate);
        });
      });

      group('withOccurrenceExpansion', () {
        test('sets occurrence expansion', () {
          const original = TaskQuery();

          final modified = original.withOccurrenceExpansion(
            OccurrenceExpansion(
              rangeStart: DateTime.utc(2025, 6, 1),
              rangeEnd: DateTime.utc(2025, 6, 30),
            ),
          );

          expect(modified.occurrenceExpansion, isNotNull);
          expect(modified.shouldExpandOccurrences, isTrue);
        });
      });
    });

    group('equality', () {
      test('equal when all fields match', () {
        const query1 = TaskQuery(
          filter: QueryFilter<TaskPredicate>(
            shared: [
              TaskBoolPredicate(
                field: TaskBoolField.completed,
                operator: BoolOperator.isFalse,
              ),
            ],
          ),
          sortCriteria: [
            SortCriterion(field: SortField.name),
          ],
        );
        const query2 = TaskQuery(
          filter: QueryFilter<TaskPredicate>(
            shared: [
              TaskBoolPredicate(
                field: TaskBoolField.completed,
                operator: BoolOperator.isFalse,
              ),
            ],
          ),
          sortCriteria: [
            SortCriterion(field: SortField.name),
          ],
        );

        expect(query1, equals(query2));
        expect(query1.hashCode, query2.hashCode);
      });

      test('not equal when filter differs', () {
        const query1 = TaskQuery(
          filter: QueryFilter<TaskPredicate>(
            shared: [
              TaskBoolPredicate(
                field: TaskBoolField.completed,
                operator: BoolOperator.isFalse,
              ),
            ],
          ),
        );
        const query2 = TaskQuery(
          filter: QueryFilter<TaskPredicate>(
            shared: [
              TaskBoolPredicate(
                field: TaskBoolField.completed,
                operator: BoolOperator.isTrue,
              ),
            ],
          ),
        );

        expect(query1, isNot(equals(query2)));
      });

      test('not equal when sort criteria differs', () {
        const query1 = TaskQuery(
          sortCriteria: [
            SortCriterion(field: SortField.name),
          ],
        );
        const query2 = TaskQuery(
          sortCriteria: [
            SortCriterion(field: SortField.deadlineDate),
          ],
        );

        expect(query1, isNot(equals(query2)));
      });

      test('not equal when occurrence expansion differs', () {
        final query1 = TaskQuery(
          occurrenceExpansion: OccurrenceExpansion(
            rangeStart: DateTime.utc(2025, 6, 1),
            rangeEnd: DateTime.utc(2025, 6, 30),
          ),
        );
        const query2 = TaskQuery();

        expect(query1, isNot(equals(query2)));
      });
    });

    group('toString', () {
      test('returns descriptive string', () {
        const query = TaskQuery(
          filter: QueryFilter<TaskPredicate>(
            shared: [
              TaskBoolPredicate(
                field: TaskBoolField.completed,
                operator: BoolOperator.isFalse,
              ),
            ],
          ),
        );

        expect(query.toString(), contains('TaskQuery'));
        expect(query.toString(), contains('filter'));
        expect(query.toString(), contains('sortCriteria'));
      });
    });
  });
}
