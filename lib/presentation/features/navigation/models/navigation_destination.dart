import 'package:flutter/material.dart';

/// View model for a navigation destination.
class NavigationDestinationVm {
  const NavigationDestinationVm({
    required this.id,
    required this.screenId,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
    this.sortOrder = 0,
  });

  final String id;
  final String screenId;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;
  final int sortOrder;
}
