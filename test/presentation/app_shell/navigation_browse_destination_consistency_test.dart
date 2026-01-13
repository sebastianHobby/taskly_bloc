import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/app_shell/navigation_bar_scaffold.dart';
import 'package:taskly_bloc/presentation/app_shell/navigation_rail_scaffold.dart';
import 'package:taskly_bloc/presentation/features/navigation/models/navigation_destination.dart';

import '../../helpers/test_imports.dart';

void main() {
  testWidgetsSafe(
    'Browse destination uses the same icon in bottom bar and rail',
    (tester) async {
      const browse = NavigationDestinationVm(
        id: 'browse',
        screenId: 'browse',
        label: 'Browse',
        icon: Icons.explore_outlined,
        selectedIcon: Icons.explore,
        route: '/browse',
        badgeStream: null,
        sortOrder: 1000,
      );

      const home = NavigationDestinationVm(
        id: 'home',
        screenId: 'home',
        label: 'Home',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        route: '/home',
        badgeStream: null,
        sortOrder: 0,
      );

      // Bottom bar
      await tester.pumpWidget(
        MaterialApp(
          home: ScaffoldWithNavigationBar(
            body: const SizedBox.shrink(),
            destinations: const [home],
            browseDestination: browse,
            activeScreenId: 'home',
            bottomVisibleCount: 1,
            onDestinationSelected: (_) {},
          ),
        ),
      );

      expect(find.byIcon(Icons.grid_view_rounded), findsNothing);
      expect(find.byIcon(Icons.explore_outlined), findsWidgets);

      // Rail
      await tester.pumpWidget(
        MaterialApp(
          home: ScaffoldWithNavigationRail(
            body: const SizedBox.shrink(),
            destinations: const [home, browse],
            activeScreenId: 'home',
            onDestinationSelected: (_) {},
          ),
        ),
      );

      expect(find.byIcon(Icons.explore_outlined), findsWidgets);
    },
  );
}
