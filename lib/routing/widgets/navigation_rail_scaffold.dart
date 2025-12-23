import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/routing/routes.dart';

/// Responsive breakpoints for navigation.
class _NavigationBreakpoints {
  static const double mobile = 600;
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
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
  });

  final Widget body;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  int _effectiveSelectedIndex(BuildContext context) {
    if (selectedIndex != 3) return selectedIndex;

    final path = GoRouterState.of(context).uri.path;
    if (path.startsWith(AppRoutePath.taskNextActions)) return 4;
    if (path.startsWith(AppRoutePath.labels)) return 5;
    if (path.startsWith(AppRoutePath.values)) return 6;
    return 3;
  }

  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
      case 1:
      case 2:
        onDestinationSelected(index);
        return;
      case 3:
        context.goNamed(AppRouteName.projects);
        return;
      case 4:
        context.goNamed(AppRouteName.taskNextActions);
        return;
      case 5:
        context.goNamed(AppRouteName.labels);
        return;
      case 6:
        context.goNamed(AppRouteName.values);
        return;
    }
  }

  List<NavigationRailDestination> _buildRailDestinations(BuildContext context) {
    return [
      NavigationRailDestination(
        label: Text(context.l10n.inboxTitle),
        icon: const Icon(Icons.inbox_outlined),
        selectedIcon: const Icon(Icons.inbox),
      ),
      NavigationRailDestination(
        label: Text(context.l10n.todayTitle),
        icon: const Icon(Icons.calendar_today_outlined),
        selectedIcon: const Icon(Icons.calendar_today),
      ),
      NavigationRailDestination(
        label: Text(context.l10n.upcomingTitle),
        icon: const Icon(Icons.event_outlined),
        selectedIcon: const Icon(Icons.event),
      ),
      NavigationRailDestination(
        label: Text(context.l10n.projectsTitle),
        icon: const Icon(Icons.folder_outlined),
        selectedIcon: const Icon(Icons.folder),
      ),
      NavigationRailDestination(
        label: Text(context.l10n.nextActionsTitle),
        icon: const Icon(Icons.playlist_play_outlined),
        selectedIcon: const Icon(Icons.playlist_play),
      ),
      NavigationRailDestination(
        label: Text(context.l10n.labelsTitle),
        icon: const Icon(Icons.label_outline),
        selectedIcon: const Icon(Icons.label),
      ),
      NavigationRailDestination(
        label: Text(context.l10n.valuesTitle),
        icon: const Icon(Icons.favorite_border),
        selectedIcon: const Icon(Icons.favorite),
      ),
    ];
  }

  List<NavigationDestination> _buildBarDestinations(BuildContext context) {
    // For mobile, show only the main 4 destinations
    return [
      NavigationDestination(
        label: context.l10n.inboxTitle,
        icon: const Icon(Icons.inbox_outlined),
        selectedIcon: const Icon(Icons.inbox),
      ),
      NavigationDestination(
        label: context.l10n.todayTitle,
        icon: const Icon(Icons.calendar_today_outlined),
        selectedIcon: const Icon(Icons.calendar_today),
      ),
      NavigationDestination(
        label: context.l10n.upcomingTitle,
        icon: const Icon(Icons.event_outlined),
        selectedIcon: const Icon(Icons.event),
      ),
      NavigationDestination(
        label: context.l10n.projectsTitle,
        icon: const Icon(Icons.folder_outlined),
        selectedIcon: const Icon(Icons.folder),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final effectiveIndex = _effectiveSelectedIndex(context);

    // Mobile: Bottom navigation bar
    if (screenWidth < _NavigationBreakpoints.mobile) {
      // Map extended indices back to the 4 visible destinations
      final mobileIndex = effectiveIndex.clamp(0, 3);

      return Scaffold(
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: mobileIndex,
          onDestinationSelected: (index) =>
              _onDestinationSelected(context, index),
          destinations: _buildBarDestinations(context),
        ),
      );
    }

    // Tablet: Compact rail, Desktop: Extended rail
    final isExtended = screenWidth >= _NavigationBreakpoints.tablet;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: effectiveIndex,
            onDestinationSelected: (index) =>
                _onDestinationSelected(context, index),
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
            destinations: _buildRailDestinations(context),
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
}
