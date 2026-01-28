import 'package:drift/drift.dart';
import 'package:taskly_data/src/infrastructure/drift/drift_database.dart';
import 'package:taskly_data/src/repositories/mixins/query_builder_mixin.dart';
import 'package:taskly_data/src/repositories/mappers/sql_comparison_builder.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/time.dart' show Clock, systemClock;

/// Maps [TaskPredicate] instances to Drift SQL expressions.
///
/// This class encapsulates all the logic for converting domain-level
/// task predicates into database-level WHERE clause expressions.
class TaskPredicateMapper with QueryBuilderMixin {
  TaskPredicateMapper({required this.driftDb, this.clock = systemClock});

  final AppDatabase driftDb;

  @override
  final Clock clock;

  // ===========================================================================
  // PUBLIC API
  // ===========================================================================

  /// Converts a single [TaskPredicate] to a Drift expression.
  Expression<bool> predicateToExpression(
    TaskPredicate predicate,
    $TaskTableTable t,
  ) {
    return switch (predicate) {
      TaskBoolPredicate() => _boolPredicateToExpression(predicate, t),
      TaskProjectPredicate() => _projectPredicateToExpression(predicate, t),
      TaskValuePredicate() => _valuePredicateToExpression(predicate, t),
      TaskDatePredicate() => _datePredicateToExpression(predicate, t),
    };
  }

  // ===========================================================================
  // PREDICATE CONVERTERS
  // ===========================================================================

  Expression<bool> _boolPredicateToExpression(
    TaskBoolPredicate predicate,
    $TaskTableTable t,
  ) {
    final column = switch (predicate.field) {
      TaskBoolField.completed => t.completed,
      TaskBoolField.repeating =>
        t.repeatIcalRrule.isNotNull() & t.repeatIcalRrule.isNotValue(''),
    };

    if (predicate.field == TaskBoolField.repeating) {
      return switch (predicate.operator) {
        BoolOperator.isTrue => column,
        BoolOperator.isFalse =>
          t.repeatIcalRrule.isNull() | t.repeatIcalRrule.equals(''),
      };
    }

    return SqlComparisonBuilder.boolComparison(column, predicate.operator);
  }

  Expression<bool> _projectPredicateToExpression(
    TaskProjectPredicate predicate,
    $TaskTableTable t,
  ) {
    return switch (predicate.operator) {
      ProjectOperator.matches =>
        predicate.projectId == null
            ? const Constant(false)
            : t.projectId.equals(predicate.projectId!),
      ProjectOperator.matchesAny =>
        predicate.projectIds.isEmpty
            ? const Constant(false)
            : t.projectId.isIn(
                predicate.projectIds.where((id) => id.isNotEmpty).toList(),
              ),
      ProjectOperator.isNull => t.projectId.isNull(),
      ProjectOperator.isNotNull => t.projectId.isNotNull(),
    };
  }

  Expression<bool> _valuePredicateToExpression(
    TaskValuePredicate predicate,
    $TaskTableTable t,
  ) {
    final normalizedValueIds = predicate.valueIds
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);

    Expression<bool> matchOverrideAny() {
      if (normalizedValueIds.isEmpty) return const Constant(false);
      return t.overridePrimaryValueId.isIn(normalizedValueIds) |
          t.overrideSecondaryValueId.isIn(normalizedValueIds);
    }

    Expression<bool> matchOverrideAll() {
      return switch (normalizedValueIds.length) {
        0 => const Constant(false),
        1 => matchOverrideAny(),
        2 =>
          (t.overridePrimaryValueId.equals(normalizedValueIds[0]) &
                  t.overrideSecondaryValueId.equals(normalizedValueIds[1])) |
              (t.overridePrimaryValueId.equals(normalizedValueIds[1]) &
                  t.overrideSecondaryValueId.equals(normalizedValueIds[0])),
        _ => const Constant(false),
      };
    }

    Expression<bool> matchProjectAny() {
      if (normalizedValueIds.isEmpty) return const Constant(false);
      final p = driftDb.projectTable;
      return existsQuery(
        driftDb.selectOnly(p)
          ..addColumns([p.id])
          ..where(p.id.equalsExp(t.projectId))
          ..where(p.primaryValueId.isIn(normalizedValueIds)),
      );
    }

    Expression<bool> matchProjectAll() {
      return switch (normalizedValueIds.length) {
        0 => const Constant(false),
        1 => matchProjectAny(),
        2 => const Constant(false),
        _ => const Constant(false),
      };
    }

    Expression<bool> matchUnionAll() {
      if (normalizedValueIds.length != 2) {
        return matchOverrideAll() | matchProjectAll();
      }

      final a = normalizedValueIds[0];
      final b = normalizedValueIds[1];
      Expression<bool> overrideHas(String id) =>
          t.overridePrimaryValueId.equals(id) |
          t.overrideSecondaryValueId.equals(id);
      Expression<bool> projectHas(String id) {
        final p = driftDb.projectTable;
        return existsQuery(
          driftDb.selectOnly(p)
            ..addColumns([p.id])
            ..where(p.id.equalsExp(t.projectId))
            ..where(p.primaryValueId.equals(id)),
        );
      }

      final overrideHasA = overrideHas(a);
      final overrideHasB = overrideHas(b);
      final projectHasA = projectHas(a);
      final projectHasB = projectHas(b);

      return (overrideHasA & overrideHasB) |
          (projectHasA & projectHasB) |
          (overrideHasA & projectHasB) |
          (overrideHasB & projectHasA);
    }

    Expression<bool> matchEffectiveIsNull() {
      final p = driftDb.projectTable;
      return t.overridePrimaryValueId.isNull() &
          t.overrideSecondaryValueId.isNull() &
          notExistsQuery(
            driftDb.selectOnly(p)
              ..addColumns([p.id])
              ..where(p.id.equalsExp(t.projectId))
              ..where(p.primaryValueId.isNotNull()),
          );
    }

    Expression<bool> matchEffectiveIsNotNull() {
      final p = driftDb.projectTable;
      return t.overridePrimaryValueId.isNotNull() |
          t.overrideSecondaryValueId.isNotNull() |
          (t.overridePrimaryValueId.isNull() &
              existsQuery(
                driftDb.selectOnly(p)
                  ..addColumns([p.id])
                  ..where(p.id.equalsExp(t.projectId))
                  ..where(p.primaryValueId.isNotNull()),
              ));
    }

    final directMatch = switch (predicate.operator) {
      ValueOperator.hasAny => matchOverrideAny(),
      ValueOperator.hasAll => matchOverrideAll(),
      ValueOperator.isNull =>
        t.overridePrimaryValueId.isNull() & t.overrideSecondaryValueId.isNull(),
      ValueOperator.isNotNull =>
        t.overridePrimaryValueId.isNotNull() |
            t.overrideSecondaryValueId.isNotNull(),
    };

    if (!predicate.includeInherited) return directMatch;

    return switch (predicate.operator) {
      ValueOperator.hasAny => directMatch | matchProjectAny(),
      ValueOperator.hasAll => matchUnionAll(),
      ValueOperator.isNull => matchEffectiveIsNull(),
      ValueOperator.isNotNull => matchEffectiveIsNotNull(),
    };
  }

  Expression<bool> _datePredicateToExpression(
    TaskDatePredicate predicate,
    $TaskTableTable t,
  ) {
    if (predicate.field == TaskDateField.completedAt) {
      return _completedAtDatePredicateToExpression(predicate, t);
    }

    // startDate and deadlineDate are text columns with type converters (YYYY-MM-DD)
    // createdAt and updatedAt are native DateTime columns
    final isTextDateColumn =
        predicate.field == TaskDateField.startDate ||
        predicate.field == TaskDateField.deadlineDate;

    if (isTextDateColumn) {
      return _textDatePredicateToExpression(predicate, t);
    }

    // Native DateTime columns (createdAt, updatedAt)
    final GeneratedColumn<DateTime> column = switch (predicate.field) {
      TaskDateField.createdAt => t.createdAt,
      TaskDateField.updatedAt => t.updatedAt,
      _ => t.updatedAt, // fallback, shouldn't reach here
    };

    // Handle relative dates
    if (predicate.operator == DateOperator.relative) {
      final comp = predicate.relativeComparison;
      final days = predicate.relativeDays;
      if (comp == null || days == null) return const Constant(false);

      return SqlComparisonBuilder.relativeDateTimeComparison(
        column,
        comp,
        relativeToAbsolute(days),
      );
    }

    // Handle absolute dates
    return SqlComparisonBuilder.dateTimeComparison(
      column,
      predicate.operator,
      date: predicate.date,
      startDate: predicate.startDate,
      endDate: predicate.endDate,
    );
  }

  /// Handles date predicates for text-based date columns (startDate, deadlineDate).
  /// These are stored as YYYY-MM-DD strings which compare correctly alphabetically.
  Expression<bool> _textDatePredicateToExpression(
    TaskDatePredicate predicate,
    $TaskTableTable t,
  ) {
    // Get the original typed column (with type converter) for null checks
    final GeneratedColumnWithTypeConverter<DateTime?, String> typedColumn =
        switch (predicate.field) {
          TaskDateField.startDate => t.startDate,
          TaskDateField.deadlineDate => t.deadlineDate,
          _ => throw ArgumentError(
            'Not a text date column: ${predicate.field}',
          ),
        };

    // Get the column as Expression<String> (the underlying SQL type) for comparisons
    final Expression<String> column = typedColumn.dartCast<String>();

    // Handle relative dates
    if (predicate.operator == DateOperator.relative) {
      final comp = predicate.relativeComparison;
      final days = predicate.relativeDays;
      if (comp == null || days == null) return const Constant(false);

      // Use the typed column for the null check (ensures proper SQL generation)
      return typedColumn.isNotNull() &
          SqlComparisonBuilder.relativeTextDateComparisonFromDateTime(
            column,
            comp,
            relativeToAbsolute(days),
          );
    }

    // Handle absolute dates
    return SqlComparisonBuilder.textDateComparisonFromDateTime(
      column,
      predicate.operator,
      date: predicate.date,
      startDate: predicate.startDate,
      endDate: predicate.endDate,
    );
  }

  /// Handles completedAt predicates using the task_completion_history table.
  Expression<bool> _completedAtDatePredicateToExpression(
    TaskDatePredicate predicate,
    $TaskTableTable t,
  ) {
    final history = driftDb.taskCompletionHistoryTable;

    // Handle isNull/isNotNull without date comparison
    if (predicate.operator == DateOperator.isNull) {
      return _completionHistoryNotExists(t);
    }
    if (predicate.operator == DateOperator.isNotNull) {
      return _completionHistoryExists(t);
    }

    // Handle relative dates
    if (predicate.operator == DateOperator.relative) {
      final comp = predicate.relativeComparison;
      final days = predicate.relativeDays;
      if (comp == null || days == null) return const Constant(false);

      final dateCondition = SqlComparisonBuilder.relativeDateTimeComparison(
        history.completedAt,
        comp,
        relativeToAbsolute(days),
      );
      return _completionHistoryExistsWithCondition(t, dateCondition);
    }

    // Handle absolute dates
    final dateCondition = SqlComparisonBuilder.dateTimeComparison(
      history.completedAt,
      predicate.operator,
      date: predicate.date,
      startDate: predicate.startDate,
      endDate: predicate.endDate,
    );
    return _completionHistoryExistsWithCondition(t, dateCondition);
  }

  // ===========================================================================
  // COMPLETION HISTORY SUBQUERY HELPERS
  // ===========================================================================

  /// Returns EXISTS subquery checking if task has any completion history.
  Expression<bool> _completionHistoryExists($TaskTableTable t) {
    final history = driftDb.taskCompletionHistoryTable;
    return existsQuery(
      driftDb.selectOnly(history)
        ..addColumns([history.taskId])
        ..where(history.taskId.equalsExp(t.id)),
    );
  }

  /// Returns NOT EXISTS subquery checking if task has no completion history.
  Expression<bool> _completionHistoryNotExists($TaskTableTable t) {
    final history = driftDb.taskCompletionHistoryTable;
    return notExistsQuery(
      driftDb.selectOnly(history)
        ..addColumns([history.taskId])
        ..where(history.taskId.equalsExp(t.id)),
    );
  }

  /// Returns EXISTS subquery with an additional date condition.
  Expression<bool> _completionHistoryExistsWithCondition(
    $TaskTableTable t,
    Expression<bool> dateCondition,
  ) {
    final history = driftDb.taskCompletionHistoryTable;
    return existsQuery(
      driftDb.selectOnly(history)
        ..addColumns([history.taskId])
        ..where(history.taskId.equalsExp(t.id))
        ..where(dateCondition),
    );
  }
}
