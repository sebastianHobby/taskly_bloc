import 'package:freezed_annotation/freezed_annotation.dart';

part 'allocation_settings.freezed.dart';

/// Allocation strategy types for task distribution.
enum AllocationStrategyType {
  proportional,
  urgencyWeighted,
  roundRobin,
  minimumViable,
  dynamic,
  topCategories,
}

/// User's preferred allocation strategy and parameters.
@freezed
abstract class AllocationSettings with _$AllocationSettings {
  const factory AllocationSettings({
    @Default(AllocationStrategyType.proportional)
    AllocationStrategyType strategyType,
    @Default(0.4) double urgencyInfluence,

    /// When true, urgent tasks always appear regardless of value allocation.
    @Default(false) bool alwaysIncludeUrgent,
    @Default(1) int minimumTasksPerCategory,
    @Default(3) int topNCategories,
    @Default(10) int dailyTaskLimit,
    @Default(true) bool showExcludedUrgentWarning,
  }) = _AllocationSettings;

  factory AllocationSettings.fromJson(Map<String, dynamic> json) {
    return AllocationSettings(
      strategyType: _parseStrategyType(json['strategyType'] as String?),
      urgencyInfluence: (json['urgencyInfluence'] as num?)?.toDouble() ?? 0.4,
      alwaysIncludeUrgent: json['alwaysIncludeUrgent'] as bool? ?? false,
      minimumTasksPerCategory: json['minimumTasksPerCategory'] as int? ?? 1,
      topNCategories: json['topNCategories'] as int? ?? 3,
      dailyTaskLimit: json['dailyTaskLimit'] as int? ?? 10,
      showExcludedUrgentWarning:
          json['showExcludedUrgentWarning'] as bool? ?? true,
    );
  }

  static AllocationStrategyType _parseStrategyType(String? value) {
    if (value == null) return AllocationStrategyType.proportional;
    return AllocationStrategyType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AllocationStrategyType.proportional,
    );
  }
}

/// Extension for JSON serialization.
extension AllocationSettingsJson on AllocationSettings {
  Map<String, dynamic> toJson() => {
    'strategyType': strategyType.name,
    'urgencyInfluence': urgencyInfluence,
    'alwaysIncludeUrgent': alwaysIncludeUrgent,
    'minimumTasksPerCategory': minimumTasksPerCategory,
    'topNCategories': topNCategories,
    'dailyTaskLimit': dailyTaskLimit,
    'showExcludedUrgentWarning': showExcludedUrgentWarning,
  };
}
