import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/domain/models/settings/focus_mode.dart';
import 'package:taskly_bloc/presentation/features/focus_setup/bloc/focus_setup_bloc.dart';
import 'package:taskly_bloc/presentation/features/next_action/widgets/focus_mode_card.dart';
import 'package:taskly_bloc/presentation/widgets/content_constraint.dart';

class FocusSetupWizardPage extends StatelessWidget {
  const FocusSetupWizardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<FocusSetupBloc, FocusSetupState>(
      listenWhen: (prev, next) => prev.saveSucceeded != next.saveSucceeded,
      listener: (context, state) {
        if (state.saveSucceeded) {
          Navigator.of(context).pop();
        }
      },
      child: BlocBuilder<FocusSetupBloc, FocusSetupState>(
        builder: (context, state) {
          final theme = Theme.of(context);
          final title = switch (state.stepIndex) {
            0 => 'Select Focus Mode',
            1 => 'Allocation Strategy',
            2 => 'Review Schedule',
            _ => 'Finalize Settings',
          };

          return Scaffold(
            appBar: AppBar(
              title: Text(title),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: state.canGoBack
                    ? () => context.read<FocusSetupBloc>().add(
                        const FocusSetupEvent.backPressed(),
                      )
                    : null,
              ),
              actions: [
                if (state.stepIndex < state.maxStepIndex)
                  TextButton(
                    onPressed: state.canGoNext
                        ? () => context.read<FocusSetupBloc>().add(
                            const FocusSetupEvent.nextPressed(),
                          )
                        : null,
                    child: const Text('Next'),
                  )
                else
                  TextButton(
                    onPressed: state.isSaving
                        ? null
                        : () => context.read<FocusSetupBloc>().add(
                            const FocusSetupEvent.finalizePressed(),
                          ),
                    child: const Text('Save'),
                  ),
              ],
            ),
            body: SafeArea(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ResponsiveBody(
                      child: Column(
                        children: [
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: _StepBody(
                                key: ValueKey(state.stepIndex),
                                state: state,
                              ),
                            ),
                          ),
                          if (state.errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Text(
                                state.errorMessage!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ),
                          if (state.stepIndex == state.maxStepIndex)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: state.isSaving
                                      ? null
                                      : () => context.read<FocusSetupBloc>().add(
                                          const FocusSetupEvent.finalizePressed(),
                                        ),
                                  icon: state.isSaving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.check_circle),
                                  label: const Text('Finalize Settings'),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _StepBody extends StatelessWidget {
  const _StepBody({
    required this.state,
    super.key,
  });

  final FocusSetupState state;

  @override
  Widget build(BuildContext context) {
    return switch (state.stepIndex) {
      0 => _FocusModeStep(state: state),
      1 => _AllocationStep(state: state),
      2 => _ReviewScheduleStep(state: state),
      _ => _FinalizeStep(state: state),
    };
  }
}

class _FocusModeStep extends StatelessWidget {
  const _FocusModeStep({required this.state});

  final FocusSetupState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<FocusSetupBloc>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'How do you want to structure your day?',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        ...FocusMode.values.map(
          (mode) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              height: 140,
              child: FocusModeCard(
                focusMode: mode,
                isSelected: mode == state.effectiveFocusMode,
                isRecommended: mode == FocusMode.sustainable,
                onTap: () => bloc.add(FocusSetupEvent.focusModeChanged(mode)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AllocationStep extends StatelessWidget {
  const _AllocationStep({required this.state});

  final FocusSetupState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<FocusSetupBloc>();
    final theme = Theme.of(context);

    final urgency = state.effectiveUrgencyBoostMultiplier;
    final neglectEnabled = state.effectiveNeglectEnabled;
    final lookback = state.effectiveNeglectLookbackDays;
    final influence = state.effectiveNeglectInfluencePercent;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.timer, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Urgency', style: theme.textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Urgency Boost'),
                    Text(
                      '${urgency.toStringAsFixed(1)}x',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: urgency.clamp(1.0, 5.0),
                  min: 1,
                  max: 5,
                  divisions: 40,
                  onChanged: (v) => bloc.add(
                    FocusSetupEvent.urgencyBoostChanged(
                      (v * 10).roundToDouble() / 10,
                    ),
                  ),
                ),
                Text(
                  'Increases priority score as due date approaches.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Enable Neglect Prevention'),
                subtitle: const Text(
                  'Boost tasks that are constantly skipped.',
                ),
                value: neglectEnabled,
                onChanged: (v) =>
                    bloc.add(FocusSetupEvent.neglectEnabledChanged(v)),
              ),
              if (neglectEnabled) const Divider(height: 1),
              if (neglectEnabled)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Lookback Days'),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () => bloc.add(
                                  FocusSetupEvent.neglectLookbackDaysChanged(
                                    lookback - 1,
                                  ),
                                ),
                              ),
                              Text(
                                '$lookback',
                                style: theme.textTheme.titleMedium,
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => bloc.add(
                                  FocusSetupEvent.neglectLookbackDaysChanged(
                                    lookback + 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Neglect Influence'),
                          Text(
                            '$influence%',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: influence.toDouble(),
                        min: 0,
                        max: 100,
                        divisions: 100,
                        onChanged: (v) => bloc.add(
                          FocusSetupEvent.neglectInfluencePercentChanged(
                            v.round(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewScheduleStep extends StatelessWidget {
  const _ReviewScheduleStep({required this.state});

  final FocusSetupState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<FocusSetupBloc>();
    final theme = Theme.of(context);

    if (state.reviewSessionRules.isEmpty) {
      return const Center(child: Text('No review rules available.'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Define how often Taskly prompts you to reflect.',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Frequency adjustments apply to future prompts.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              for (final rule in state.reviewSessionRules)
                _ReviewRuleRow(
                  ruleId: rule.id,
                  title:
                      (rule.displayConfig['title'] as String?) ?? rule.ruleKey,
                  enabled: state.draftRuleEnabled[rule.id] ?? rule.active,
                  frequencyDays:
                      state.draftRuleFrequencyDays[rule.id] ??
                      (rule.triggerConfig['frequency_days'] as int? ?? 30),
                  lastResolvedAt: state.lastResolvedAt[rule.id],
                  onEnabledChanged: (enabled) => bloc.add(
                    FocusSetupEvent.reviewRuleEnabledChanged(
                      ruleId: rule.id,
                      enabled: enabled,
                    ),
                  ),
                  onFrequencyChanged: (days) => bloc.add(
                    FocusSetupEvent.reviewRuleFrequencyDaysChanged(
                      ruleId: rule.id,
                      frequencyDays: days,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewRuleRow extends StatelessWidget {
  const _ReviewRuleRow({
    required this.ruleId,
    required this.title,
    required this.enabled,
    required this.frequencyDays,
    required this.lastResolvedAt,
    required this.onEnabledChanged,
    required this.onFrequencyChanged,
  });

  final String ruleId;
  final String title;
  final bool enabled;
  final int frequencyDays;
  final DateTime? lastResolvedAt;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<int> onFrequencyChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lastText = _formatLast(lastResolvedAt);

    return ListTile(
      title: Text(title),
      subtitle: Text('Last: $lastText'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FrequencyDropdown(
            enabled: enabled,
            valueDays: frequencyDays,
            onChanged: onFrequencyChanged,
          ),
          const SizedBox(width: 8),
          Switch(
            value: enabled,
            onChanged: onEnabledChanged,
          ),
        ],
      ),
      textColor: enabled ? null : theme.colorScheme.onSurfaceVariant,
    );
  }

  String _formatLast(DateTime? dt) {
    if (dt == null) return 'Never';
    final local = dt.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';

    return DateFormat.yMMMd().format(local);
  }
}

class _FrequencyDropdown extends StatelessWidget {
  const _FrequencyDropdown({
    required this.enabled,
    required this.valueDays,
    required this.onChanged,
  });

  final bool enabled;
  final int valueDays;
  final ValueChanged<int> onChanged;

  static const _options = <int, String>{
    1: 'Daily',
    7: 'Weekly',
    14: 'Bi-weekly',
    30: 'Monthly',
    90: 'Quarterly',
  };

  @override
  Widget build(BuildContext context) {
    final items = _options.entries
        .map(
          (e) => DropdownMenuItem<int>(
            value: e.key,
            child: Text(e.value),
          ),
        )
        .toList(growable: false);

    final safeValue = _options.containsKey(valueDays) ? valueDays : 30;

    return DropdownButton<int>(
      value: safeValue,
      onChanged: enabled ? (v) => v != null ? onChanged(v) : null : null,
      items: items,
    );
  }
}

class _FinalizeStep extends StatelessWidget {
  const _FinalizeStep({required this.state});

  final FocusSetupState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Review your settings before saving.',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            title: const Text('Focus Mode'),
            subtitle: Text(state.effectiveFocusMode.displayName),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            title: const Text('Urgency Boost'),
            subtitle: Text(
              '${state.effectiveUrgencyBoostMultiplier.toStringAsFixed(1)}x',
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            title: const Text('Neglect Prevention'),
            subtitle: Text(
              state.effectiveNeglectEnabled
                  ? 'On • ${state.effectiveNeglectLookbackDays}d lookback • ${state.effectiveNeglectInfluencePercent}% influence'
                  : 'Off',
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Review Schedule', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final rule in state.reviewSessionRules)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '• ${(rule.displayConfig['title'] as String?) ?? rule.ruleKey}: '
                      '${(state.draftRuleEnabled[rule.id] ?? rule.active) ? 'On' : 'Off'} '
                      '(${state.draftRuleFrequencyDays[rule.id] ?? (rule.triggerConfig['frequency_days'] as int? ?? 30)} days)',
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
