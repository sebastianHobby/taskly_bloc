import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/models/screens/screen_category.dart';
import 'package:taskly_bloc/presentation/features/navigation/models/navigation_destination.dart';

class ScaffoldWithNavigationBar extends StatelessWidget {
  ScaffoldWithNavigationBar({
    required this.body,
    required this.destinations,
    required this.activeScreenId,
    required this.bottomVisibleCount,
    required this.onDestinationSelected,
    super.key,
  });

  final Widget body;
  final List<NavigationDestinationVm> destinations;
  final String? activeScreenId;
  final int bottomVisibleCount;
  final ValueChanged<String> onDestinationSelected;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    // Separate workspace destinations from others
    final workspaceDestinations = destinations
        .where((d) => d.category == ScreenCategory.workspace)
        .toList();
    final otherDestinations = destinations
        .where((d) => d.category != ScreenCategory.workspace)
        .toList();

    // Show first N workspace destinations + More button if there are overflow items
    final visible = workspaceDestinations.take(bottomVisibleCount).toList();
    final overflow = [
      ...workspaceDestinations.skip(bottomVisibleCount),
      ...otherDestinations,
    ];
    final hasOverflow = overflow.isNotEmpty;

    final selectedIndex = _selectedIndex(
      visibleLength: visible.length,
      allDestinations: destinations,
    );

    return Scaffold(
      key: _scaffoldKey,
      drawer: NavigationDrawer(
        selectedIndex: destinations.indexWhere(
          (d) => d.screenId == activeScreenId,
        ),
        onDestinationSelected: (index) {
          // Close drawer
          _scaffoldKey.currentState?.closeDrawer();
          onDestinationSelected(destinations[index].screenId);
        },
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
            child: Text(
              'Taskly',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          ...destinations.map(
            (dest) => NavigationDrawerDestination(
              icon: _buildIcon(dest),
              selectedIcon: _buildIcon(dest, selected: true),
              label: Text(dest.label),
            ),
          ),
        ],
      ),
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        destinations: [
          ...visible.map(_toNavDestination),
          if (hasOverflow)
            const NavigationDestination(
              label: 'Browse',
              icon: Icon(Icons.menu),
              selectedIcon: Icon(Icons.menu),
            ),
        ],
        onDestinationSelected: (index) {
          if (index < visible.length) {
            onDestinationSelected(visible[index].screenId);
            return;
          }
          _scaffoldKey.currentState?.openDrawer();
        },
      ),
    );
  }

  int _selectedIndex({
    required int visibleLength,
    required List<NavigationDestinationVm> allDestinations,
  }) {
    final workspaceDestinations = allDestinations
        .where((d) => d.category == ScreenCategory.workspace)
        .toList();
    final idx = workspaceDestinations.indexWhere(
      (d) => d.screenId == activeScreenId,
    );
    if (idx == -1) {
      // Check if active screen is in overflow (non-workspace or beyond visible)
      final isInOverflow =
          allDestinations.any(
            (d) =>
                d.screenId == activeScreenId &&
                d.category != ScreenCategory.workspace,
          ) ||
          idx >= visibleLength;
      return isInOverflow ? visibleLength : 0;
    }
    if (idx < visibleLength) return idx;
    return visibleLength; // Highlight "More" when selection is in overflow.
  }

  NavigationDestination _toNavDestination(NavigationDestinationVm dest) {
    return NavigationDestination(
      label: dest.label,
      icon: _buildIcon(dest),
      selectedIcon: _buildIcon(dest, selected: true),
    );
  }

  Widget _buildIcon(NavigationDestinationVm dest, {bool selected = false}) {
    final baseIcon = Icon(selected ? dest.selectedIcon : dest.icon);
    final badgeStream = dest.badgeStream;
    if (badgeStream == null) return baseIcon;

    return StreamBuilder<int>(
      stream: badgeStream,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        if (count <= 0) return baseIcon;
        return Badge(label: Text(count.toString()), child: baseIcon);
      },
    );
  }
}
