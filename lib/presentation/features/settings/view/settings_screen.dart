import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_domain/settings.dart';
import 'package:taskly_bloc/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/settings_maintenance_cubit.dart';
import 'package:taskly_bloc/presentation/features/settings/widgets/accent_palette_gallery.dart';
import 'package:taskly_bloc/presentation/features/review/view/weekly_review_modal.dart';
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
                      _MyDayDueSoonToggle(settings: settings),
                      _MyDayDueWindowSlider(settings: settings),
                      _MyDayShowAvailableToStartToggle(settings: settings),
                    ],
                  ),
                  _buildSection(
                    context: context,
                    title: 'Weekly Review',
                    children: [
                      _WeeklyReviewSchedule(settings: settings),
                      _WeeklyReviewValuesSummary(settings: settings),
                      _WeeklyReviewMaintenance(settings: settings),
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
                      const SizedBox.shrink(),
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

class _MyDayDueSoonToggle extends StatelessWidget {
  const _MyDayDueSoonToggle({required this.settings});

  final GlobalSettings settings;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      title: const Text('Due soon'),
      subtitle: const Text(
        'Include tasks with due dates in the due-soon window.',
      ),
      value: settings.myDayDueSoonEnabled,
      onChanged: (enabled) {
        context.read<GlobalSettingsBloc>().add(
          GlobalSettingsEvent.myDayDueSoonEnabledChanged(enabled),
        );
      },
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
    final enabled = settings.myDayDueSoonEnabled;
    final helperText = enabled
        ? 'Include tasks due within the next $days days'
        : 'Enable the "Due soon" toggle to include deadline-based tasks.';

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
            helperText,
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
            onChanged: enabled
                ? (value) {
                    context.read<GlobalSettingsBloc>().add(
                      GlobalSettingsEvent.myDayDueWindowDaysChanged(
                        value.round(),
                      ),
                    );
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

class _MyDayShowAvailableToStartToggle extends StatelessWidget {
  const _MyDayShowAvailableToStartToggle({required this.settings});

  final GlobalSettings settings;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      title: const Text('Show planned tasks'),
      subtitle: const Text('Tasks with a planned date of today or earlier'),
      value: settings.myDayShowAvailableToStart,
      onChanged: (enabled) {
        context.read<GlobalSettingsBloc>().add(
          GlobalSettingsEvent.myDayShowAvailableToStartChanged(enabled),
        );
      },
    );
  }
}

class _WeeklyReviewSchedule extends StatelessWidget {
  const _WeeklyReviewSchedule({required this.settings});

  final GlobalSettings settings;

  @override
  Widget build(BuildContext context) {
    final isEnabled = settings.weeklyReviewEnabled;
    final dayLabel = _weekdayLabel(settings.weeklyReviewDayOfWeek);
    final cadenceLabel = _cadenceLabel(settings.weeklyReviewCadenceWeeks);
    final timeLabel = _formatTime(context, settings.weeklyReviewTimeMinutes);

    return Column(
      children: [
        SwitchListTile.adaptive(
          title: const Text('Weekly review'),
          subtitle: const Text(
            'A gentle check-in on a day that works for you.',
          ),
          value: isEnabled,
          onChanged: (enabled) {
            context.read<GlobalSettingsBloc>().add(
              GlobalSettingsEvent.weeklyReviewEnabledChanged(enabled),
            );
          },
        ),
        ListTile(
          title: const Text('Day of week'),
          subtitle: Text(dayLabel),
          enabled: isEnabled,
          trailing: const Icon(Icons.chevron_right),
          onTap: !isEnabled
              ? null
              : () async {
                  final selected = await _showDayPicker(
                    context,
                    selectedDay: settings.weeklyReviewDayOfWeek,
                  );
                  if (selected == null || !context.mounted) return;
                  context.read<GlobalSettingsBloc>().add(
                    GlobalSettingsEvent.weeklyReviewDayOfWeekChanged(selected),
                  );
                },
        ),
        ListTile(
          title: const Text('Frequency'),
          subtitle: Text(cadenceLabel),
          enabled: isEnabled,
          trailing: const Icon(Icons.chevron_right),
          onTap: !isEnabled
              ? null
              : () async {
                  final selected = await _showCadencePicker(
                    context,
                    selectedWeeks: settings.weeklyReviewCadenceWeeks,
                  );
                  if (selected == null || !context.mounted) return;
                  context.read<GlobalSettingsBloc>().add(
                    GlobalSettingsEvent.weeklyReviewCadenceWeeksChanged(
                      selected,
                    ),
                  );
                },
        ),
        ListTile(
          title: const Text('Time'),
          subtitle: Text(timeLabel),
          enabled: isEnabled,
          trailing: const Icon(Icons.chevron_right),
          onTap: !isEnabled
              ? null
              : () async {
                  final timeOfDay = _timeOfDayFromMinutes(
                    settings.weeklyReviewTimeMinutes,
                  );
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: timeOfDay,
                  );
                  if (picked == null || !context.mounted) return;
                  final minutes = picked.hour * 60 + picked.minute;
                  context.read<GlobalSettingsBloc>().add(
                    GlobalSettingsEvent.weeklyReviewTimeMinutesChanged(minutes),
                  );
                },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: isEnabled
                  ? () => showWeeklyReviewModal(
                      context,
                      settings: settings,
                    )
                  : null,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Run review now'),
            ),
          ),
        ),
      ],
    );
  }

  String _weekdayLabel(int dayOfWeek) {
    return switch (dayOfWeek.clamp(1, 7)) {
      DateTime.monday => 'Monday',
      DateTime.tuesday => 'Tuesday',
      DateTime.wednesday => 'Wednesday',
      DateTime.thursday => 'Thursday',
      DateTime.friday => 'Friday',
      DateTime.saturday => 'Saturday',
      _ => 'Sunday',
    };
  }

  String _cadenceLabel(int weeks) {
    final clamped = weeks.clamp(1, 12);
    return clamped == 1 ? 'Every week' : 'Every $clamped weeks';
  }

  String _formatTime(BuildContext context, int minutesOfDay) {
    final hours = (minutesOfDay ~/ 60).clamp(0, 23);
    final minutes = (minutesOfDay % 60).clamp(0, 59);
    final tod = TimeOfDay(hour: hours, minute: minutes);
    return tod.format(context);
  }

  TimeOfDay _timeOfDayFromMinutes(int minutesOfDay) {
    final hours = (minutesOfDay ~/ 60).clamp(0, 23);
    final minutes = (minutesOfDay % 60).clamp(0, 59);
    return TimeOfDay(hour: hours, minute: minutes);
  }

  Future<int?> _showDayPicker(
    BuildContext context, {
    required int selectedDay,
  }) async {
    final items = <int, String>{
      DateTime.monday: 'Monday',
      DateTime.tuesday: 'Tuesday',
      DateTime.wednesday: 'Wednesday',
      DateTime.thursday: 'Thursday',
      DateTime.friday: 'Friday',
      DateTime.saturday: 'Saturday',
      DateTime.sunday: 'Sunday',
    };

    return showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return ListView(
          children: items.entries
              .map((entry) {
                return ListTile(
                  title: Text(entry.value),
                  trailing: selectedDay == entry.key
                      ? Icon(
                          Icons.check,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  onTap: () => Navigator.of(context).pop(entry.key),
                );
              })
              .toList(growable: false),
        );
      },
    );
  }

  Future<int?> _showCadencePicker(
    BuildContext context, {
    required int selectedWeeks,
  }) async {
    final options = List<int>.generate(12, (index) => index + 1);
    return showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return ListView(
          children: options
              .map((weeks) {
                return ListTile(
                  title: Text(weeks == 1 ? 'Every week' : 'Every $weeks weeks'),
                  trailing: weeks == selectedWeeks
                      ? Icon(
                          Icons.check,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  onTap: () => Navigator.of(context).pop(weeks),
                );
              })
              .toList(growable: false),
        );
      },
    );
  }
}

class _WeeklyReviewValuesSummary extends StatelessWidget {
  const _WeeklyReviewValuesSummary({required this.settings});

  final GlobalSettings settings;

  @override
  Widget build(BuildContext context) {
    final enabled = settings.valuesSummaryEnabled;
    final weeks = settings.valuesSummaryWindowWeeks.clamp(1, 12);
    final wins = settings.valuesSummaryWinsCount.clamp(1, 5);

    return Column(
      children: [
        SwitchListTile.adaptive(
          title: const Text('Values Snapshot'),
          subtitle: const Text('Show value balance and wins in each review.'),
          value: enabled,
          onChanged: (value) {
            context.read<GlobalSettingsBloc>().add(
              GlobalSettingsEvent.valuesSummaryEnabledChanged(value),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Opacity(
            opacity: enabled ? 1 : 0.5,
            child: IgnorePointer(
              ignoring: !enabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Lookback window',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        '$weeks weeks',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  Slider(
                    value: weeks.toDouble(),
                    min: 1,
                    max: 12,
                    divisions: 11,
                    label: '$weeks weeks',
                    onChanged: (value) {
                      context.read<GlobalSettingsBloc>().add(
                        GlobalSettingsEvent.valuesSummaryWindowWeeksChanged(
                          value.round(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Value wins',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        '$wins items',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  Slider(
                    value: wins.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: '$wins items',
                    onChanged: (value) {
                      context.read<GlobalSettingsBloc>().add(
                        GlobalSettingsEvent.valuesSummaryWinsCountChanged(
                          value.round(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WeeklyReviewMaintenance extends StatelessWidget {
  const _WeeklyReviewMaintenance({required this.settings});

  final GlobalSettings settings;

  @override
  Widget build(BuildContext context) {
    final enabled = settings.maintenanceEnabled;

    return Column(
      children: [
        SwitchListTile.adaptive(
          title: const Text('Maintenance Check'),
          subtitle: const Text('Optional prompts to keep things on track.'),
          value: enabled,
          onChanged: (value) {
            context.read<GlobalSettingsBloc>().add(
              GlobalSettingsEvent.maintenanceEnabledChanged(value),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Opacity(
            opacity: enabled ? 1 : 0.5,
            child: IgnorePointer(
              ignoring: !enabled,
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    title: const Text('Deadline risk'),
                    value: settings.maintenanceDeadlineRiskEnabled,
                    onChanged: (value) {
                      context.read<GlobalSettingsBloc>().add(
                        GlobalSettingsEvent.maintenanceDeadlineRiskChanged(
                          value,
                        ),
                      );
                    },
                  ),
                  SwitchListTile.adaptive(
                    title: const Text('Due soon (under control)'),
                    value: settings.maintenanceDueSoonEnabled,
                    onChanged: (value) {
                      context.read<GlobalSettingsBloc>().add(
                        GlobalSettingsEvent.maintenanceDueSoonChanged(value),
                      );
                    },
                  ),
                  SwitchListTile.adaptive(
                    title: const Text('Stale tasks & projects'),
                    value: settings.maintenanceStaleEnabled,
                    onChanged: (value) {
                      context.read<GlobalSettingsBloc>().add(
                        GlobalSettingsEvent.maintenanceStaleChanged(value),
                      );
                    },
                  ),
                  SwitchListTile.adaptive(
                    title: const Text('Frequently snoozed tasks'),
                    value: settings.maintenanceFrequentSnoozedEnabled,
                    onChanged: (value) {
                      context.read<GlobalSettingsBloc>().add(
                        GlobalSettingsEvent.maintenanceFrequentSnoozedChanged(
                          value,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
