import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Shared occurrence data - composed into Task and Project domain models.
///
/// This is only populated when instances are returned from occurrence expansion
/// methods (e.g., `getOccurrences`, `watchOccurrences`). For base entities
/// fetched via standard CRUD methods, the `occurrence` field will be null.
@immutable
class OccurrenceData extends Equatable {
  const OccurrenceData({
    required this.date,
    required this.isRescheduled,
    this.deadline,
    this.originalDate,
    this.completionId,
    this.completedAt,
    this.completionNotes,
  });

  /// The date of this occurrence (acts as the start date).
  /// For rescheduled occurrences, this is the new date.
  final DateTime date;

  /// The calculated deadline for this occurrence.
  /// Computed as: `occurrenceDate + (baseDeadline - baseStartDate)`.
  /// Null if base entity has no deadline.
  final DateTime? deadline;

  /// The original RRULE-generated date before rescheduling.
  /// Null if not rescheduled. Used for on-time reporting.
  final DateTime? originalDate;

  /// Whether this occurrence was rescheduled from its original date.
  final bool isRescheduled;

  /// The ID of the completion record, if this occurrence is completed.
  final String? completionId;

  /// When this occurrence was completed.
  final DateTime? completedAt;

  /// Optional notes added when completing this occurrence.
  final String? completionNotes;

  /// Whether this occurrence has been completed.
  bool get isCompleted => completionId != null;

  /// Whether this occurrence was completed on or before its deadline.
  /// Returns null if there's no deadline or if not completed.
  bool? get isOnTime {
    if (!isCompleted || deadline == null || completedAt == null) {
      return null;
    }
    return !completedAt!.isAfter(deadline!);
  }

  /// Whether this occurrence is overdue (past deadline and not completed).
  /// Returns false if there's no deadline.
  bool get isOverdue {
    if (deadline == null || isCompleted) {
      return false;
    }
    return DateTime.now().isAfter(deadline!);
  }

  /// Creates a copy of this OccurrenceData with the given fields replaced.
  OccurrenceData copyWith({
    DateTime? date,
    DateTime? deadline,
    DateTime? originalDate,
    bool? isRescheduled,
    String? completionId,
    DateTime? completedAt,
    String? completionNotes,
  }) {
    return OccurrenceData(
      date: date ?? this.date,
      deadline: deadline ?? this.deadline,
      originalDate: originalDate ?? this.originalDate,
      isRescheduled: isRescheduled ?? this.isRescheduled,
      completionId: completionId ?? this.completionId,
      completedAt: completedAt ?? this.completedAt,
      completionNotes: completionNotes ?? this.completionNotes,
    );
  }

  @override
  List<Object?> get props => [
    date,
    deadline,
    originalDate,
    isRescheduled,
    completionId,
    completedAt,
    completionNotes,
  ];

  @override
  String toString() {
    return 'OccurrenceData(date: $date, deadline: $deadline, '
        'isCompleted: $isCompleted, isRescheduled: $isRescheduled)';
  }
}
