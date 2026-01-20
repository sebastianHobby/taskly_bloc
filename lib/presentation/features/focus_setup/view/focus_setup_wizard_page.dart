import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/features/attention/view/attention_rules_settings_page.dart';
import 'package:taskly_bloc/presentation/features/focus_setup/bloc/focus_setup_bloc.dart';
import 'package:taskly_bloc/presentation/screens/widgets/focus_mode_card.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/shared/app_bar/taskly_app_bar_actions.dart';
import 'package:taskly_bloc/presentation/shared/responsive/responsive.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_bloc/presentation/widgets/icon_picker/icon_catalog.dart';

class FocusSetupWizardPage extends StatelessWidget {
  const FocusSetupWizardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<FocusSetupBloc, FocusSetupState>(
      listenWhen: (prev, next) =>
          prev.saveSucceeded != next.saveSucceeded ||
          prev.errorMessage != next.errorMessage,
      listener: (context, state) {
        final message = state.errorMessage;
        if (message != null && message.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }

        if (!state.saveSucceeded) return;

        final router = GoRouter.of(context);
        if (router.canPop()) {
          router.pop();
        } else {
          router.go(Routing.screenPath('my_day'));
        }
      },
      child: BlocBuilder<FocusSetupBloc, FocusSetupState>(
        builder: (context, state) {
          final theme = Theme.of(context);
          final title = _titleForStep(state.currentStep);

          return Scaffold(
            appBar: AppBar(
              title: Text(title),
              actions: TasklyAppBarActions.withAttentionBell(
                context,
                actions: const <Widget>[],
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(36),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: state.maxStepIndex == 0
                              ? 1
                              : (state.stepIndex / state.maxStepIndex).clamp(
                                  0,
                                  1,
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${state.stepIndex + 1}/${state.maxStepIndex + 1}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            body: SafeArea(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _StepBody(
                  key: ValueKey(state.currentStep),
                  state: state,
                ),
              ),
            ),
            bottomNavigationBar: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  children: [
                    if (state.canGoBack)
                      OutlinedButton(
                        onPressed: () => context.read<FocusSetupBloc>().add(
                          const FocusSetupEvent.backPressed(),
                        ),
                        child: const Text('Back'),
                      )
                    else
                      const SizedBox.shrink(),
                    const Spacer(),
                    FilledButton(
                      onPressed: _primaryActionEnabled(state)
                          ? () => _primaryAction(context, state)
                          : null,
                      child: state.isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Text(_primaryLabel(state)),
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

  static String _titleForStep(FocusSetupWizardStep step) {
    return switch (step) {
      FocusSetupWizardStep.selectFocusMode => 'Focus mode',
      FocusSetupWizardStep.allocationStrategy => 'Tune Focus',
      FocusSetupWizardStep.valuesCta => 'Your values',
      FocusSetupWizardStep.finalize => 'All set',
    };
  }

  static String _primaryLabel(FocusSetupState state) {
    if (state.currentStep == FocusSetupWizardStep.finalize) return 'Save';
    if (state.currentStep == FocusSetupWizardStep.valuesCta &&
        state.valuesCount == 0) {
      return 'Add a value to continue';
    }
    return 'Next';
  }

  static bool _primaryActionEnabled(FocusSetupState state) {
    if (state.isSaving) return false;
    if (state.currentStep == FocusSetupWizardStep.finalize) return true;
    return state.canGoNext;
  }

  static void _primaryAction(BuildContext context, FocusSetupState state) {
    final bloc = context.read<FocusSetupBloc>();
    if (state.currentStep == FocusSetupWizardStep.finalize) {
      bloc.add(const FocusSetupEvent.finalizePressed());
      return;
    }
    bloc.add(const FocusSetupEvent.nextPressed());
  }
}

class _StepBody extends StatelessWidget {
  const _StepBody({required this.state, super.key});

  final FocusSetupState state;

  @override
  Widget build(BuildContext context) {
    final body = switch (state.currentStep) {
      FocusSetupWizardStep.selectFocusMode => _FocusModeStep(state: state),
      FocusSetupWizardStep.allocationStrategy => _AllocationStep(state: state),
      FocusSetupWizardStep.valuesCta => _ValuesCtaStep(state: state),
      FocusSetupWizardStep.finalize => _FinalizeStep(state: state),
    };

    final applyConstraints = WindowSizeClass.of(context).isExpanded;

    if (!applyConstraints) {
      return body;
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: body,
      ),
    );
  }
}

class _FocusModeStep extends StatelessWidget {
  const _FocusModeStep({required this.state});

  final FocusSetupState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<FocusSetupBloc>();
    final theme = Theme.of(context);
    final selected = state.effectiveFocusMode;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Choose how you want Focus to make tradeoffs.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        _SafetyNetCard(
          onManagePressed: () => _openAttentionRulesOverlay(context),
        ),
        const SizedBox(height: 16),
        for (final mode in FocusMode.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FocusModeCard(
              focusMode: mode,
              isSelected: selected == mode,
              isRecommended: mode == FocusMode.sustainable,
              onTap: () => bloc.add(FocusSetupEvent.focusModeChanged(mode)),
            ),
          ),
      ],
    );
  }

  Future<void> _openAttentionRulesOverlay(BuildContext context) async {
    final width = MediaQuery.sizeOf(context).width;
    final content = AttentionRulesSettingsView(
      embedded: true,
      initialSection: AttentionRulesInitialSection.problemDetection,
    );

    if (width < 700) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) {
          final height = MediaQuery.sizeOf(context).height;
          return SizedBox(height: height * 0.85, child: content);
        },
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 760,
              maxHeight: 760,
            ),
            child: content,
          ),
        );
      },
    );
  }
}

class _SafetyNetCard extends StatelessWidget {
  const _SafetyNetCard({required this.onManagePressed});

  final VoidCallback onManagePressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Safety net alerts',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onManagePressed,
                  child: const Text('Manage'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Even if you pick a values-first mode, Taskly can still warn you '
              'about urgent deadlines or big gaps. Alerts are optional and '
              'fully configurable.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
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
    final influencePercent = state.effectiveNeglectInfluencePercent;

    final valuePriorityPercent = state.effectiveValuePriorityWeightPercent;
    final taskFlagBoost = state.effectiveTaskFlagBoost;
    final overdueEmergencyMultiplier =
        state.effectiveOverdueEmergencyMultiplier;

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
                        'Tune your preferences',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => bloc.add(
                        const FocusSetupEvent.allocationResetToDefaultPressed(),
                      ),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'These settings only affect how your Focus list is ranked '
                  'and filtered.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                Text('Urgency boost', style: theme.textTheme.titleSmall),
                const SizedBox(height: 6),
                Text(
                  '${urgency.toStringAsFixed(1)}x',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                Slider(
                  value: urgency.clamp(0.5, 5.0),
                  min: 0.5,
                  max: 5,
                  divisions: 18,
                  onChanged: (v) => bloc.add(
                    FocusSetupEvent.urgencyBoostChanged(
                      (v * 2).roundToDouble() / 2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Value priority weight',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  '$valuePriorityPercent%',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                Slider(
                  value: valuePriorityPercent.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 20,
                  onChanged: (v) => bloc.add(
                    FocusSetupEvent.valuePriorityWeightPercentChanged(
                      v.round(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Task flag boost',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  '${taskFlagBoost.toStringAsFixed(1)}x',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                Slider(
                  value: taskFlagBoost.clamp(0.5, 5.0),
                  min: 0.5,
                  max: 5,
                  divisions: 18,
                  onChanged: (v) => bloc.add(
                    FocusSetupEvent.taskFlagBoostChanged(
                      (v * 2).roundToDouble() / 2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Overdue emergency boost',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  '${overdueEmergencyMultiplier.toStringAsFixed(1)}x',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
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
                const SizedBox(height: 20),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: neglectEnabled,
                  onChanged: (v) => bloc.add(
                    FocusSetupEvent.neglectEnabledChanged(v),
                  ),
                  title: const Text('Boost neglected values'),
                  subtitle: Text(
                    'If you have been ignoring a value lately, give it a '
                    'small lift.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (neglectEnabled) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Lookback window',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$lookback days',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Slider(
                    value: lookback.toDouble(),
                    min: 1,
                    max: 60,
                    divisions: 59,
                    onChanged: (v) => bloc.add(
                      FocusSetupEvent.neglectLookbackDaysChanged(v.round()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Neglect influence',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$influencePercent%',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Slider(
                    value: influencePercent.toDouble().clamp(0, 100),
                    min: 0,
                    max: 100,
                    divisions: 20,
                    onChanged: (v) => bloc.add(
                      FocusSetupEvent.neglectInfluencePercentChanged(v.round()),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ValuesCtaStep extends StatefulWidget {
  const _ValuesCtaStep({required this.state});

  final FocusSetupState state;

  @override
  State<_ValuesCtaStep> createState() => _ValuesCtaStepState();
}

class _ValuesCtaStepState extends State<_ValuesCtaStep> {
  final _controller = TextEditingController();

  static const _palette = <String>[
    '#6366F1',
    '#0EA5E9',
    '#10B981',
    '#F59E0B',
    '#EF4444',
    '#8B5CF6',
    '#14B8A6',
    '#22C55E',
    '#E11D48',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valuesCount = widget.state.valuesCount;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Focus works best when you define what matters to you.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add at least one value (Health, Family, Craft, Learning…) '
                  'so values-first modes can make smart tradeoffs.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.favorite_outline,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'You have $valuesCount value${valuesCount == 1 ? '' : 's'}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Quick add a value',
                    hintText: 'e.g. Health',
                  ),
                  onSubmitted: (text) => _submitQuickAdd(context, text),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () => _openCustomValueEditor(context),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Create a custom value'),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final suggestion in _quickAddSuggestions)
                      _ValueSuggestionChip(
                        suggestion: suggestion,
                        onPressed: () =>
                            _submitQuickAdd(context, suggestion.name),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => context.push('/values'),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open Values'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitQuickAdd(BuildContext context, String raw) async {
    final name = raw.trim();
    if (name.isEmpty) return;

    context.read<FocusSetupBloc>().add(
      FocusSetupEvent.quickAddValueRequested(name),
    );
    _controller.clear();
  }

  Future<void> _openCustomValueEditor(BuildContext context) async {
    final name = _controller.text.trim();
    final launcher = EditorLauncher.fromGetIt();
    await launcher.openValueEditor(
      context,
      initialDraft: ValueDraft(
        name: name,
        color: _colorHexForName(name.isEmpty ? 'Custom' : name),
        priority: ValuePriority.medium,
        iconName: null,
      ),
      showDragHandle: true,
    );
    _controller.clear();
  }

  String _colorHexForName(String name) {
    final hash = name.toLowerCase().codeUnits.fold<int>(
      0,
      (a, b) => (a * 31 + b) & 0x7fffffff,
    );
    return _palette[hash % _palette.length];
  }
}

class _ValueSuggestion {
  const _ValueSuggestion({
    required this.name,
    required this.colorHex,
    required this.iconName,
  });

  final String name;
  final String colorHex;
  final String iconName;
}

const _quickAddSuggestions = <_ValueSuggestion>[
  _ValueSuggestion(name: 'Health', colorHex: '#43A047', iconName: 'health'),
  _ValueSuggestion(name: 'Family', colorHex: '#FB8C00', iconName: 'home'),
  _ValueSuggestion(name: 'Career', colorHex: '#1E88E5', iconName: 'work'),
  _ValueSuggestion(
    name: 'Learning',
    colorHex: '#7E57C2',
    iconName: 'lightbulb',
  ),
  _ValueSuggestion(
    name: 'Relationships',
    colorHex: '#E91E63',
    iconName: 'group',
  ),
];

class _ValueSuggestionChip extends StatelessWidget {
  const _ValueSuggestionChip({
    required this.suggestion,
    required this.onPressed,
  });

  final _ValueSuggestion suggestion;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = ColorUtils.fromHexWithThemeFallback(
      context,
      suggestion.colorHex,
    );
    final iconData = getIconDataFromName(suggestion.iconName) ?? Icons.star;

    return InputChip(
      avatar: CircleAvatar(
        backgroundColor: color,
        child: Icon(
          iconData,
          size: 16,
          color: theme.colorScheme.onPrimary,
        ),
      ),
      label: Text(suggestion.name),
      onPressed: onPressed,
    );
  }
}

class _FinalizeStep extends StatelessWidget {
  const _FinalizeStep({required this.state});

  final FocusSetupState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mode = state.effectiveFocusMode;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ready to use Focus.',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You can change this anytime in settings.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.center_focus_strong,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Focus mode: ${mode.displayName}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.favorite_outline,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Values: ${state.valuesCount}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
