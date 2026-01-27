import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_domain/settings.dart';
import 'package:taskly_bloc/presentation/features/review/view/weekly_review_modal.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_bloc/presentation/shared/responsive/responsive.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class SettingsWeeklyReviewPage extends StatelessWidget {
  const SettingsWeeklyReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Review'),
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
                _WeeklyReviewSchedule(settings: settings),
                _WeeklyReviewValuesSummary(settings: settings),
                _WeeklyReviewMaintenance(settings: settings),
                SizedBox(height: TasklyTokens.of(context).spaceSm),
              ],
            ),
          );
        },
      ),
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
          padding: EdgeInsets.fromLTRB(
            TasklyTokens.of(context).spaceLg,
            TasklyTokens.of(context).spaceXs,
            TasklyTokens.of(context).spaceLg,
            TasklyTokens.of(context).spaceSm,
          ),
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
          padding: EdgeInsets.fromLTRB(
            TasklyTokens.of(context).spaceLg,
            0,
            TasklyTokens.of(context).spaceLg,
            0,
          ),
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
                  SizedBox(height: TasklyTokens.of(context).spaceSm),
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
          padding: EdgeInsets.fromLTRB(
            TasklyTokens.of(context).spaceLg,
            0,
            TasklyTokens.of(context).spaceLg,
            0,
          ),
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
                    title: const Text('Missing next actions'),
                    value: settings.maintenanceMissingNextActionsEnabled,
                    onChanged: (value) {
                      context.read<GlobalSettingsBloc>().add(
                        GlobalSettingsEvent.maintenanceMissingNextActionsChanged(
                          value,
                        ),
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
