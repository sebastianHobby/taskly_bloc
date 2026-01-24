import 'package:freezed_annotation/freezed_annotation.dart';

part 'priority_ranking.freezed.dart';
part 'priority_ranking.g.dart';

/// Types of entities that can be ranked
enum RankingType {
  @JsonValue('value')
  value,
  @JsonValue('project')
  project,
  @JsonValue('context')
  context,
  @JsonValue('goal')
  goal,
}

/// Types of entities that can be ranked items
enum RankedEntityType {
  @JsonValue('label')
  label,
  @JsonValue('project')
  project,
}

/// User's explicit priority ranking for values, projects, contexts, or goals
@freezed
abstract class PriorityRanking with _$PriorityRanking {
  @JsonSerializable(explicitToJson: true)
  const factory PriorityRanking({
    required String id,
    required String userId,
    required RankingType rankingType,
    required List<RankedItem> items,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _PriorityRanking;

  factory PriorityRanking.fromJson(Map<String, dynamic> json) =>
      _$PriorityRankingFromJson(json);
}

/// Individual ranked item within a priority ranking
@freezed
abstract class RankedItem with _$RankedItem {
  const factory RankedItem({
    required String id,
    required String rankingId,
    required String entityId,
    required RankedEntityType entityType,
    required int weight, // 1-10 scale
    required int sortOrder, // Display order
    required String userId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _RankedItem;

  factory RankedItem.fromJson(Map<String, dynamic> json) =>
      _$RankedItemFromJson(json);
}
