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

      final repeatingFalse = mapper.predicateToExpression(
        const TaskBoolPredicate(
          field: TaskBoolField.repeating,
          operator: BoolOperator.isFalse,
        ),
        t,
      );
      expect(repeatingFalse, isA<Expression<bool>>());

      final projectIsNull = mapper.predicateToExpression(
        const TaskProjectPredicate(operator: ProjectOperator.isNull),
        t,
      );
      expect(projectIsNull, isA<Expression<bool>>());

      final projectMatchesAnyEmpty = mapper.predicateToExpression(
        const TaskProjectPredicate(
          operator: ProjectOperator.matchesAny,
          projectIds: <String>[],
        ),
        t,
      );
      expect(projectMatchesAnyEmpty, isA<Constant<bool>>());

      final valueIsNotNullInherited = mapper.predicateToExpression(
        const TaskValuePredicate(
          operator: ValueOperator.isNotNull,
          includeInherited: true,
        ),
        t,
      );
      expect(valueIsNotNullInherited, isA<Expression<bool>>());

      final textDateRelativeMissingArgs = mapper.predicateToExpression(
        const TaskDatePredicate(
          field: TaskDateField.deadlineDate,
          operator: DateOperator.relative,
        ),
        t,
      );
      expect(textDateRelativeMissingArgs, isA<Constant<bool>>());
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

        final repeatingFalse = mapper.predicateToExpression(
          const ProjectBoolPredicate(
            field: ProjectBoolField.repeating,
            operator: BoolOperator.isFalse,
          ),
          p,
        );
        expect(repeatingFalse, isA<Expression<bool>>());

        final textDateRelativeMissingArgs = mapper.predicateToExpression(
          const ProjectDatePredicate(
            field: ProjectDateField.startDate,
            operator: DateOperator.relative,
          ),
          p,
        );
        expect(textDateRelativeMissingArgs, isA<Constant<bool>>());
      },
    );

    testSafe(
      'ProjectPredicateMapper covers id, bool, date and value branches',
      () async {
        final db = autoTearDown(
          AppDatabase(NativeDatabase.memory()),
          (d) async => d.close(),
        );

        final mapper = ProjectPredicateMapper(driftDb: db, clock: clock);
        final p = db.projectTable;

        expect(
          mapper.predicateToExpression(
            const ProjectIdPredicate(id: 'p1'),
            p,
          ),
          isA<Expression<bool>>(),
        );
        expect(
          mapper.predicateToExpression(
            const ProjectBoolPredicate(
              field: ProjectBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
            p,
          ),
          isA<Expression<bool>>(),
        );
        expect(
          mapper.predicateToExpression(
            const ProjectDatePredicate(
              field: ProjectDateField.createdAt,
              operator: DateOperator.relative,
              relativeComparison: RelativeComparison.onOrAfter,
              relativeDays: -7,
            ),
            p,
          ),
          isA<Expression<bool>>(),
        );
        expect(
          mapper.predicateToExpression(
            const ProjectDatePredicate(
              field: ProjectDateField.completedAt,
              operator: DateOperator.relative,
            ),
            p,
          ),
          isA<Constant<bool>>(),
        );
        expect(
          mapper.predicateToExpression(
            const ProjectValuePredicate(
              operator: ValueOperator.hasAny,
              valueIds: ['v1'],
            ),
            p,
          ),
          isA<Expression<bool>>(),
        );
        expect(
          mapper.predicateToExpression(
            const ProjectValuePredicate(
              operator: ValueOperator.hasAll,
              valueIds: ['v1'],
            ),
            p,
          ),
          isA<Expression<bool>>(),
        );
        expect(
          mapper.predicateToExpression(
            const ProjectValuePredicate(
              operator: ValueOperator.hasAny,
              valueIds: <String>[],
            ),
            p,
          ),
          isA<Constant<bool>>(),
        );
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

        final moodIsNull = mapper.predicateToExpression(
          const JournalMoodPredicate(operator: MoodOperator.isNull),
          j,
        );
        expect(moodIsNull, isA<Constant<bool>>());

        final moodEquals = mapper.predicateToExpression(
          const JournalMoodPredicate(operator: MoodOperator.equals),
          j,
        );
        expect(moodEquals, isA<Constant<bool>>());

        final textContains = mapper.predicateToExpression(
          const JournalTextPredicate(
            operator: TextOperator.contains,
            value: 'focus',
          ),
          j,
        );
        expect(textContains, isA<Expression<bool>>());

        final textIsNotEmpty = mapper.predicateToExpression(
          const JournalTextPredicate(operator: TextOperator.isNotEmpty),
          j,
        );
        expect(textIsNotEmpty, isA<Expression<bool>>());
      },
    );

    testSafe(
      'JournalPredicateMapper covers additional text and mood branches',
      () async {
        final mapper = JournalPredicateMapper(clock: clock);
        final db = autoTearDown(
          AppDatabase(NativeDatabase.memory()),
          (d) async => d.close(),
        );

        final j = db.journalEntries;

        expect(
          mapper.predicateToExpression(
            const JournalIdPredicate(id: 'j1'),
            j,
          ),
          isA<Expression<bool>>(),
        );
        expect(
          mapper.predicateToExpression(
            const JournalDatePredicate(
              operator: DateOperator.relative,
            ),
            j,
          ),
          isA<Constant<bool>>(),
        );
        expect(
          mapper.predicateToExpression(
            const JournalMoodPredicate(operator: MoodOperator.isNotNull),
            j,
          ),
          isA<Constant<bool>>(),
        );
        expect(
          mapper.predicateToExpression(
            const JournalTextPredicate(
              operator: TextOperator.equals,
              value: 'entry',
            ),
            j,
          ),
          isA<Expression<bool>>(),
        );
        expect(
          mapper.predicateToExpression(
            const JournalTextPredicate(
              operator: TextOperator.contains,
            ),
            j,
          ),
          isA<Constant<bool>>(),
        );
        expect(
          mapper.predicateToExpression(
            const JournalTextPredicate(operator: TextOperator.isEmpty),
            j,
          ),
          isA<Expression<bool>>(),
        );
      },
    );
  });
}
