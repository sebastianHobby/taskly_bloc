import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/shared/responsive/responsive.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class SettingsDeveloperPage extends StatelessWidget {
  const SettingsDeveloperPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.developerTitle),
      ),
      body: ResponsiveBody(
        isExpandedLayout: context.isExpandedScreen,
        child: ListView(
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
      ),
    );
  }

  Widget _buildViewLogsItem(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.bug_report_outlined),
      title: Text(context.l10n.viewAppLogsTitle),
      subtitle: Text(context.l10n.viewAppLogsSubtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => TalkerScreen(talker: talkerRaw),
          ),
        );
      },
    );
  }

  Widget _buildSyncIssuesItem(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.sync_problem_outlined),
      title: Text(context.l10n.settingsSyncIssuesTitle),
      subtitle: Text(context.l10n.settingsSyncIssuesSubtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Routing.pushSettingsSyncIssues(context),
    );
  }

  Widget _buildStatsItem(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.bar_chart_outlined),
      title: Text(context.l10n.settingsStatsTitle),
      subtitle: Text(context.l10n.settingsStatsSubtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Routing.pushSettingsStats(context),
    );
  }
}
