import 'package:flutter/material.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/navigation/services/navigation_icon_resolver.dart';
import 'package:taskly_bloc/presentation/features/settings/widgets/settings_navigation_tile.dart';
import 'package:taskly_bloc/presentation/shared/responsive/responsive.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_ui/taskly_ui_chrome.dart';
import 'package:taskly_ui/taskly_ui_theme.dart';
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
      appBar: AppBar(),
      body: TasklyPageGradientSurface(
        child: ResponsiveBody(
          isExpandedLayout: context.isExpandedScreen,
          child: ListView(
            padding: EdgeInsets.only(
              bottom: TasklyTokens.of(context).spaceLg,
            ),
            children: [
              TasklyPageHeader(
                icon: iconSet.selectedIcon,
                title: l10n.settingsTitle,
                variant: TasklyHeaderVariant.hero,
              ),
              _SettingsSectionPadding(
                child: SettingsNavigationTile(
                  icon: Icons.palette_outlined,
                  title: l10n.settingsAppearanceTitle,
                  subtitle: l10n.settingsAppearanceSubtitle,
                  onTap: () => Routing.pushSettingsAppearance(context),
                ),
              ),
              _SettingsSectionPadding(
                child: SettingsNavigationTile(
                  icon: Icons.language_outlined,
                  title: l10n.settingsLanguageRegionTitle,
                  subtitle: l10n.settingsLanguageRegionSubtitle,
                  onTap: () => Routing.pushSettingsLanguageRegion(context),
                ),
              ),
              _SettingsSectionPadding(
                child: SettingsNavigationTile(
                  icon: Icons.person_outline,
                  title: l10n.settingsAccountTitle,
                  subtitle: l10n.settingsAccountSubtitle,
                  onTap: () => Routing.pushSettingsAccount(context),
                ),
              ),
              _SettingsSectionPadding(
                child: SettingsNavigationTile(
                  icon: Icons.event_repeat_outlined,
                  title: l10n.weeklyReviewTitle,
                  subtitle: l10n.settingsWeeklyReviewSubtitle,
                  onTap: () => Routing.pushSettingsWeeklyReview(context),
                  variant: TasklyCardVariant.maintenance,
                ),
              ),
              _SettingsSectionPadding(
                child: SettingsNavigationTile(
                  icon: Icons.notifications_none_rounded,
                  title: l10n.settingsNotificationsTitle,
                  subtitle: l10n.settingsNotificationsSubtitle,
                  onTap: () => Routing.pushSettingsNotifications(context),
                  variant: TasklyCardVariant.maintenance,
                ),
              ),
              _SettingsSectionPadding(
                child: SettingsNavigationTile(
                  icon: Icons.lightbulb_outline,
                  title: l10n.settingsMicroLearningTitle,
                  subtitle: l10n.settingsMicroLearningSubtitle,
                  onTap: () => Routing.pushSettingsMicroLearning(context),
                ),
              ),
              _SettingsSectionPadding(
                child: SettingsNavigationTile(
                  icon: Icons.bug_report_outlined,
                  title: l10n.settingsDeveloperTitle,
                  subtitle: l10n.settingsDeveloperSubtitle,
                  onTap: () => Routing.pushSettingsDeveloper(context),
                  variant: TasklyCardVariant.editor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSectionPadding extends StatelessWidget {
  const _SettingsSectionPadding({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.sectionPaddingH,
        tokens.spaceSm,
        tokens.sectionPaddingH,
        0,
      ),
      child: child,
    );
  }
}
