import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/notifications/notification_permission_service.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/notification_permission_bloc.dart';
import 'package:taskly_bloc/presentation/features/settings/view/settings_page_layout.dart';
import 'package:taskly_domain/settings.dart';
import 'package:taskly_ui/taskly_ui_primitives.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class SettingsNotificationsPage extends StatelessWidget {
  const SettingsNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: BlocBuilder<GlobalSettingsBloc, GlobalSettingsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SettingsPageLayout(
            icon: Icons.notifications_none_rounded,
            title: context.l10n.settingsNotificationsTitle,
            subtitle: context.l10n.settingsNotificationsSubtitle,
            children: [
              _PlanMyDayReminderCard(settings: state.settings),
            ],
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
  bool _pendingEnableRequest = false;

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final summary = settings.planMyDayReminderEnabled
        ? _formatMinutes(context, settings.planMyDayReminderTimeMinutes)
        : context.l10n.offLabel;

    return BlocListener<
      NotificationPermissionBloc,
      NotificationPermissionState
    >(
      listenWhen: (previous, current) =>
          previous.requestsCompleted != current.requestsCompleted,
      listener: (context, permissionState) {
        if (!_pendingEnableRequest) return;
        _pendingEnableRequest = false;
        if (!permissionState.status.isGranted) return;

        context.read<GlobalSettingsBloc>().add(
          const GlobalSettingsEvent.planMyDayReminderEnabledChanged(true),
        );
      },
      child: BlocBuilder<NotificationPermissionBloc, NotificationPermissionState>(
        builder: (context, permissionState) {
          final notificationsGranted =
              permissionState.status == NotificationPermissionStatus.granted;

          return _SettingsSectionPadding(
            child: TasklySettingsCard(
              title: context.l10n.settingsPlanMyDayReminderTitle,
              subtitle: context.l10n.settingsPlanMyDayReminderSubtitle,
              summary: summary,
              isExpanded: _isExpanded,
              onExpandedChanged: (next) => setState(() => _isExpanded = next),
              child: Column(
                children: [
                  if (permissionState.isLoading)
                    const LinearProgressIndicator(),
                  if (!notificationsGranted)
                    _NotificationPermissionPanel(
                      status: permissionState.status,
                      onEnableRequested: () {
                        _pendingEnableRequest = true;
                        context.read<NotificationPermissionBloc>().add(
                          const NotificationPermissionRequestRequested(),
                        );
                      },
                      onOpenSettingsRequested: () {
                        context.read<NotificationPermissionBloc>().add(
                          const NotificationPermissionOpenSettingsRequested(),
                        );
                      },
                    ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: settings.planMyDayReminderEnabled,
                    title: Text(
                      context.l10n.settingsPlanMyDayReminderEnabledLabel,
                    ),
                    subtitle:
                        !settings.planMyDayReminderEnabled ||
                            notificationsGranted
                        ? null
                        : Text(
                            context
                                .l10n
                                .settingsNotificationsPermissionRequiredInline,
                          ),
                    onChanged: permissionState.status.isSupported
                        ? (value) => _handleReminderToggle(
                            context,
                            value: value,
                            permissionState: permissionState,
                          )
                        : null,
                  ),
                  _SettingsNavigationRow(
                    title: context.l10n.settingsPlanMyDayReminderTimeLabel,
                    value: _formatMinutes(
                      context,
                      settings.planMyDayReminderTimeMinutes,
                    ),
                    enabled:
                        settings.planMyDayReminderEnabled &&
                        notificationsGranted,
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
        },
      ),
    );
  }

  void _handleReminderToggle(
    BuildContext context, {
    required bool value,
    required NotificationPermissionState permissionState,
  }) {
    if (!value) {
      context.read<GlobalSettingsBloc>().add(
        const GlobalSettingsEvent.planMyDayReminderEnabledChanged(false),
      );
      return;
    }

    if (permissionState.status.isGranted) {
      context.read<GlobalSettingsBloc>().add(
        const GlobalSettingsEvent.planMyDayReminderEnabledChanged(true),
      );
      return;
    }

    _pendingEnableRequest = true;
    context.read<NotificationPermissionBloc>().add(
      const NotificationPermissionRequestRequested(),
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

class _NotificationPermissionPanel extends StatelessWidget {
  const _NotificationPermissionPanel({
    required this.status,
    required this.onEnableRequested,
    required this.onOpenSettingsRequested,
  });

  final NotificationPermissionStatus status;
  final VoidCallback onEnableRequested;
  final VoidCallback onOpenSettingsRequested;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = TasklyTokens.of(context);

    final title = switch (status) {
      NotificationPermissionStatus.unsupported =>
        context.l10n.settingsNotificationsUnsupportedTitle,
      NotificationPermissionStatus.denied =>
        context.l10n.settingsNotificationsPermissionTitle,
      NotificationPermissionStatus.granted => '',
    };
    final body = switch (status) {
      NotificationPermissionStatus.unsupported =>
        context.l10n.settingsNotificationsUnsupportedBody,
      NotificationPermissionStatus.denied =>
        context.l10n.settingsNotificationsPermissionBody,
      NotificationPermissionStatus.granted => '',
    };

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: tokens.spaceSm),
      padding: EdgeInsets.all(tokens.spaceSm),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          SizedBox(height: tokens.spaceXs2),
          Text(body),
          if (status == NotificationPermissionStatus.denied) ...[
            SizedBox(height: tokens.spaceSm),
            Wrap(
              spacing: tokens.spaceXs2,
              runSpacing: tokens.spaceXs2,
              children: [
                FilledButton.tonal(
                  onPressed: onEnableRequested,
                  child: Text(
                    context.l10n.settingsNotificationsEnableAction,
                  ),
                ),
                TextButton(
                  onPressed: onOpenSettingsRequested,
                  child: Text(
                    context.l10n.settingsNotificationsOpenSettingsAction,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
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
