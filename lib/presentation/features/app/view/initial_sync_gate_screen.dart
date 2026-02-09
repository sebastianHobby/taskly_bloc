import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/app/bloc/initial_sync_gate_bloc.dart';
import 'package:taskly_bloc/presentation/shared/widgets/app_loading_screen.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class InitialSyncGateScreen extends StatelessWidget {
  const InitialSyncGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InitialSyncGateBloc, InitialSyncGateState>(
      builder: (context, state) {
        final l10n = context.l10n;
        final title = l10n.initialSyncTitle;
        final subtitle = l10n.initialSyncSubtitle;

        return switch (state) {
          InitialSyncGateInProgress(:final progress) => AppLoadingScreen(
            title: title,
            subtitle: subtitle,
            icon: Icons.sync,
            progressLabel: _labelForProgress(progress, l10n),
            progressValue: progress?.downloadFraction,
          ),
          InitialSyncGateFailure(:final message) => Scaffold(
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: EdgeInsets.all(
                      TasklyTokens.of(context).spaceXl,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: TasklyTokens.of(context).spaceMd),
                        Icon(
                          Icons.sync_problem,
                          size:
                              TasklyTokens.of(context).spaceXxl +
                              TasklyTokens.of(context).spaceSm,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        SizedBox(height: TasklyTokens.of(context).spaceLg),
                        Text(
                          message,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: TasklyTokens.of(context).spaceLg),
                        FilledButton(
                          onPressed: () {
                            context.read<InitialSyncGateBloc>().add(
                              const InitialSyncGateRetryRequested(),
                            );
                          },
                          child: Text(l10n.retryButton),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          InitialSyncGateReady() => AppLoadingScreen(
            title: title,
            subtitle: subtitle,
            icon: Icons.sync,
          ),
        };
      },
    );
  }
}

String? _labelForProgress(
  InitialSyncProgress? progress,
  AppLocalizations l10n,
) {
  return switch (progress) {
    null => l10n.initialSyncPreparing,
    InitialSyncProgress(downloading: true) => l10n.initialSyncDownloading,
    InitialSyncProgress(uploading: true) => l10n.initialSyncUploading,
    InitialSyncProgress(connected: true) => l10n.initialSyncFinalizing,
    InitialSyncProgress(connecting: true) => l10n.initialSyncConnecting,
    _ => l10n.initialSyncPreparing,
  };
}
