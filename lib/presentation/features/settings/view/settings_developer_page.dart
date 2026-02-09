import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/debug/taskly_tile_catalog_page.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/settings_maintenance_bloc.dart';
import 'package:taskly_bloc/presentation/shared/responsive/responsive.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class SettingsDeveloperPage extends StatelessWidget {
  const SettingsDeveloperPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsMaintenanceBloc>(
      create: (context) => SettingsMaintenanceBloc(
        templateDataService: context.read<TemplateDataService>(),
        userDataWipeService: context.read<UserDataWipeService>(),
        authRepository: context.read<AuthRepositoryContract>(),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.developerTitle),
        ),
        body: ResponsiveBody(
          isExpandedLayout: context.isExpandedScreen,
          child: ListView(
            children: [
              _buildViewLogsItem(context),
              _buildTileCatalogItem(context),
              if (kDebugMode) const _ResetOnboardingItem(),
              const _GenerateTemplateDataItem(),
              SizedBox(height: TasklyTokens.of(context).spaceSm),
            ],
          ),
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

  Widget _buildTileCatalogItem(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.dashboard_outlined),
      title: Text(context.l10n.tileCatalogTitle),
      subtitle: Text(context.l10n.tileCatalogSubtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const TasklyTileCatalogPage(),
          ),
        );
      },
    );
  }
}

class _ResetOnboardingItem extends StatelessWidget {
  const _ResetOnboardingItem();

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsMaintenanceBloc, SettingsMaintenanceState>(
      listenWhen: (prev, next) =>
          prev.status.runtimeType != next.status.runtimeType,
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);

        switch (state.status) {
          case SettingsMaintenanceRunning(:final action)
              when action == SettingsMaintenanceAction.resetOnboardingAndLogout:
            messenger.clearSnackBars();
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  context.l10n.resetOnboardingRunningMessage,
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          case SettingsMaintenanceSuccess(:final action)
              when action == SettingsMaintenanceAction.resetOnboardingAndLogout:
            messenger.clearSnackBars();
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  context.l10n.resetOnboardingSuccessMessage,
                ),
              ),
            );
          case SettingsMaintenanceFailure(:final action, :final message)
              when action == SettingsMaintenanceAction.resetOnboardingAndLogout:
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
      child: ListTile(
        leading: Icon(
          Icons.restart_alt_outlined,
          color: Theme.of(context).colorScheme.error,
        ),
        title: Text(context.l10n.resetOnboardingTitle),
        subtitle: Text(context.l10n.resetOnboardingSubtitle),
        trailing: Icon(
          Icons.warning_amber,
          color: Theme.of(context).colorScheme.error,
        ),
        onTap: () => _confirmAndRun(context),
      ),
    );
  }

  Future<void> _confirmAndRun(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.resetOnboardingDialogTitle),
        content: Text(context.l10n.resetOnboardingDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancelLabel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.resetOnboardingConfirmButton),
          ),
        ],
      ),
    );

    if (!(confirmed ?? false) || !context.mounted) return;
    await context.read<SettingsMaintenanceBloc>().resetOnboardingAndSignOut();
  }
}

class _GenerateTemplateDataItem extends StatelessWidget {
  const _GenerateTemplateDataItem();

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsMaintenanceBloc, SettingsMaintenanceState>(
      listenWhen: (prev, next) =>
          prev.status.runtimeType != next.status.runtimeType,
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);

        switch (state.status) {
          case SettingsMaintenanceRunning(:final action)
              when action == SettingsMaintenanceAction.generateTemplateData:
            messenger.clearSnackBars();
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  context.l10n.templateDataGeneratingMessage,
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          case SettingsMaintenanceSuccess(:final action)
              when action == SettingsMaintenanceAction.generateTemplateData:
            messenger.clearSnackBars();
            messenger.showSnackBar(
              SnackBar(
                content: Text(context.l10n.templateDataGeneratedMessage),
              ),
            );
          case SettingsMaintenanceFailure(:final action, :final message)
              when action == SettingsMaintenanceAction.generateTemplateData:
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
      child: ListTile(
        leading: Icon(
          Icons.auto_awesome,
          color: Theme.of(context).colorScheme.error,
        ),
        title: Text(context.l10n.templateDataGenerateTitle),
        subtitle: Text(context.l10n.templateDataGenerateSubtitle),
        trailing: Icon(
          Icons.warning_amber,
          color: Theme.of(context).colorScheme.error,
        ),
        onTap: () => _confirmAndRun(context),
      ),
    );
  }

  Future<void> _confirmAndRun(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.templateDataGenerateDialogTitle),
        content: Text(context.l10n.templateDataGenerateDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancelLabel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.generateLabel),
          ),
        ],
      ),
    );

    if (!(confirmed ?? false) || !context.mounted) return;
    await context.read<SettingsMaintenanceBloc>().generateTemplateData();
  }
}
