import 'package:flutter/material.dart';
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
    // Show first N destinations in bottom nav, rest in drawer overflow
    // Destinations are already sorted by sortOrder from NavigationBloc
    final visible = destinations.take(bottomVisibleCount).toList();
    final overflow = destinations.skip(bottomVisibleCount).toList();
    final hasOverflow = overflow.isNotEmpty;

    final selectedIndex = _selectedIndex(visibleLength: visible.length);

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

  int _selectedIndex({required int visibleLength}) {
    final idx = destinations
        .take(visibleLength)
        .toList()
        .indexWhere(
          (d) => d.screenId == activeScreenId,
        );
    if (idx == -1) {
      // Active screen is in overflow - highlight "Browse" button
      final isInOverflow = destinations
          .skip(visibleLength)
          .any(
            (d) => d.screenId == activeScreenId,
          );
      return isInOverflow ? visibleLength : 0;
    }
    return idx;
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
