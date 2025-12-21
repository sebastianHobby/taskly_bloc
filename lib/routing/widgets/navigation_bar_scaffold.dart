import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/routing/routes.dart';

class ScaffoldWithNavigationBar extends StatefulWidget {
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
  State<ScaffoldWithNavigationBar> createState() =>
      _ScaffoldWithNavigationBarState();
}

class _ScaffoldWithNavigationBarState extends State<ScaffoldWithNavigationBar> {
  static const _browseIndex = 3;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _onDestinationSelected(int index) {
    if (index == _browseIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scaffoldKey.currentState?.openDrawer();
      });
      return;
    }

    widget.onDestinationSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: Text(context.l10n.projectsTitle),
                onTap: () {
                  Navigator.of(context).pop();
                  context.goNamed(AppRouteName.projects);
                },
              ),
              ListTile(
                leading: const Icon(Icons.label_outline),
                title: Text(context.l10n.labelsTitle),
                onTap: () {
                  Navigator.of(context).pop();
                  context.goNamed(AppRouteName.labels);
                },
              ),
            ],
          ),
        ),
      ),
      body: widget.body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.selectedIndex,
        destinations: [
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
            label: context.l10n.browseTitle,
            icon: const Icon(Icons.menu),
          ),
        ],
        onDestinationSelected: _onDestinationSelected,
      ),
    );
  }
}
