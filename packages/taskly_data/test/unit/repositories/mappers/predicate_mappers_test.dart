@Tags(['unit'])
library;

import '../../../helpers/test_imports.dart';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:taskly_data/src/infrastructure/drift/drift_database.dart';
import 'package:taskly_data/src/repositories/mappers/journal_predicate_mapper.dart';
import 'package:taskly_data/src/repositories/mappers/project_predicate_mapper.dart';
import 'package:taskly_data/src/repositories/mappers/task_predicate_mapper.dart';
import 'package:taskly_domain/queries.dart';

import '../../../helpers/fixed_clock.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  final clock = FixedClock(DateTime(2025, 1, 15, 12));

  group('Predicate mappers (SQL expression building)', () {
    testSafe('TaskPredicateMapper covers main predicate types', () async {
      final db = autoTearDown(
        AppDatabase(NativeDatabase.memory()),
        (d) async => d.close(),
      );

      final mapper = TaskPredicateMapper(driftDb: db, clock: clock);
      final t = db.taskTable;

      final boolExpr = mapper.predicateToExpression(
        const TaskBoolPredicate(
          field: TaskBoolField.completed,
          operator: BoolOperator.isTrue,
        ),
        t,
      );
      expect(boolExpr, isA<Expression<bool>>());

      final projectNullMatch = mapper.predicateToExpression(
        const TaskProjectPredicate(operator: ProjectOperator.matches),
        t,
      );
      expect(projectNullMatch, isA<Constant<bool>>());

      final valueHasAllTooMany = mapper.predicateToExpression(
        const TaskValuePredicate(
          operator: ValueOperator.hasAll,
          valueIds: ['v1', 'v2', 'v3'],
        ),
        t,
      );
      expect(valueHasAllTooMany, isA<Constant<bool>>());

      final valueInheritedAny = mapper.predicateToExpression(
        const TaskValuePredicate(
          operator: ValueOperator.hasAny,
          valueIds: ['v1'],
          includeInherited: true,
        ),
        t,
      );
      expect(valueInheritedAny, isA<Expression<bool>>());

      final relativeCreatedAt = mapper.predicateToExpression(
        const TaskDatePredicate(
          field: TaskDateField.createdAt,
          operator: DateOperator.relative,
          relativeComparison: RelativeComparison.onOrAfter,
          relativeDays: -7,
        ),
        t,
      );
      expect(relativeCreatedAt, isA<Expression<bool>>());

      final relativeMissingArgs = mapper.predicateToExpression(
        const TaskDatePredicate(
          field: TaskDateField.createdAt,
          operator: DateOperator.relative,
        ),
        t,
      );
      expect(relativeMissingArgs, isA<Constant<bool>>());

      final completedAtIsNull = mapper.predicateToExpression(
        const TaskDatePredicate(
          field: TaskDateField.completedAt,
          operator: DateOperator.isNull,
        ),
        t,
      );
      expect(completedAtIsNull, isA<Expression<bool>>());
    });

    testSafe(
      'ProjectPredicateMapper covers completion history paths',
      () async {
        final db = autoTearDown(
          AppDatabase(NativeDatabase.memory()),
          (d) async => d.close(),
        );

        final mapper = ProjectPredicateMapper(driftDb: db, clock: clock);
        final p = db.projectTable;

        final completedAtIsNotNull = mapper.predicateToExpression(
          const ProjectDatePredicate(
            field: ProjectDateField.completedAt,
            operator: DateOperator.isNotNull,
          ),
          p,
        );
        expect(completedAtIsNotNull, isA<Expression<bool>>());

        final valueHasAll = mapper.predicateToExpression(
          const ProjectValuePredicate(
            operator: ValueOperator.hasAll,
            valueIds: ['v1', 'v2'],
          ),
          p,
        );
        expect(valueHasAll, isA<Expression<bool>>());
      },
    );

    testSafe(
      'JournalPredicateMapper relative date uses injected clock',
      () async {
        final mapper = JournalPredicateMapper(clock: clock);
        final db = autoTearDown(
          AppDatabase(NativeDatabase.memory()),
          (d) async => d.close(),
        );

        final j = db.journalEntries;

        final relativeEntryDate = mapper.predicateToExpression(
          const JournalDatePredicate(
            operator: DateOperator.relative,
            relativeComparison: RelativeComparison.onOrBefore,
            relativeDays: 0,
          ),
          j,
        );

        expect(relativeEntryDate, isA<Expression<bool>>());
      },
    );
  });
}
