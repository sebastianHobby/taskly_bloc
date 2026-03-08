import 'package:flutter/material.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/navigation/services/navigation_icon_resolver.dart';
import 'package:taskly_bloc/presentation/shared/responsive/responsive.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_ui/taskly_ui_chrome.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final iconSet = const NavigationIconResolver().resolve(
      screenId: 'settings',
      iconName: null,
    );
    return Scaffold(
      appBar: AppBar(
        title: TasklyPageHeader(
          icon: iconSet.selectedIcon,
          title: l10n.settingsTitle,
        ),
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
              title: l10n.settingsAppearanceTitle,
              subtitle: l10n.settingsAppearanceSubtitle,
              onTap: () => Routing.pushSettingsAppearance(context),
            ),
            _SettingsNavItem(
              icon: Icons.lightbulb_outline,
              title: l10n.settingsMicroLearningTitle,
              subtitle: l10n.settingsMicroLearningSubtitle,
              onTap: () => Routing.pushSettingsMicroLearning(context),
            ),
            _SettingsNavItem(
              icon: Icons.event_repeat_outlined,
              title: l10n.weeklyReviewTitle,
              subtitle: l10n.settingsWeeklyReviewSubtitle,
              onTap: () => Routing.pushSettingsWeeklyReview(context),
            ),
            _SettingsNavItem(
              icon: Icons.notifications_none_rounded,
              title: l10n.settingsNotificationsTitle,
              subtitle: l10n.settingsNotificationsSubtitle,
              onTap: () => Routing.pushSettingsNotifications(context),
            ),
            _SettingsNavItem(
              icon: Icons.language_outlined,
              title: l10n.settingsLanguageRegionTitle,
              subtitle: l10n.settingsLanguageRegionSubtitle,
              onTap: () => Routing.pushSettingsLanguageRegion(context),
            ),
            _SettingsNavItem(
              icon: Icons.person_outline,
              title: l10n.settingsAccountTitle,
              subtitle: l10n.settingsAccountSubtitle,
              onTap: () => Routing.pushSettingsAccount(context),
            ),
            _SettingsNavItem(
              icon: Icons.bug_report_outlined,
              title: l10n.settingsDeveloperTitle,
              subtitle: l10n.settingsDeveloperSubtitle,
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
