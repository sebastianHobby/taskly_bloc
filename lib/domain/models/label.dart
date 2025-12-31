import 'package:flutter/foundation.dart';

/// Type of label - either a category label or a value tag.
enum LabelType {
  label,
  value,
}

/// System label types for special functionality.
enum SystemLabelType {
  pinned,
}

/// Domain representation of a Label used across the app.
@immutable
class Label {
  const Label({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    this.color,
    this.type = LabelType.label,
    this.iconName,
    this.isSystemLabel = false,
    this.systemLabelType,
  });

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String name;
  final String? color;
  final LabelType type;
  final String? iconName;
  final bool isSystemLabel;
  final SystemLabelType? systemLabelType;

  /// Creates a copy of this Label with the given fields replaced.
  Label copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? name,
    String? color,
    LabelType? type,
    String? iconName,
    bool? isSystemLabel,
    SystemLabelType? systemLabelType,
  }) {
    return Label(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      color: color ?? this.color,
      type: type ?? this.type,
      iconName: iconName ?? this.iconName,
      isSystemLabel: isSystemLabel ?? this.isSystemLabel,
      systemLabelType: systemLabelType ?? this.systemLabelType,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Label &&
        other.id == id &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.name == name &&
        other.color == color &&
        other.type == type &&
        other.iconName == iconName &&
        other.isSystemLabel == isSystemLabel &&
        other.systemLabelType == systemLabelType;
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    name,
    color,
    type,
    iconName,
    isSystemLabel,
    systemLabelType,
  );

  @override
  String toString() {
    return 'Label(id: $id, createdAt: $createdAt, updatedAt: $updatedAt, '
        'name: $name, color: $color, type: $type, iconName: $iconName, '
        'isSystemLabel: $isSystemLabel, systemLabelType: $systemLabelType)';
  }
}
