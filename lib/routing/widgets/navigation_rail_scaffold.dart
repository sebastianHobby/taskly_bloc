import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            labelType: NavigationRailLabelType.all,
            destinations: [
              NavigationRailDestination(
                label: Text(context.l10n.projectsTitle),
                icon: const Icon(Icons.home),
              ),
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
                label: Text(context.l10n.tasksTitle),
                icon: const Icon(Icons.settings),
              ),
              NavigationRailDestination(
                label: Text(context.l10n.valuesTitle),
                icon: const Icon(Icons.favorite_outline),
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
