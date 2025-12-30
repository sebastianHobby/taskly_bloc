import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/features/navigation/models/navigation_destination.dart';

/// Responsive breakpoints for navigew ation.
class _NavigationBreakpoints {
  static const double tablet = 840;
}

/// A scaffold with responsive navigation that adapts to screen size.
///
/// - Mobile (< 600dp): Bottom navigation bar
/// - Tablet (600-840dp): Compact navigation rail
/// - Desktop (> 840dp): Extended navigation rail
class ScaffoldWithNavigationRail extends StatelessWidget {
  const ScaffoldWithNavigationRail({
    required this.body,
    required this.destinations,
    required this.activeScreenId,
    required this.onDestinationSelected,
    super.key,
  });

  final Widget body;
  final List<NavigationDestinationVm> destinations;
  final String? activeScreenId;
  final ValueChanged<String> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final selectedIndex = _selectedIndex();

    // Tablet: Compact rail, Desktop: Extended rail
    final isExtended = screenWidth >= _NavigationBreakpoints.tablet;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) =>
                onDestinationSelected(destinations[index].screenId),
            extended: isExtended,
            labelType: isExtended
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            leading: isExtended
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Taskly',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Icon(
                      Icons.check_circle_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 32,
                    ),
                  ),
            destinations: destinations.map(_toRailDestination).toList(),
            useIndicator: true,
            minWidth: 72,
            minExtendedWidth: 200,
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }

  int _selectedIndex() {
    final idx = destinations.indexWhere((d) => d.screenId == activeScreenId);
    if (idx == -1) return 0;
    return idx;
  }

  NavigationRailDestination _toRailDestination(
    NavigationDestinationVm destination,
  ) {
    return NavigationRailDestination(
      label: Text(destination.label),
      icon: _buildIcon(destination),
      selectedIcon: _buildIcon(destination, selected: true),
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
