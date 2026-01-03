import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:powersync/powersync.dart' show PowerSyncDatabase;
import 'package:talker_flutter/talker_flutter.dart';
import 'package:taskly_bloc/core/routing/routes.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/models/settings.dart';
import 'package:taskly_bloc/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:taskly_bloc/presentation/widgets/color_picker/color_picker_field.dart';
import 'package:taskly_bloc/presentation/widgets/content_constraint.dart';
import 'package:taskly_bloc/presentation/widgets/sign_out_confirmation.dart';

/// Settings screen for global app configuration.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({required this.settingsRepository, super.key});

  final SettingsRepositoryContract settingsRepository;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SettingsRepositoryContract get _settingsRepo => widget.settingsRepository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: StreamBuilder<GlobalSettings>(
        stream: _settingsRepo.watchGlobalSettings(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final settings = snapshot.data!;

          return ResponsiveBody(
            child: ListView(
              children: [
                _buildSection(
                  title: 'Appearance',
                  children: [
                    _buildThemeModeSelector(settings),
                    _buildColorPicker(settings),
                    _buildTextSizeSlider(settings),
                  ],
                ),
                _buildSection(
                  title: 'Language & Region',
                  children: [
                    _buildLanguageSelector(settings),
                    _buildDateFormatSelector(settings),
                  ],
                ),
                _buildSection(
                  title: 'Customization',
                  children: [
                    _buildTaskAllocationItem(),
                    _buildNavigationOrderItem(),
                  ],
                ),
                _buildSection(
                  title: 'Advanced',
                  children: [
                    _buildScreenManagementItem(),
                    _buildWorkflowManagementItem(),
                    _buildResetButton(),
                  ],
                ),
                _buildSection(
                  title: 'Developer',
                  children: [
                    _buildViewLogsItem(),
                    if (kDebugMode) _buildClearLocalDataItem(),
                  ],
                ),
                _buildSection(
                  title: 'Account',
                  children: [
                    _buildAccountInfo(),
                    _buildSignOutItem(),
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

  Widget _buildThemeModeSelector(GlobalSettings settings) {
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
        onSelectionChanged: (Set<AppThemeMode> newSelection) async {
          final updated = settings.copyWith(themeMode: newSelection.first);
          await _settingsRepo.saveGlobalSettings(updated);
        },
      ),
    );
  }

  Widget _buildColorPicker(GlobalSettings settings) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ColorPickerField(
        color: Color(settings.colorSchemeSeedArgb),
        onColorChanged: (color) async {
          final updated = settings.copyWith(colorSchemeSeedArgb: color.value);
          await _settingsRepo.saveGlobalSettings(updated);
        },
        label: 'Theme Color',
        showMaterialName: true,
      ),
    );
  }

  Widget _buildTextSizeSlider(GlobalSettings settings) {
    return ListTile(
      title: const Text('Text Size'),
      subtitle: Slider(
        value: settings.textScaleFactor,
        min: 0.8,
        max: 1.4,
        divisions: 6,
        label: '${(settings.textScaleFactor * 100).round()}%',
        onChanged: (value) async {
          final updated = settings.copyWith(textScaleFactor: value);
          await _settingsRepo.saveGlobalSettings(updated);
        },
      ),
      trailing: Text(
        '${(settings.textScaleFactor * 100).round()}%',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  Widget _buildLanguageSelector(GlobalSettings settings) {
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
        onChanged: (localeCode) async {
          final updated = settings.copyWith(localeCode: localeCode);
          await _settingsRepo.saveGlobalSettings(updated);
        },
      ),
    );
  }

  Widget _buildDateFormatSelector(GlobalSettings settings) {
    final patterns = [
      DateFormatPatterns.short,
      DateFormatPatterns.medium,
      DateFormatPatterns.long,
      DateFormatPatterns.full,
    ];

    return ListTile(
      title: const Text('Date Format'),
      subtitle: Text(_getDateFormatExample(settings.dateFormatPattern)),
      trailing: DropdownButton<String>(
        value: settings.dateFormatPattern,
        items: patterns.map((pattern) {
          return DropdownMenuItem(
            value: pattern,
            child: Text(_getDateFormatLabel(pattern)),
          );
        }).toList(),
        onChanged: (pattern) async {
          if (pattern != null) {
            final updated = settings.copyWith(dateFormatPattern: pattern);
            await _settingsRepo.saveGlobalSettings(updated);
          }
        },
      ),
    );
  }

  Widget _buildTaskAllocationItem() {
    return ListTile(
      leading: const Icon(Icons.tune),
      title: const Text('Task Allocation'),
      subtitle: const Text('Strategy, limits, and value ranking'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        context.pushNamed(AppRouteName.taskNextActionsSettings);
      },
    );
  }

  Widget _buildNavigationOrderItem() {
    return ListTile(
      leading: const Icon(Icons.menu),
      title: const Text('Navigation Order'),
      subtitle: const Text('Reorder sidebar items'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        context.pushNamed(AppRouteName.navigationSettings);
      },
    );
  }

  Widget _buildScreenManagementItem() {
    return ListTile(
      leading: const Icon(Icons.dashboard_customize),
      title: const Text('Custom Screens'),
      subtitle: const Text('Create and manage custom screens'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        context.pushNamed(AppRouteName.screenManagement);
      },
    );
  }

  Widget _buildWorkflowManagementItem() {
    return ListTile(
      leading: const Icon(Icons.loop),
      title: const Text('Review Workflows'),
      subtitle: const Text('Create and manage review workflows'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        context.pushNamed(AppRouteName.workflows);
      },
    );
  }

  Widget _buildResetButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: OutlinedButton.icon(
        onPressed: _showResetConfirmation,
        icon: const Icon(Icons.restore),
        label: const Text('Reset to Defaults'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }

  Widget _buildViewLogsItem() {
    return ListTile(
      leading: const Icon(Icons.bug_report_outlined),
      title: const Text('View App Logs'),
      subtitle: const Text('View and share app logs for debugging'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => TalkerScreen(talker: talker),
          ),
        );
      },
    );
  }

  Widget _buildClearLocalDataItem() {
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
      onTap: _showClearLocalDataConfirmation,
    );
  }

  Future<void> _showClearLocalDataConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Local Data'),
        content: const Text(
          'This will delete all locally cached data and force a full resync '
          'from the server. The app will restart after clearing.\n\n'
          'Use this to fix data sync issues or corrupted local state.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear & Restart'),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && mounted) {
      await _clearLocalData();
    }
  }

  Future<void> _clearLocalData() async {
    try {
      final db = GetIt.instance<PowerSyncDatabase>();

      // Disconnect from sync
      await db.disconnect();

      // Delete all local data
      await db.disconnectedAndClear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Local data cleared. Please restart the app.'),
            duration: Duration(seconds: 5),
          ),
        );
      }

      // Force sign out to trigger full re-auth and resync
      if (mounted) {
        context.read<AuthBloc>().add(const AuthSignOutRequested());
      }
    } catch (e, st) {
      talker.handle(e, st, '[Settings] Failed to clear local data');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear data: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _showResetConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all settings to their default values?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && mounted) {
      await _settingsRepo.saveGlobalSettings(const GlobalSettings());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings reset to defaults')),
        );
      }
    }
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

  Widget _buildAccountInfo() {
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

  Widget _buildSignOutItem() {
    return BlocListener<AuthBloc, AppAuthState>(
      listenWhen: (prev, curr) =>
          prev.error != curr.error && curr.error != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Sign out failed. Please try again.'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _performSignOut,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: OutlinedButton.icon(
          onPressed: _performSignOut,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sign Out'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
        ),
      ),
    );
  }

  Future<void> _performSignOut() async {
    final confirmed = await showSignOutConfirmationDialog(context: context);
    if (!confirmed || !mounted) return;

    await HapticFeedback.lightImpact();
    if (mounted) {
      context.read<AuthBloc>().add(const AuthSignOutRequested());
    }
  }
}
