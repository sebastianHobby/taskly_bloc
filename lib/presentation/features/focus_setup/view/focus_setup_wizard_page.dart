import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/domain/allocation/model/allocation_config.dart';
import 'package:taskly_bloc/domain/allocation/model/focus_mode.dart';
import 'package:taskly_bloc/domain/allocation/engine/allocation_snapshot_coordinator.dart';
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
          // Ask the centralized coordinator to generate/refresh today's
          // allocation snapshot immediately after saving.
          getIt<AllocationSnapshotCoordinator>().requestRefreshNow(
            AllocationSnapshotRefreshReason.focusSetupSaved,
          );

          final router = GoRouter.of(context);
          if (router.canPop()) {
            router.pop();
          } else {
            router.go(Routing.screenPath('my_day'));
          }
        }
      },
      child: BlocBuilder<FocusSetupBloc, FocusSetupState>(
        builder: (context, state) {
          final theme = Theme.of(context);
          final title = switch (state.currentStep) {
            FocusSetupWizardStep.selectFocusMode => 'Select Focus Mode',
            FocusSetupWizardStep.allocationStrategy => 'Allocation Strategy',
            FocusSetupWizardStep.reviewSchedule => 'Review Schedule',
            FocusSetupWizardStep.finalize => 'Finalize Settings',
          };

          return Scaffold(
            appBar: AppBar(
              title: Text(title),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (state.canGoBack) {
                    context.read<FocusSetupBloc>().add(
                      const FocusSetupEvent.backPressed(),
                    );
                    return;
                  }

                  final router = GoRouter.of(context);
                  if (router.canPop()) {
                    router.pop();
                  } else {
                    router.go(Routing.screenPath('my_day'));
                  }
                },
              ),
              actions: [
                if (state.stepIndex != 0 &&
                    state.stepIndex < state.maxStepIndex)
                  TextButton(
                    onPressed: state.canGoNext
                        ? () => context.read<FocusSetupBloc>().add(
                            const FocusSetupEvent.nextPressed(),
                          )
                        : null,
                    child: const Text('Next'),
                  )
                else if (state.stepIndex == state.maxStepIndex)
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
                          if (state.stepIndex == 0)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                12,
                                16,
                                16,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    theme.scaffoldBackgroundColor.withOpacity(
                                      0,
                                    ),
                                    theme.scaffoldBackgroundColor.withOpacity(
                                      0.9,
                                    ),
                                    theme.scaffoldBackgroundColor,
                                  ],
                                ),
                              ),
                              child: SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(56),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: state.canGoNext
                                      ? () => context.read<FocusSetupBloc>().add(
                                          const FocusSetupEvent.nextPressed(),
                                        )
                                      : null,
                                  child: const Text('Confirm Selection'),
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
    return switch (state.currentStep) {
      FocusSetupWizardStep.selectFocusMode => _FocusModeStep(state: state),
      FocusSetupWizardStep.allocationStrategy => _AllocationStep(state: state),
      FocusSetupWizardStep.reviewSchedule => _ReviewScheduleStep(state: state),
      FocusSetupWizardStep.finalize => _FinalizeStep(state: state),
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
        const SizedBox(height: 24),
        ...FocusMode.values.map(
          (mode) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: FocusModeCard(
              focusMode: mode,
              isSelected: mode == state.effectiveFocusMode,
              isRecommended: mode == FocusMode.sustainable,
              onTap: () => bloc.add(FocusSetupEvent.focusModeChanged(mode)),
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

    final valuePriorityPercent = state.effectiveValuePriorityWeightPercent;
    final taskFlagBoost = state.effectiveTaskFlagBoost;
    final recencyPenaltyPercent = state.effectiveRecencyPenaltyPercent;
    final overdueEmergencyMultiplier =
        state.effectiveOverdueEmergencyMultiplier;

    final preset = StrategySettings.forFocusMode(state.effectiveFocusMode);
    final presetInfluencePercent = (preset.neglectInfluence * 100)
        .round()
        .clamp(0, 100);

    final presetValuePriorityPercent = (preset.valuePriorityWeight * 50)
        .round()
        .clamp(0, 100);
    final presetRecencyPenaltyPercent = (preset.recencyPenalty * 100)
        .round()
        .clamp(0, 50);

    final isModifiedFromPreset =
        urgency != preset.urgencyBoostMultiplier ||
        neglectEnabled != preset.enableNeglectWeighting ||
        lookback != preset.neglectLookbackDays ||
        influence != presetInfluencePercent ||
        valuePriorityPercent != presetValuePriorityPercent ||
        taskFlagBoost != preset.taskPriorityBoost ||
        recencyPenaltyPercent != presetRecencyPenaltyPercent ||
        overdueEmergencyMultiplier != preset.overdueEmergencyMultiplier;

    final persisted = state.persistedAllocationConfig?.strategySettings;
    final isUnsaved =
        persisted != null &&
        ((state.draftUrgencyBoostMultiplier != null &&
                state.draftUrgencyBoostMultiplier !=
                    persisted.urgencyBoostMultiplier) ||
            (state.draftNeglectEnabled != null &&
                state.draftNeglectEnabled !=
                    persisted.enableNeglectWeighting) ||
            (state.draftNeglectLookbackDays != null &&
                state.draftNeglectLookbackDays !=
                    persisted.neglectLookbackDays) ||
            (state.draftNeglectInfluencePercent != null &&
                state.draftNeglectInfluencePercent !=
                    (persisted.neglectInfluence * 100).round().clamp(0, 100)) ||
            (state.draftValuePriorityWeightPercent != null &&
                state.draftValuePriorityWeightPercent !=
                    (persisted.valuePriorityWeight * 50).round().clamp(
                      0,
                      100,
                    )) ||
            (state.draftTaskFlagBoost != null &&
                state.draftTaskFlagBoost != persisted.taskPriorityBoost) ||
            (state.draftRecencyPenaltyPercent != null &&
                state.draftRecencyPenaltyPercent !=
                    (persisted.recencyPenalty * 100).round().clamp(0, 50)) ||
            (state.draftOverdueEmergencyMultiplier != null &&
                state.draftOverdueEmergencyMultiplier !=
                    persisted.overdueEmergencyMultiplier));

    final presetName = switch (state.effectiveFocusMode) {
      FocusMode.sustainable => 'Standard Balanced',
      _ => state.effectiveFocusMode.displayName,
    };
    final deviationName = switch (state.effectiveFocusMode) {
      FocusMode.sustainable => 'Balanced',
      _ => state.effectiveFocusMode.displayName,
    };
    final headerPresetText = isModifiedFromPreset
        ? 'Custom (Modified)'
        : presetName;

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
                    Icon(Icons.tune, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Preset: $headerPresetText',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (isUnsaved)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'UNSAVED',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onTertiaryContainer,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isModifiedFromPreset
                      ? 'You have deviated from the $deviationName preset.'
                      : 'Using the $presetName preset.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isModifiedFromPreset
                        ? () => bloc.add(
                            const FocusSetupEvent.allocationResetToDefaultPressed(),
                          )
                        : null,
                    child: const Text('Reset to Default'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
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
                  'Increases priority score exponentially as due date approaches.',
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
                          const Text("Days until 'Neglected'"),
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
                          const Text('Neglect Multiplier'),
                          Text(
                            '${(1 + (influence / 100)).toStringAsFixed(1)}x',
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
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.tune, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Fine Tuning', style: theme.textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Value Priority Weight'),
                    Text(
                      _valuePriorityChipText(valuePriorityPercent),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: valuePriorityPercent.toDouble().clamp(0, 100),
                  min: 0,
                  max: 100,
                  divisions: 100,
                  onChanged: (v) => bloc.add(
                    FocusSetupEvent.valuePriorityWeightPercentChanged(
                      v.round(),
                    ),
                  ),
                ),

                const Divider(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Task Flag Boost'),
                    Text(
                      '${taskFlagBoost.toStringAsFixed(1)}x',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      '0.5x',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        value: taskFlagBoost.clamp(0.5, 5.0),
                        min: 0.5,
                        max: 5,
                        divisions: 9,
                        onChanged: (v) => bloc.add(
                          FocusSetupEvent.taskFlagBoostChanged(
                            (v * 2).roundToDouble() / 2,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      '5x',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

                const Divider(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Recency Penalty'),
                    Text(
                      '-$recencyPenaltyPercent%',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Avoids "shiny object syndrome" by lowering score of new tasks.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Slider(
                  value: recencyPenaltyPercent.toDouble().clamp(0, 50),
                  min: 0,
                  max: 50,
                  divisions: 50,
                  onChanged: (v) => bloc.add(
                    FocusSetupEvent.recencyPenaltyPercentChanged(v.round()),
                  ),
                ),

                const Divider(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Overdue Emergency Multiplier'),
                    Text(
                      '${overdueEmergencyMultiplier.toStringAsFixed(1)}x',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: overdueEmergencyMultiplier.clamp(1.0, 5.0),
                  min: 1,
                  max: 5,
                  divisions: 8,
                  onChanged: (v) => bloc.add(
                    FocusSetupEvent.overdueEmergencyMultiplierChanged(
                      (v * 2).roundToDouble() / 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _valuePriorityChipText(int percent) {
    final p = percent.clamp(0, 100);
    final label = switch (p) {
      <= 33 => 'Low',
      <= 66 => 'Medium',
      _ => 'High',
    };
    return '$label ($p%)';
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

    final presetLabel = switch (state.effectiveFocusMode) {
      FocusMode.sustainable => 'STANDARD BALANCED',
      _ => state.effectiveFocusMode.displayName.toUpperCase(),
    };

    final projectHealthRules = state.reviewSessionRules
        .where((r) => r.ruleKey.startsWith('review_project_'))
        .toList(growable: false);
    final periodicRules = state.reviewSessionRules
        .where((r) => !r.ruleKey.startsWith('review_project_'))
        .toList(growable: false);

    final content = <Widget>[
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'PRESET: $presetLabel',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Text(
        'Define how often Taskly prompts you to reflect.',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Consistent reviews help you catch stalled projects and realign with '
        'your values before they drift too far.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          height: 1.35,
        ),
      ),
      const SizedBox(height: 20),
    ];

    if (projectHealthRules.isNotEmpty) {
      content
        ..add(
          Text(
            'Rule #3: Project Health',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        )
        ..add(const SizedBox(height: 10))
        ..add(
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < projectHealthRules.length; i++) ...[
                  _ReviewRuleRow(
                    ruleId: projectHealthRules[i].id,
                    ruleKey: projectHealthRules[i].ruleKey,
                    title:
                        (projectHealthRules[i].displayConfig['title']
                            as String?) ??
                        projectHealthRules[i].ruleKey,
                    enabled:
                        state.draftRuleEnabled[projectHealthRules[i].id] ??
                        projectHealthRules[i].active,
                    frequencyDays:
                        state.draftRuleFrequencyDays[projectHealthRules[i]
                            .id] ??
                        (projectHealthRules[i].triggerConfig['frequency_days']
                                as int? ??
                            30),
                    lastResolvedAt:
                        state.lastResolvedAt[projectHealthRules[i].id],
                    onEnabledChanged: (enabled) => bloc.add(
                      FocusSetupEvent.reviewRuleEnabledChanged(
                        ruleId: projectHealthRules[i].id,
                        enabled: enabled,
                      ),
                    ),
                    onFrequencyChanged: (days) => bloc.add(
                      FocusSetupEvent.reviewRuleFrequencyDaysChanged(
                        ruleId: projectHealthRules[i].id,
                        frequencyDays: days,
                      ),
                    ),
                  ),
                  if (i != projectHealthRules.length - 1)
                    Divider(
                      height: 1,
                      color: theme.dividerColor.withOpacity(0.6),
                    ),
                ],
              ],
            ),
          ),
        )
        ..add(const SizedBox(height: 24));
    }

    if (periodicRules.isNotEmpty) {
      content
        ..add(
          Text(
            'Periodic Review Schedule',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        )
        ..add(const SizedBox(height: 10))
        ..add(
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < periodicRules.length; i++) ...[
                  _ReviewRuleRow(
                    ruleId: periodicRules[i].id,
                    ruleKey: periodicRules[i].ruleKey,
                    title:
                        (periodicRules[i].displayConfig['title'] as String?) ??
                        periodicRules[i].ruleKey,
                    enabled:
                        state.draftRuleEnabled[periodicRules[i].id] ??
                        periodicRules[i].active,
                    frequencyDays:
                        state.draftRuleFrequencyDays[periodicRules[i].id] ??
                        (periodicRules[i].triggerConfig['frequency_days']
                                as int? ??
                            30),
                    lastResolvedAt: state.lastResolvedAt[periodicRules[i].id],
                    onEnabledChanged: (enabled) => bloc.add(
                      FocusSetupEvent.reviewRuleEnabledChanged(
                        ruleId: periodicRules[i].id,
                        enabled: enabled,
                      ),
                    ),
                    onFrequencyChanged: (days) => bloc.add(
                      FocusSetupEvent.reviewRuleFrequencyDaysChanged(
                        ruleId: periodicRules[i].id,
                        frequencyDays: days,
                      ),
                    ),
                  ),
                  if (i != periodicRules.length - 1)
                    Divider(
                      height: 1,
                      color: theme.dividerColor.withOpacity(0.6),
                    ),
                ],
              ],
            ),
          ),
        );
    }

    content
      ..add(const SizedBox(height: 16))
      ..add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'Frequency adjustments apply to future prompts. You can always run '
            'a manual review from the "My Focus" tab.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.75),
              height: 1.35,
            ),
          ),
        ),
      )
      ..add(const SizedBox(height: 12));

    return ListView(padding: const EdgeInsets.all(16), children: content);
  }
}

class _ReviewRuleRow extends StatelessWidget {
  const _ReviewRuleRow({
    required this.ruleId,
    required this.ruleKey,
    required this.title,
    required this.enabled,
    required this.frequencyDays,
    required this.lastResolvedAt,
    required this.onEnabledChanged,
    required this.onFrequencyChanged,
  });

  final String ruleId;
  final String ruleKey;
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

    final visual = _visualForRule(ruleKey: ruleKey, theme: theme);
    final tileBg = visual.backgroundColor;
    final iconColor = visual.foregroundColor;

    final rowOpacity = enabled ? 1.0 : 0.7;
    final titleStyle = theme.textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w600,
      color: enabled
          ? theme.colorScheme.onSurface
          : theme.colorScheme.onSurface,
    );
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );

    return Opacity(
      opacity: rowOpacity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tileBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(visual.icon, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: titleStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Last: $lastText',
                    style: subtitleStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _FrequencyControl(
              enabled: enabled,
              valueDays: frequencyDays,
              onChanged: onFrequencyChanged,
            ),
            const SizedBox(width: 10),
            Switch(value: enabled, onChanged: onEnabledChanged),
          ],
        ),
      ),
    );
  }

  String _formatLast(DateTime? dt) {
    if (dt == null) return 'Never';
    final local = dt.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 4) return '${diff.inDays} days ago';
    if (diff.inDays < 7) return DateFormat.EEEE().format(local);

    const monthAbbrev = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sept',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = monthAbbrev[local.month - 1];
    final day = local.day.toString().padLeft(2, '0');
    return '$month $day';
  }

  _RuleVisual _visualForRule({
    required String ruleKey,
    required ThemeData theme,
  }) {
    final cs = theme.colorScheme;

    return switch (ruleKey) {
      'review_values_alignment' => _RuleVisual(
        icon: Icons.diamond_outlined,
        foregroundColor: cs.tertiary,
        backgroundColor: cs.tertiary.withOpacity(0.14),
      ),
      'review_progress' => _RuleVisual(
        icon: Icons.trending_up,
        foregroundColor: cs.secondary,
        backgroundColor: cs.secondary.withOpacity(0.14),
      ),
      'review_wellbeing' => _RuleVisual(
        icon: Icons.spa,
        foregroundColor: cs.primary,
        backgroundColor: cs.primary.withOpacity(0.14),
      ),
      'review_balance' => _RuleVisual(
        icon: Icons.balance,
        foregroundColor: cs.primary,
        backgroundColor: cs.primary.withOpacity(0.14),
      ),
      'review_pinned_tasks' => _RuleVisual(
        icon: Icons.push_pin,
        foregroundColor: cs.onSurfaceVariant,
        backgroundColor: cs.onSurfaceVariant.withOpacity(0.12),
      ),
      'review_project_no_allocated_recently' => _RuleVisual(
        icon: Icons.pending_actions,
        foregroundColor: cs.tertiary,
        backgroundColor: cs.tertiary.withOpacity(0.14),
      ),
      'review_project_high_value_neglected' => _RuleVisual(
        icon: Icons.star_outline,
        foregroundColor: cs.error,
        backgroundColor: cs.error.withOpacity(0.14),
      ),
      'review_project_no_allocatable_tasks' => _RuleVisual(
        icon: Icons.check_circle_outline,
        foregroundColor: cs.secondary,
        backgroundColor: cs.secondary.withOpacity(0.14),
      ),
      _ => _RuleVisual(
        icon: Icons.rate_review_outlined,
        foregroundColor: cs.onSurfaceVariant,
        backgroundColor: cs.onSurfaceVariant.withOpacity(0.12),
      ),
    };
  }
}

class _FrequencyControl extends StatelessWidget {
  const _FrequencyControl({
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
    final theme = Theme.of(context);
    final safeValue = _options.containsKey(valueDays) ? valueDays : 30;
    final label = _options[safeValue] ?? 'Monthly';

    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: enabled
          ? theme.colorScheme.primary
          : theme.colorScheme.onSurfaceVariant,
    );

    return PopupMenuButton<int>(
      enabled: enabled,
      initialValue: safeValue,
      onSelected: onChanged,
      itemBuilder: (context) => _options.entries
          .map(
            (e) => PopupMenuItem<int>(
              value: e.key,
              child: Text(e.value),
            ),
          )
          .toList(growable: false),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: textStyle),
          Icon(
            Icons.expand_more,
            size: 18,
            color: enabled
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _RuleVisual {
  const _RuleVisual({
    required this.icon,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  final IconData icon;
  final Color foregroundColor;
  final Color backgroundColor;
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
