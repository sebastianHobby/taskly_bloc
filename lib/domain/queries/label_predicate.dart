import 'package:flutter/foundation.dart';
import 'package:taskly_bloc/domain/models/label.dart';

/// Operators for string predicates.
enum StringOperator {
  equals,
  contains,
  startsWith,
  endsWith,
  isNull,
  isNotNull,
}

/// A single predicate in a label filter.
@immutable
sealed class LabelPredicate {
  const LabelPredicate();

  Map<String, dynamic> toJson();

  static LabelPredicate fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    return switch (type) {
      'type' => LabelTypePredicate.fromJson(json),
      'name' => LabelNamePredicate.fromJson(json),
      'color' => LabelColorPredicate.fromJson(json),
      'id' => LabelIdPredicate.fromJson(json),
      'ids' => LabelIdsPredicate.fromJson(json),
      _ => throw ArgumentError('Unknown LabelPredicate type: $type'),
    };
  }
}

/// Filter by label type (label vs value).
@immutable
final class LabelTypePredicate extends LabelPredicate {
  const LabelTypePredicate({required this.labelType});

  factory LabelTypePredicate.fromJson(Map<String, dynamic> json) {
    return LabelTypePredicate(
      labelType: LabelType.values.byName(
        json['labelType'] as String? ?? LabelType.label.name,
      ),
    );
  }

  final LabelType labelType;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': 'type',
    'labelType': labelType.name,
  };

  @override
  bool operator ==(Object other) {
    return other is LabelTypePredicate && other.labelType == labelType;
  }

  @override
  int get hashCode => labelType.hashCode;
}

/// Filter by label name.
@immutable
final class LabelNamePredicate extends LabelPredicate {
  const LabelNamePredicate({
    required this.value,
    this.operator = StringOperator.contains,
  });

  factory LabelNamePredicate.fromJson(Map<String, dynamic> json) {
    return LabelNamePredicate(
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
    return other is LabelNamePredicate &&
        other.value == value &&
        other.operator == operator;
  }

  @override
  int get hashCode => Object.hash(value, operator);
}

/// Filter by label color.
@immutable
final class LabelColorPredicate extends LabelPredicate {
  const LabelColorPredicate({required this.colorHex});

  factory LabelColorPredicate.fromJson(Map<String, dynamic> json) {
    return LabelColorPredicate(
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
    return other is LabelColorPredicate && other.colorHex == colorHex;
  }

  @override
  int get hashCode => colorHex.hashCode;
}

/// Filter by specific label ID.
@immutable
final class LabelIdPredicate extends LabelPredicate {
  const LabelIdPredicate({required this.labelId});

  factory LabelIdPredicate.fromJson(Map<String, dynamic> json) {
    return LabelIdPredicate(
      labelId: json['labelId'] as String? ?? '',
    );
  }

  final String labelId;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': 'id',
    'labelId': labelId,
  };

  @override
  bool operator ==(Object other) {
    return other is LabelIdPredicate && other.labelId == labelId;
  }

  @override
  int get hashCode => labelId.hashCode;
}

/// Filter by multiple label IDs.
@immutable
final class LabelIdsPredicate extends LabelPredicate {
  const LabelIdsPredicate({required this.labelIds});

  factory LabelIdsPredicate.fromJson(Map<String, dynamic> json) {
    final ids =
        (json['labelIds'] as List<dynamic>?)?.whereType<String>().toList(
          growable: false,
        ) ??
        const <String>[];
    return LabelIdsPredicate(labelIds: ids);
  }

  final List<String> labelIds;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': 'ids',
    'labelIds': labelIds,
  };

  @override
  bool operator ==(Object other) {
    if (other is! LabelIdsPredicate) return false;
    if (labelIds.length != other.labelIds.length) return false;
    for (var i = 0; i < labelIds.length; i++) {
      if (labelIds[i] != other.labelIds[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(labelIds);
}
