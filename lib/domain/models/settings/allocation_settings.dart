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

/// Simplified urgency modes for Focus screen (DR-015).
///
/// These map to combinations of [AllocationStrategyType], [urgencyInfluence],
/// and [alwaysIncludeUrgent] for a clearer user mental model.
enum UrgencyMode {
  /// ⚖️ Pure value-based selection, deadlines ignored.
  /// Maps to: strategyType=proportional, urgencyInfluence=0.0
  valuesOnly,

  /// 🔀 Values + deadlines combined with adjustable slider.
  /// Maps to: strategyType=urgencyWeighted, urgencyInfluence=0.4 (adjustable)
  balanced,

  /// 🚨 Urgent tasks always appear, remaining slots by values.
  /// Maps to: strategyType=proportional, alwaysIncludeUrgent=true
  urgentFirst,
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
    this.alwaysIncludeUrgent = false,
    this.minimumTasksPerCategory = 1,
    this.topNCategories = 3,
    this.dailyTaskLimit = 10,
    this.showExcludedUrgentWarning = true,
  });

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

  final AllocationStrategyType strategyType;
  final double urgencyInfluence;

  /// When true, urgent tasks always appear regardless of value allocation.
  /// Used by [UrgencyMode.urgentFirst] (DR-015).
  final bool alwaysIncludeUrgent;
  final int minimumTasksPerCategory;
  final int topNCategories;
  final int dailyTaskLimit;
  final bool showExcludedUrgentWarning;

  /// Returns the effective [UrgencyMode] based on current settings (DR-015).
  UrgencyMode get urgencyMode {
    if (alwaysIncludeUrgent) return UrgencyMode.urgentFirst;
    if (strategyType == AllocationStrategyType.urgencyWeighted) {
      return UrgencyMode.balanced;
    }
    if (urgencyInfluence == 0.0) return UrgencyMode.valuesOnly;
    // Default to balanced if urgencyInfluence > 0
    return UrgencyMode.balanced;
  }

  /// Creates settings configured for the given [UrgencyMode] (DR-015).
  AllocationSettings withUrgencyMode(UrgencyMode mode) {
    return switch (mode) {
      UrgencyMode.valuesOnly => copyWith(
        strategyType: AllocationStrategyType.proportional,
        urgencyInfluence: 0,
        alwaysIncludeUrgent: false,
      ),
      UrgencyMode.balanced => copyWith(
        strategyType: AllocationStrategyType.urgencyWeighted,
        urgencyInfluence: urgencyInfluence > 0 ? urgencyInfluence : 0.4,
        alwaysIncludeUrgent: false,
      ),
      UrgencyMode.urgentFirst => copyWith(
        strategyType: AllocationStrategyType.proportional,
        alwaysIncludeUrgent: true,
      ),
    };
  }

  Map<String, dynamic> toJson() => {
    'strategyType': strategyType.name,
    'urgencyInfluence': urgencyInfluence,
    'alwaysIncludeUrgent': alwaysIncludeUrgent,
    'minimumTasksPerCategory': minimumTasksPerCategory,
    'topNCategories': topNCategories,
    'dailyTaskLimit': dailyTaskLimit,
    'showExcludedUrgentWarning': showExcludedUrgentWarning,
  };

  AllocationSettings copyWith({
    AllocationStrategyType? strategyType,
    double? urgencyInfluence,
    bool? alwaysIncludeUrgent,
    int? minimumTasksPerCategory,
    int? topNCategories,
    int? dailyTaskLimit,
    bool? showExcludedUrgentWarning,
  }) {
    return AllocationSettings(
      strategyType: strategyType ?? this.strategyType,
      urgencyInfluence: urgencyInfluence ?? this.urgencyInfluence,
      alwaysIncludeUrgent: alwaysIncludeUrgent ?? this.alwaysIncludeUrgent,
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
        other.alwaysIncludeUrgent == alwaysIncludeUrgent &&
        other.minimumTasksPerCategory == minimumTasksPerCategory &&
        other.topNCategories == topNCategories &&
        other.dailyTaskLimit == dailyTaskLimit &&
        other.showExcludedUrgentWarning == showExcludedUrgentWarning;
  }

  @override
  int get hashCode => Object.hash(
    strategyType,
    urgencyInfluence,
    alwaysIncludeUrgent,
    minimumTasksPerCategory,
    topNCategories,
    dailyTaskLimit,
    showExcludedUrgentWarning,
  );

  @override
  String toString() =>
      'AllocationSettings(strategyType: $strategyType, dailyTaskLimit: $dailyTaskLimit)';
}
