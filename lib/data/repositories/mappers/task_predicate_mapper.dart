import 'package:drift/drift.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/mappers/sql_comparison_builder.dart';
import 'package:taskly_bloc/data/repositories/mixins/query_builder_mixin.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart';

/// Maps [TaskPredicate] instances to Drift SQL expressions.
///
/// This class encapsulates all the logic for converting domain-level
/// task predicates into database-level WHERE clause expressions.
class TaskPredicateMapper with QueryBuilderMixin {
  TaskPredicateMapper({required this.driftDb});

  final AppDatabase driftDb;

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
      TaskLabelPredicate() => _labelPredicateToExpression(predicate, t),
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
    return SqlComparisonBuilder.boolComparison(t.completed, predicate.operator);
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

  Expression<bool> _labelPredicateToExpression(
    TaskLabelPredicate predicate,
    $TaskTableTable t,
  ) {
    return switch (predicate.operator) {
      LabelOperator.hasAny => existsQuery(
        driftDb.selectOnly(driftDb.taskLabelsTable)
          ..addColumns([driftDb.taskLabelsTable.taskId])
          ..where(driftDb.taskLabelsTable.taskId.equalsExp(t.id))
          ..where(driftDb.taskLabelsTable.labelId.isIn(predicate.labelIds)),
      ),
      LabelOperator.hasAll => existsQuery(
        driftDb.selectOnly(driftDb.taskLabelsTable)
          ..addColumns([driftDb.taskLabelsTable.taskId])
          ..where(driftDb.taskLabelsTable.taskId.equalsExp(t.id))
          ..where(driftDb.taskLabelsTable.labelId.isIn(predicate.labelIds))
          ..groupBy([driftDb.taskLabelsTable.taskId]),
      ),
      LabelOperator.isNull => notExistsQuery(
        driftDb.selectOnly(driftDb.taskLabelsTable)
          ..addColumns([driftDb.taskLabelsTable.taskId])
          ..where(driftDb.taskLabelsTable.taskId.equalsExp(t.id)),
      ),
      LabelOperator.isNotNull => existsQuery(
        driftDb.selectOnly(driftDb.taskLabelsTable)
          ..addColumns([driftDb.taskLabelsTable.taskId])
          ..where(driftDb.taskLabelsTable.taskId.equalsExp(t.id)),
      ),
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
      _ => throw ArgumentError('Not a text date column: ${predicate.field}'),
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
