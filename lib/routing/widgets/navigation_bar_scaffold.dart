import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';

class ScaffoldWithNavigationBar extends StatelessWidget {
  const ScaffoldWithNavigationBar({
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
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        destinations: [
          NavigationDestination(
            label: context.l10n.projectsTitle,
            icon: const Icon(Icons.home),
          ),
          NavigationDestination(
            label: context.l10n.inboxTitle,
            icon: const Icon(Icons.inbox_outlined),
          ),
          NavigationDestination(
            label: context.l10n.todayTitle,
            icon: const Icon(Icons.calendar_today_outlined),
          ),
          NavigationDestination(
            label: context.l10n.upcomingTitle,
            icon: const Icon(Icons.event_outlined),
          ),
          NavigationDestination(
            label: context.l10n.tasksTitle,
            icon: const Icon(Icons.settings),
          ),
          NavigationDestination(
            label: context.l10n.valuesTitle,
            icon: const Icon(Icons.favorite_outline),
          ),
          NavigationDestination(
            label: context.l10n.labelsTitle,
            icon: const Icon(Icons.label_outline),
          ),
        ],
        onDestinationSelected: onDestinationSelected,
      ),
    );
  }
}
