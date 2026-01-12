import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/app_shell/navigation_bar_scaffold.dart';
import 'package:taskly_bloc/presentation/app_shell/navigation_rail_scaffold.dart';
import 'package:taskly_bloc/core/logging/app_log.dart';
import 'package:taskly_bloc/presentation/shared/responsive/responsive.dart';
import 'package:taskly_bloc/domain/screens/catalog/system_screens/system_screen_definitions.dart';
import 'package:taskly_bloc/presentation/features/navigation/models/navigation_destination.dart';
import 'package:taskly_bloc/presentation/features/navigation/services/navigation_badge_service.dart';
import 'package:taskly_bloc/presentation/features/navigation/services/navigation_icon_resolver.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';

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

    final badgeService = NavigationBadgeService(
      taskRepository: getIt<TaskRepositoryContract>(),
      projectRepository: getIt<ProjectRepositoryContract>(),
    );
    const iconResolver = NavigationIconResolver();

    final systemDestinations = SystemScreenDefinitions.navigationScreens
        .map(
          (screen) {
            final iconSet = iconResolver.resolve(
              screenId: screen.screenKey,
              iconName: screen.chrome.iconName,
            );
            return NavigationDestinationVm(
              id: screen.id,
              screenId: screen.screenKey,
              label: screen.name,
              icon: iconSet.icon,
              selectedIcon: iconSet.selectedIcon,
              route: Routing.screenPath(screen.screenKey),
              screenSource: screen.screenSource,
              badgeStream: badgeService.badgeStreamFor(screen),
              sortOrder: SystemScreenDefinitions.getDefaultSortOrder(
                screen.screenKey,
              ),
            );
          },
        )
        .toList(growable: false);

    final browseScreen = SystemScreenDefinitions.browse;
    final browseIconSet = iconResolver.resolve(
      screenId: browseScreen.screenKey,
      iconName: browseScreen.chrome.iconName,
    );
    final browseDestination = NavigationDestinationVm(
      id: browseScreen.id,
      screenId: browseScreen.screenKey,
      label: browseScreen.name,
      icon: browseIconSet.icon,
      selectedIcon: browseIconSet.selectedIcon,
      route: Routing.screenPath(browseScreen.screenKey),
      screenSource: browseScreen.screenSource,
      badgeStream: null,
      sortOrder: 1000,
    );

    final railDestinations = <NavigationDestinationVm>[
      ...systemDestinations,
      browseDestination,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (Breakpoints.isCompact(constraints.maxWidth)) {
          return ScaffoldWithNavigationBar(
            body: child,
            destinations: systemDestinations,
            browseDestination: browseDestination,
            activeScreenId: activeScreenId,
            bottomVisibleCount: bottomVisibleCount,
            onDestinationSelected: (screenId) => _goTo(context, screenId),
          );
        }

        return ScaffoldWithNavigationRail(
          body: child,
          destinations: railDestinations,
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
