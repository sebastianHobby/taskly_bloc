import 'package:flutter/foundation.dart';

/// Represents a single item in the value ranking configuration.
@immutable
class ValueRankItem {
  const ValueRankItem({
    required this.valueId,
    this.weight = 1,
    this.sortOrder = 0,
  });

  factory ValueRankItem.fromJson(Map<String, dynamic> json) {
    return ValueRankItem(
      valueId: json['valueId'] as String,
      weight: json['weight'] as int? ?? 1,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  final String valueId;
  final int weight;
  final int sortOrder;

  Map<String, dynamic> toJson() => {
    'valueId': valueId,
    'weight': weight,
    'sortOrder': sortOrder,
  };

  ValueRankItem copyWith({
    String? valueId,
    int? weight,
    int? sortOrder,
  }) {
    return ValueRankItem(
      valueId: valueId ?? this.valueId,
      weight: weight ?? this.weight,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValueRankItem &&
          runtimeType == other.runtimeType &&
          valueId == other.valueId &&
          weight == other.weight &&
          sortOrder == other.sortOrder;

  @override
  int get hashCode => valueId.hashCode ^ weight.hashCode ^ sortOrder.hashCode;
}

/// Configuration for value ranking.
@immutable
class ValueRanking {
  const ValueRanking({
    this.items = const [],
  });

  factory ValueRanking.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>?;
    final items =
        itemsJson
            ?.map((e) => ValueRankItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];
    return ValueRanking(items: items);
  }

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValueRanking &&
          runtimeType == other.runtimeType &&
          listEquals(items, other.items);

  @override
  int get hashCode => items.hashCode;
}
