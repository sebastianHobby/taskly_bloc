import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/models/screens/screen_category.dart';
import 'package:taskly_bloc/domain/models/screens/screen_source.dart';

/// View model for a navigation destination built from a ScreenDefinition.
class NavigationDestinationVm {
  const NavigationDestinationVm({
    required this.id,
    required this.screenId,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
    required this.screenSource,
    this.badgeStream,
    this.sortOrder = 0,
    this.category = ScreenCategory.workspace,
  });

  final String id;
  final String screenId;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;
  final ScreenSource screenSource;
  final Stream<int>? badgeStream;
  final int sortOrder;
  final ScreenCategory category;

  /// Convenience getter for system screen check.
  bool get isSystemScreen => screenSource == ScreenSource.systemTemplate;
}
