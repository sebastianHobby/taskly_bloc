import 'package:flutter/foundation.dart';
import 'package:taskly_bloc/domain/domain.dart' show AppSettings;
import 'package:taskly_bloc/domain/models/models.dart' show AppSettings;
import 'package:taskly_bloc/domain/models/settings.dart' show AppSettings;

/// A single ranked item in a value ranking.
@immutable
class ValueRankItem {
  const ValueRankItem({
    required this.labelId,
    required this.weight,
    this.sortOrder = 0,
  });

  factory ValueRankItem.fromJson(Map<String, dynamic> json) {
    return ValueRankItem(
      labelId: json['labelId'] as String,
      weight: json['weight'] as int? ?? 5,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  /// The ID of the value label being ranked.
  final String labelId;

  /// Weight from 1-10 indicating importance.
  final int weight;

  /// Display order within the ranking.
  final int sortOrder;

  Map<String, dynamic> toJson() => {
    'labelId': labelId,
    'weight': weight,
    'sortOrder': sortOrder,
  };

  ValueRankItem copyWith({
    String? labelId,
    int? weight,
    int? sortOrder,
  }) {
    return ValueRankItem(
      labelId: labelId ?? this.labelId,
      weight: weight ?? this.weight,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ValueRankItem &&
        other.labelId == labelId &&
        other.weight == weight &&
        other.sortOrder == sortOrder;
  }

  @override
  int get hashCode => Object.hash(labelId, weight, sortOrder);
}

/// User's value ranking for allocation.
///
/// Stored in [AppSettings.valueRanking]. This replaces the
/// priority_rankings and ranked_items tables for RankingType.value.
@immutable
class ValueRanking {
  const ValueRanking({
    this.items = const [],
  });

  factory ValueRanking.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>?;
    final items =
        rawItems
            ?.map((e) => ValueRankItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return ValueRanking(items: items);
  }

  /// Ranked value labels with weights.
  final List<ValueRankItem> items;

  Map<String, dynamic> toJson() => {
    'items': items.map((e) => e.toJson()).toList(),
  };

  ValueRanking copyWith({
    List<ValueRankItem>? items,
  }) {
    return ValueRanking(
      items: items ?? this.items,
    );
  }

  /// Get the weight for a specific label ID.
  /// Returns null if the label is not ranked.
  int? weightForLabel(String labelId) {
    final item = items.where((i) => i.labelId == labelId).firstOrNull;
    return item?.weight;
  }

  /// Update or add a ranking for a label.
  ValueRanking upsertItem(ValueRankItem item) {
    final existingIndex = items.indexWhere((i) => i.labelId == item.labelId);
    final newItems = List<ValueRankItem>.from(items);
    if (existingIndex >= 0) {
      newItems[existingIndex] = item;
    } else {
      newItems.add(item);
    }
    return copyWith(items: newItems);
  }

  /// Remove a ranking for a label.
  ValueRanking removeItem(String labelId) {
    return copyWith(
      items: items.where((i) => i.labelId != labelId).toList(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ValueRanking && listEquals(other.items, items);
  }

  @override
  int get hashCode => Object.hashAll(items);

  @override
  String toString() => 'ValueRanking(${items.length} items)';
}
