import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/routing/routes.dart';

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
    if (path.startsWith(AppRoutePath.labels)) return 4;
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
        context.goNamed(AppRouteName.labels);
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _effectiveSelectedIndex(context),
            onDestinationSelected: (index) =>
                _onDestinationSelected(context, index),
            labelType: NavigationRailLabelType.all,
            destinations: [
              NavigationRailDestination(
                label: Text(context.l10n.inboxTitle),
                icon: const Icon(Icons.inbox_outlined),
              ),
              NavigationRailDestination(
                label: Text(context.l10n.todayTitle),
                icon: const Icon(Icons.calendar_today_outlined),
              ),
              NavigationRailDestination(
                label: Text(context.l10n.upcomingTitle),
                icon: const Icon(Icons.event_outlined),
              ),
              NavigationRailDestination(
                label: Text(context.l10n.projectsTitle),
                icon: const Icon(Icons.home_outlined),
              ),
              NavigationRailDestination(
                label: Text(context.l10n.labelsTitle),
                icon: const Icon(Icons.label_outline),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }
}
