import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/settings/view/settings_page_layout.dart';
import 'package:taskly_bloc/presentation/features/settings/widgets/settings_navigation_tile.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class SettingsDeveloperPage extends StatelessWidget {
  const SettingsDeveloperPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SettingsPageLayout(
        icon: Icons.bug_report_outlined,
        title: context.l10n.developerTitle,
        subtitle: context.l10n.settingsDeveloperSubtitle,
        children: [
          _buildViewLogsItem(context),
          if (kDebugMode) ...[
            SizedBox(height: TasklyTokens.of(context).spaceSm),
            _buildSyncIssuesItem(context),
            SizedBox(height: TasklyTokens.of(context).spaceSm),
            _buildStatsItem(context),
          ],
          SizedBox(height: TasklyTokens.of(context).spaceSm),
        ],
      ),
    );
  }

  Widget _buildViewLogsItem(BuildContext context) {
    return _SettingsSectionPadding(
      child: SettingsNavigationTile(
        icon: Icons.bug_report_outlined,
        title: context.l10n.viewAppLogsTitle,
        subtitle: context.l10n.viewAppLogsSubtitle,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => TalkerScreen(talker: talkerRaw),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSyncIssuesItem(BuildContext context) {
    return _SettingsSectionPadding(
      child: SettingsNavigationTile(
        icon: Icons.sync_problem_outlined,
        title: context.l10n.settingsSyncIssuesTitle,
        subtitle: context.l10n.settingsSyncIssuesSubtitle,
        onTap: () => Routing.pushSettingsSyncIssues(context),
      ),
    );
  }

  Widget _buildStatsItem(BuildContext context) {
    return _SettingsSectionPadding(
      child: SettingsNavigationTile(
        icon: Icons.bar_chart_outlined,
        title: context.l10n.settingsStatsTitle,
        subtitle: context.l10n.settingsStatsSubtitle,
        onTap: () => Routing.pushSettingsStats(context),
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
