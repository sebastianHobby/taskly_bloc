import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/features/guided_tour/bloc/guided_tour_bloc.dart';
import 'package:taskly_bloc/presentation/features/navigation/services/navigation_icon_resolver.dart';
import 'package:taskly_bloc/presentation/shared/responsive/responsive.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const _SettingsAppBarTitle(),
        centerTitle: false,
      ),
      body: ResponsiveBody(
        isExpandedLayout: context.isExpandedScreen,
        child: ListView(
          padding: EdgeInsets.symmetric(
            vertical: TasklyTokens.of(context).spaceSm,
          ),
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
              subtitle: 'Values balance and project focus',
              onTap: () => Routing.pushSettingsTaskSuggestions(context),
            ),
            _SettingsNavItem(
              icon: Icons.flag_outlined,
              title: 'Guided tour',
              subtitle: 'Walk through the core screens again',
              onTap: () => context.read<GuidedTourBloc>().add(
                const GuidedTourStarted(force: true),
              ),
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

class _SettingsAppBarTitle extends StatelessWidget {
  const _SettingsAppBarTitle();

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final iconSet = const NavigationIconResolver().resolve(
      screenId: 'settings',
      iconName: null,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.sectionPaddingH,
        tokens.spaceMd,
        tokens.sectionPaddingH,
        tokens.spaceSm,
      ),
      child: Row(
        children: [
          Icon(
            iconSet.selectedIcon,
            color: scheme.primary,
            size: tokens.spaceLg3,
          ),
          SizedBox(width: tokens.spaceSm),
          Text(
            'Settings',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
