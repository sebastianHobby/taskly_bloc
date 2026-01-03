import 'package:freezed_annotation/freezed_annotation.dart';

part 'value_ranking.freezed.dart';

/// A single ranked item in a value ranking.
@freezed
abstract class ValueRankItem with _$ValueRankItem {
  const factory ValueRankItem({
    /// The ID of the value label being ranked.
    required String labelId,

    /// Weight from 1-10 indicating importance.
    @Default(5) int weight,

    /// Display order within the ranking.
    @Default(0) int sortOrder,
  }) = _ValueRankItem;

  factory ValueRankItem.fromJson(Map<String, dynamic> json) {
    return ValueRankItem(
      labelId: json['labelId'] as String,
      weight: json['weight'] as int? ?? 5,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }
}

/// Extension for JSON serialization.
extension ValueRankItemJson on ValueRankItem {
  Map<String, dynamic> toJson() => {
    'labelId': labelId,
    'weight': weight,
    'sortOrder': sortOrder,
  };
}

/// User's value ranking for allocation.
@freezed
abstract class ValueRanking with _$ValueRanking {
  const factory ValueRanking({
    /// Ranked value labels with weights.
    @Default([]) List<ValueRankItem> items,
  }) = _ValueRanking;

  factory ValueRanking.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>?;
    final items =
        rawItems
            ?.map((e) => ValueRankItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return ValueRanking(items: items);
  }
}

/// Extension for JSON serialization.
extension ValueRankingJson on ValueRanking {
  Map<String, dynamic> toJson() => {
    'items': items.map((e) => e.toJson()).toList(),
  };
}
