import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_bloc/presentation/shared/responsive/responsive.dart';
import 'package:taskly_domain/settings.dart';
import 'package:taskly_ui/taskly_ui_primitives.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class SettingsNotificationsPage extends StatelessWidget {
  const SettingsNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settingsNotificationsTitle)),
      body: BlocBuilder<GlobalSettingsBloc, GlobalSettingsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ResponsiveBody(
            isExpandedLayout: context.isExpandedScreen,
            child: ListView(
              children: [
                _PlanMyDayReminderCard(settings: state.settings),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PlanMyDayReminderCard extends StatefulWidget {
  const _PlanMyDayReminderCard({required this.settings});

  final GlobalSettings settings;

  @override
  State<_PlanMyDayReminderCard> createState() => _PlanMyDayReminderCardState();
}

class _PlanMyDayReminderCardState extends State<_PlanMyDayReminderCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final summary = settings.planMyDayReminderEnabled
        ? _formatMinutes(context, settings.planMyDayReminderTimeMinutes)
        : context.l10n.offLabel;

    return _SettingsSectionPadding(
      child: TasklySettingsCard(
        title: context.l10n.settingsPlanMyDayReminderTitle,
        subtitle: context.l10n.settingsPlanMyDayReminderSubtitle,
        summary: summary,
        isExpanded: _isExpanded,
        onExpandedChanged: (next) => setState(() => _isExpanded = next),
        child: Column(
          children: [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: settings.planMyDayReminderEnabled,
              title: Text(context.l10n.settingsPlanMyDayReminderEnabledLabel),
              onChanged: (value) {
                context.read<GlobalSettingsBloc>().add(
                  GlobalSettingsEvent.planMyDayReminderEnabledChanged(value),
                );
              },
            ),
            _SettingsNavigationRow(
              title: context.l10n.settingsPlanMyDayReminderTimeLabel,
              value: _formatMinutes(context, settings.planMyDayReminderTimeMinutes),
              enabled: settings.planMyDayReminderEnabled,
              onTap: () async {
                final selected = await _pickTime(
                  context,
                  settings.planMyDayReminderTimeMinutes,
                );
                if (selected == null || !context.mounted) return;
                context.read<GlobalSettingsBloc>().add(
                  GlobalSettingsEvent.planMyDayReminderTimeMinutesChanged(
                    selected,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatMinutes(BuildContext context, int minutes) {
    final clamped = minutes.clamp(0, 1439);
    final hour = clamped ~/ 60;
    final minute = clamped % 60;
    final time = TimeOfDay(hour: hour, minute: minute);
    return MaterialLocalizations.of(context).formatTimeOfDay(time);
  }

  Future<int?> _pickTime(BuildContext context, int currentMinutes) async {
    final initial = TimeOfDay(
      hour: currentMinutes.clamp(0, 1439) ~/ 60,
      minute: currentMinutes.clamp(0, 1439) % 60,
    );
    final selected = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (selected == null) return null;
    return selected.hour * 60 + selected.minute;
  }
}

class _SettingsSectionPadding extends StatelessWidget {
  const _SettingsSectionPadding({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.sectionPaddingH,
        tokens.spaceSm,
        tokens.sectionPaddingH,
        0,
      ),
      child: child,
    );
  }
}

class _SettingsNavigationRow extends StatelessWidget {
  const _SettingsNavigationRow({
    required this.title,
    required this.value,
    required this.onTap,
    this.enabled = true,
  });

  final String title;
  final String value;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      enabled: enabled,
      title: Text(title),
      subtitle: Text(value),
      trailing: const Icon(Icons.chevron_right),
      textColor: enabled ? null : onSurfaceVariant,
      iconColor: enabled ? null : onSurfaceVariant,
      onTap: enabled ? onTap : null,
    );
  }
}
