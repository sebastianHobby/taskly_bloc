import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:taskly_bloc/presentation/features/settings/view/settings_page_layout.dart';
import 'package:taskly_ui/taskly_ui_primitives.dart';
import 'package:taskly_ui/taskly_ui_sections.dart';
import 'package:taskly_ui/taskly_ui_theme.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class SettingsAccountPage extends StatelessWidget {
  const SettingsAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SettingsPageLayout(
        icon: Icons.person_outline,
        title: context.l10n.accountTitle,
        subtitle: context.l10n.settingsAccountSubtitle,
        children: [
          const _AccountInfo(),
          const _SignOutItem(),
          SizedBox(height: TasklyTokens.of(context).spaceSm),
        ],
      ),
    );
  }
}

class _AccountInfo extends StatelessWidget {
  const _AccountInfo();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AppAuthState>(
      builder: (context, state) {
        final user = state.user;
        if (user == null) {
          return SizedBox.shrink();
        }

        final email = user.email;
        final displayName =
            user.metadata?['display_name'] as String? ??
            user.metadata?['full_name'] as String? ??
            user.metadata?['name'] as String?;

        final tokens = TasklyTokens.of(context);
        return Padding(
          padding: EdgeInsets.fromLTRB(
            tokens.sectionPaddingH,
            tokens.spaceSm,
            tokens.sectionPaddingH,
            0,
          ),
          child: TasklyCardSurface(
            variant: TasklyCardVariant.summary,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  child: Text(
                    _getInitials(displayName, email),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: tokens.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName ?? context.l10n.userFallbackLabel,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (email != null) ...[
                        SizedBox(height: tokens.spaceXs2),
                        Text(
                          email,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getInitials(String? displayName, String? email) {
    if (displayName != null && displayName.isNotEmpty) {
      final parts = displayName.trim().split(' ');
      if (parts.length >= 2) {
        return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      }
      return displayName[0].toUpperCase();
    }
    if (email != null && email.isNotEmpty) {
      return email[0].toUpperCase();
    }
    return 'U';
  }
}

class _SignOutItem extends StatelessWidget {
  const _SignOutItem();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AppAuthState>(
      listenWhen: (prev, curr) =>
          prev.error != curr.error && curr.error != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.signOutFailedMessage),
            action: SnackBarAction(
              label: context.l10n.retryButton,
              onPressed: () => _performSignOut(context),
            ),
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          TasklyTokens.of(context).sectionPaddingH,
          TasklyTokens.of(context).spaceSm,
          TasklyTokens.of(context).sectionPaddingH,
          TasklyTokens.of(context).spaceSm,
        ),
        child: TasklyCardSurface(
          variant: TasklyCardVariant.editor,
          child: OutlinedButton.icon(
            onPressed: () => _performSignOut(context),
            icon: const Icon(Icons.logout_rounded),
            label: Text(context.l10n.signOutLabel),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _performSignOut(BuildContext context) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final confirmed = await ConfirmationDialog.show(
      context,
      title: context.l10n.signOutConfirmTitle,
      confirmLabel: context.l10n.signOutLabel,
      cancelLabel: context.l10n.cancelLabel,
      content: Text(
        context.l10n.signOutConfirmBody,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      icon: Icons.logout_rounded,
      iconColor: colorScheme.primary,
      iconBackgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
    );
    if (!confirmed || !context.mounted) return;

    await HapticFeedback.lightImpact();
    if (context.mounted) {
      context.read<AuthBloc>().add(const AuthSignOutRequested());
    }
  }
}
