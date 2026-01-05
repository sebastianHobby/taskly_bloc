import 'package:flutter/foundation.dart';

/// Operators for string predicates.
enum StringOperator {
  equals,
  contains,
  startsWith,
  endsWith,
  isNull,
  isNotNull,
}

/// A single predicate in a value filter.
@immutable
sealed class ValuePredicate {
  const ValuePredicate();

  Map<String, dynamic> toJson();

  static ValuePredicate fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    return switch (type) {
      'name' => ValueNamePredicate.fromJson(json),
      'color' => ValueColorPredicate.fromJson(json),
      'id' => ValueIdPredicate.fromJson(json),
      'ids' => ValueIdsPredicate.fromJson(json),
      _ => throw ArgumentError('Unknown ValuePredicate type: $type'),
    };
  }
}

/// Filter by value name.
@immutable
final class ValueNamePredicate extends ValuePredicate {
  const ValueNamePredicate({
    required this.value,
    this.operator = StringOperator.contains,
  });

  factory ValueNamePredicate.fromJson(Map<String, dynamic> json) {
    return ValueNamePredicate(
      value: json['value'] as String? ?? '',
      operator: StringOperator.values.byName(
        json['operator'] as String? ?? StringOperator.contains.name,
      ),
    );
  }

  final String value;
  final StringOperator operator;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': 'name',
    'value': value,
    'operator': operator.name,
  };

  @override
  bool operator ==(Object other) {
    return other is ValueNamePredicate &&
        other.value == value &&
        other.operator == operator;
  }

  @override
  int get hashCode => Object.hash(value, operator);
}

/// Filter by value color.
@immutable
final class ValueColorPredicate extends ValuePredicate {
  const ValueColorPredicate({required this.colorHex});

  factory ValueColorPredicate.fromJson(Map<String, dynamic> json) {
    return ValueColorPredicate(
      colorHex: json['colorHex'] as String? ?? '',
    );
  }

  final String colorHex;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': 'color',
    'colorHex': colorHex,
  };

  @override
  bool operator ==(Object other) {
    return other is ValueColorPredicate && other.colorHex == colorHex;
  }

  @override
  int get hashCode => colorHex.hashCode;
}

/// Filter by value ID.
@immutable
final class ValueIdPredicate extends ValuePredicate {
  const ValueIdPredicate({required this.valueId});

  factory ValueIdPredicate.fromJson(Map<String, dynamic> json) {
    return ValueIdPredicate(
      valueId: json['valueId'] as String? ?? '',
    );
  }

  final String valueId;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': 'id',
    'valueId': valueId,
  };

  @override
  bool operator ==(Object other) {
    return other is ValueIdPredicate && other.valueId == valueId;
  }

  @override
  int get hashCode => valueId.hashCode;
}

/// Filter by multiple value IDs.
@immutable
final class ValueIdsPredicate extends ValuePredicate {
  const ValueIdsPredicate({required this.valueIds});

  factory ValueIdsPredicate.fromJson(Map<String, dynamic> json) {
    final ids =
        (json['valueIds'] as List<dynamic>?)?.whereType<String>().toList(
          growable: false,
        ) ??
        const <String>[];
    return ValueIdsPredicate(valueIds: ids);
  }

  final List<String> valueIds;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': 'ids',
    'valueIds': valueIds,
  };

  @override
  bool operator ==(Object other) {
    if (other is! ValueIdsPredicate) return false;
    if (valueIds.length != other.valueIds.length) return false;
    for (var i = 0; i < valueIds.length; i++) {
      if (valueIds[i] != other.valueIds[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(valueIds);
}
