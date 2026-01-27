import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/presentation/debug/taskly_tile_catalog_page.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/settings_maintenance_cubit.dart';
import 'package:taskly_bloc/presentation/shared/responsive/responsive.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class SettingsDeveloperPage extends StatelessWidget {
  const SettingsDeveloperPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsMaintenanceCubit>(
      create: (_) => SettingsMaintenanceCubit(
        templateDataService: getIt<TemplateDataService>(),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Developer'),
        ),
        body: ResponsiveBody(
          isExpandedLayout: context.isExpandedScreen,
          child: ListView(
            children: [
              _buildViewLogsItem(context),
              _buildTileCatalogItem(context),
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
      title: const Text('View App Logs'),
      subtitle: const Text('View and share app logs for debugging'),
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
      title: const Text('Tile Catalog'),
      subtitle: const Text('Preview all task, project, and value tiles'),
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

class _GenerateTemplateDataItem extends StatelessWidget {
  const _GenerateTemplateDataItem();

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsMaintenanceCubit, SettingsMaintenanceState>(
      listenWhen: (prev, next) =>
          prev.status.runtimeType != next.status.runtimeType,
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);

        switch (state.status) {
          case SettingsMaintenanceRunning(:final action)
              when action == SettingsMaintenanceAction.generateTemplateData:
            messenger.clearSnackBars();
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Generating template data...'),
                duration: Duration(seconds: 2),
              ),
            );
          case SettingsMaintenanceSuccess(:final action)
              when action == SettingsMaintenanceAction.generateTemplateData:
            messenger.clearSnackBars();
            messenger.showSnackBar(
              const SnackBar(content: Text('Template data generated.')),
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
        title: const Text('Generate Template Data'),
        subtitle: const Text(
          'Deletes user data and seeds a demo set (single-value projects)',
        ),
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
        title: const Text('Generate Template Data'),
        content: const Text(
          'This will delete all Tasks, Projects, and Values for the current '
          'account and then generate a sample dataset with single-value '
          'projects and optional task values.\n\n'
          'It will also clear any saved My Day plan selections.\n\n'
          'This is intended for debug/demo use only.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Generate'),
          ),
        ],
      ),
    );

    if (!(confirmed ?? false) || !context.mounted) return;
    await context.read<SettingsMaintenanceCubit>().generateTemplateData();
  }
}
