import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/core/routing/widgets/navigation_bar_scaffold.dart';
import 'package:taskly_bloc/core/routing/widgets/navigation_rail_scaffold.dart';
import 'package:taskly_bloc/core/utils/responsive.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/presentation/features/navigation/bloc/navigation_bloc.dart';
import 'package:taskly_bloc/presentation/features/navigation/models/navigation_destination.dart';

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
    talker.debug(
      '[navigation] ScaffoldWithNestedNavigation.build() called, activeScreenId=$activeScreenId',
    );
    return BlocBuilder<NavigationBloc, NavigationState>(
      builder: (context, state) {
        return switch (state.status) {
          NavigationStatus.loading => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          NavigationStatus.failure => Scaffold(
            body: Center(
              child: Text(state.error ?? 'Failed to load navigation'),
            ),
          ),
          NavigationStatus.ready => LayoutBuilder(
            builder: (context, constraints) {
              final destinations = state.destinations;
              if (destinations.isEmpty) return child;

              if (Breakpoints.isCompact(constraints.maxWidth)) {
                return ScaffoldWithNavigationBar(
                  body: child,
                  destinations: destinations,
                  activeScreenId: activeScreenId,
                  bottomVisibleCount: bottomVisibleCount,
                  onDestinationSelected: (screenId) =>
                      _goTo(context, destinations, screenId),
                );
              }

              return ScaffoldWithNavigationRail(
                body: child,
                destinations: destinations,
                activeScreenId: activeScreenId,
                onDestinationSelected: (screenId) =>
                    _goTo(context, destinations, screenId),
              );
            },
          ),
        };
      },
    );
  }

  void _goTo(
    BuildContext context,
    List<NavigationDestinationVm> destinations,
    String screenId,
  ) {
    talker.debug('[navigation] _goTo called with screenId="$screenId"');
    final dest = destinations.firstWhere(
      (d) => d.screenId == screenId,
      orElse: () => destinations.first,
    );

    // Debug: log current location before navigating
    final currentLocation = GoRouterState.of(context).uri.toString();
    talker.debug('[navigation] Current location: $currentLocation');
    talker.debug('[navigation] Navigating to route: ${dest.route}');

    context.go(dest.route);

    // Debug: log location after go() call
    final newLocation = GoRouterState.of(context).uri.toString();
    talker.debug('[navigation] After go(), location is: $newLocation');
  }
}
