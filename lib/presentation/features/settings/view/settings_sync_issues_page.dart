import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/sync_issues_debug_bloc.dart';
import 'package:taskly_bloc/presentation/features/settings/view/settings_page_layout.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/telemetry.dart';
import 'package:taskly_ui/taskly_ui_primitives.dart';
import 'package:taskly_ui/taskly_ui_sections.dart';
import 'package:taskly_ui/taskly_ui_theme.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class SettingsSyncIssuesPage extends StatelessWidget {
  const SettingsSyncIssuesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SyncIssuesDebugBloc(
        repository: context.read<SyncIssueRepositoryContract>(),
      )..add(const SyncIssuesDebugStarted()),
      child: const _SettingsSyncIssuesView(),
    );
  }
}

class _SettingsSyncIssuesView extends StatelessWidget {
  const _SettingsSyncIssuesView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: l10n.retry,
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<SyncIssuesDebugBloc>().add(
                const SyncIssuesDebugRefreshRequested(),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<SyncIssuesDebugBloc, SyncIssuesDebugState>(
        builder: (context, state) {
          if (state.loading && state.issues.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.errorMessage != null && state.issues.isEmpty) {
            return SettingsPageLayout(
              icon: Icons.sync_problem_outlined,
              title: l10n.settingsSyncIssuesTitle,
              subtitle: l10n.settingsSyncIssuesSubtitle,
              children: [
                _SectionPadding(
                  child: EmptyStateWidget(
                    icon: Icons.sync_problem_outlined,
                    title: l10n.settingsSyncIssuesTitle,
                    description: l10n.settingsSyncIssuesLoadFailed,
                    actionLabel: l10n.retry,
                    onAction: () {
                      context.read<SyncIssuesDebugBloc>().add(
                        const SyncIssuesDebugRefreshRequested(),
                      );
                    },
                  ),
                ),
              ],
            );
          }

          if (state.issues.isEmpty) {
            return SettingsPageLayout(
              icon: Icons.sync_problem_outlined,
              title: l10n.settingsSyncIssuesTitle,
              subtitle: l10n.settingsSyncIssuesSubtitle,
              children: [
                _SectionPadding(
                  child: EmptyStateWidget(
                    icon: Icons.check_circle_outline_rounded,
                    title: l10n.settingsSyncIssuesTitle,
                    description: l10n.settingsSyncIssuesEmpty,
                  ),
                ),
              ],
            );
          }

          return SettingsPageLayout(
            icon: Icons.sync_problem_outlined,
            title: l10n.settingsSyncIssuesTitle,
            subtitle: l10n.settingsSyncIssuesSubtitle,
            children: [
              _SectionPadding(
                child: RefreshIndicator(
                  onRefresh: () async {
                    context.read<SyncIssuesDebugBloc>().add(
                      const SyncIssuesDebugRefreshRequested(),
                    );
                  },
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.issues.length,
                    separatorBuilder: (_, __) =>
                        SizedBox(height: TasklyTokens.of(context).spaceSm),
                    itemBuilder: (context, index) {
                      final issue = state.issues[index];
                      return TasklyCardSurface(
                        variant: TasklyCardVariant.editor,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(_iconForSeverity(issue.severity)),
                          title: Text(issue.title),
                          subtitle: Text(
                            '${issue.issueCode} • ${issue.category.name} • '
                            '${l10n.settingsSyncIssuesOccurrences(issue.occurrenceCount)}',
                          ),
                          trailing: Text(issue.lastSeenAt.toLocal().toString()),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _iconForSeverity(SyncIssueSeverity severity) {
    return switch (severity) {
      SyncIssueSeverity.info => Icons.info_outline,
      SyncIssueSeverity.warning => Icons.warning_amber_outlined,
      SyncIssueSeverity.error => Icons.error_outline,
      SyncIssueSeverity.critical => Icons.dangerous_outlined,
    };
  }
}

class _SectionPadding extends StatelessWidget {
  const _SectionPadding({required this.child});

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
