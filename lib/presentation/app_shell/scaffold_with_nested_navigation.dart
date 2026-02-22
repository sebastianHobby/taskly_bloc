import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
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
    final l10n = context.l10n;

    final primaryNavigationKeys = <String>[
      'my_day',
      'scheduled',
      'projects',
      'journal',
      'values',
      'settings',
    ];

    final labels = <String, String>{
      'my_day': l10n.myDayTitle,
      'scheduled': l10n.scheduledTitle,
      'projects': l10n.projectsTitle,
      'journal': l10n.journalTitle,
      'values': l10n.valuesTitle,
      'settings': l10n.settingsTitle,
    };

    const sortOrders = <String, int>{
      'my_day': 0,
      'scheduled': 1,
      'projects': 2,
      'journal': 5,
      'values': 6,
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
