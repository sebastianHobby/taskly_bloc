import 'package:freezed_annotation/freezed_annotation.dart';

part 'allocation_preference.freezed.dart';
part 'allocation_preference.g.dart';

/// Allocation strategy types for next actions
enum AllocationStrategyType {
  @JsonValue('proportional')
  proportional,
  @JsonValue('urgency_weighted')
  urgencyWeighted,
  @JsonValue('round_robin')
  roundRobin,
  @JsonValue('minimum_viable')
  minimumViable,
  @JsonValue('dynamic')
  dynamic,
  @JsonValue('top_categories')
  topCategories,
}

/// User's allocation strategy preferences
@freezed
abstract class AllocationPreference with _$AllocationPreference {
  const factory AllocationPreference({
    required String id,
    required String userId,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(AllocationStrategyType.proportional)
    AllocationStrategyType strategyType,
    @Default(0.4) double urgencyInfluence, // For urgency_weighted (0-1)
    @Default(1) int minimumTasksPerCategory, // For minimum_viable
    @Default(3) int topNCategories, // For top_categories
  }) = _AllocationPreference;

  factory AllocationPreference.fromJson(Map<String, dynamic> json) =>
      _$AllocationPreferenceFromJson(json);
}
