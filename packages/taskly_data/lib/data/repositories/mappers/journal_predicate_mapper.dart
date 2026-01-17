import 'package:drift/drift.dart';
import 'package:taskly_data/data/infrastructure/drift/drift_database.dart';
import 'package:taskly_data/data/repositories/mappers/sql_comparison_builder.dart';
import 'package:taskly_data/data/repositories/mixins/query_builder_mixin.dart';
import 'package:taskly_domain/queries.dart';

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
    // Mood is represented as tracker events in the OPT-A model.
    // The journal_entries table does not store a mood_rating column.
    // Until journal queries are implemented via joins/projections, treat mood
    // predicates as unsupported at the SQL layer.
    return switch (predicate.operator) {
      MoodOperator.isNull => const Constant(true),
      MoodOperator.isNotNull => const Constant(false),
      _ => const Constant(false),
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
