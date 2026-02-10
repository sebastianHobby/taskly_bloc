import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:taskly_domain/settings.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/review/view/weekly_review_modal.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_bloc/presentation/shared/responsive/responsive.dart';
import 'package:taskly_ui/taskly_ui_primitives.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class SettingsWeeklyReviewPage extends StatelessWidget {
  const SettingsWeeklyReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.weeklyReviewTitle),
      ),
      body: BlocBuilder<GlobalSettingsBloc, GlobalSettingsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final settings = state.settings;
          final tokens = TasklyTokens.of(context);

          return ResponsiveBody(
            isExpandedLayout: context.isExpandedScreen,
            child: ListView(
              padding: EdgeInsets.only(bottom: tokens.spaceSm),
              children: [
                _WeeklyReviewSchedule(settings: settings),
                _WeeklyReviewMaintenance(settings: settings),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WeeklyReviewSchedule extends StatefulWidget {
  const _WeeklyReviewSchedule({required this.settings});

  final GlobalSettings settings;

  @override
  State<_WeeklyReviewSchedule> createState() => _WeeklyReviewScheduleState();
}

class _WeeklyReviewScheduleState extends State<_WeeklyReviewSchedule> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final tokens = TasklyTokens.of(context);
    final dayLabel = _weekdayLabel(context, settings.weeklyReviewDayOfWeek);
    final cadenceLabel = _cadenceLabel(
      context,
      settings.weeklyReviewCadenceWeeks,
    );
    final summary = '$dayLabel - $cadenceLabel';

    return _SettingsSectionPadding(
      child: TasklySettingsCard(
        title: context.l10n.weeklyReviewScheduleTitle,
        subtitle: context.l10n.weeklyReviewScheduleSubtitle,
        summary: summary,
        isExpanded: _isExpanded,
        onExpandedChanged: (next) => setState(() => _isExpanded = next),
        child: Column(
          children: [
            _SettingsNavigationRow(
              title: context.l10n.weeklyReviewDayOfWeekLabel,
              value: dayLabel,
              onTap: () async {
                final selected = await _showDayPicker(
                  context,
                  selectedDay: settings.weeklyReviewDayOfWeek,
                );
                if (selected == null || !context.mounted) return;
                context.read<GlobalSettingsBloc>().add(
                  GlobalSettingsEvent.weeklyReviewDayOfWeekChanged(
                    selected,
                  ),
                );
              },
            ),
            SizedBox(height: tokens.spaceSm),
            _SettingsNavigationRow(
              title: context.l10n.weeklyReviewFrequencyLabel,
              value: cadenceLabel,
              onTap: () async {
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
            SizedBox(height: tokens.spaceMd),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonal(
                onPressed: () => showWeeklyReviewModal(
                  context,
                  settings: settings,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_arrow_rounded),
                    SizedBox(width: tokens.spaceSm),
                    Text(context.l10n.weeklyReviewRunNowLabel),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _weekdayLabel(BuildContext context, int dayOfWeek) {
    final locale = Localizations.localeOf(context).toString();
    final formatter = DateFormat.EEEE(locale);
    final baseMonday = DateTime(2020, 1, 6);
    final offset = dayOfWeek.clamp(1, 7) - DateTime.monday;
    return formatter.format(baseMonday.add(Duration(days: offset)));
  }

  String _cadenceLabel(BuildContext context, int weeks) {
    final clamped = weeks.clamp(1, 12);
    return context.l10n.weeklyReviewCadenceLabel(clamped);
  }

  Future<int?> _showDayPicker(
    BuildContext context, {
    required int selectedDay,
  }) async {
    final items = <int, String>{
      DateTime.monday: _weekdayLabel(context, DateTime.monday),
      DateTime.tuesday: _weekdayLabel(context, DateTime.tuesday),
      DateTime.wednesday: _weekdayLabel(context, DateTime.wednesday),
      DateTime.thursday: _weekdayLabel(context, DateTime.thursday),
      DateTime.friday: _weekdayLabel(context, DateTime.friday),
      DateTime.saturday: _weekdayLabel(context, DateTime.saturday),
      DateTime.sunday: _weekdayLabel(context, DateTime.sunday),
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
    const options = [1, 2];
    return showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return ListView(
          children: options
              .map((weeks) {
                return ListTile(
                  title: Text(context.l10n.weeklyReviewCadenceLabel(weeks)),
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

class _WeeklyReviewMaintenance extends StatefulWidget {
  const _WeeklyReviewMaintenance({required this.settings});

  final GlobalSettings settings;

  @override
  State<_WeeklyReviewMaintenance> createState() =>
      _WeeklyReviewMaintenanceState();
}

class _WeeklyReviewMaintenanceState extends State<_WeeklyReviewMaintenance> {
  bool _isExpanded = false;
  bool _deadlineExpanded = false;
  bool _staleExpanded = false;

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final tokens = TasklyTokens.of(context);
    final summary = _maintenanceSummary(context, settings);

    return _SettingsSectionPadding(
      child: TasklySettingsCard(
        title: context.l10n.weeklyReviewMaintenanceTitle,
        subtitle: context.l10n.weeklyReviewMaintenanceSubtitle,
        summary: summary,
        isExpanded: _isExpanded,
        onExpandedChanged: (next) => setState(() => _isExpanded = next),
        child: Column(
          children: [
            _RuleCard(
              title: context.l10n.weeklyReviewDeadlineRiskTitle,
              summary: context.l10n.weeklyReviewDeadlineRiskDescription,
              enabled: settings.maintenanceDeadlineRiskEnabled,
              isExpanded: _deadlineExpanded,
              onExpandedChanged: (next) =>
                  setState(() => _deadlineExpanded = next),
              onEnabledChanged: (value) {
                context.read<GlobalSettingsBloc>().add(
                  GlobalSettingsEvent.maintenanceDeadlineRiskChanged(
                    value,
                  ),
                );
              },
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      context.l10n.weeklyReviewDeadlineRiskDescription,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  SizedBox(height: tokens.spaceSm),
                  _RuleSlider(
                    label: context.l10n.weeklyReviewDueWithinLabel,
                    value: settings.maintenanceDeadlineRiskDueWithinDays,
                    min: GlobalSettings.maintenanceDeadlineRiskDueWithinDaysMin,
                    max: GlobalSettings.maintenanceDeadlineRiskDueWithinDaysMax,
                    valueLabel: context.l10n.daysCountLabel(
                      settings.maintenanceDeadlineRiskDueWithinDays,
                    ),
                    onCommit: (value) {
                      context.read<GlobalSettingsBloc>().add(
                        GlobalSettingsEvent.maintenanceDeadlineRiskDueWithinDaysChanged(
                          value,
                        ),
                      );
                    },
                  ),
                  SizedBox(height: tokens.spaceSm),
                  _RuleSlider(
                    label: context.l10n.weeklyReviewUnscheduledTasksLabel,
                    value: settings.maintenanceDeadlineRiskMinUnscheduledCount,
                    min: GlobalSettings
                        .maintenanceDeadlineRiskMinUnscheduledCountMin,
                    max: GlobalSettings
                        .maintenanceDeadlineRiskMinUnscheduledCountMax,
                    valueLabel: context.l10n.tasksCountLabel(
                      settings.maintenanceDeadlineRiskMinUnscheduledCount,
                    ),
                    onCommit: (value) {
                      context.read<GlobalSettingsBloc>().add(
                        GlobalSettingsEvent.maintenanceDeadlineRiskMinUnscheduledCountChanged(
                          value,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: tokens.spaceSm),
            _RuleCard(
              title: context.l10n.weeklyReviewStaleTitle,
              summary: context.l10n.weeklyReviewStaleDescription,
              enabled: settings.maintenanceStaleEnabled,
              isExpanded: _staleExpanded,
              onExpandedChanged: (next) =>
                  setState(() => _staleExpanded = next),
              onEnabledChanged: (value) {
                context.read<GlobalSettingsBloc>().add(
                  GlobalSettingsEvent.maintenanceStaleChanged(value),
                );
              },
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      context.l10n.weeklyReviewStaleDescription,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  SizedBox(height: tokens.spaceSm),
                  _RuleSlider(
                    label: context.l10n.weeklyReviewTaskStaleAfterLabel,
                    value: settings.maintenanceTaskStaleThresholdDays,
                    min: GlobalSettings.maintenanceStaleThresholdDaysMin,
                    max: GlobalSettings.maintenanceStaleThresholdDaysMax,
                    valueLabel: context.l10n.daysCountLabel(
                      settings.maintenanceTaskStaleThresholdDays,
                    ),
                    onCommit: (value) {
                      context.read<GlobalSettingsBloc>().add(
                        GlobalSettingsEvent.maintenanceTaskStaleThresholdDaysChanged(
                          value,
                        ),
                      );
                    },
                  ),
                  SizedBox(height: tokens.spaceSm),
                  _RuleSlider(
                    label: context.l10n.weeklyReviewProjectIdleAfterLabel,
                    value: settings.maintenanceProjectIdleThresholdDays,
                    min: GlobalSettings.maintenanceStaleThresholdDaysMin,
                    max: GlobalSettings.maintenanceStaleThresholdDaysMax,
                    valueLabel: context.l10n.daysCountLabel(
                      settings.maintenanceProjectIdleThresholdDays,
                    ),
                    onCommit: (value) {
                      context.read<GlobalSettingsBloc>().add(
                        GlobalSettingsEvent.maintenanceProjectIdleThresholdDaysChanged(
                          value,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: tokens.spaceSm),
            _RuleCard(
              title: context.l10n.weeklyReviewFrequentSnoozedTitle,
              summary: context.l10n.weeklyReviewFrequentSnoozedDescription,
              enabled: settings.maintenanceFrequentSnoozedEnabled,
              onEnabledChanged: (value) {
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
    );
  }

  String _maintenanceSummary(BuildContext context, GlobalSettings settings) {
    final labels = <String>[];
    if (settings.maintenanceDeadlineRiskEnabled) {
      labels.add(context.l10n.weeklyReviewDeadlineRiskTitle);
    }
    if (settings.maintenanceStaleEnabled) {
      labels.add(context.l10n.weeklyReviewStaleItemsLabel);
    }
    if (settings.maintenanceFrequentSnoozedEnabled) {
      labels.add(context.l10n.weeklyReviewFrequentSnoozesLabel);
    }
    if (labels.isEmpty) {
      return context.l10n.weeklyReviewNoChecksEnabled;
    }
    if (labels.length <= 2) {
      return labels.join(' - ');
    }
    final preview = labels.take(2).join(' - ');
    return '$preview ${context.l10n.moreCountLabel(labels.length - 2)}';
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
        tokens.spaceLg,
        tokens.spaceSm,
        tokens.spaceLg,
        0,
      ),
      child: child,
    );
  }
}

class _SettingsCardBody extends StatelessWidget {
  const _SettingsCardBody({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: IgnorePointer(
        ignoring: !enabled,
        child: child,
      ),
    );
  }
}

class _SettingsNavigationRow extends StatelessWidget {
  const _SettingsNavigationRow({
    required this.title,
    required this.value,
    required this.onTap,
  });

  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(tokens.radiusMd),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceSm,
          vertical: tokens.spaceSm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.titleSmall),
                  SizedBox(height: tokens.spaceXs2),
                  Text(
                    value,
                    style: textTheme.bodySmall?.copyWith(color: muted),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.title,
    required this.summary,
    required this.enabled,
    required this.onEnabledChanged,
    this.isExpanded = false,
    this.onExpandedChanged,
    this.child,
  });

  final String title;
  final String summary;
  final bool enabled;
  final ValueChanged<bool> onEnabledChanged;
  final bool isExpanded;
  final ValueChanged<bool>? onExpandedChanged;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return TasklySettingsCard(
      title: title,
      summary: summary,
      trailing: Switch.adaptive(
        value: enabled,
        onChanged: onEnabledChanged,
      ),
      density: TasklySettingsCardDensity.compact,
      isExpanded: isExpanded,
      onExpandedChanged: child == null ? null : onExpandedChanged,
      child: child == null
          ? null
          : _SettingsCardBody(enabled: enabled, child: child!),
    );
  }
}

class _RuleSlider extends StatelessWidget {
  const _RuleSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.valueLabel,
    required this.onCommit,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final String valueLabel;
  final ValueChanged<int> onCommit;

  @override
  Widget build(BuildContext context) {
    return _CommitSlider(
      value: value,
      min: min,
      max: max,
      divisions: max - min,
      labelBuilder: (_) => valueLabel,
      header: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Text(
            valueLabel,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ),
      onCommit: onCommit,
    );
  }
}

class _CommitSlider extends StatefulWidget {
  const _CommitSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.labelBuilder,
    required this.onCommit,
    this.header,
  });

  final int value;
  final int min;
  final int max;
  final int divisions;
  final String Function(int value) labelBuilder;
  final ValueChanged<int> onCommit;
  final Widget? header;

  @override
  State<_CommitSlider> createState() => _CommitSliderState();
}

class _CommitSliderState extends State<_CommitSlider> {
  late int _draftValue = widget.value;

  @override
  void didUpdateWidget(covariant _CommitSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _draftValue = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final clamped = _draftValue.clamp(widget.min, widget.max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.header != null) widget.header!,
        Slider(
          value: clamped.toDouble(),
          min: widget.min.toDouble(),
          max: widget.max.toDouble(),
          divisions: widget.divisions,
          label: widget.labelBuilder(clamped),
          onChanged: (next) => setState(() {
            _draftValue = next.round();
          }),
          onChangeEnd: (next) => widget.onCommit(next.round()),
        ),
      ],
    );
  }
}
