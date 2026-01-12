import 'package:freezed_annotation/freezed_annotation.dart';

part 'soft_gates_settings.freezed.dart';

/// Settings controlling soft gates (warnings).
@freezed
abstract class SoftGatesSettings with _$SoftGatesSettings {
  const factory SoftGatesSettings({
    /// A task is urgent when its deadline is due within this many days
    /// (or overdue).
    @Default(7) int urgentDeadlineWithinDays,

    /// A task is stale when it has not been updated within this many days.
    @Default(30) int staleAfterDaysWithoutUpdates,
  }) = _SoftGatesSettings;

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
}

/// Extension for JSON serialization.
extension SoftGatesSettingsJson on SoftGatesSettings {
  Map<String, dynamic> toJson() => <String, dynamic>{
    'urgentDeadlineWithinDays': urgentDeadlineWithinDays,
    'staleAfterDaysWithoutUpdates': staleAfterDaysWithoutUpdates,
  };
}
