import 'package:flutter/foundation.dart';

/// User preferences for a specific screen.
///
/// Stored in `AppSettings.screenPreferences` keyed by screenKey.
/// This replaces the `sort_order` and `is_active` columns from the
/// screen_definitions table for system screens.
@immutable
class ScreenPreferences {
  const ScreenPreferences({
    this.sortOrder,
    this.isActive = true,
  });

  factory ScreenPreferences.fromJson(Map<String, dynamic> json) {
    return ScreenPreferences(
      sortOrder: json['sortOrder'] as int?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Custom sort order. Null means use default from template.
  final int? sortOrder;

  /// Whether the screen is visible in navigation.
  final bool isActive;

  Map<String, dynamic> toJson() => {
    if (sortOrder != null) 'sortOrder': sortOrder,
    'isActive': isActive,
  };

  ScreenPreferences copyWith({
    int? sortOrder,
    bool? isActive,
  }) {
    return ScreenPreferences(
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScreenPreferences &&
        other.sortOrder == sortOrder &&
        other.isActive == isActive;
  }

  @override
  int get hashCode => Object.hash(sortOrder, isActive);

  @override
  String toString() =>
      'ScreenPreferences(sortOrder: $sortOrder, isActive: $isActive)';
}
