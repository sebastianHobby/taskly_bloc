import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/features/guided_tour/guided_tour_anchors.dart';
import 'package:taskly_bloc/presentation/features/navigation/models/navigation_destination.dart';

class ScaffoldWithNavigationBar extends StatelessWidget {
  const ScaffoldWithNavigationBar({
    required this.body,
    required this.destinations,
    required this.activeScreenId,
    required this.bottomVisibleCount,
    required this.onDestinationSelected,
    required this.onMorePressed,
    super.key,
  });

  final Widget body;
  final List<NavigationDestinationVm> destinations;
  final String? activeScreenId;
  final int bottomVisibleCount;
  final ValueChanged<String> onDestinationSelected;
  final VoidCallback onMorePressed;

  @override
  Widget build(BuildContext context) {
    // L4: bottom bar shows first N system screens + an overflow.
    final visible = destinations.take(bottomVisibleCount).toList();

    final selectedIndex = _selectedIndex(visibleLength: visible.length);

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        destinations: [
          ...visible.map(_toNavDestination),
          const NavigationDestination(
            label: 'More',
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz),
          ),
        ],
        onDestinationSelected: (index) {
          if (index < visible.length) {
            onDestinationSelected(visible[index].screenId);
            return;
          }
          onMorePressed();
        },
      ),
    );
  }

  int _selectedIndex({required int visibleLength}) {
    final idx = destinations
        .take(visibleLength)
        .toList()
        .indexWhere(
          (d) => d.screenId == activeScreenId,
        );
    if (idx == -1) {
      // Highlight More when not on a bottom-bar system screen.
      return visibleLength;
    }
    return idx;
  }

  NavigationDestination _toNavDestination(NavigationDestinationVm dest) {
    return NavigationDestination(
      key: _guidedTourKeyFor(dest.screenId),
      label: dest.label,
      icon: Icon(dest.icon),
      selectedIcon: Icon(dest.selectedIcon),
    );
  }

  Key? _guidedTourKeyFor(String screenId) {
    return switch (screenId) {
      'my_day' => GuidedTourAnchors.myDayNavItem,
      _ => null,
    };
  }
}
