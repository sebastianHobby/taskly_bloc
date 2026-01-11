import 'package:flutter/material.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
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
    // L4: bottom bar shows first N system screens + Browse hub.
    final visible = destinations.take(bottomVisibleCount).toList();

    final selectedIndex = _selectedIndex(visibleLength: visible.length);

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        destinations: [
          ...visible.map(_toNavDestination),
          NavigationDestination(
            label: context.l10n.browseTitle,
            icon: const Icon(Icons.grid_view_rounded),
            selectedIcon: const Icon(Icons.grid_view_rounded),
          ),
        ],
        onDestinationSelected: (index) {
          if (index < visible.length) {
            onDestinationSelected(visible[index].screenId);
            return;
          }
          onDestinationSelected('browse');
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
      // Highlight Browse when not on a bottom-bar system screen.
      return activeScreenId == null ? 0 : visibleLength;
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
