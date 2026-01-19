import 'package:taskly_domain/src/time/date_only.dart';

/// Persisted My Day ritual state.
///
/// Stores the UTC day key for the last completed ritual and the ordered task
/// ids selected for that day.
class MyDayRitualState {
  const MyDayRitualState({
    this.completedDayUtc,
    this.selectedTaskIds = const <String>[],
  });

  factory MyDayRitualState.fromJson(Map<String, dynamic> json) {
    return MyDayRitualState(
      completedDayUtc: json['completedDayUtc'] as String?,
      selectedTaskIds:
          (json['selectedTaskIds'] as List<dynamic>?)
              ?.whereType<String>()
              .toList(growable: false) ??
          const <String>[],
    );
  }

  /// Date-only UTC string (`YYYY-MM-DD`) for the last completed ritual.
  final String? completedDayUtc;

  /// Ordered task ids selected for the day.
  final List<String> selectedTaskIds;

  bool get hasSelection => selectedTaskIds.isNotEmpty;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'completedDayUtc': completedDayUtc,
    'selectedTaskIds': selectedTaskIds,
  };

  /// Returns true when the ritual was completed for [dayUtc].
  bool isCompletedFor(DateTime dayUtc) {
    final dayKey = encodeDateOnly(dayUtc);
    return completedDayUtc == dayKey;
  }
}
