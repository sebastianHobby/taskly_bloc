import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/presentation/features/app/bloc/initial_sync_gate_bloc.dart';
import 'package:taskly_bloc/presentation/shared/widgets/app_loading_screen.dart';
import 'package:taskly_domain/services.dart';

class InitialSyncGateScreen extends StatelessWidget {
  const InitialSyncGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InitialSyncGateBloc, InitialSyncGateState>(
      builder: (context, state) {
        const title = 'Syncing your data';
        const subtitle = 'This is a one-time setup for this device.';

        return switch (state) {
          InitialSyncGateInProgress(:final progress) => AppLoadingScreen(
            title: title,
            subtitle: subtitle,
            icon: Icons.sync,
            progressLabel: _labelForProgress(progress),
            progressValue: progress?.downloadFraction,
          ),
          InitialSyncGateFailure(:final message) => Scaffold(
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 12),
                        Icon(
                          Icons.sync_problem,
                          size: 40,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          message,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () {
                            context.read<InitialSyncGateBloc>().add(
                              const InitialSyncGateRetryRequested(),
                            );
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          InitialSyncGateReady() => const AppLoadingScreen(
            title: title,
            subtitle: subtitle,
            icon: Icons.sync,
          ),
        };
      },
    );
  }
}

String? _labelForProgress(InitialSyncProgress? progress) {
  return switch (progress) {
    null => 'Preparing sync...',
    InitialSyncProgress(downloading: true) => 'Downloading...',
    InitialSyncProgress(uploading: true) => 'Uploading...',
    InitialSyncProgress(connected: true) => 'Finalizing...',
    InitialSyncProgress(connecting: true) => 'Connecting...',
    _ => 'Preparing sync...',
  };
}
