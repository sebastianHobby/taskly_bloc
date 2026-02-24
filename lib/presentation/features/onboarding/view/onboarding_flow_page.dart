import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/features/onboarding/bloc/onboarding_bloc.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_bloc/presentation/features/review/bloc/weekly_review_cubit.dart';
import 'package:taskly_bloc/presentation/features/review/widgets/weekly_value_checkin_sheet.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_bloc/presentation/shared/widgets/taskly_brand_logo.dart';
import 'package:taskly_bloc/presentation/widgets/icon_picker/icon_catalog.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/attention.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/settings.dart';
import 'package:taskly_ui/taskly_ui_forms.dart';
import 'package:taskly_ui/taskly_ui_icons.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class OnboardingFlowPage extends StatelessWidget {
  const OnboardingFlowPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OnboardingBloc(
        settingsRepository: context.read<SettingsRepositoryContract>(),
        valueRepository: context.read<ValueRepositoryContract>(),
        valueWriteService: context.read<ValueWriteService>(),
        errorReporter: context.read<AppErrorReporter>(),
      ),
      child: const _OnboardingFlowView(),
    );
  }
}

class _OnboardingFlowView extends StatefulWidget {
  const _OnboardingFlowView();

  @override
  State<_OnboardingFlowView> createState() => _OnboardingFlowViewState();
}

class _OnboardingFlowViewState extends State<_OnboardingFlowView> {
  late final PageController _pageController;
  late final WeeklyReviewBloc _weeklyReviewBloc;
  bool _ratingsRequested = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _weeklyReviewBloc = WeeklyReviewBloc(
      analyticsService: context.read<AnalyticsService>(),
      attentionEngine: context.read<AttentionEngineContract>(),
      valueRepository: context.read<ValueRepositoryContract>(),
      valueRatingsRepository: context.read<ValueRatingsRepositoryContract>(),
      valueRatingsWriteService: context.read<ValueRatingsWriteService>(),
      routineRepository: context.read<RoutineRepositoryContract>(),
      taskRepository: context.read<TaskRepositoryContract>(),
      nowService: context.read<NowService>(),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _weeklyReviewBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);

    return BlocProvider.value(
      value: _weeklyReviewBloc,
      child: Scaffold(
        body: SafeArea(
          child: BlocConsumer<OnboardingBloc, OnboardingState>(
            listenWhen: (prev, next) =>
                prev.effect != next.effect || prev.step != next.step,
            listener: (context, state) async {
              final effect = state.effect;
              if (effect is OnboardingErrorEffect) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(effect.message),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
                context.read<OnboardingBloc>().add(
                  const OnboardingEffectHandled(),
                );
              } else if (effect is OnboardingCompletedEffect) {
                context.read<OnboardingBloc>().add(
                  const OnboardingEffectHandled(),
                );
                context.read<GlobalSettingsBloc>().add(
                  const GlobalSettingsEvent.onboardingCompleted(),
                );
                Routing.toScreenKey(context, 'projects');
              }

              if (state.step == OnboardingStep.ratings) {
                if (!_ratingsRequested) {
                  _ratingsRequested = true;
                  _weeklyReviewBloc.add(
                    WeeklyReviewRequested(_onboardingReviewConfig()),
                  );
                }
              } else {
                _ratingsRequested = false;
              }

              final targetPage = state.step.index;
              if (_pageController.hasClients &&
                  _pageController.page?.round() != targetPage) {
                await _pageController.animateToPage(
                  targetPage,
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOut,
                );
              }
            },
            builder: (context, state) {
              final showFooter = state.step != OnboardingStep.ratings;
              final canGoBack = state.step != OnboardingStep.welcome;
              final primaryLabel = _primaryLabelFor(state);
              final isPrimaryBusy = state.isCreatingValue || state.isCompleting;

              return Column(
                children: [
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _WelcomeStep(tokens: tokens),
                        _ValuesStep(
                          selectedValues: state.selectedValues,
                          isBusy: state.isCreatingValue,
                        ),
                        _RatingsStep(
                          wizardStep: state.step.index + 1,
                          wizardTotal: OnboardingStep.values.length,
                          onBack: () => context.read<OnboardingBloc>().add(
                            const OnboardingBackRequested(),
                          ),
                          onComplete: () => context.read<OnboardingBloc>().add(
                            const OnboardingRatingsCompleted(),
                          ),
                        ),
                        const _ReviewSettingsStep(),
                      ],
                    ),
                  ),
                  if (showFooter)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        tokens.spaceLg,
                        tokens.spaceSm,
                        tokens.spaceLg,
                        tokens.spaceLg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            context.l10n.onboardingStepProgress(
                              state.step.index + 1,
                              OnboardingStep.values.length,
                            ),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          SizedBox(height: tokens.spaceSm),
                          FilledButton(
                            onPressed:
                                isPrimaryBusy || !_isPrimaryEnabled(state)
                                ? null
                                : () => context.read<OnboardingBloc>().add(
                                    const OnboardingNextRequested(),
                                  ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: tokens.spaceMd,
                              ),
                              child: isPrimaryBusy
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(primaryLabel),
                            ),
                          ),
                          if (state.step == OnboardingStep.valuesSetup &&
                              !state.hasMinimumValues) ...[
                            SizedBox(height: tokens.spaceXs),
                            Text(
                              context.l10n.onboardingValuesMinimumHint(
                                kOnboardingMinimumValuesRequired,
                              ),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                          if (canGoBack) ...[
                            SizedBox(height: tokens.spaceSm),
                            TextButton(
                              onPressed: () =>
                                  context.read<OnboardingBloc>().add(
                                    const OnboardingBackRequested(),
                                  ),
                              child: Text(context.l10n.backLabel),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  bool _isPrimaryEnabled(OnboardingState state) {
    return switch (state.step) {
      OnboardingStep.valuesSetup => state.hasMinimumValues,
      OnboardingStep.reviewSettings => true,
      OnboardingStep.welcome => true,
      OnboardingStep.ratings => false,
    };
  }

  String _primaryLabelFor(OnboardingState state) {
    final step = state.step;
    return switch (step) {
      OnboardingStep.welcome => context.l10n.onboardingGetStartedLabel,
      OnboardingStep.valuesSetup =>
        state.hasMinimumValues
            ? context.l10n.onboardingContinueLabel
            : context.l10n.onboardingContinueValuesRemaining(
                kOnboardingMinimumValuesRequired - state.selectedValues.length,
              ),
      OnboardingStep.reviewSettings => context.l10n.onboardingFinishLabel,
      OnboardingStep.ratings => context.l10n.onboardingContinueLabel,
    };
  }

  WeeklyReviewConfig _onboardingReviewConfig() {
    return WeeklyReviewConfig(
      checkInWindowWeeks: WeeklyReviewConfig.defaultCheckInWindowWeeks,
      maintenanceEnabled: false,
      showDeadlineRisk: false,
      showStaleItems: false,
      taskStaleThresholdDays:
          GlobalSettings.defaultMaintenanceTaskStaleThresholdDays,
      projectIdleThresholdDays:
          GlobalSettings.defaultMaintenanceProjectIdleThresholdDays,
      deadlineRiskDueWithinDays:
          GlobalSettings.defaultMaintenanceDeadlineRiskDueWithinDays,
      deadlineRiskMinUnscheduledCount:
          GlobalSettings.defaultMaintenanceDeadlineRiskMinUnscheduledCount,
      showFrequentSnoozed: false,
      showRoutineSupport: false,
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.tokens});

  final TasklyTokens tokens;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const TasklyBrandLogo(size: 84),
          SizedBox(height: tokens.spaceLg),
          Text(
            context.l10n.onboardingWelcomeTitle,
            style: theme.textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: tokens.spaceSm),
          Text(
            context.l10n.onboardingWelcomeSubtitle1,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: tokens.spaceSm),
          Text(
            context.l10n.onboardingWelcomeSubtitle2,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ValuesStep extends StatefulWidget {
  const _ValuesStep({
    required this.selectedValues,
    required this.isBusy,
  });

  final List<OnboardingValueSelection> selectedValues;
  final bool isBusy;

  @override
  State<_ValuesStep> createState() => _ValuesStepState();
}

class _ValuesStepState extends State<_ValuesStep> {
  static const int _maxValues = 8;

  final TextEditingController _nameController = TextEditingController();
  String? _selectedIconName;
  String _selectedColorId = ColorUtils.valueBlueId;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_clearNameError);
  }

  @override
  void dispose() {
    _nameController.removeListener(_clearNameError);
    _nameController.dispose();
    super.dispose();
  }

  void _clearNameError() {
    if (_nameError == null) return;
    setState(() => _nameError = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = TasklyTokens.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    final canAddMore = widget.selectedValues.length < _maxValues;
    final isInputEnabled = canAddMore && !widget.isBusy;
    final iconData = getIconDataFromName(_selectedIconName) ?? Icons.star;
    final color = ColorUtils.valueColorForTheme(context, _selectedColorId);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLg,
        tokens.spaceXl,
        tokens.spaceLg,
        tokens.spaceLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.onboardingValuesTitle,
            style: theme.textTheme.displaySmall,
          ),
          SizedBox(height: tokens.spaceSm),
          Text(
            l10n.onboardingValuesSubtitle,
            style: theme.textTheme.bodyLarge,
          ),
          SizedBox(height: tokens.spaceSm),
          Text(
            l10n.onboardingValuesHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: tokens.spaceLg),
          Text(
            l10n.onboardingValueQuickAddTitle,
            style: theme.textTheme.titleMedium,
          ),
          SizedBox(height: tokens.spaceSm),
          TextField(
            controller: _nameController,
            enabled: isInputEnabled,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: l10n.valueNameLabel,
              hintText: l10n.onboardingValueNameHint,
              border: const OutlineInputBorder(),
              errorText: _nameError,
            ),
          ),
          SizedBox(height: tokens.spaceSm),
          Row(
            children: [
              Expanded(
                child: _ValueQuickSelector(
                  label: l10n.onboardingValueIconLabel,
                  enabled: isInputEnabled,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: scheme.surfaceContainerHighest,
                    child: Icon(iconData, size: 18, color: scheme.onSurface),
                  ),
                  onTap: () => _openIconPicker(context),
                ),
              ),
              SizedBox(width: tokens.spaceSm),
              Expanded(
                child: _ValueQuickSelector(
                  label: l10n.onboardingValueColorLabel,
                  enabled: isInputEnabled,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: color,
                    child: Icon(Icons.palette, size: 16, color: scheme.surface),
                  ),
                  onTap: () => _openColorPicker(context),
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.spaceSm),
          FilledButton(
            onPressed: isInputEnabled ? _handleAddValue : null,
            child: Text(l10n.onboardingAddValueLabel),
          ),
          SizedBox(height: tokens.spaceXs),
          TextButton(
            onPressed: isInputEnabled ? () => _openIdeasSheet(context) : null,
            child: Text(l10n.onboardingValueIdeasLabel),
          ),
          SizedBox(height: tokens.spaceLg),
          Text(
            l10n.onboardingYourValuesTitle(
              widget.selectedValues.length,
              _maxValues,
            ),
            style: theme.textTheme.titleMedium,
          ),
          SizedBox(height: tokens.spaceSm),
          if (widget.selectedValues.isEmpty)
            Text(
              l10n.onboardingPickAtLeastOneValue,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          else
            Wrap(
              spacing: tokens.spaceSm,
              runSpacing: tokens.spaceSm,
              children: [
                for (final value in widget.selectedValues)
                  _ValueChip(
                    value: value,
                    onEdit: () => _openEditValue(context, value.id),
                    onRemove: () => context.read<OnboardingBloc>().add(
                      OnboardingValueRemoved(value.id),
                    ),
                  ),
              ],
            ),
          if (!canAddMore) ...[
            SizedBox(height: tokens.spaceSm),
            Text(
              l10n.onboardingValuesMaxHint(_maxValues),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openIconPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => _IconPickerSheet(
        selectedIconName: _selectedIconName,
      ),
    );
    if (!context.mounted) return;
    if (selected == null) return;
    setState(() => _selectedIconName = selected);
  }

  Future<void> _openColorPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => _ColorPickerSheet(
        selectedColorId: _selectedColorId,
      ),
    );
    if (!context.mounted) return;
    if (selected == null) return;
    setState(() => _selectedColorId = selected);
  }

  Future<void> _openIdeasSheet(BuildContext context) async {
    final selected = await showModalBottomSheet<ValueDraft>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => _IdeasSheet(
        templates: _ideaTemplates(context.l10n),
      ),
    );
    if (!context.mounted) return;
    if (selected == null) return;
    context.read<OnboardingBloc>().add(
      OnboardingCustomValueConfirmed(selected),
    );
  }

  void _handleAddValue() {
    final name = _nameController.text.trim();
    final l10n = context.l10n;
    if (name.isEmpty) {
      setState(() => _nameError = l10n.valueFormNameRequired);
      return;
    }
    if (name.length > ValueValidators.maxNameLength) {
      setState(
        () => _nameError = l10n.valueFormNameTooLong(
          ValueValidators.maxNameLength,
        ),
      );
      return;
    }

    setState(() => _nameError = null);
    context.read<OnboardingBloc>().add(
      OnboardingCustomValueConfirmed(
        ValueDraft(
          name: name,
          color: _selectedColorId,
          priority: ValuePriority.medium,
          iconName: _selectedIconName,
        ),
      ),
    );
    _nameController.clear();
  }

  List<_ValueIdeaTemplate> _ideaTemplates(AppLocalizations l10n) {
    return [
      _ValueIdeaTemplate(
        name: l10n.onboardingValueHealth,
        iconName: 'health',
        colorId: ColorUtils.valueGreenId,
      ),
      _ValueIdeaTemplate(
        name: l10n.onboardingValueRelationships,
        iconName: 'group',
        colorId: ColorUtils.valueRoseId,
      ),
      _ValueIdeaTemplate(
        name: l10n.onboardingValueCareer,
        iconName: 'work',
        colorId: ColorUtils.valueBlueId,
      ),
      _ValueIdeaTemplate(
        name: l10n.onboardingValueLearning,
        iconName: 'lightbulb',
        colorId: ColorUtils.valueVioletId,
      ),
      _ValueIdeaTemplate(
        name: l10n.onboardingValueHome,
        iconName: 'home',
        colorId: ColorUtils.valueSlateId,
      ),
      _ValueIdeaTemplate(
        name: l10n.onboardingValueAdventure,
        iconName: 'rocket',
        colorId: ColorUtils.valueAmberId,
      ),
    ];
  }

  Future<void> _openEditValue(BuildContext context, String valueId) async {
    await context.read<EditorLauncher>().openValueEditor(
      context,
      valueId: valueId,
      showDragHandle: true,
    );
    if (!context.mounted) return;
    context.read<OnboardingBloc>().add(
      OnboardingValueRefreshRequested(valueId),
    );
  }
}

class _ValueIdeaTemplate {
  const _ValueIdeaTemplate({
    required this.name,
    required this.iconName,
    required this.colorId,
  });

  final String name;
  final String iconName;
  final String colorId;
}

class _ValueQuickSelector extends StatelessWidget {
  const _ValueQuickSelector({
    required this.label,
    required this.child,
    required this.onTap,
    required this.enabled,
  });

  final String label;
  final Widget child;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(tokens.radiusLg),
      child: Container(
        padding: EdgeInsets.all(tokens.spaceSm),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(tokens.radiusLg),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            child,
            SizedBox(width: tokens.spaceSm),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: tokens.spaceMd,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _ValueChip extends StatelessWidget {
  const _ValueChip({
    required this.value,
    required this.onEdit,
    required this.onRemove,
  });

  final OnboardingValueSelection value;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final color = ColorUtils.valueColorForTheme(context, value.color);
    final iconData = getIconDataFromName(value.iconName) ?? Icons.star;
    final tokens = TasklyTokens.of(context);

    return InputChip(
      avatar: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.2),
        child: Icon(iconData, size: 16, color: color),
      ),
      label: Text(value.name),
      onPressed: onEdit,
      onDeleted: onRemove,
      deleteIcon: const Icon(Icons.close),
      side: BorderSide(
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceXs,
        vertical: tokens.spaceXxs,
      ),
    );
  }
}

class _IconPickerSheet extends StatelessWidget {
  const _IconPickerSheet({
    required this.selectedIconName,
  });

  final String? selectedIconName;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLg,
        tokens.spaceSm,
        tokens.spaceLg,
        tokens.spaceLg,
      ),
      child: TasklyFormIconSearchPicker(
        icons: tasklySymbolIcons,
        selectedIconName: selectedIconName,
        searchHintText: context.l10n.valueFormIconSearchHint,
        noIconsFoundLabel: context.l10n.valueFormIconNoResults,
        tooltipBuilder: formatIconLabel,
        onSelected: (iconName) => Navigator.of(context).pop(iconName),
      ),
    );
  }
}

class _ColorPickerSheet extends StatelessWidget {
  const _ColorPickerSheet({
    required this.selectedColorId,
  });

  final String selectedColorId;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final palette = ColorUtils.valuePaletteColorsFor(
      Theme.of(context).brightness,
    );
    final selectedColor = ColorUtils.valueColorForTheme(
      context,
      selectedColorId,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLg,
        tokens.spaceLg,
        tokens.spaceLg,
        tokens.spaceLg,
      ),
      child: TasklyFormColorPalettePicker(
        colors: palette,
        selectedColor: selectedColor,
        onSelected: (color) => Navigator.of(context).pop(
          ColorUtils.valuePaletteIdOrHex(color),
        ),
      ),
    );
  }
}

class _IdeasSheet extends StatelessWidget {
  const _IdeasSheet({
    required this.templates,
  });

  final List<_ValueIdeaTemplate> templates;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: templates
          .map(
            (template) => ListTile(
              leading: CircleAvatar(
                backgroundColor: ColorUtils.valueColorForTheme(
                  context,
                  template.colorId,
                ).withValues(alpha: 0.2),
                child: Icon(
                  getIconDataFromName(template.iconName) ?? Icons.star,
                  color: ColorUtils.valueColorForTheme(
                    context,
                    template.colorId,
                  ),
                ),
              ),
              title: Text(template.name),
              trailing: Icon(
                Icons.add,
                color: Theme.of(context).colorScheme.primary,
              ),
              onTap: () => Navigator.of(context).pop(
                ValueDraft(
                  name: template.name,
                  color: template.colorId,
                  priority: ValuePriority.medium,
                  iconName: template.iconName,
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _RatingsStep extends StatelessWidget {
  const _RatingsStep({
    required this.wizardStep,
    required this.wizardTotal,
    required this.onBack,
    required this.onComplete,
  });

  final int wizardStep;
  final int wizardTotal;
  final VoidCallback onBack;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return WeeklyValueCheckInContent(
      initialValueId: null,
      windowWeeks: WeeklyReviewConfig.defaultCheckInWindowWeeks,
      onExit: onBack,
      onComplete: onComplete,
      wizardStep: wizardStep,
      wizardTotal: wizardTotal,
      onWizardBack: onBack,
      showHistory: false,
      showActivityMix: false,
      showTopBar: false,
      useWizardFooter: true,
      introTitle: l10n.onboardingRatingsTitle,
      introBody: l10n.onboardingRatingsBody,
      promptTitleBuilder: (valueName, _) =>
          l10n.onboardingRatingsPrompt(valueName),
      promptSubtitleBuilder: (_, __) => '',
      scaleHint: l10n.onboardingRatingsScaleHint,
      nextActionLabel: l10n.onboardingRatingsSaveAction,
      completeActionLabel: l10n.onboardingRatingsSaveAction,
    );
  }
}

class _ReviewSettingsStep extends StatelessWidget {
  const _ReviewSettingsStep();

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    return BlocBuilder<GlobalSettingsBloc, GlobalSettingsState>(
      builder: (context, state) {
        final settings = state.settings;
        final cadence = settings.weeklyReviewCadenceWeeks.clamp(1, 2);

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            tokens.spaceLg,
            tokens.spaceXl,
            tokens.spaceLg,
            tokens.spaceLg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.onboardingReviewTitle,
                style: theme.textTheme.displaySmall,
              ),
              SizedBox(height: tokens.spaceSm),
              Text(
                l10n.onboardingReviewBody,
                style: theme.textTheme.bodyLarge,
              ),
              SizedBox(height: tokens.spaceLg),
              Text(
                l10n.onboardingReviewFrequencyLabel,
                style: theme.textTheme.titleMedium,
              ),
              SizedBox(height: tokens.spaceSm),
              SegmentedButton<int>(
                segments: [
                  ButtonSegment<int>(
                    value: 1,
                    label: Text(l10n.onboardingReviewWeeklyOption),
                  ),
                  ButtonSegment<int>(
                    value: 2,
                    label: Text(l10n.onboardingReviewBiweeklyOption),
                  ),
                ],
                selected: {cadence},
                onSelectionChanged: (selection) {
                  final next = selection.first;
                  context.read<GlobalSettingsBloc>().add(
                    GlobalSettingsEvent.weeklyReviewCadenceWeeksChanged(next),
                  );
                },
              ),
              SizedBox(height: tokens.spaceXs),
              Text(
                l10n.onboardingReviewFrequencyHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: tokens.spaceLg),
              Text(
                l10n.onboardingMaintenanceTitle,
                style: theme.textTheme.titleMedium,
              ),
              SizedBox(height: tokens.spaceXs),
              Text(
                l10n.onboardingMaintenanceIntro,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: tokens.spaceSm),
              _MaintenanceToggle(
                title: l10n.onboardingMaintenanceDeadlineTitle,
                subtitle: l10n.onboardingMaintenanceDeadlineBody,
                value: settings.maintenanceDeadlineRiskEnabled,
                onChanged: (value) => context.read<GlobalSettingsBloc>().add(
                  GlobalSettingsEvent.maintenanceDeadlineRiskChanged(value),
                ),
                onTune: () => _showDeadlineTuneSheet(context, settings),
                tuneLabel: l10n.onboardingMaintenanceTuneLabel,
              ),
              SizedBox(height: tokens.spaceSm),
              _MaintenanceToggle(
                title: l10n.onboardingMaintenanceStaleTitle,
                subtitle: l10n.onboardingMaintenanceStaleBody,
                value: settings.maintenanceStaleEnabled,
                onChanged: (value) => context.read<GlobalSettingsBloc>().add(
                  GlobalSettingsEvent.maintenanceStaleChanged(value),
                ),
                onTune: () => _showStaleTuneSheet(context, settings),
                tuneLabel: l10n.onboardingMaintenanceTuneLabel,
              ),
              SizedBox(height: tokens.spaceSm),
              _MaintenanceToggle(
                title: l10n.onboardingMaintenanceDeferredTitle,
                subtitle: l10n.onboardingMaintenanceDeferredBody,
                value: settings.maintenanceFrequentSnoozedEnabled,
                onChanged: (value) => context.read<GlobalSettingsBloc>().add(
                  GlobalSettingsEvent.maintenanceFrequentSnoozedChanged(value),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showDeadlineTuneSheet(
    BuildContext context,
    GlobalSettings settings,
  ) {
    final tokens = TasklyTokens.of(context);
    final l10n = context.l10n;

    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        var dueWithin = settings.maintenanceDeadlineRiskDueWithinDays;
        var minUnscheduled =
            settings.maintenanceDeadlineRiskMinUnscheduledCount;

        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                tokens.spaceLg,
                tokens.spaceLg,
                tokens.spaceLg,
                tokens.spaceLg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.onboardingMaintenanceTuneDeadlineTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: tokens.spaceLg),
                  _TuneSlider(
                    label: l10n.weeklyReviewDueWithinLabel,
                    value: dueWithin,
                    min: GlobalSettings.maintenanceDeadlineRiskDueWithinDaysMin,
                    max: GlobalSettings.maintenanceDeadlineRiskDueWithinDaysMax,
                    valueLabel: l10n.daysCountLabel(dueWithin),
                    onChanged: (next) => setState(() => dueWithin = next),
                    onCommit: (next) {
                      context.read<GlobalSettingsBloc>().add(
                        GlobalSettingsEvent.maintenanceDeadlineRiskDueWithinDaysChanged(
                          next,
                        ),
                      );
                    },
                  ),
                  SizedBox(height: tokens.spaceSm),
                  _TuneSlider(
                    label: l10n.weeklyReviewUnscheduledTasksLabel,
                    value: minUnscheduled,
                    min: GlobalSettings
                        .maintenanceDeadlineRiskMinUnscheduledCountMin,
                    max: GlobalSettings
                        .maintenanceDeadlineRiskMinUnscheduledCountMax,
                    valueLabel: l10n.tasksCountLabel(minUnscheduled),
                    onChanged: (next) => setState(() => minUnscheduled = next),
                    onCommit: (next) {
                      context.read<GlobalSettingsBloc>().add(
                        GlobalSettingsEvent.maintenanceDeadlineRiskMinUnscheduledCountChanged(
                          next,
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showStaleTuneSheet(
    BuildContext context,
    GlobalSettings settings,
  ) {
    final tokens = TasklyTokens.of(context);
    final l10n = context.l10n;

    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        var taskDays = settings.maintenanceTaskStaleThresholdDays;
        var projectDays = settings.maintenanceProjectIdleThresholdDays;

        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                tokens.spaceLg,
                tokens.spaceLg,
                tokens.spaceLg,
                tokens.spaceLg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.onboardingMaintenanceTuneStaleTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: tokens.spaceLg),
                  _TuneSlider(
                    label: l10n.weeklyReviewTaskStaleAfterLabel,
                    value: taskDays,
                    min: GlobalSettings.maintenanceStaleThresholdDaysMin,
                    max: GlobalSettings.maintenanceStaleThresholdDaysMax,
                    valueLabel: l10n.daysCountLabel(taskDays),
                    onChanged: (next) => setState(() => taskDays = next),
                    onCommit: (next) {
                      context.read<GlobalSettingsBloc>().add(
                        GlobalSettingsEvent.maintenanceTaskStaleThresholdDaysChanged(
                          next,
                        ),
                      );
                    },
                  ),
                  SizedBox(height: tokens.spaceSm),
                  _TuneSlider(
                    label: l10n.weeklyReviewProjectIdleAfterLabel,
                    value: projectDays,
                    min: GlobalSettings.maintenanceStaleThresholdDaysMin,
                    max: GlobalSettings.maintenanceStaleThresholdDaysMax,
                    valueLabel: l10n.daysCountLabel(projectDays),
                    onChanged: (next) => setState(() => projectDays = next),
                    onCommit: (next) {
                      context.read<GlobalSettingsBloc>().add(
                        GlobalSettingsEvent.maintenanceProjectIdleThresholdDaysChanged(
                          next,
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _MaintenanceToggle extends StatelessWidget {
  const _MaintenanceToggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.onTune,
    this.tuneLabel,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onTune;
  final String? tuneLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(tokens.spaceMd),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                SizedBox(height: tokens.spaceXxs),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (onTune != null && tuneLabel != null) ...[
                  SizedBox(height: tokens.spaceXs),
                  TextButton(
                    onPressed: onTune,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.square(tokens.minTapTargetSize),
                      alignment: Alignment.centerLeft,
                    ),
                    child: Text(tuneLabel!),
                  ),
                ],
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _TuneSlider extends StatelessWidget {
  const _TuneSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.valueLabel,
    required this.onChanged,
    required this.onCommit,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final String valueLabel;
  final ValueChanged<int> onChanged;
  final ValueChanged<int> onCommit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
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
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          label: valueLabel,
          onChanged: (next) => onChanged(next.round()),
          onChangeEnd: (next) => onCommit(next.round()),
        ),
      ],
    );
  }
}
