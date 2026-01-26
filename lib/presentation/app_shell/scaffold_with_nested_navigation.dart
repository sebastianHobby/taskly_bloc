import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/app_shell/navigation_bar_scaffold.dart';
import 'package:taskly_bloc/presentation/app_shell/navigation_rail_scaffold.dart';
import 'package:taskly_bloc/presentation/app_shell/more_destinations_sheet.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_bloc/presentation/shared/responsive/responsive.dart';
import 'package:taskly_bloc/presentation/features/navigation/models/navigation_destination.dart';
import 'package:taskly_bloc/presentation/features/navigation/services/navigation_icon_resolver.dart';

class ScaffoldWithNestedNavigation extends StatelessWidget {
  const ScaffoldWithNestedNavigation({
    required this.child,
    required this.activeScreenId,
    this.bottomVisibleCount = 4,
    super.key,
  });

  final Widget child;
  final String? activeScreenId;
  final int bottomVisibleCount;

  @override
  Widget build(BuildContext context) {
    AppLog.routine(
      'navigation',
      'ScaffoldWithNestedNavigation.build(): activeScreenId=$activeScreenId',
    );

    const iconResolver = NavigationIconResolver();

    const primaryNavigationKeys = <String>[
      'my_day',
      'scheduled',
      'someday',
      'routines',
      'journal',
      'values',
      'settings',
    ];

    const labels = <String, String>{
      'my_day': 'My Day',
      'scheduled': 'Scheduled',
      'someday': 'Anytime',
      'routines': 'Routines',
      'journal': 'Journal',
      'values': 'Values',
      'settings': 'Settings',
    };

    const sortOrders = <String, int>{
      'my_day': 0,
      'scheduled': 1,
      'someday': 2,
      'journal': 3,
      'routines': 4,
      'values': 5,
      'settings': 100,
    };

    final systemDestinations = primaryNavigationKeys
        .map((screenKey) {
          final iconSet = iconResolver.resolve(
            screenId: screenKey,
            iconName: null,
          );

          return NavigationDestinationVm(
            id: screenKey,
            screenId: screenKey,
            label: labels[screenKey] ?? screenKey,
            icon: iconSet.icon,
            selectedIcon: iconSet.selectedIcon,
            route: Routing.screenPath(screenKey),
            sortOrder: sortOrders[screenKey] ?? 999,
          );
        })
        .toList(growable: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (Breakpoints.isCompact(constraints.maxWidth)) {
          return ScaffoldWithNavigationBar(
            body: child,
            destinations: systemDestinations,
            activeScreenId: activeScreenId,
            bottomVisibleCount: bottomVisibleCount,
            onDestinationSelected: (screenId) => _goTo(context, screenId),
            onMorePressed: () async {
              final selected = await showMoreDestinationsSheet(
                context: context,
                destinations: systemDestinations,
                activeScreenId: activeScreenId,
              );
              if (selected == null || !context.mounted) return;
              _goTo(context, selected);
            },
          );
        }

        return ScaffoldWithNavigationRail(
          body: child,
          destinations: systemDestinations,
          activeScreenId: activeScreenId,
          onDestinationSelected: (screenId) => _goTo(context, screenId),
        );
      },
    );
  }

  void _goTo(BuildContext context, String screenId) {
    AppLog.routine('navigation', '_goTo: screenId="$screenId"');

    final currentLocation = GoRouterState.of(context).uri.toString();
    AppLog.routine('navigation', 'Current location: $currentLocation');
    final route = Routing.screenPath(screenId);
    AppLog.routine('navigation', 'Navigating to route: $route');
    context.go(route);
  }
}
