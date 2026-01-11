import 'package:drift/drift.dart';
import 'package:taskly_bloc/data/infrastructure/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/mappers/sql_comparison_builder.dart';
import 'package:taskly_bloc/data/repositories/mixins/query_builder_mixin.dart';
import 'package:taskly_bloc/domain/queries/journal_predicate.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart'
    show DateOperator;

/// Maps [JournalPredicate] instances to Drift SQL expressions.
///
/// This class encapsulates all the logic for converting domain-level
/// journal predicates into database-level WHERE clause expressions.
class JournalPredicateMapper with QueryBuilderMixin {
  const JournalPredicateMapper();

  // ===========================================================================
  // PUBLIC API
  // ===========================================================================

  /// Converts a single [JournalPredicate] to a Drift expression.
  Expression<bool> predicateToExpression(
    JournalPredicate predicate,
    $JournalEntriesTable j,
  ) {
    return switch (predicate) {
      JournalIdPredicate() => _idPredicateToExpression(predicate, j),
      JournalDatePredicate() => _datePredicateToExpression(predicate, j),
      JournalMoodPredicate() => _moodPredicateToExpression(predicate, j),
      JournalTextPredicate() => _textPredicateToExpression(predicate, j),
    };
  }

  // ===========================================================================
  // PREDICATE CONVERTERS
  // ===========================================================================

  Expression<bool> _idPredicateToExpression(
    JournalIdPredicate predicate,
    $JournalEntriesTable j,
  ) {
    return j.id.equals(predicate.id);
  }

  Expression<bool> _datePredicateToExpression(
    JournalDatePredicate predicate,
    $JournalEntriesTable j,
  ) {
    // entryDate is a native DateTime column
    final column = j.entryDate;

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

  Expression<bool> _moodPredicateToExpression(
    JournalMoodPredicate predicate,
    $JournalEntriesTable j,
  ) {
    final column = j.moodRating;

    return switch (predicate.operator) {
      MoodOperator.equals =>
        predicate.value == null
            ? const Constant(false)
            : column.equals(predicate.value!.value),
      MoodOperator.greaterThanOrEqual =>
        predicate.value == null
            ? const Constant(false)
            : column.isBiggerOrEqualValue(predicate.value!.value),
      MoodOperator.lessThanOrEqual =>
        predicate.value == null
            ? const Constant(false)
            : column.isSmallerOrEqualValue(predicate.value!.value),
      MoodOperator.isNull => column.isNull(),
      MoodOperator.isNotNull => column.isNotNull(),
    };
  }

  Expression<bool> _textPredicateToExpression(
    JournalTextPredicate predicate,
    $JournalEntriesTable j,
  ) {
    final column = j.journalText;

    return switch (predicate.operator) {
      TextOperator.contains =>
        predicate.value == null
            ? const Constant(false)
            : column.like('%${predicate.value}%'),
      TextOperator.equals =>
        predicate.value == null
            ? const Constant(false)
            : column.equals(predicate.value!),
      TextOperator.isEmpty => column.isNull() | column.equals(''),
      TextOperator.isNotEmpty => column.isNotNull() & column.equals('').not(),
    };
  }
}
