import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/config/debug_bootstrap_flags.dart';
import 'package:taskly_bloc/presentation/features/app/bloc/debug_bootstrap_bloc.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class DebugBootstrapSheet extends StatelessWidget {
  const DebugBootstrapSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          tokens.spaceLg,
          tokens.spaceLg,
          tokens.spaceLg,
          tokens.spaceLg,
        ),
        child: BlocListener<DebugBootstrapBloc, DebugBootstrapState>(
          listenWhen: (previous, current) =>
              previous.status.runtimeType != current.status.runtimeType,
          listener: (context, state) {
            final messenger = ScaffoldMessenger.of(context);

            switch (state.status) {
              case DebugBootstrapSuccess(:final action):
                messenger.clearSnackBars();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      action == DebugBootstrapAction.wipeAndSeed
                          ? 'Template data generated.'
                          : 'Account wipe started. Signing out...',
                    ),
                  ),
                );
                Navigator.pop(context);
              case DebugBootstrapFailure(:final message):
                messenger.clearSnackBars();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              default:
                break;
            }
          },
          child: BlocBuilder<DebugBootstrapBloc, DebugBootstrapState>(
            builder: (context, state) {
              final status = state.status;
              final isRunning = status is DebugBootstrapRunning;
              final runningLabel = switch (status) {
                DebugBootstrapRunning(:final action) => switch (action) {
                  DebugBootstrapAction.wipeAndSeed => 'Wiping and seeding...',
                  DebugBootstrapAction.wipeAccountAndReset =>
                    'Wiping account data...',
                },
                _ => null,
              };

              final errorMessage = switch (status) {
                DebugBootstrapFailure(:final message) => message,
                _ => null,
              };

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Debug Bootstrap',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: tokens.spaceXs),
                  Text(
                    'Choose how to initialize demo data for this launch.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  SizedBox(height: tokens.spaceSm),
                  if (runningLabel != null) ...[
                    Row(
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: tokens.spaceSm),
                        Text(runningLabel),
                      ],
                    ),
                    SizedBox(height: tokens.spaceSm),
                  ],
                  if (errorMessage != null) ...[
                    Text(
                      errorMessage,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    SizedBox(height: tokens.spaceSm),
                  ],
                  _ActionButton(
                    label: 'Wipe + Seed Demo Data (recommended)',
                    subtitle:
                        'Deletes all account data, then seeds template values, projects, tasks, routines, and ratings. Weekly review is due immediately.',
                    isRunning: isRunning,
                    onTap: () async {
                      await context.read<DebugBootstrapBloc>().wipeAndSeed();
                    },
                  ),
                  if (DebugBootstrapFlags.enableAccountWipeOption) ...[
                    SizedBox(height: tokens.spaceSm),
                    _ActionButton(
                      label: 'Wipe Account + Reset Onboarding',
                      subtitle:
                          'Deletes all synced data and signs you out. Onboarding runs next sign-in.',
                      isRunning: isRunning,
                      danger: true,
                      onTap: () async {
                        await context
                            .read<DebugBootstrapBloc>()
                            .wipeAccountAndResetOnboarding();
                      },
                    ),
                  ],
                  SizedBox(height: tokens.spaceSm),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: isRunning
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Skip this launch'),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.subtitle,
    required this.onTap,
    required this.isRunning,
    this.danger = false,
  });

  final String label;
  final String subtitle;
  final Future<void> Function() onTap;
  final bool isRunning;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final buttonColor = danger ? colorScheme.error : colorScheme.primary;
    final textColor = danger ? colorScheme.onError : colorScheme.onPrimary;

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: danger ? buttonColor : null,
          foregroundColor: danger ? textColor : null,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
        onPressed: isRunning ? null : onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: danger ? textColor : null,
                    ),
                  ),
                ),
                if (danger)
                  Icon(
                    Icons.warning_amber,
                    color: textColor,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: danger ? textColor : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
