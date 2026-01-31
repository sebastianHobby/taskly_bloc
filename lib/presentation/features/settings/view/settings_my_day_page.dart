import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_domain/settings.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_bloc/presentation/shared/responsive/responsive.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class SettingsMyDayPage extends StatelessWidget {
  const SettingsMyDayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Day'),
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
                _MyDayShowTriageToggle(settings: settings),
                _MyDayDueWindowSlider(settings: settings),
                _MyDayShowPlannedToggle(settings: settings),
                _MyDayShowRoutinesToggle(settings: settings),
                _MyDayCountTriagePicksToggle(settings: settings),
                _MyDayCountRoutinePicksToggle(settings: settings),
                SizedBox(height: TasklyTokens.of(context).spaceSm),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MyDayShowTriageToggle extends StatelessWidget {
  const _MyDayShowTriageToggle({required this.settings});

  final GlobalSettings settings;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      title: const Text('Show triage'),
      subtitle: const Text('Include time-sensitive tasks due soon.'),
      value: settings.myDayDueSoonEnabled,
      onChanged: (enabled) {
        context.read<GlobalSettingsBloc>().add(
          GlobalSettingsEvent.myDayDueSoonEnabledChanged(enabled),
        );
      },
    );
  }
}

class _MyDayDueWindowSlider extends StatefulWidget {
  const _MyDayDueWindowSlider({required this.settings});

  final GlobalSettings settings;

  static const int _min = 1;
  static const int _max = 30;

  @override
  State<_MyDayDueWindowSlider> createState() => _MyDayDueWindowSliderState();
}

class _MyDayDueWindowSliderState extends State<_MyDayDueWindowSlider> {
  late int _draftDays = widget.settings.myDayDueWindowDays.clamp(
    _MyDayDueWindowSlider._min,
    _MyDayDueWindowSlider._max,
  );

  @override
  void didUpdateWidget(covariant _MyDayDueWindowSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.settings.myDayDueWindowDays.clamp(
      _MyDayDueWindowSlider._min,
      _MyDayDueWindowSlider._max,
    );
    if (next != _draftDays) {
      _draftDays = next;
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = _draftDays;
    final enabled = widget.settings.myDayDueSoonEnabled;
    final helperText = enabled
        ? 'Include tasks due within the next $days days'
        : 'Enable "Show triage" to include deadline-based tasks.';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        TasklyTokens.of(context).spaceLg,
        TasklyTokens.of(context).spaceSm,
        TasklyTokens.of(context).spaceLg,
        0,
      ),
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
            min: _MyDayDueWindowSlider._min.toDouble(),
            max: _MyDayDueWindowSlider._max.toDouble(),
            divisions: _MyDayDueWindowSlider._max - _MyDayDueWindowSlider._min,
            label: '$days days',
            onChanged: enabled
                ? (value) => setState(() {
                    _draftDays = value.round();
                  })
                : null,
            onChangeEnd: enabled
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

class _MyDayShowPlannedToggle extends StatelessWidget {
  const _MyDayShowPlannedToggle({required this.settings});

  final GlobalSettings settings;

  @override
  Widget build(BuildContext context) {
    final enabled = settings.myDayDueSoonEnabled;
    return SwitchListTile.adaptive(
      title: const Text('Show planned'),
      subtitle: const Text('Tasks with a planned date of today or earlier.'),
      value: settings.myDayShowAvailableToStart,
      onChanged: enabled
          ? (value) {
              context.read<GlobalSettingsBloc>().add(
                GlobalSettingsEvent.myDayShowAvailableToStartChanged(value),
              );
            }
          : null,
    );
  }
}

class _MyDayShowRoutinesToggle extends StatelessWidget {
  const _MyDayShowRoutinesToggle({required this.settings});

  final GlobalSettings settings;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      title: const Text('Show routines'),
      subtitle: const Text('Include routines as a guided step.'),
      value: settings.myDayShowRoutines,
      onChanged: (enabled) {
        context.read<GlobalSettingsBloc>().add(
          GlobalSettingsEvent.myDayShowRoutinesChanged(enabled),
        );
      },
    );
  }
}

class _MyDayCountTriagePicksToggle extends StatelessWidget {
  const _MyDayCountTriagePicksToggle({required this.settings});

  final GlobalSettings settings;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      title: const Text('Count triage picks'),
      subtitle: const Text('Reduce value suggestions based on triage picks.'),
      value: settings.myDayCountTriagePicksAgainstValueQuotas,
      onChanged: (enabled) {
        context.read<GlobalSettingsBloc>().add(
          GlobalSettingsEvent.myDayCountTriagePicksAgainstValueQuotasChanged(
            enabled,
          ),
        );
      },
    );
  }
}

class _MyDayCountRoutinePicksToggle extends StatelessWidget {
  const _MyDayCountRoutinePicksToggle({required this.settings});

  final GlobalSettings settings;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      title: const Text('Count routine picks'),
      subtitle: const Text('Reduce value suggestions based on routines.'),
      value: settings.myDayCountRoutinePicksAgainstValueQuotas,
      onChanged: (enabled) {
        context.read<GlobalSettingsBloc>().add(
          GlobalSettingsEvent.myDayCountRoutinePicksAgainstValueQuotasChanged(
            enabled,
          ),
        );
      },
    );
  }
}
