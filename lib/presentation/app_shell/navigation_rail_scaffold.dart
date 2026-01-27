import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/shared/responsive/responsive.dart';
import 'package:taskly_bloc/presentation/features/navigation/models/navigation_destination.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

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
    final tokens = TasklyTokens.of(context);

    final selectedIndex = _selectedIndex(destinations);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: Row(
              children: [
                SizedBox(
                  width: isExtended ? 200 : 72,
                  child: NavigationRail(
                    selectedIndex: selectedIndex,
                    onDestinationSelected: (index) =>
                        onDestinationSelected(destinations[index].screenId),
                    extended: isExtended,
                    labelType: isExtended
                        ? NavigationRailLabelType.none
                        : NavigationRailLabelType.all,
                    leading: isExtended
                        ? Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: tokens.spaceSm,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  size: 28,
                                ),
                                SizedBox(width: tokens.spaceMd),
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
                            padding: EdgeInsets.only(bottom: tokens.spaceSm),
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
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: body),
              ],
            ),
          );
        },
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
      label: Text(
        destination.label,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
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
