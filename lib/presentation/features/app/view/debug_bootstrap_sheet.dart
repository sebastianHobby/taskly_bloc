import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/config/debug_bootstrap_flags.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/app/bloc/debug_bootstrap_bloc.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class DebugBootstrapSheet extends StatelessWidget {
  const DebugBootstrapSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final l10n = context.l10n;

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
                          ? l10n.debugBootstrapTemplateGenerated
                          : l10n.debugBootstrapAccountWipeStarted,
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
                  DebugBootstrapAction.wipeAndSeed =>
                    l10n.debugBootstrapWipingAndSeeding,
                  DebugBootstrapAction.wipeAccountAndReset =>
                    l10n.debugBootstrapWipingAccountData,
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
                    l10n.debugBootstrapTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: tokens.spaceXs),
                  Text(
                    l10n.debugBootstrapSubtitle,
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
                    label: l10n.debugBootstrapWipeSeedLabel,
                    subtitle: l10n.debugBootstrapWipeSeedSubtitle,
                    isRunning: isRunning,
                    onTap: () async {
                      await context.read<DebugBootstrapBloc>().wipeAndSeed();
                    },
                  ),
                  if (DebugBootstrapFlags.enableAccountWipeOption) ...[
                    SizedBox(height: tokens.spaceSm),
                    _ActionButton(
                      label: l10n.debugBootstrapWipeAccountLabel,
                      subtitle: l10n.debugBootstrapWipeAccountSubtitle,
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
                      child: Text(l10n.debugBootstrapSkipLaunch),
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
