import 'package:drift/drift.dart';
import 'package:taskly_data/src/infrastructure/drift/drift_database.dart';
import 'package:taskly_data/src/repositories/mixins/query_builder_mixin.dart';
import 'package:taskly_data/src/repositories/mappers/sql_comparison_builder.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/time.dart' show Clock, systemClock;

/// Maps [ProjectPredicate] instances to Drift SQL expressions.
///
/// This class encapsulates all the logic for converting domain-level
/// project predicates into database-level WHERE clause expressions.
class ProjectPredicateMapper with QueryBuilderMixin {
  ProjectPredicateMapper({required this.driftDb, this.clock = systemClock});

  final AppDatabase driftDb;

  @override
  final Clock clock;

  /// Converts a single [ProjectPredicate] to a Drift expression.
  Expression<bool> predicateToExpression(
    ProjectPredicate predicate,
    $ProjectTableTable p,
  ) {
    return switch (predicate) {
      ProjectIdPredicate() => _idPredicateToExpression(predicate, p),
      ProjectBoolPredicate() => _boolPredicateToExpression(predicate, p),
      ProjectDatePredicate() => _datePredicateToExpression(predicate, p),
      ProjectValuePredicate() => _valuePredicateToExpression(predicate, p),
    };
  }

  Expression<bool> _idPredicateToExpression(
    ProjectIdPredicate predicate,
    $ProjectTableTable p,
  ) {
    return p.id.equals(predicate.id);
  }

  Expression<bool> _boolPredicateToExpression(
    ProjectBoolPredicate predicate,
    $ProjectTableTable p,
  ) {
    final column = switch (predicate.field) {
      ProjectBoolField.completed => p.completed,
    };
    return SqlComparisonBuilder.boolComparison(column, predicate.operator);
  }

  Expression<bool> _datePredicateToExpression(
    ProjectDatePredicate predicate,
    $ProjectTableTable p,
  ) {
    if (predicate.field == ProjectDateField.completedAt) {
      return _completedAtDatePredicateToExpression(predicate, p);
    }

    // startDate and deadlineDate are text columns with type converters (YYYY-MM-DD)
    // createdAt and updatedAt are native DateTime columns
    final isTextDateColumn =
        predicate.field == ProjectDateField.startDate ||
        predicate.field == ProjectDateField.deadlineDate;

    if (isTextDateColumn) {
      return _textDatePredicateToExpression(predicate, p);
    }

    // Native DateTime columns (createdAt, updatedAt)
    final GeneratedColumn<DateTime> column = switch (predicate.field) {
      ProjectDateField.createdAt => p.createdAt,
      ProjectDateField.updatedAt => p.updatedAt,
      _ => p.updatedAt, // fallback, shouldn't reach here
    };

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

    return SqlComparisonBuilder.dateTimeComparison(
      column,
      predicate.operator,
      date: predicate.date,
      startDate: predicate.startDate,
      endDate: predicate.endDate,
    );
  }

  /// Handles date predicates for text-based date columns (startDate, deadlineDate).
  Expression<bool> _textDatePredicateToExpression(
    ProjectDatePredicate predicate,
    $ProjectTableTable p,
  ) {
    final Expression<String> column = switch (predicate.field) {
      ProjectDateField.startDate => p.startDate.dartCast<String>(),
      ProjectDateField.deadlineDate => p.deadlineDate.dartCast<String>(),
      _ => throw ArgumentError('Not a text date column: ${predicate.field}'),
    };

    if (predicate.operator == DateOperator.relative) {
      final comp = predicate.relativeComparison;
      final days = predicate.relativeDays;
      if (comp == null || days == null) return const Constant(false);

      return SqlComparisonBuilder.relativeTextDateComparisonFromDateTime(
        column,
        comp,
        relativeToAbsolute(days),
      );
    }

    return SqlComparisonBuilder.textDateComparisonFromDateTime(
      column,
      predicate.operator,
      date: predicate.date,
      startDate: predicate.startDate,
      endDate: predicate.endDate,
    );
  }

  /// Handles completedAt predicates using the project_completion_history table.
  Expression<bool> _completedAtDatePredicateToExpression(
    ProjectDatePredicate predicate,
    $ProjectTableTable p,
  ) {
    final history = driftDb.projectCompletionHistoryTable;

    // Handle isNull/isNotNull
    if (predicate.operator == DateOperator.isNull) {
      return _completionHistoryNotExists(p);
    }
    if (predicate.operator == DateOperator.isNotNull) {
      return _completionHistoryExists(p);
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
      return _completionHistoryExistsWithCondition(p, dateCondition);
    }

    // Handle absolute dates
    final dateCondition = SqlComparisonBuilder.dateTimeComparison(
      history.completedAt,
      predicate.operator,
      date: predicate.date,
      startDate: predicate.startDate,
      endDate: predicate.endDate,
    );
    return _completionHistoryExistsWithCondition(p, dateCondition);
  }

  // ===========================================================================
  // COMPLETION HISTORY SUBQUERY HELPERS
  // ===========================================================================

  Expression<bool> _completionHistoryExists($ProjectTableTable p) {
    final history = driftDb.projectCompletionHistoryTable;
    return existsQuery(
      driftDb.selectOnly(history)
        ..addColumns([history.projectId])
        ..where(history.projectId.equalsExp(p.id)),
    );
  }

  Expression<bool> _completionHistoryNotExists($ProjectTableTable p) {
    final history = driftDb.projectCompletionHistoryTable;
    return notExistsQuery(
      driftDb.selectOnly(history)
        ..addColumns([history.projectId])
        ..where(history.projectId.equalsExp(p.id)),
    );
  }

  Expression<bool> _completionHistoryExistsWithCondition(
    $ProjectTableTable p,
    Expression<bool> dateCondition,
  ) {
    final history = driftDb.projectCompletionHistoryTable;
    return existsQuery(
      driftDb.selectOnly(history)
        ..addColumns([history.projectId])
        ..where(history.projectId.equalsExp(p.id))
        ..where(dateCondition),
    );
  }

  Expression<bool> _valuePredicateToExpression(
    ProjectValuePredicate predicate,
    $ProjectTableTable p,
  ) {
    final normalizedValueIds = predicate.valueIds
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);

    Expression<bool> matchAny() {
      if (normalizedValueIds.isEmpty) return const Constant(false);
      return p.primaryValueId.isIn(normalizedValueIds);
    }

    Expression<bool> matchAll() {
      return switch (normalizedValueIds.length) {
        0 => const Constant(false),
        1 => matchAny(),
        2 => const Constant(false),
        _ => const Constant(false),
      };
    }

    return switch (predicate.operator) {
      ValueOperator.hasAny => matchAny(),
      ValueOperator.hasAll => matchAll(),
      ValueOperator.isNull => p.primaryValueId.isNull(),
      ValueOperator.isNotNull => p.primaryValueId.isNotNull(),
    };
  }
}
