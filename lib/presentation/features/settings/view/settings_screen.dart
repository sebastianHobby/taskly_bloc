import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/features/guided_tour/bloc/guided_tour_bloc.dart';
import 'package:taskly_bloc/presentation/features/navigation/services/navigation_icon_resolver.dart';
import 'package:taskly_bloc/presentation/shared/responsive/responsive.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
              title: l10n.settingsAppearanceTitle,
              subtitle: l10n.settingsAppearanceSubtitle,
              onTap: () => Routing.pushSettingsAppearance(context),
            ),
            _SettingsNavItem(
              icon: Icons.auto_awesome_outlined,
              title: l10n.settingsTaskSuggestionsTitle,
              subtitle: l10n.settingsTaskSuggestionsSubtitle,
              onTap: () => Routing.pushSettingsTaskSuggestions(context),
            ),
            _SettingsNavItem(
              icon: Icons.flag_outlined,
              title: l10n.settingsGuidedTourTitle,
              subtitle: l10n.settingsGuidedTourSubtitle,
              onTap: () => context.read<GuidedTourBloc>().add(
                const GuidedTourStarted(force: true),
              ),
            ),
            _SettingsNavItem(
              icon: Icons.event_repeat_outlined,
              title: l10n.weeklyReviewTitle,
              subtitle: l10n.settingsWeeklyReviewSubtitle,
              onTap: () => Routing.pushSettingsWeeklyReview(context),
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
            if (kDebugMode)
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

class _SettingsAppBarTitle extends StatelessWidget {
  const _SettingsAppBarTitle();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
            l10n.settingsTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
