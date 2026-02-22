import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/sync_issues_debug_bloc.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/telemetry.dart';

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
        title: Text(l10n.settingsSyncIssuesTitle),
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
            return Center(child: Text(l10n.settingsSyncIssuesLoadFailed));
          }

          if (state.issues.isEmpty) {
            return Center(child: Text(l10n.settingsSyncIssuesEmpty));
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<SyncIssuesDebugBloc>().add(
                const SyncIssuesDebugRefreshRequested(),
              );
            },
            child: ListView.separated(
              itemCount: state.issues.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final issue = state.issues[index];
                return ListTile(
                  leading: Icon(_iconForSeverity(issue.severity)),
                  title: Text(issue.title),
                  subtitle: Text(
                    '${issue.issueCode} • ${issue.category.name} • '
                    '${l10n.settingsSyncIssuesOccurrences(issue.occurrenceCount)}',
                  ),
                  trailing: Text(issue.lastSeenAt.toLocal().toString()),
                );
              },
            ),
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
