import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/screens/data_config.dart';
import 'package:taskly_bloc/domain/models/screens/display_config.dart';
import 'package:taskly_bloc/domain/models/screens/entity_selector.dart';
import 'package:taskly_bloc/domain/models/screens/section.dart';
import 'package:taskly_bloc/domain/queries/project_query.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart';
import 'package:taskly_bloc/domain/queries/project_predicate.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/services/screens/screen_query_builder.dart';
import 'package:taskly_bloc/domain/models/sort_preferences.dart' as sp;

void main() {
  late ScreenQueryBuilder queryBuilder;
  final now = DateTime(2024, 1, 15);

  setUp(() {
    queryBuilder = ScreenQueryBuilder();
  });

  // Helper to get expected UTC date from relative offset
  DateTime expectedUtcDate(int daysOffset) {
    final base = DateTime(now.year, now.month, now.day + daysOffset);
    return DateTime.utc(base.year, base.month, base.day);
  }

  group('ScreenQueryBuilder', () {
    group('buildTaskQuery', () {
      test('throws when entityType is not task', () {
        const selector = EntitySelector(entityType: EntityType.project);
        const display = DisplayConfig();

        expect(
          () => queryBuilder.buildTaskQuery(
            selector: selector,
            display: display,
            now: now,
          ),
          throwsArgumentError,
        );
      });

      test(
        'returns query with matchAll filter when no taskFilter specified',
        () {
          const selector = EntitySelector(entityType: EntityType.task);
          const display = DisplayConfig();

          final query = queryBuilder.buildTaskQuery(
            selector: selector,
            display: display,
            now: now,
          );

          expect(query.filter.shared, isEmpty);
          expect(query.filter.orGroups, isEmpty);
        },
      );

      test('adds incomplete filter when showCompleted is false', () {
        const selector = EntitySelector(entityType: EntityType.task);
        const display = DisplayConfig(showCompleted: false);

        final query = queryBuilder.buildTaskQuery(
          selector: selector,
          display: display,
          now: now,
        );

        final hasIncompletePredicate = query.filter.shared.any(
          (p) =>
              p is TaskBoolPredicate &&
              p.field == TaskBoolField.completed &&
              p.operator == BoolOperator.isFalse,
        );
        expect(hasIncompletePredicate, isTrue);
      });

      test('does not duplicate incomplete filter if already present', () {
        const incompletePredicate = TaskBoolPredicate(
          field: TaskBoolField.completed,
          operator: BoolOperator.isFalse,
        );
        const filter = QueryFilter<TaskPredicate>(
          shared: [incompletePredicate],
        );
        const selector = EntitySelector(
          entityType: EntityType.task,
          taskFilter: filter,
        );
        const display = DisplayConfig(showCompleted: false);

        final query = queryBuilder.buildTaskQuery(
          selector: selector,
          display: display,
          now: now,
        );

        final incompletePredicates = query.filter.shared.where(
          (p) =>
              p is TaskBoolPredicate &&
              p.field == TaskBoolField.completed &&
              p.operator == BoolOperator.isFalse,
        );
        expect(incompletePredicates, hasLength(1));
      });

      test('preserves existing taskFilter predicates', () {
        const boolPredicate = TaskBoolPredicate(
          field: TaskBoolField.completed,
          operator: BoolOperator.isTrue,
        );
        const filter = QueryFilter<TaskPredicate>(shared: [boolPredicate]);
        const selector = EntitySelector(
          entityType: EntityType.task,
          taskFilter: filter,
        );
        const display = DisplayConfig();

        final query = queryBuilder.buildTaskQuery(
          selector: selector,
          display: display,
          now: now,
        );

        expect(query.filter.shared, contains(boolPredicate));
      });

      test(
        'converts relative date predicate to absolute with "on" comparison',
        () {
          const relativePredicate = TaskDatePredicate(
            field: TaskDateField.deadlineDate,
            operator: DateOperator.relative,
            relativeDays: 0,
            relativeComparison: RelativeComparison.on,
          );
          const filter = QueryFilter<TaskPredicate>(
            shared: [relativePredicate],
          );
          const selector = EntitySelector(
            entityType: EntityType.task,
            taskFilter: filter,
          );
          const display = DisplayConfig();

          final query = queryBuilder.buildTaskQuery(
            selector: selector,
            display: display,
            now: now,
          );

          final datePredicate = query.filter.shared
              .whereType<TaskDatePredicate>()
              .first;
          expect(datePredicate.operator, DateOperator.on);
          expect(datePredicate.date, expectedUtcDate(0));
        },
      );

      test(
        'converts relative date predicate to absolute with "before" comparison',
        () {
          const relativePredicate = TaskDatePredicate(
            field: TaskDateField.deadlineDate,
            operator: DateOperator.relative,
            relativeDays: -1, // yesterday
            relativeComparison: RelativeComparison.before,
          );
          const filter = QueryFilter<TaskPredicate>(
            shared: [relativePredicate],
          );
          const selector = EntitySelector(
            entityType: EntityType.task,
            taskFilter: filter,
          );
          const display = DisplayConfig();

          final query = queryBuilder.buildTaskQuery(
            selector: selector,
            display: display,
            now: now,
          );

          final datePredicate = query.filter.shared
              .whereType<TaskDatePredicate>()
              .first;
          expect(datePredicate.operator, DateOperator.before);
          expect(datePredicate.date, expectedUtcDate(-1));
        },
      );

      test('converts relative date predicate with positive offset', () {
        const relativePredicate = TaskDatePredicate(
          field: TaskDateField.deadlineDate,
          operator: DateOperator.relative,
          relativeDays: 7, // one week from now
          relativeComparison: RelativeComparison.onOrBefore,
        );
        const filter = QueryFilter<TaskPredicate>(shared: [relativePredicate]);
        const selector = EntitySelector(
          entityType: EntityType.task,
          taskFilter: filter,
        );
        const display = DisplayConfig();

        final query = queryBuilder.buildTaskQuery(
          selector: selector,
          display: display,
          now: now,
        );

        final datePredicate = query.filter.shared
            .whereType<TaskDatePredicate>()
            .first;
        expect(datePredicate.operator, DateOperator.onOrBefore);
        expect(datePredicate.date, expectedUtcDate(7));
      });

      test('normalizes relative predicates in orGroups', () {
        const relativePredicate = TaskDatePredicate(
          field: TaskDateField.startDate,
          operator: DateOperator.relative,
          relativeDays: 0,
          relativeComparison: RelativeComparison.onOrAfter,
        );
        const filter = QueryFilter<TaskPredicate>(
          orGroups: [
            [relativePredicate],
          ],
        );
        const selector = EntitySelector(
          entityType: EntityType.task,
          taskFilter: filter,
        );
        const display = DisplayConfig();

        final query = queryBuilder.buildTaskQuery(
          selector: selector,
          display: display,
          now: now,
        );

        final datePredicate = query.filter.orGroups.first
            .whereType<TaskDatePredicate>()
            .first;
        expect(datePredicate.operator, DateOperator.onOrAfter);
        expect(datePredicate.date, expectedUtcDate(0));
      });

      test('preserves non-relative date predicates unchanged', () {
        final absolutePredicate = TaskDatePredicate(
          field: TaskDateField.deadlineDate,
          operator: DateOperator.on,
          date: DateTime.utc(2024, 6),
        );
        final filter = QueryFilter<TaskPredicate>(shared: [absolutePredicate]);
        final selector = EntitySelector(
          entityType: EntityType.task,
          taskFilter: filter,
        );
        const display = DisplayConfig();

        final query = queryBuilder.buildTaskQuery(
          selector: selector,
          display: display,
          now: now,
        );

        final datePredicate = query.filter.shared
            .whereType<TaskDatePredicate>()
            .first;
        expect(datePredicate.operator, DateOperator.on);
        expect(datePredicate.date, DateTime.utc(2024, 6));
      });

      test('maps sorting criteria from display config', () {
        const selector = EntitySelector(entityType: EntityType.task);
        const display = DisplayConfig(
          sorting: [
            SortCriterion(
              field: SortField.name,
            ),
            SortCriterion(
              field: SortField.deadlineDate,
              direction: SortDirection.desc,
            ),
          ],
        );

        final query = queryBuilder.buildTaskQuery(
          selector: selector,
          display: display,
          now: now,
        );

        expect(query.sortCriteria, hasLength(2));
        expect(query.sortCriteria[0].field, sp.SortField.name);
        expect(query.sortCriteria[0].direction, sp.SortDirection.ascending);
        expect(query.sortCriteria[1].field, sp.SortField.deadlineDate);
        expect(query.sortCriteria[1].direction, sp.SortDirection.descending);
      });

      test('filters out unsupported sort fields (priority)', () {
        const selector = EntitySelector(entityType: EntityType.task);
        const display = DisplayConfig(
          sorting: [
            SortCriterion(
              field: SortField.priority,
            ),
            SortCriterion(
              field: SortField.name,
            ),
          ],
        );

        final query = queryBuilder.buildTaskQuery(
          selector: selector,
          display: display,
          now: now,
        );

        expect(query.sortCriteria, hasLength(1));
        expect(query.sortCriteria[0].field, sp.SortField.name);
      });

      test('maps createdAt sort field to createdDate', () {
        const selector = EntitySelector(entityType: EntityType.task);
        const display = DisplayConfig(
          sorting: [
            SortCriterion(
              field: SortField.createdAt,
              direction: SortDirection.desc,
            ),
          ],
        );

        final query = queryBuilder.buildTaskQuery(
          selector: selector,
          display: display,
          now: now,
        );

        expect(query.sortCriteria[0].field, sp.SortField.createdDate);
      });

      test('maps updatedAt sort field to updatedDate', () {
        const selector = EntitySelector(entityType: EntityType.task);
        const display = DisplayConfig(
          sorting: [
            SortCriterion(
              field: SortField.updatedAt,
            ),
          ],
        );

        final query = queryBuilder.buildTaskQuery(
          selector: selector,
          display: display,
          now: now,
        );

        expect(query.sortCriteria[0].field, sp.SortField.updatedDate);
      });
    });

    group('buildProjectQuery', () {
      test('throws when entityType is not project', () {
        const selector = EntitySelector(entityType: EntityType.task);
        const display = DisplayConfig();

        expect(
          () => queryBuilder.buildProjectQuery(
            selector: selector,
            display: display,
          ),
          throwsArgumentError,
        );
      });

      test(
        'returns query with matchAll filter when no projectFilter specified',
        () {
          const selector = EntitySelector(entityType: EntityType.project);
          const display = DisplayConfig();

          final query = queryBuilder.buildProjectQuery(
            selector: selector,
            display: display,
          );

          expect(query.filter.shared, isEmpty);
          expect(query.filter.orGroups, isEmpty);
        },
      );

      test('preserves existing projectFilter', () {
        const projectFilter = QueryFilter<ProjectPredicate>(
          shared: [
            ProjectBoolPredicate(
              field: ProjectBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
          ],
        );
        const selector = EntitySelector(
          entityType: EntityType.project,
          projectFilter: projectFilter,
        );
        const display = DisplayConfig();

        final query = queryBuilder.buildProjectQuery(
          selector: selector,
          display: display,
        );

        expect(query.filter.shared, hasLength(1));
        expect(query.filter.shared.first, isA<ProjectBoolPredicate>());
      });

      test('maps sorting criteria for projects', () {
        const selector = EntitySelector(entityType: EntityType.project);
        const display = DisplayConfig(
          sorting: [
            SortCriterion(
              field: SortField.name,
            ),
            SortCriterion(
              field: SortField.startDate,
              direction: SortDirection.desc,
            ),
          ],
        );

        final query = queryBuilder.buildProjectQuery(
          selector: selector,
          display: display,
        );

        expect(query.sortCriteria, hasLength(2));
        expect(query.sortCriteria[0].field, sp.SortField.name);
        expect(query.sortCriteria[1].field, sp.SortField.startDate);
        expect(query.sortCriteria[1].direction, sp.SortDirection.descending);
      });
    });

    group('buildTaskQueryFromSection', () {
      test('builds query from TaskDataConfig section', () {
        final section = DataSection(
          config: DataConfig.task(query: TaskQuery.incomplete()),
          title: 'Test Section',
        );

        final query = queryBuilder.buildTaskQueryFromSection(
          section: section,
          now: now,
        );

        expect(query, isA<TaskQuery>());
        expect(query.filter.shared, isNotEmpty);
      });

      test('throws for non-TaskDataConfig sections', () {
        final section = DataSection(
          config: DataConfig.project(query: ProjectQuery.all()),
          title: 'Projects',
        );

        expect(
          () => queryBuilder.buildTaskQueryFromSection(
            section: section,
            now: now,
          ),
          throwsArgumentError,
        );
      });

      test('applies display config showCompleted=false filter', () {
        final section = DataSection(
          config: DataConfig.task(query: TaskQuery.all()),
          title: 'Test',
          display: const DisplayConfig(showCompleted: false),
        );

        final query = queryBuilder.buildTaskQueryFromSection(
          section: section,
          now: now,
        );

        final hasIncompletePredicate = query.filter.shared.any(
          (p) =>
              p is TaskBoolPredicate &&
              p.field == TaskBoolField.completed &&
              p.operator == BoolOperator.isFalse,
        );
        expect(hasIncompletePredicate, isTrue);
      });

      test('preserves display sorting when query has no sort criteria', () {
        final section = DataSection(
          config: DataConfig.task(query: const TaskQuery()),
          title: 'Test',
          display: const DisplayConfig(
            sorting: [
              SortCriterion(field: SortField.name),
            ],
          ),
        );

        final query = queryBuilder.buildTaskQueryFromSection(
          section: section,
          now: now,
        );

        expect(query.sortCriteria, isNotEmpty);
      });
    });

    group('buildTaskQueryFromAllocationSection', () {
      test('returns sourceFilter when provided', () {
        final sourceQuery = TaskQuery.incomplete();
        final section = AllocationSection(
          title: 'Focus',
          sourceFilter: sourceQuery,
        );

        final query = queryBuilder.buildTaskQueryFromAllocationSection(
          section: section,
          now: now,
        );

        expect(query, sourceQuery);
      });

      test('returns default incomplete query when no sourceFilter', () {
        const section = AllocationSection(
          title: 'Focus',
        );

        final query = queryBuilder.buildTaskQueryFromAllocationSection(
          section: section,
          now: now,
        );

        final hasIncompletePredicate = query.filter.shared.any(
          (p) =>
              p is TaskBoolPredicate &&
              p.field == TaskBoolField.completed &&
              p.operator == BoolOperator.isFalse,
        );
        expect(hasIncompletePredicate, isTrue);
      });
    });

    group('buildTaskQueryFromAgendaSection', () {
      test('builds query with date filter for deadlineDate field', () {
        const section = AgendaSection(
          title: 'Agenda',
          dateField: AgendaDateField.deadlineDate,
          grouping: AgendaGrouping.standard,
        );

        final query = queryBuilder.buildTaskQueryFromAgendaSection(
          section: section,
          now: now,
        );

        final datePreds = query.filter.shared
            .whereType<TaskDatePredicate>()
            .toList();
        expect(datePreds, isNotEmpty);
        expect(datePreds.first.field, TaskDateField.deadlineDate);
      });

      test('builds query with date filter for startDate field', () {
        const section = AgendaSection(
          title: 'Agenda',
          dateField: AgendaDateField.startDate,
          grouping: AgendaGrouping.standard,
        );

        final query = queryBuilder.buildTaskQueryFromAgendaSection(
          section: section,
          now: now,
        );

        final datePreds = query.filter.shared
            .whereType<TaskDatePredicate>()
            .toList();
        expect(datePreds, isNotEmpty);
        expect(datePreds.first.field, TaskDateField.startDate);
      });

      test('includes incomplete filter', () {
        const section = AgendaSection(
          title: 'Agenda',
          dateField: AgendaDateField.deadlineDate,
          grouping: AgendaGrouping.standard,
        );

        final query = queryBuilder.buildTaskQueryFromAgendaSection(
          section: section,
          now: now,
        );

        final hasIncompletePredicate = query.filter.shared.any(
          (p) =>
              p is TaskBoolPredicate &&
              p.field == TaskBoolField.completed &&
              p.operator == BoolOperator.isFalse,
        );
        expect(hasIncompletePredicate, isTrue);
      });

      test('includes additional filter predicates when provided', () {
        final additionalQuery = TaskQuery(
          filter: const QueryFilter(
            shared: [
              TaskProjectPredicate(
                operator: ProjectOperator.isNotNull,
              ),
            ],
          ),
        );
        final section = AgendaSection(
          title: 'Agenda',
          dateField: AgendaDateField.deadlineDate,
          grouping: AgendaGrouping.standard,
          additionalFilter: additionalQuery,
        );

        final query = queryBuilder.buildTaskQueryFromAgendaSection(
          section: section,
          now: now,
        );

        final hasProjectPredicate = query.filter.shared.any(
          (p) => p is TaskProjectPredicate,
        );
        expect(hasProjectPredicate, isTrue);
      });
    });
  });
}
