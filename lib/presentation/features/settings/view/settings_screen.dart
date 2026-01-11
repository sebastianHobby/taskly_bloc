import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:powersync/powersync.dart' show PowerSyncDatabase;
import 'package:talker_flutter/talker_flutter.dart';
import 'package:taskly_bloc/core/routing/routing.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/value_repository_contract.dart';
import 'package:taskly_bloc/domain/services/debug/template_data_service.dart';
import 'package:taskly_bloc/domain/models/settings.dart';
import 'package:taskly_bloc/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_bloc/presentation/widgets/color_picker/color_picker_field.dart';
import 'package:taskly_bloc/presentation/widgets/content_constraint.dart';
import 'package:taskly_bloc/presentation/widgets/sign_out_confirmation.dart';

/// Settings screen for global app configuration.
///
/// Uses [GlobalSettingsBloc] for reactive settings management with
/// optimistic UI updates.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const bool _showLegacyFocusItems = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: BlocBuilder<GlobalSettingsBloc, GlobalSettingsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final settings = state.settings;

          return ResponsiveBody(
            child: ListView(
              children: [
                _buildSection(
                  context: context,
                  title: 'Appearance',
                  children: [
                    _ThemeModeSelector(settings: settings),
                    _ColorPicker(settings: settings),
                    _TextSizeSlider(settings: settings),
                  ],
                ),
                _buildSection(
                  context: context,
                  title: 'Language & Region',
                  children: [
                    _LanguageSelector(settings: settings),
                    _HomeTimeZoneSelector(settings: settings),
                    _DateFormatSelector(settings: settings),
                  ],
                ),
                _buildSection(
                  context: context,
                  title: 'Customization',
                  children: [
                    _buildNavigationOrderItem(context),
                    if (_showLegacyFocusItems)
                      _buildTaskAllocationItem(context),
                    if (_showLegacyFocusItems)
                      _buildAttentionRulesItem(context),
                  ],
                ),
                _buildSection(
                  context: context,
                  title: 'Advanced',
                  children: [
                    _buildScreenManagementItem(context),
                    _buildWorkflowManagementItem(context),
                    const _ResetButton(),
                  ],
                ),
                _buildSection(
                  context: context,
                  title: 'Developer',
                  children: [
                    _buildViewLogsItem(context),
                    if (kDebugMode) const _GenerateTemplateDataItem(),
                    if (kDebugMode) const _ClearLocalDataItem(),
                  ],
                ),
                _buildSection(
                  context: context,
                  title: 'Account',
                  children: const [
                    _AccountInfo(),
                    _SignOutItem(),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildTaskAllocationItem(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.tune),
      title: const Text('Task Allocation'),
      subtitle: const Text('Strategy, limits, and value ranking'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Routing.toScreenKey(context, 'focus_setup'),
    );
  }

  Widget _buildNavigationOrderItem(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.menu),
      title: const Text('Navigation Order'),
      subtitle: const Text('Reorder sidebar items'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Routing.toScreenKey(context, 'navigation-settings'),
    );
  }

  Widget _buildScreenManagementItem(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.dashboard_customize),
      title: const Text('Custom Screens'),
      subtitle: const Text('Create and manage custom screens'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Routing.toScreenKey(context, 'screen-management'),
    );
  }

  Widget _buildWorkflowManagementItem(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.loop),
      title: const Text('Review Workflows'),
      subtitle: const Text('Create and manage review workflows'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Routing.toScreenKey(context, 'workflows'),
    );
  }

  Widget _buildAttentionRulesItem(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.notifications_active),
      title: const Text('Attention Rules'),
      subtitle: const Text('Configure problem detection and review reminders'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Routing.toScreenKey(context, 'focus_setup'),
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
            builder: (_) => TalkerScreen(talker: talker.raw),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Private Widget Classes
// ---------------------------------------------------------------------------

class _ThemeModeSelector extends StatelessWidget {
  const _ThemeModeSelector({required this.settings});

  final GlobalSettings settings;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('Theme Mode'),
      subtitle: const Text('Choose between light, dark, or system theme'),
      trailing: SegmentedButton<AppThemeMode>(
        segments: const [
          ButtonSegment(
            value: AppThemeMode.light,
            icon: Icon(Icons.light_mode, size: 16),
          ),
          ButtonSegment(
            value: AppThemeMode.dark,
            icon: Icon(Icons.dark_mode, size: 16),
          ),
          ButtonSegment(
            value: AppThemeMode.system,
            icon: Icon(Icons.brightness_auto, size: 16),
          ),
        ],
        selected: {settings.themeMode},
        onSelectionChanged: (Set<AppThemeMode> newSelection) {
          context.read<GlobalSettingsBloc>().add(
            GlobalSettingsEvent.themeModeChanged(newSelection.first),
          );
        },
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({required this.settings});

  final GlobalSettings settings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ColorPickerField(
        color: Color(settings.colorSchemeSeedArgb),
        onColorChanged: (color) {
          context.read<GlobalSettingsBloc>().add(
            GlobalSettingsEvent.colorChanged(color.toARGB32()),
          );
        },
        label: 'Theme Color',
        showMaterialName: true,
      ),
    );
  }
}

class _TextSizeSlider extends StatelessWidget {
  const _TextSizeSlider({required this.settings});

  final GlobalSettings settings;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('Text Size'),
      subtitle: Slider(
        value: settings.textScaleFactor,
        min: 0.8,
        max: 1.4,
        divisions: 6,
        label: '${(settings.textScaleFactor * 100).round()}%',
        onChanged: (value) {
          context.read<GlobalSettingsBloc>().add(
            GlobalSettingsEvent.textScaleChanged(value),
          );
        },
      ),
      trailing: Text(
        '${(settings.textScaleFactor * 100).round()}%',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({required this.settings});

  final GlobalSettings settings;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('Language'),
      subtitle: const Text('Select your preferred language'),
      trailing: DropdownButton<String?>(
        value: settings.localeCode,
        items: const [
          DropdownMenuItem(
            child: Text('System'),
          ),
          DropdownMenuItem(
            value: 'en',
            child: Text('English'),
          ),
          DropdownMenuItem(
            value: 'es',
            child: Text('Español'),
          ),
        ],
        onChanged: (localeCode) {
          context.read<GlobalSettingsBloc>().add(
            GlobalSettingsEvent.localeChanged(localeCode),
          );
        },
      ),
    );
  }
}

class _DateFormatSelector extends StatelessWidget {
  const _DateFormatSelector({required this.settings});

  final GlobalSettings settings;

  static const List<String> _patterns = [
    DateFormatPatterns.short,
    DateFormatPatterns.medium,
    DateFormatPatterns.long,
    DateFormatPatterns.full,
  ];

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('Date Format'),
      subtitle: Text(_getDateFormatExample(settings.dateFormatPattern)),
      trailing: DropdownButton<String>(
        value: settings.dateFormatPattern,
        items: _patterns.map((pattern) {
          return DropdownMenuItem(
            value: pattern,
            child: Text(_getDateFormatLabel(pattern)),
          );
        }).toList(),
        onChanged: (pattern) {
          if (pattern != null) {
            context.read<GlobalSettingsBloc>().add(
              GlobalSettingsEvent.dateFormatChanged(pattern),
            );
          }
        },
      ),
    );
  }

  String _getDateFormatLabel(String pattern) {
    switch (pattern) {
      case DateFormatPatterns.short:
        return 'Short';
      case DateFormatPatterns.medium:
        return 'Medium';
      case DateFormatPatterns.long:
        return 'Long';
      case DateFormatPatterns.full:
        return 'Full';
      default:
        return 'Custom';
    }
  }

  String _getDateFormatExample(String pattern) {
    final now = DateTime(2025, 12, 30);
    final formatter = DateFormatPatterns.getFormat(pattern);
    return 'Example: ${formatter.format(now)}';
  }
}

class _HomeTimeZoneSelector extends StatelessWidget {
  const _HomeTimeZoneSelector({required this.settings});

  final GlobalSettings settings;

  static const int _minOffsetMinutes = -12 * 60;
  static const int _maxOffsetMinutes = 14 * 60;
  static const int _stepMinutes = 30;

  @override
  Widget build(BuildContext context) {
    final items = <DropdownMenuItem<int>>[];
    for (
      var offset = _minOffsetMinutes;
      offset <= _maxOffsetMinutes;
      offset += _stepMinutes
    ) {
      items.add(
        DropdownMenuItem<int>(
          value: offset,
          child: Text(_formatOffset(offset)),
        ),
      );
    }

    return ListTile(
      title: const Text('Home Timezone'),
      subtitle: const Text(
        'Fixed day boundary for “today” and daily snapshots',
      ),
      trailing: DropdownButton<int>(
        value: settings.homeTimeZoneOffsetMinutes,
        items: items,
        onChanged: (offsetMinutes) {
          if (offsetMinutes == null) return;
          context.read<GlobalSettingsBloc>().add(
            GlobalSettingsEvent.homeTimeZoneOffsetChanged(offsetMinutes),
          );
        },
      ),
    );
  }

  String _formatOffset(int offsetMinutes) {
    final sign = offsetMinutes >= 0 ? '+' : '-';
    final abs = offsetMinutes.abs();
    final hours = abs ~/ 60;
    final minutes = abs % 60;
    final hh = hours.toString().padLeft(2, '0');
    final mm = minutes.toString().padLeft(2, '0');
    return minutes == 0 ? 'GMT$sign$hh' : 'GMT$sign$hh:$mm';
  }
}

class _ResetButton extends StatelessWidget {
  const _ResetButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: OutlinedButton.icon(
        onPressed: () => _showResetConfirmation(context),
        icon: const Icon(Icons.restore),
        label: const Text('Reset to Defaults'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }

  Future<void> _showResetConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all settings to their default values?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && context.mounted) {
      context.read<GlobalSettingsBloc>().add(const GlobalSettingsEvent.reset());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings reset to defaults')),
      );
    }
  }
}

class _GenerateTemplateDataItem extends StatelessWidget {
  const _GenerateTemplateDataItem();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        Icons.auto_awesome,
        color: Theme.of(context).colorScheme.error,
      ),
      title: const Text('Generate Template Data'),
      subtitle: const Text('Deletes user data and seeds a demo set'),
      trailing: Icon(
        Icons.warning_amber,
        color: Theme.of(context).colorScheme.error,
      ),
      onTap: () => _confirmAndRun(context),
    );
  }

  Future<void> _confirmAndRun(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Generate Template Data'),
        content: const Text(
          'This will delete all Tasks, Projects, and Values for the current '
          'account and then generate a sample dataset.\n\n'
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

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Generating template data…'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final getIt = GetIt.instance;
      final service = TemplateDataService(
        taskRepository: getIt<TaskRepositoryContract>(),
        projectRepository: getIt<ProjectRepositoryContract>(),
        valueRepository: getIt<ValueRepositoryContract>(),
        settingsRepository: getIt<SettingsRepositoryContract>(),
      );

      await service.resetAndSeed();

      if (!context.mounted) return;
      messenger.clearSnackBars();
      messenger.showSnackBar(
        const SnackBar(content: Text('Template data generated.')),
      );
    } catch (e, st) {
      talker.handle(e, st, '[Settings] Failed to generate template data');
      if (!context.mounted) return;
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to generate template data: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

class _ClearLocalDataItem extends StatelessWidget {
  const _ClearLocalDataItem();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        Icons.delete_forever,
        color: Theme.of(context).colorScheme.error,
      ),
      title: const Text('Clear Local Data'),
      subtitle: const Text('Delete all cached data and resync'),
      trailing: Icon(
        Icons.warning_amber,
        color: Theme.of(context).colorScheme.error,
      ),
      onTap: () => _showClearLocalDataConfirmation(context),
    );
  }

  Future<void> _showClearLocalDataConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Local Data'),
        content: const Text(
          'This will delete all locally cached data and force a full resync '
          'from the server. The app will restart after clearing.\n\n'
          'Use this to fix data sync issues or corrupted local state.',
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
            child: const Text('Clear & Restart'),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && context.mounted) {
      await _clearLocalData(context);
    }
  }

  Future<void> _clearLocalData(BuildContext context) async {
    try {
      final db = GetIt.instance<PowerSyncDatabase>();

      // Disconnect from sync
      await db.disconnect();

      // Delete all local data
      await db.disconnectedAndClear();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Local data cleared. Please restart the app.'),
            duration: Duration(seconds: 5),
          ),
        );
      }

      // Force sign out to trigger full re-auth and resync
      if (context.mounted) {
        context.read<AuthBloc>().add(const AuthSignOutRequested());
      }
    } catch (e, st) {
      talker.handle(e, st, '[Settings] Failed to clear local data');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear data: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
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
          return const SizedBox.shrink();
        }

        final email = user.email;
        final displayName =
            user.userMetadata?['display_name'] as String? ??
            user.userMetadata?['full_name'] as String? ??
            user.userMetadata?['name'] as String?;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              _getInitials(displayName, email),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            displayName ?? 'User',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: email != null ? Text(email) : null,
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
            content: const Text('Sign out failed. Please try again.'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _performSignOut(context),
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: OutlinedButton.icon(
          onPressed: () => _performSignOut(context),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sign Out'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
        ),
      ),
    );
  }

  Future<void> _performSignOut(BuildContext context) async {
    final confirmed = await showSignOutConfirmationDialog(context: context);
    if (!confirmed || !context.mounted) return;

    await HapticFeedback.lightImpact();
    if (context.mounted) {
      context.read<AuthBloc>().add(const AuthSignOutRequested());
    }
  }
}
