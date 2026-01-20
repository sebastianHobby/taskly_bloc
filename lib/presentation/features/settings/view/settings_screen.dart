import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_domain/settings.dart';
import 'package:taskly_bloc/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/settings_maintenance_cubit.dart';
import 'package:taskly_bloc/presentation/features/settings/widgets/accent_palette_gallery.dart';
import 'package:taskly_bloc/presentation/theme/app_seed_palettes.dart';
import 'package:taskly_bloc/presentation/shared/responsive/responsive.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_ui/taskly_ui_sections.dart';

/// Settings screen for global app configuration.
///
/// Uses [GlobalSettingsBloc] for reactive settings management with
/// optimistic UI updates.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const bool _showLegacyFocusItems = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsMaintenanceCubit>(
      create: (_) => SettingsMaintenanceCubit(
        templateDataService: getIt<TemplateDataService>(),
      ),
      child: Scaffold(
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
              isExpandedLayout: context.isExpandedScreen,
              child: ListView(
                children: [
                  _buildSection(
                    context: context,
                    title: 'Appearance',
                    children: [
                      _ThemeModeSelector(settings: settings),
                      _AccentPalettePicker(settings: settings),
                      _TextSizeSlider(settings: settings),
                    ],
                  ),
                  _buildSection(
                    context: context,
                    title: 'My Day',
                    children: [
                      _MyDayDueWindowSlider(settings: settings),
                    ],
                  ),
                  _buildSection(
                    context: context,
                    title: 'Language & Region',
                    children: [
                      _LanguageSelector(settings: settings),
                      _HomeTimeZoneSelector(settings: settings),
                    ],
                  ),
                  _buildSection(
                    context: context,
                    title: 'Customization',
                    children: [
                      if (_showLegacyFocusItems)
                        _buildTaskAllocationItem(context),
                      if (_showLegacyFocusItems)
                        _buildAttentionRulesItem(context),
                    ],
                  ),
                  _buildSection(
                    context: context,
                    title: 'Developer',
                    children: [
                      _buildViewLogsItem(context),
                      if (kDebugMode) const _GenerateTemplateDataItem(),
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
            builder: (_) => TalkerScreen(talker: talkerRaw),
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
      title: const Text('Theme'),
      subtitle: const Text('Light, dark, or system'),
      trailing: DropdownButton<AppThemeMode>(
        value: settings.themeMode,
        items: const [
          DropdownMenuItem(
            value: AppThemeMode.system,
            child: Text('System'),
          ),
          DropdownMenuItem(
            value: AppThemeMode.light,
            child: Text('Light'),
          ),
          DropdownMenuItem(
            value: AppThemeMode.dark,
            child: Text('Dark'),
          ),
        ],
        onChanged: (themeMode) {
          if (themeMode == null) return;
          context.read<GlobalSettingsBloc>().add(
            GlobalSettingsEvent.themeModeChanged(themeMode),
          );
        },
      ),
    );
  }
}

class _AccentPalettePicker extends StatelessWidget {
  const _AccentPalettePicker({required this.settings});

  final GlobalSettings settings;

  @override
  Widget build(BuildContext context) {
    return AccentPaletteGallery(
      title: 'Accent palette',
      subtitle: 'Pick a focused productivity theme',
      palettes: AppSeedPalettes.focusedProductivity,
      selectedSeedArgb: settings.colorSchemeSeedArgb,
      onSelected: (palette) {
        context.read<GlobalSettingsBloc>().add(
          GlobalSettingsEvent.colorChanged(palette.seedArgb),
        );
      },
    );
  }
}

class _TextSizeSlider extends StatelessWidget {
  const _TextSizeSlider({required this.settings});

  final GlobalSettings settings;

  static const double _min = 0.85;
  static const double _max = 1.25;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Text size',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                '${(settings.textScaleFactor * 100).round()}%',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          Slider(
            value: settings.textScaleFactor.clamp(_min, _max),
            min: _min,
            max: _max,
            divisions: 8,
            label: '${(settings.textScaleFactor * 100).round()}%',
            onChanged: (value) {
              context.read<GlobalSettingsBloc>().add(
                GlobalSettingsEvent.textScaleChanged(value),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MyDayDueWindowSlider extends StatelessWidget {
  const _MyDayDueWindowSlider({required this.settings});

  final GlobalSettings settings;

  static const int _min = 1;
  static const int _max = 30;

  @override
  Widget build(BuildContext context) {
    final days = settings.myDayDueWindowDays.clamp(_min, _max);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Due window',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                '$days days',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          Text(
            'Include tasks due within the next $days days',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Slider(
            value: days.toDouble(),
            min: _min.toDouble(),
            max: _max.toDouble(),
            divisions: _max - _min,
            label: '$days days',
            onChanged: (value) {
              context.read<GlobalSettingsBloc>().add(
                GlobalSettingsEvent.myDayDueWindowDaysChanged(value.round()),
              );
            },
          ),
        ],
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
        'Fixed day boundary for “today” and My Day planning',
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
                content: Text('Generating template data…'),
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
        subtitle: const Text('Deletes user data and seeds a demo set'),
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
          'account and then generate a sample dataset.\n\n'
          'It will also clear any saved My Day ritual selections.\n\n'
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Sign Out?',
      confirmLabel: 'Sign Out',
      cancelLabel: 'Cancel',
      content: Text(
        "You'll need to sign in again to access your tasks and projects.",
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
