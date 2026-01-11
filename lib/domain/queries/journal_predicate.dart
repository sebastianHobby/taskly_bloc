import 'package:flutter/foundation.dart';
import 'package:taskly_bloc/domain/wellbeing/model/mood_rating.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart'
    show DateOperator, RelativeComparison;

/// Operators for mood predicates.
enum MoodOperator {
  equals,
  greaterThanOrEqual,
  lessThanOrEqual,
  isNull,
  isNotNull,
}

/// Operators for text predicates.
enum TextOperator {
  contains,
  equals,
  isEmpty,
  isNotEmpty,
}

/// A single predicate in a journal entry filter.
@immutable
sealed class JournalPredicate {
  const JournalPredicate();

  Map<String, dynamic> toJson();

  static JournalPredicate fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    return switch (type) {
      'id' => JournalIdPredicate.fromJson(json),
      'date' => JournalDatePredicate.fromJson(json),
      'mood' => JournalMoodPredicate.fromJson(json),
      'text' => JournalTextPredicate.fromJson(json),
      _ => throw ArgumentError('Unknown JournalPredicate type: $type'),
    };
  }
}

/// Filter by journal entry ID.
@immutable
final class JournalIdPredicate extends JournalPredicate {
  const JournalIdPredicate({required this.id});

  factory JournalIdPredicate.fromJson(Map<String, dynamic> json) {
    return JournalIdPredicate(id: json['id'] as String? ?? '');
  }

  final String id;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': 'id',
    'id': id,
  };

  @override
  bool operator ==(Object other) {
    return other is JournalIdPredicate && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Filter by journal entry date.
@immutable
final class JournalDatePredicate extends JournalPredicate {
  const JournalDatePredicate({
    required this.operator,
    this.date,
    this.startDate,
    this.endDate,
    this.relativeComparison,
    this.relativeDays,
  });

  factory JournalDatePredicate.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String key) {
      final value = json[key] as String?;
      return value == null ? null : DateTime.tryParse(value);
    }

    return JournalDatePredicate(
      operator: DateOperator.values.byName(
        json['operator'] as String? ?? DateOperator.on.name,
      ),
      date: parseDate('date'),
      startDate: parseDate('startDate'),
      endDate: parseDate('endDate'),
      relativeComparison: (json['relativeComparison'] as String?) != null
          ? RelativeComparison.values.byName(
              json['relativeComparison'] as String,
            )
          : null,
      relativeDays: json['relativeDays'] as int?,
    );
  }

  final DateOperator operator;

  /// Pivot date for single-date operators.
  final DateTime? date;

  /// Range start for [DateOperator.between].
  final DateTime? startDate;

  /// Range end for [DateOperator.between].
  final DateTime? endDate;

  /// Used when [operator] is [DateOperator.relative].
  final RelativeComparison? relativeComparison;

  /// Days offset from today for relative comparison.
  final int? relativeDays;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': 'date',
    'operator': operator.name,
    if (date != null) 'date': date!.toIso8601String(),
    if (startDate != null) 'startDate': startDate!.toIso8601String(),
    if (endDate != null) 'endDate': endDate!.toIso8601String(),
    if (relativeComparison != null)
      'relativeComparison': relativeComparison!.name,
    if (relativeDays != null) 'relativeDays': relativeDays,
  };

  @override
  bool operator ==(Object other) {
    return other is JournalDatePredicate &&
        other.operator == operator &&
        other.date == date &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.relativeComparison == relativeComparison &&
        other.relativeDays == relativeDays;
  }

  @override
  int get hashCode => Object.hash(
    operator,
    date,
    startDate,
    endDate,
    relativeComparison,
    relativeDays,
  );
}

/// Filter by mood rating.
@immutable
final class JournalMoodPredicate extends JournalPredicate {
  const JournalMoodPredicate({
    required this.operator,
    this.value,
  });

  factory JournalMoodPredicate.fromJson(Map<String, dynamic> json) {
    final valueInt = json['value'] as int?;
    return JournalMoodPredicate(
      operator: MoodOperator.values.byName(
        json['operator'] as String? ?? MoodOperator.equals.name,
      ),
      value: valueInt != null ? MoodRating.fromValue(valueInt) : null,
    );
  }

  final MoodOperator operator;
  final MoodRating? value;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': 'mood',
    'operator': operator.name,
    if (value != null) 'value': value!.value,
  };

  @override
  bool operator ==(Object other) {
    return other is JournalMoodPredicate &&
        other.operator == operator &&
        other.value == value;
  }

  @override
  int get hashCode => Object.hash(operator, value);
}

/// Filter by journal text content.
@immutable
final class JournalTextPredicate extends JournalPredicate {
  const JournalTextPredicate({
    required this.operator,
    this.value,
  });

  factory JournalTextPredicate.fromJson(Map<String, dynamic> json) {
    return JournalTextPredicate(
      operator: TextOperator.values.byName(
        json['operator'] as String? ?? TextOperator.contains.name,
      ),
      value: json['value'] as String?,
    );
  }

  final TextOperator operator;
  final String? value;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': 'text',
    'operator': operator.name,
    if (value != null) 'value': value,
  };

  @override
  bool operator ==(Object other) {
    return other is JournalTextPredicate &&
        other.operator == operator &&
        other.value == value;
  }

  @override
  int get hashCode => Object.hash(operator, value);
}
