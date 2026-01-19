import 'package:taskly_domain/src/time/date_only.dart';

/// Persisted My Day ritual state.
///
/// Stores the UTC day key for the last completed ritual and the ordered task
/// ids selected for that day.
class MyDayRitualState {
  const MyDayRitualState({
    this.completedDayUtc,
    this.selectedTaskIds = const <String>[],
    this.acceptedDueTaskIds = const <String>[],
    this.acceptedStartsTaskIds = const <String>[],
    this.acceptedFocusTaskIds = const <String>[],
    this.candidateDueTaskIds = const <String>[],
    this.candidateStartsTaskIds = const <String>[],
  });

  factory MyDayRitualState.fromJson(Map<String, dynamic> json) {
    return MyDayRitualState(
      completedDayUtc: json['completedDayUtc'] as String?,
      selectedTaskIds:
          (json['selectedTaskIds'] as List<dynamic>?)
              ?.whereType<String>()
              .toList(growable: false) ??
          const <String>[],
      acceptedDueTaskIds:
          (json['acceptedDueTaskIds'] as List<dynamic>?)
              ?.whereType<String>()
              .toList(growable: false) ??
          const <String>[],
      acceptedStartsTaskIds:
          (json['acceptedStartsTaskIds'] as List<dynamic>?)
              ?.whereType<String>()
              .toList(growable: false) ??
          const <String>[],
      acceptedFocusTaskIds:
          (json['acceptedFocusTaskIds'] as List<dynamic>?)
              ?.whereType<String>()
              .toList(growable: false) ??
          const <String>[],
      candidateDueTaskIds:
          (json['candidateDueTaskIds'] as List<dynamic>?)
              ?.whereType<String>()
              .toList(growable: false) ??
          const <String>[],
      candidateStartsTaskIds:
          (json['candidateStartsTaskIds'] as List<dynamic>?)
              ?.whereType<String>()
              .toList(growable: false) ??
          const <String>[],
    );
  }

  /// Date-only UTC string (`YYYY-MM-DD`) for the last completed ritual.
  final String? completedDayUtc;

  /// Ordered task ids selected for the day.
  final List<String> selectedTaskIds;

  /// Ordered task ids accepted from the ritual "Overdue & due" section.
  final List<String> acceptedDueTaskIds;

  /// Ordered task ids accepted from the ritual "Starts today" section.
  final List<String> acceptedStartsTaskIds;

  /// Ordered task ids accepted from the ritual "Suggestions" section.
  final List<String> acceptedFocusTaskIds;

  /// Ordered task ids that were in the ritual "Overdue & due" candidate
  /// universe at the time the ritual was confirmed.
  ///
  /// This is used to explain "not selected" counts and support add-on flows
  /// without introducing new suggestions after the ritual.
  final List<String> candidateDueTaskIds;

  /// Ordered task ids that were in the ritual "Starts today" candidate
  /// universe at the time the ritual was confirmed.
  ///
  /// This is used to explain "not selected" counts and support add-on flows
  /// without introducing new suggestions after the ritual.
  final List<String> candidateStartsTaskIds;

  bool get hasSelection => selectedTaskIds.isNotEmpty;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'completedDayUtc': completedDayUtc,
    'selectedTaskIds': selectedTaskIds,
    'acceptedDueTaskIds': acceptedDueTaskIds,
    'acceptedStartsTaskIds': acceptedStartsTaskIds,
    'acceptedFocusTaskIds': acceptedFocusTaskIds,
    'candidateDueTaskIds': candidateDueTaskIds,
    'candidateStartsTaskIds': candidateStartsTaskIds,
  };

  /// Returns true when the ritual was completed for [dayUtc].
  bool isCompletedFor(DateTime dayUtc) {
    final dayKey = encodeDateOnly(dayUtc);
    return completedDayUtc == dayKey;
  }
}
