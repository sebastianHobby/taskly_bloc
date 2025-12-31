@Tags(['integration', 'parity'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';
import 'package:taskly_bloc/domain/filtering/evaluation_context.dart';
import 'package:taskly_bloc/domain/queries/project_filter_evaluator.dart';
import 'package:taskly_bloc/domain/queries/project_predicate.dart';
import 'package:taskly_bloc/domain/queries/project_query.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';
import 'package:taskly_bloc/domain/queries/task_filter_evaluator.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';

import '../helpers/test_db.dart';
import '../mocks/repository_mocks.dart';

/// Parity tests ensuring SQL queries and in-memory evaluation produce identical results.
///
/// These tests verify that for any given predicate:
/// 1. SQL queries filter correctly at database level
/// 2. In-memory evaluators filter correctly on domain objects
/// 3. Both produce the EXACT SAME results
///
/// This is critical because:
/// - Some filters are applied via SQL for efficiency
/// - Some filters require in-memory evaluation (e.g., after occurrence expansion)
/// - Any mismatch could cause confusing bugs where "the same filter" gives different results
void main() {
  late AppDatabase db;
  late TaskRepository taskRepo;
  late ProjectRepository projectRepo;
  late EvaluationContext ctx;
  const taskEvaluator = TaskFilterEvaluator();
  const projectEvaluator = ProjectFilterEvaluator();

  /// Reference date for all tests - use actual "today" so SQL and in-memory align
  late DateTime today;
  late DateTime pastDate; // today - 5 days
  late DateTime futureDate; // today + 5 days
  late DateTime farFutureDate; // today + 10 days

  setUp(() async {
    // Use real current date for parity (SQL uses DateTime.now())
    final now = DateTime.now();
    today = DateTime(now.year, now.month, now.day);
    pastDate = today.subtract(const Duration(days: 5));
    futureDate = today.add(const Duration(days: 5));
    farFutureDate = today.add(const Duration(days: 10));

    db = createTestDb();
    taskRepo = TaskRepository(
      driftDb: db,
      occurrenceExpander: MockOccurrenceStreamExpanderContract(),
      occurrenceWriteHelper: MockOccurrenceWriteHelperContract(),
    );
    projectRepo = ProjectRepository(
      driftDb: db,
      occurrenceExpander: MockOccurrenceStreamExpanderContract(),
      occurrenceWriteHelper: MockOccurrenceWriteHelperContract(),
    );
    ctx = EvaluationContext.forDate(today);
  });

  tearDown(() async {
    await closeTestDb(db);
  });

  /// Helper: creates tasks with varied date/bool properties for comprehensive testing.
  Future<void> seedTasks() async {
    // Task 1: incomplete, deadline in past
    await taskRepo.create(
      name: 'Past deadline incomplete',
      deadlineDate: pastDate,
    );

    // Task 2: incomplete, deadline today
    await taskRepo.create(
      name: 'Today deadline incomplete',
      deadlineDate: today,
    );

    // Task 3: incomplete, deadline in future
    await taskRepo.create(
      name: 'Future deadline incomplete',
      deadlineDate: futureDate,
    );

    // Task 4: completed, deadline in past
    await taskRepo.create(
      name: 'Past deadline completed',
      deadlineDate: pastDate,
      completed: true,
    );

    // Task 5: incomplete, no deadline
    await taskRepo.create(name: 'No deadline incomplete');

    // Task 6: incomplete, deadline in far future, with start date
    await taskRepo.create(
      name: 'With start and deadline',
      startDate: today.subtract(const Duration(days: 1)),
      deadlineDate: farFutureDate,
    );
  }

  /// Helper: creates projects with varied properties.
  Future<void> seedProjects() async {
    await projectRepo.create(
      name: 'Past deadline project',
      deadlineDate: pastDate,
    );

    await projectRepo.create(
      name: 'Today deadline project',
      deadlineDate: today,
    );

    await projectRepo.create(
      name: 'Future deadline project',
      deadlineDate: futureDate,
    );

    await projectRepo.create(
      name: 'Completed project',
      deadlineDate: pastDate,
      completed: true,
    );

    await projectRepo.create(name: 'No deadline project');
  }

  group('Task Predicate Parity', () {
    group('BoolPredicate', () {
      test('completed=false matches same tasks in SQL and memory', () async {
        await seedTasks();
        const filter = QueryFilter<TaskPredicate>(
          shared: [
            TaskBoolPredicate(
              field: TaskBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
          ],
        );
        final query = TaskQuery(filter: filter);

        // SQL query
        final sqlResults = await taskRepo.watchAll(query).first;

        // In-memory evaluation
        final allTasks = await taskRepo.watchAll().first;
        final memoryResults = allTasks
            .where((t) => taskEvaluator.matches(t, filter, ctx))
            .toList();

        // Parity check
        expect(
          sqlResults.map((t) => t.id).toSet(),
          equals(memoryResults.map((t) => t.id).toSet()),
          reason:
              'SQL and in-memory should return same tasks for '
              'completed=false',
        );
        expect(sqlResults.length, 5); // All except completed task
      });

      test('completed=true matches same tasks in SQL and memory', () async {
        await seedTasks();
        const filter = QueryFilter<TaskPredicate>(
          shared: [
            TaskBoolPredicate(
              field: TaskBoolField.completed,
              operator: BoolOperator.isTrue,
            ),
          ],
        );
        final query = TaskQuery(filter: filter);

        final sqlResults = await taskRepo.watchAll(query).first;
        final allTasks = await taskRepo.watchAll().first;
        final memoryResults = allTasks
            .where((t) => taskEvaluator.matches(t, filter, ctx))
            .toList();

        expect(
          sqlResults.map((t) => t.id).toSet(),
          equals(memoryResults.map((t) => t.id).toSet()),
        );
        expect(sqlResults.length, 1);
      });
    });

    group('DatePredicate - Absolute', () {
      test('deadlineDate.onOrBefore(today) matches same tasks', () async {
        await seedTasks();
        final filter = QueryFilter<TaskPredicate>(
          shared: [
            TaskDatePredicate(
              field: TaskDateField.deadlineDate,
              operator: DateOperator.onOrBefore,
              date: today,
            ),
          ],
        );
        final query = TaskQuery(filter: filter);

        final sqlResults = await taskRepo.watchAll(query).first;
        final allTasks = await taskRepo.watchAll().first;
        final memoryResults = allTasks
            .where((t) => taskEvaluator.matches(t, filter, ctx))
            .toList();

        expect(
          sqlResults.map((t) => t.id).toSet(),
          equals(memoryResults.map((t) => t.id).toSet()),
          reason: 'onOrBefore should match deadline <= today',
        );
        // Past deadline (10th), Today deadline (15th), Past completed (10th)
        expect(sqlResults.length, 3);
      });

      test('deadlineDate.after(today) matches same tasks', () async {
        await seedTasks();
        final filter = QueryFilter<TaskPredicate>(
          shared: [
            TaskDatePredicate(
              field: TaskDateField.deadlineDate,
              operator: DateOperator.after,
              date: today,
            ),
          ],
        );
        final query = TaskQuery(filter: filter);

        final sqlResults = await taskRepo.watchAll(query).first;
        final allTasks = await taskRepo.watchAll().first;
        final memoryResults = allTasks
            .where((t) => taskEvaluator.matches(t, filter, ctx))
            .toList();

        expect(
          sqlResults.map((t) => t.id).toSet(),
          equals(memoryResults.map((t) => t.id).toSet()),
        );
        // Future deadline (20th), With start and deadline (25th)
        expect(sqlResults.length, 2);
      });

      test('deadlineDate.on(today) matches same tasks', () async {
        await seedTasks();
        final filter = QueryFilter<TaskPredicate>(
          shared: [
            TaskDatePredicate(
              field: TaskDateField.deadlineDate,
              operator: DateOperator.on,
              date: today,
            ),
          ],
        );
        final query = TaskQuery(filter: filter);

        final sqlResults = await taskRepo.watchAll(query).first;
        final allTasks = await taskRepo.watchAll().first;
        final memoryResults = allTasks
            .where((t) => taskEvaluator.matches(t, filter, ctx))
            .toList();

        expect(
          sqlResults.map((t) => t.id).toSet(),
          equals(memoryResults.map((t) => t.id).toSet()),
        );
        expect(sqlResults.length, 1);
        expect(sqlResults.first.name, 'Today deadline incomplete');
      });

      test(
        'deadlineDate.between(pastDate, today) matches same tasks',
        () async {
          await seedTasks();
          final filter = QueryFilter<TaskPredicate>(
            shared: [
              TaskDatePredicate(
                field: TaskDateField.deadlineDate,
                operator: DateOperator.between,
                startDate: pastDate,
                endDate: today,
              ),
            ],
          );
          final query = TaskQuery(filter: filter);

          final sqlResults = await taskRepo.watchAll(query).first;
          final allTasks = await taskRepo.watchAll().first;
          final memoryResults = allTasks
              .where((t) => taskEvaluator.matches(t, filter, ctx))
              .toList();

          expect(
            sqlResults.map((t) => t.id).toSet(),
            equals(memoryResults.map((t) => t.id).toSet()),
          );
          // Tasks with deadline on 10th (2) and 15th (1)
          expect(sqlResults.length, 3);
        },
      );

      test('deadlineDate.isNull matches same tasks', () async {
        await seedTasks();
        const filter = QueryFilter<TaskPredicate>(
          shared: [
            TaskDatePredicate(
              field: TaskDateField.deadlineDate,
              operator: DateOperator.isNull,
            ),
          ],
        );
        const query = TaskQuery(filter: filter);

        final sqlResults = await taskRepo.watchAll(query).first;
        final allTasks = await taskRepo.watchAll().first;
        final memoryResults = allTasks
            .where((t) => taskEvaluator.matches(t, filter, ctx))
            .toList();

        expect(
          sqlResults.map((t) => t.id).toSet(),
          equals(memoryResults.map((t) => t.id).toSet()),
        );
        expect(sqlResults.length, 1);
        expect(sqlResults.first.name, 'No deadline incomplete');
      });

      test('deadlineDate.isNotNull matches same tasks', () async {
        await seedTasks();
        const filter = QueryFilter<TaskPredicate>(
          shared: [
            TaskDatePredicate(
              field: TaskDateField.deadlineDate,
              operator: DateOperator.isNotNull,
            ),
          ],
        );
        const query = TaskQuery(filter: filter);

        final sqlResults = await taskRepo.watchAll(query).first;
        final allTasks = await taskRepo.watchAll().first;
        final memoryResults = allTasks
            .where((t) => taskEvaluator.matches(t, filter, ctx))
            .toList();

        expect(
          sqlResults.map((t) => t.id).toSet(),
          equals(memoryResults.map((t) => t.id).toSet()),
        );
        expect(sqlResults.length, 5);
      });
    });

    group('DatePredicate - Relative', () {
      test('deadlineDate.relative(onOrBefore, 0 days) matches today', () async {
        await seedTasks();
        const filter = QueryFilter<TaskPredicate>(
          shared: [
            TaskDatePredicate(
              field: TaskDateField.deadlineDate,
              operator: DateOperator.relative,
              relativeComparison: RelativeComparison.onOrBefore,
              relativeDays: 0,
            ),
          ],
        );
        const query = TaskQuery(filter: filter);

        final sqlResults = await taskRepo.watchAll(query).first;
        final allTasks = await taskRepo.watchAll().first;
        final memoryResults = allTasks
            .where((t) => taskEvaluator.matches(t, filter, ctx))
            .toList();

        expect(
          sqlResults.map((t) => t.id).toSet(),
          equals(memoryResults.map((t) => t.id).toSet()),
          reason: 'Relative comparison should behave identically',
        );
      });

      test('deadlineDate.relative(after, 3 days) matches same tasks', () async {
        await seedTasks();
        const filter = QueryFilter<TaskPredicate>(
          shared: [
            TaskDatePredicate(
              field: TaskDateField.deadlineDate,
              operator: DateOperator.relative,
              relativeComparison: RelativeComparison.after,
              relativeDays: 3, // today + 3 days
            ),
          ],
        );
        const query = TaskQuery(filter: filter);

        final sqlResults = await taskRepo.watchAll(query).first;
        final allTasks = await taskRepo.watchAll().first;
        final memoryResults = allTasks
            .where((t) => taskEvaluator.matches(t, filter, ctx))
            .toList();

        expect(
          sqlResults.map((t) => t.id).toSet(),
          equals(memoryResults.map((t) => t.id).toSet()),
        );
        // futureDate (today + 5) and farFutureDate (today + 10) are both after (today + 3)
        expect(sqlResults.length, 2);
      });
    });

    group('Combined predicates', () {
      test('incomplete AND deadline before today matches same tasks', () async {
        await seedTasks();
        final filter = QueryFilter<TaskPredicate>(
          shared: [
            const TaskBoolPredicate(
              field: TaskBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
            TaskDatePredicate(
              field: TaskDateField.deadlineDate,
              operator: DateOperator.before,
              date: today,
            ),
          ],
        );
        final query = TaskQuery(filter: filter);

        final sqlResults = await taskRepo.watchAll(query).first;
        final allTasks = await taskRepo.watchAll().first;
        final memoryResults = allTasks
            .where((t) => taskEvaluator.matches(t, filter, ctx))
            .toList();

        expect(
          sqlResults.map((t) => t.id).toSet(),
          equals(memoryResults.map((t) => t.id).toSet()),
        );
        expect(sqlResults.length, 1);
        expect(sqlResults.first.name, 'Past deadline incomplete');
      });
    });
  });

  group('Project Predicate Parity', () {
    group('BoolPredicate', () {
      test('completed=false matches same projects in SQL and memory', () async {
        await seedProjects();
        const filter = QueryFilter<ProjectPredicate>(
          shared: [
            ProjectBoolPredicate(
              field: ProjectBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
          ],
        );
        const query = ProjectQuery(filter: filter);

        final sqlResults = await projectRepo.watchAllByQuery(query).first;
        final allProjects = await projectRepo.watchAll().first;
        final memoryResults = allProjects
            .where((p) => projectEvaluator.matches(p, filter, ctx))
            .toList();

        expect(
          sqlResults.map((p) => p.id).toSet(),
          equals(memoryResults.map((p) => p.id).toSet()),
        );
        expect(sqlResults.length, 4);
      });
    });

    group('DatePredicate - Absolute', () {
      test('deadlineDate.onOrBefore(today) matches same projects', () async {
        await seedProjects();
        final filter = QueryFilter<ProjectPredicate>(
          shared: [
            ProjectDatePredicate(
              field: ProjectDateField.deadlineDate,
              operator: DateOperator.onOrBefore,
              date: today,
            ),
          ],
        );
        final query = ProjectQuery(filter: filter);

        final sqlResults = await projectRepo.watchAllByQuery(query).first;
        final allProjects = await projectRepo.watchAll().first;
        final memoryResults = allProjects
            .where((p) => projectEvaluator.matches(p, filter, ctx))
            .toList();

        expect(
          sqlResults.map((p) => p.id).toSet(),
          equals(memoryResults.map((p) => p.id).toSet()),
        );
        expect(sqlResults.length, 3);
      });

      test('deadlineDate.isNull matches same projects', () async {
        await seedProjects();
        const filter = QueryFilter<ProjectPredicate>(
          shared: [
            ProjectDatePredicate(
              field: ProjectDateField.deadlineDate,
              operator: DateOperator.isNull,
            ),
          ],
        );
        const query = ProjectQuery(filter: filter);

        final sqlResults = await projectRepo.watchAllByQuery(query).first;
        final allProjects = await projectRepo.watchAll().first;
        final memoryResults = allProjects
            .where((p) => projectEvaluator.matches(p, filter, ctx))
            .toList();

        expect(
          sqlResults.map((p) => p.id).toSet(),
          equals(memoryResults.map((p) => p.id).toSet()),
        );
        expect(sqlResults.length, 1);
        expect(sqlResults.first.name, 'No deadline project');
      });
    });
  });
}
