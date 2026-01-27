import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/shared/responsive/responsive.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ResponsiveBody(
        isExpandedLayout: context.isExpandedScreen,
        child: ListView(
          children: [
            _SettingsNavItem(
              icon: Icons.palette_outlined,
              title: 'Appearance',
              subtitle: 'Theme, accent palette, and text size',
              onTap: () => Routing.pushSettingsAppearance(context),
            ),
            _SettingsNavItem(
              icon: Icons.today_outlined,
              title: 'My Day',
              subtitle: 'Triage, due windows, routines, and quotas',
              onTap: () => Routing.pushSettingsMyDay(context),
            ),
            _SettingsNavItem(
              icon: Icons.auto_awesome_outlined,
              title: 'Task Suggestions',
              subtitle: 'Values balance, project focus, and suggestion scope',
              onTap: () => Routing.pushSettingsTaskSuggestions(context),
            ),
            _SettingsNavItem(
              icon: Icons.event_repeat_outlined,
              title: 'Weekly Review',
              subtitle: 'Schedule, values snapshot, and maintenance',
              onTap: () => Routing.pushSettingsWeeklyReview(context),
            ),
            _SettingsNavItem(
              icon: Icons.language_outlined,
              title: 'Language & Region',
              subtitle: 'Language and home timezone',
              onTap: () => Routing.pushSettingsLanguageRegion(context),
            ),
            _SettingsNavItem(
              icon: Icons.person_outline,
              title: 'Account',
              subtitle: 'Profile details and sign out',
              onTap: () => Routing.pushSettingsAccount(context),
            ),
            if (kDebugMode)
              _SettingsNavItem(
                icon: Icons.bug_report_outlined,
                title: 'Developer',
                subtitle: 'Logs, tile catalog, and template data',
                onTap: () => Routing.pushSettingsDeveloper(context),
              ),
            SizedBox(height: TasklyTokens.of(context).spaceSm),
          ],
        ),
      ),
    );
  }
}

class _SettingsNavItem extends StatelessWidget {
  const _SettingsNavItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
