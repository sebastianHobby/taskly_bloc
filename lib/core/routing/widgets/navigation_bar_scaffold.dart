import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/models/screens/screen_category.dart';
import 'package:taskly_bloc/presentation/features/navigation/models/navigation_destination.dart';

class ScaffoldWithNavigationBar extends StatelessWidget {
  const ScaffoldWithNavigationBar({
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
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        destinations: [
          ...visible.map(_toNavDestination),
          if (hasOverflow)
            const NavigationDestination(
              label: 'More',
              icon: Icon(Icons.more_horiz),
            ),
        ],
        onDestinationSelected: (index) async {
          if (index < visible.length) {
            onDestinationSelected(visible[index].screenId);
            return;
          }
          if (!hasOverflow) return;
          await _openOverflowSheet(context, overflow);
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

  Future<void> _openOverflowSheet(
    BuildContext context,
    List<NavigationDestinationVm> overflow,
  ) async {
    // Group overflow items by category
    final grouped = <ScreenCategory, List<NavigationDestinationVm>>{};
    for (final dest in overflow) {
      grouped.putIfAbsent(dest.category, () => []).add(dest);
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final category in [
                ScreenCategory.workspace,
                ScreenCategory.wellbeing,
                ScreenCategory.settings,
              ])
                if (grouped.containsKey(category)) ...[
                  if (category != ScreenCategory.workspace)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        category.displayName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ...grouped[category]!.map(
                    (dest) => ListTile(
                      leading: Icon(dest.icon),
                      title: Text(dest.label),
                      trailing: dest.badgeStream == null
                          ? null
                          : StreamBuilder<int>(
                              stream: dest.badgeStream,
                              builder: (context, snapshot) {
                                final count = snapshot.data ?? 0;
                                if (count <= 0) return const SizedBox.shrink();
                                return Badge(label: Text(count.toString()));
                              },
                            ),
                      onTap: () {
                        Navigator.of(context).pop();
                        onDestinationSelected(dest.screenId);
                      },
                    ),
                  ),
                ],
            ],
          ),
        );
      },
    );
  }
}
