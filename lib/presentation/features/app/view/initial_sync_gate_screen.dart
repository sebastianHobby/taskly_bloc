import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/presentation/features/app/bloc/initial_sync_gate_bloc.dart';
import 'package:taskly_domain/services.dart';

class InitialSyncGateScreen extends StatelessWidget {
  const InitialSyncGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InitialSyncGateBloc, InitialSyncGateState>(
      builder: (context, state) {
        return Scaffold(
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
                        Icons.sync,
                        size: 40,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Syncing your data',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This is a one-time setup for this device.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ...switch (state) {
                        InitialSyncGateInProgress(:final progress) => [
                          _ProgressIndicator(progress: progress),
                        ],
                        InitialSyncGateFailure(:final message) => [
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
                        InitialSyncGateReady() => const <Widget>[
                          _ProgressIndicator(progress: null),
                        ],
                      },
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProgressIndicator extends StatelessWidget {
  const _ProgressIndicator({required this.progress});

  final InitialSyncProgress? progress;

  @override
  Widget build(BuildContext context) {
    final p = progress;
    final fraction = p?.downloadFraction;

    final label = switch (p) {
      null => 'Preparing sync…',
      InitialSyncProgress(downloading: true) => 'Downloading…',
      InitialSyncProgress(uploading: true) => 'Uploading…',
      InitialSyncProgress(connected: true) => 'Finalizing…',
      InitialSyncProgress(connecting: true) => 'Connecting…',
      _ => 'Preparing sync…',
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (fraction != null)
          LinearProgressIndicator(value: fraction)
        else
          const LinearProgressIndicator(),
        const SizedBox(height: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
