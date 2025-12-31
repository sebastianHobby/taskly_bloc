/// Settings controlling workflow-run soft gates (warnings).
class SoftGatesSettings {
  const SoftGatesSettings({
    this.urgentDeadlineWithinDays = 7,
    this.staleAfterDaysWithoutUpdates = 30,
  });

  factory SoftGatesSettings.fromJson(Map<String, dynamic> json) {
    int clampPositiveInt(Object? value, int fallback) {
      final parsed = value is int ? value : (value is num ? value.toInt() : 0);
      if (parsed <= 0) return fallback;
      return parsed;
    }

    return SoftGatesSettings(
      urgentDeadlineWithinDays: clampPositiveInt(
        json['urgentDeadlineWithinDays'],
        7,
      ),
      staleAfterDaysWithoutUpdates: clampPositiveInt(
        json['staleAfterDaysWithoutUpdates'],
        30,
      ),
    );
  }

  /// A task is urgent when its deadline is due within this many days
  /// (or overdue).
  final int urgentDeadlineWithinDays;

  /// A task is stale when it has not been updated within this many days.
  final int staleAfterDaysWithoutUpdates;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'urgentDeadlineWithinDays': urgentDeadlineWithinDays,
    'staleAfterDaysWithoutUpdates': staleAfterDaysWithoutUpdates,
  };

  SoftGatesSettings copyWith({
    int? urgentDeadlineWithinDays,
    int? staleAfterDaysWithoutUpdates,
  }) {
    return SoftGatesSettings(
      urgentDeadlineWithinDays:
          urgentDeadlineWithinDays ?? this.urgentDeadlineWithinDays,
      staleAfterDaysWithoutUpdates:
          staleAfterDaysWithoutUpdates ?? this.staleAfterDaysWithoutUpdates,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SoftGatesSettings &&
        other.urgentDeadlineWithinDays == urgentDeadlineWithinDays &&
        other.staleAfterDaysWithoutUpdates == staleAfterDaysWithoutUpdates;
  }

  @override
  int get hashCode =>
      Object.hash(urgentDeadlineWithinDays, staleAfterDaysWithoutUpdates);
}
