import 'package:flutter/foundation.dart';
import 'package:taskly_bloc/domain/domain.dart' show AppSettings;
import 'package:taskly_bloc/domain/models/models.dart' show AppSettings;
import 'package:taskly_bloc/domain/models/settings.dart' show AppSettings;

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
///
/// Stored in [AppSettings.allocation]. This replaces the
/// allocation_preferences table.
@immutable
class AllocationSettings {
  const AllocationSettings({
    this.strategyType = AllocationStrategyType.proportional,
    this.urgencyInfluence = 0.4,
    this.minimumTasksPerCategory = 1,
    this.topNCategories = 3,
    this.dailyTaskLimit = 10,
    this.showExcludedUrgentWarning = true,
  });

  factory AllocationSettings.fromJson(Map<String, dynamic> json) {
    return AllocationSettings(
      strategyType: _parseStrategyType(json['strategyType'] as String?),
      urgencyInfluence: (json['urgencyInfluence'] as num?)?.toDouble() ?? 0.4,
      minimumTasksPerCategory: json['minimumTasksPerCategory'] as int? ?? 1,
      topNCategories: json['topNCategories'] as int? ?? 3,
      dailyTaskLimit: json['dailyTaskLimit'] as int? ?? 10,
      showExcludedUrgentWarning:
          json['showExcludedUrgentWarning'] as bool? ?? true,
    );
  }

  final AllocationStrategyType strategyType;
  final double urgencyInfluence;
  final int minimumTasksPerCategory;
  final int topNCategories;
  final int dailyTaskLimit;
  final bool showExcludedUrgentWarning;

  Map<String, dynamic> toJson() => {
    'strategyType': strategyType.name,
    'urgencyInfluence': urgencyInfluence,
    'minimumTasksPerCategory': minimumTasksPerCategory,
    'topNCategories': topNCategories,
    'dailyTaskLimit': dailyTaskLimit,
    'showExcludedUrgentWarning': showExcludedUrgentWarning,
  };

  AllocationSettings copyWith({
    AllocationStrategyType? strategyType,
    double? urgencyInfluence,
    int? minimumTasksPerCategory,
    int? topNCategories,
    int? dailyTaskLimit,
    bool? showExcludedUrgentWarning,
  }) {
    return AllocationSettings(
      strategyType: strategyType ?? this.strategyType,
      urgencyInfluence: urgencyInfluence ?? this.urgencyInfluence,
      minimumTasksPerCategory:
          minimumTasksPerCategory ?? this.minimumTasksPerCategory,
      topNCategories: topNCategories ?? this.topNCategories,
      dailyTaskLimit: dailyTaskLimit ?? this.dailyTaskLimit,
      showExcludedUrgentWarning:
          showExcludedUrgentWarning ?? this.showExcludedUrgentWarning,
    );
  }

  static AllocationStrategyType _parseStrategyType(String? value) {
    if (value == null) return AllocationStrategyType.proportional;
    return AllocationStrategyType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AllocationStrategyType.proportional,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AllocationSettings &&
        other.strategyType == strategyType &&
        other.urgencyInfluence == urgencyInfluence &&
        other.minimumTasksPerCategory == minimumTasksPerCategory &&
        other.topNCategories == topNCategories &&
        other.dailyTaskLimit == dailyTaskLimit &&
        other.showExcludedUrgentWarning == showExcludedUrgentWarning;
  }

  @override
  int get hashCode => Object.hash(
    strategyType,
    urgencyInfluence,
    minimumTasksPerCategory,
    topNCategories,
    dailyTaskLimit,
    showExcludedUrgentWarning,
  );

  @override
  String toString() =>
      'AllocationSettings(strategyType: $strategyType, dailyTaskLimit: $dailyTaskLimit)';
}
