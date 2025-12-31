import 'package:flutter/material.dart';
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
    final visible = destinations.take(bottomVisibleCount).toList();
    final overflow = destinations.skip(bottomVisibleCount).toList();
    final hasOverflow = overflow.isNotEmpty;

    final selectedIndex = _selectedIndex(visibleLength: visible.length);

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

  int _selectedIndex({required int visibleLength}) {
    final idx = destinations.indexWhere((d) => d.screenId == activeScreenId);
    if (idx == -1) return 0;
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
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView.builder(
            itemCount: overflow.length,
            itemBuilder: (context, index) {
              final dest = overflow[index];
              return ListTile(
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
              );
            },
          ),
        );
      },
    );
  }
}
