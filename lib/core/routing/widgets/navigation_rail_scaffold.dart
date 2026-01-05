import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/utils/responsive.dart';
import 'package:taskly_bloc/presentation/features/navigation/models/navigation_destination.dart';

/// A scaffold with responsive navigation that adapts to screen size.
///
/// - Tablet (600-839dp): Compact navigation rail
/// - Desktop (840dp+): Extended navigation rail with labels
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
    final isExtended = screenWidth >= Breakpoints.medium;

    // Split destinations into main and settings
    final settingsDest = destinations
        .where((d) => d.screenId == 'settings')
        .firstOrNull;
    final mainDestinations = destinations
        .where((d) => d.screenId != 'settings')
        .toList();

    final topIndex = _selectedIndex(mainDestinations);
    final bottomIndex =
        settingsDest != null && activeScreenId == settingsDest.screenId
        ? 0
        : null;

    return Scaffold(
      body: Row(
        children: [
          Column(
            children: [
              Expanded(
                child: NavigationRail(
                  selectedIndex: topIndex,
                  onDestinationSelected: (index) =>
                      onDestinationSelected(mainDestinations[index].screenId),
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
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
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
                  destinations: mainDestinations
                      .map(_toRailDestination)
                      .toList(),
                  useIndicator: true,
                  minWidth: 72,
                  minExtendedWidth: 200,
                ),
              ),
              if (settingsDest != null)
                NavigationRail(
                  selectedIndex: bottomIndex,
                  onDestinationSelected: (_) =>
                      onDestinationSelected(settingsDest.screenId),
                  extended: isExtended,
                  labelType: isExtended
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  destinations: [_toRailDestination(settingsDest)],
                  useIndicator: true,
                  minWidth: 72,
                  minExtendedWidth: 200,
                ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }

  int? _selectedIndex(List<NavigationDestinationVm> dests) {
    final idx = dests.indexWhere((d) => d.screenId == activeScreenId);
    if (idx == -1) return null;
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
