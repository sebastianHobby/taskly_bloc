import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/features/onboarding/bloc/onboarding_bloc.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_bloc/presentation/shared/validation/form_builder_validator_adapter.dart';
import 'package:taskly_bloc/presentation/widgets/form_fields/form_builder_color_picker.dart';
import 'package:taskly_bloc/presentation/widgets/form_fields/form_builder_icon_picker.dart';
import 'package:taskly_bloc/presentation/widgets/icon_picker/icon_catalog.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_ui/taskly_ui_feed.dart';
import 'package:taskly_ui/taskly_ui_forms.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class OnboardingFlowPage extends StatelessWidget {
  const OnboardingFlowPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OnboardingBloc(
        authRepository: context.read<AuthRepositoryContract>(),
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
  late final OnboardingBloc _bloc;
  late final PageController _pageController;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _bloc = context.read<OnboardingBloc>();
    _pageController = PageController();
    _nameController.addListener(_handleNameChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_handleNameChanged);
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _handleNameChanged() {
    _bloc.add(OnboardingNameChanged(_nameController.text));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);

    return Scaffold(
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
              Routing.toScreenKey(context, 'someday');
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
            final canGoBack = state.step != OnboardingStep.welcome;
            final primaryLabel = _primaryLabelFor(state.step);
            final isPrimaryBusy =
                state.isSavingName ||
                state.isCreatingValue ||
                state.isCompleting;

            return Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _WelcomeStep(tokens: tokens),
                      _NameStep(controller: _nameController),
                      _ValuesStep(
                        selectedValues: state.selectedValues,
                        isBusy: state.isCreatingValue,
                      ),
                      _PlanMyDayStep(tokens: tokens),
                      _OverviewStep(tokens: tokens),
                    ],
                  ),
                ),
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
                      FilledButton(
                        onPressed: isPrimaryBusy || !_isPrimaryEnabled(state)
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
                      if (canGoBack) ...[
                        SizedBox(height: tokens.spaceSm),
                        TextButton(
                          onPressed: () => context.read<OnboardingBloc>().add(
                            const OnboardingBackRequested(),
                          ),
                          child: const Text('Back'),
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
    );
  }

  bool _isPrimaryEnabled(OnboardingState state) {
    return switch (state.step) {
      OnboardingStep.name => state.displayName.trim().isNotEmpty,
      OnboardingStep.valuesSetup => state.hasMinimumValues,
      _ => true,
    };
  }

  String _primaryLabelFor(OnboardingStep step) {
    return switch (step) {
      OnboardingStep.welcome => 'Get started',
      OnboardingStep.name => 'Continue',
      OnboardingStep.valuesSetup => 'Continue',
      OnboardingStep.planMyDay => 'Next',
      OnboardingStep.overview => 'Got it',
    };
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
          Icon(
            Icons.check_circle_outline,
            size: 84,
            color: theme.colorScheme.primary,
          ),
          SizedBox(height: tokens.spaceLg),
          Text(
            'Welcome to Taskly',
            style: theme.textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: tokens.spaceSm),
          Text(
            'Focus your day without losing your backlog.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _NameStep extends StatelessWidget {
  const _NameStep({
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = TasklyTokens.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'What should we call you?',
            style: theme.textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: tokens.spaceSm),
          Text(
            'Used on your profile and reminders.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: tokens.spaceXl),
          TextField(
            controller: controller,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'Jordan Lee',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ValuesStep extends StatelessWidget {
  const _ValuesStep({
    required this.selectedValues,
    required this.isBusy,
  });

  final List<OnboardingValueSelection> selectedValues;
  final bool isBusy;

  static const int _maxValues = 3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = TasklyTokens.of(context);
    final scheme = theme.colorScheme;

    final quickPicks = _quickPickTemplates();
    final canAddMore = selectedValues.length < _maxValues;

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
            'Choose your top values',
            style: theme.textTheme.displaySmall,
          ),
          SizedBox(height: tokens.spaceSm),
          Text(
            'Values guide your daily focus. Taskly uses them to suggest tasks '
            'and keep your attention balanced.',
            style: theme.textTheme.bodyLarge,
          ),
          SizedBox(height: tokens.spaceSm),
          Text(
            'Pick 1-3 values that feel meaningful and doable.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: tokens.spaceLg),
          Text(
            'Quick picks',
            style: theme.textTheme.titleMedium,
          ),
          SizedBox(height: tokens.spaceSm),
          _QuickPickGrid(
            picks: quickPicks,
            selectedValues: selectedValues,
            enabled: canAddMore && !isBusy,
          ),
          SizedBox(height: tokens.spaceSm),
          OutlinedButton.icon(
            onPressed: canAddMore && !isBusy
                ? () => _openCustomValueSheet(context)
                : null,
            icon: const Icon(Icons.add),
            label: const Text('Custom value'),
          ),
          SizedBox(height: tokens.spaceLg),
          Text(
            'Your picks',
            style: theme.textTheme.titleMedium,
          ),
          SizedBox(height: tokens.spaceSm),
          if (selectedValues.isEmpty)
            Text(
              'Pick at least 1 value to continue.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          else
            Column(
              children: [
                for (final value in selectedValues) ...[
                  _SelectedValueRow(
                    value: value,
                    onEdit: () => _openEditValue(context, value.id),
                    onRemove: () => context.read<OnboardingBloc>().add(
                      OnboardingValueRemoved(value.id),
                    ),
                  ),
                  SizedBox(height: tokens.spaceSm),
                ],
              ],
            ),
        ],
      ),
    );
  }

  List<_QuickPickTemplate> _quickPickTemplates() {
    return [
      _QuickPickTemplate(
        name: 'Health',
        iconName: 'health',
        colorId: ColorUtils.valueGreenId,
      ),
      _QuickPickTemplate(
        name: 'Relationships',
        iconName: 'group',
        colorId: ColorUtils.valueRoseId,
      ),
      _QuickPickTemplate(
        name: 'Career',
        iconName: 'work',
        colorId: ColorUtils.valueBlueId,
      ),
      _QuickPickTemplate(
        name: 'Learning',
        iconName: 'lightbulb',
        colorId: ColorUtils.valueVioletId,
      ),
      _QuickPickTemplate(
        name: 'Home',
        iconName: 'home',
        colorId: ColorUtils.valueSlateId,
      ),
      _QuickPickTemplate(
        name: 'Adventure',
        iconName: 'rocket',
        colorId: ColorUtils.valueAmberId,
      ),
    ];
  }

  Future<void> _openCustomValueSheet(BuildContext context) async {
    final sheetContext = _navigatorContext(context);
    final draft = await showModalBottomSheet<ValueDraft>(
      context: sheetContext,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _CustomValueSheet(),
    );
    if (draft == null || !context.mounted) return;
    context.read<OnboardingBloc>().add(OnboardingCustomValueConfirmed(draft));
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

class _QuickPickTemplate {
  const _QuickPickTemplate({
    required this.name,
    required this.iconName,
    required this.colorId,
  });

  final String name;
  final String iconName;
  final String colorId;
}

class _QuickPickGrid extends StatelessWidget {
  const _QuickPickGrid({
    required this.picks,
    required this.selectedValues,
    required this.enabled,
  });

  final List<_QuickPickTemplate> picks;
  final List<OnboardingValueSelection> selectedValues;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 2.3,
      crossAxisSpacing: tokens.spaceSm,
      mainAxisSpacing: tokens.spaceSm,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: [
        for (final pick in picks)
          _QuickPickCard(
            template: pick,
            isSelected: selectedValues.any(
              (value) => value.name.toLowerCase() == pick.name.toLowerCase(),
            ),
            enabled: enabled,
          ),
      ],
    );
  }
}

class _QuickPickCard extends StatelessWidget {
  const _QuickPickCard({
    required this.template,
    required this.isSelected,
    required this.enabled,
  });

  final _QuickPickTemplate template;
  final bool isSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final iconData = getIconDataFromName(template.iconName) ?? Icons.star;
    final color = ColorUtils.valueColorForTheme(context, template.colorId);

    final background = isSelected
        ? Color.alphaBlend(
            color.withValues(alpha: 0.18),
            scheme.surfaceContainerHighest,
          )
        : scheme.surfaceContainerLow;

    return InkWell(
      onTap: enabled
          ? () async {
              if (isSelected) return;
              final priority = await _selectPriority(context, template.name);
              if (priority == null || !context.mounted) return;
              final draft = ValueDraft(
                name: template.name,
                color: template.colorId,
                priority: priority,
                iconName: template.iconName,
              );
              context.read<OnboardingBloc>().add(
                OnboardingQuickPickConfirmed(draft),
              );
            }
          : null,
      borderRadius: BorderRadius.circular(tokens.radiusLg),
      child: Container(
        padding: EdgeInsets.all(tokens.spaceSm),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(tokens.radiusLg),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.4)
                : scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: color.withValues(alpha: 0.2),
              child: Icon(iconData, color: color, size: 18),
            ),
            SizedBox(width: tokens.spaceSm),
            Expanded(
              child: Text(
                template.name,
                style: Theme.of(context).textTheme.labelLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected) Icon(Icons.check_rounded, size: 18, color: color),
          ],
        ),
      ),
    );
  }

  Future<ValuePriority?> _selectPriority(
    BuildContext context,
    String name,
  ) {
    final sheetContext = _navigatorContext(context);
    return showModalBottomSheet<ValuePriority>(
      context: sheetContext,
      useSafeArea: true,
      builder: (_) => _PrioritySheet(valueName: name),
    );
  }
}

class _SelectedValueRow extends StatelessWidget {
  const _SelectedValueRow({
    required this.value,
    required this.onEdit,
    required this.onRemove,
  });

  final OnboardingValueSelection value;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final iconData = getIconDataFromName(value.iconName) ?? Icons.star;
    final color = ColorUtils.valueColorForTheme(context, value.color);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceSm,
        vertical: tokens.spaceXs2,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.2),
            child: Icon(iconData, color: color, size: 18),
          ),
          SizedBox(width: tokens.spaceSm),
          Expanded(
            child: Text(
              value.name,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          _PriorityPill(priority: value.priority),
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: onEdit,
          ),
          IconButton(
            tooltip: 'Remove',
            icon: const Icon(Icons.close),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _PriorityPill extends StatelessWidget {
  const _PriorityPill({required this.priority});

  final ValuePriority priority;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final label = switch (priority) {
      ValuePriority.high => context.l10n.valuePriorityHighLabel,
      ValuePriority.medium => context.l10n.valuePriorityMediumLabel,
      ValuePriority.low => context.l10n.valuePriorityLowLabel,
    };
    final color = switch (priority) {
      ValuePriority.high => scheme.secondary,
      ValuePriority.medium => scheme.primary,
      ValuePriority.low => scheme.onSurfaceVariant,
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceXs,
        vertical: tokens.spaceXxs2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(tokens.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PrioritySheet extends StatefulWidget {
  const _PrioritySheet({required this.valueName});

  final String valueName;

  @override
  State<_PrioritySheet> createState() => _PrioritySheetState();
}

class _PrioritySheetState extends State<_PrioritySheet> {
  ValuePriority _priority = ValuePriority.medium;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLg,
        tokens.spaceLg,
        tokens.spaceLg,
        tokens.spaceXl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Priority for ${widget.valueName}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: tokens.spaceSm),
          Text(
            'Higher priorities get a little more space in suggestions.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: tokens.spaceLg),
          TasklyFormPrioritySegmented(
            segments: [
              TasklyFormPrioritySegment(
                label: context.l10n.valuePriorityLowLabel,
                value: ValuePriority.low.index,
                selectedColor: scheme.onSurfaceVariant,
              ),
              TasklyFormPrioritySegment(
                label: context.l10n.valuePriorityMediumLabel,
                value: ValuePriority.medium.index,
                selectedColor: scheme.primary,
              ),
              TasklyFormPrioritySegment(
                label: context.l10n.valuePriorityHighLabel,
                value: ValuePriority.high.index,
                selectedColor: scheme.secondary,
              ),
            ],
            value: _priority.index,
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _priority = ValuePriority.values[value];
              });
            },
          ),
          SizedBox(height: tokens.spaceLg),
          FilledButton(
            onPressed: () => Navigator.pop(context, _priority),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

class _CustomValueSheet extends StatefulWidget {
  const _CustomValueSheet();

  @override
  State<_CustomValueSheet> createState() => _CustomValueSheetState();
}

class _CustomValueSheetState extends State<_CustomValueSheet> {
  final _formKey = GlobalKey<FormBuilderState>();
  ValuePriority _priority = ValuePriority.medium;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: tokens.spaceLg,
        right: tokens.spaceLg,
        top: tokens.spaceLg,
        bottom: MediaQuery.of(context).viewInsets.bottom + tokens.spaceLg,
      ),
      child: FormBuilder(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Custom value',
              style: theme.textTheme.titleLarge,
            ),
            SizedBox(height: tokens.spaceSm),
            Text(
              'Name it, pick an icon and color, then set priority.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: tokens.spaceLg),
            FormBuilderTextField(
              name: ValueFieldKeys.name.id,
              textInputAction: TextInputAction.next,
              maxLength: ValueValidators.maxNameLength,
              decoration: const InputDecoration(
                labelText: 'Value name',
                border: OutlineInputBorder(),
              ),
              validator: toFormBuilderValidator<String>(
                ValueValidators.name,
                context,
              ),
            ),
            SizedBox(height: tokens.spaceMd),
            TasklyFormSectionLabel(text: context.l10n.valueFormIconLabel),
            SizedBox(height: tokens.spaceSm),
            FormBuilderIconPicker(
              name: ValueFieldKeys.iconName.id,
              searchHintText: context.l10n.valueFormIconSearchHint,
              noIconsFoundLabel: context.l10n.valueFormIconNoResults,
              gridHeight: 200,
            ),
            SizedBox(height: tokens.spaceMd),
            TasklyFormSectionLabel(text: context.l10n.valueFormColorLabel),
            SizedBox(height: tokens.spaceSm),
            FormBuilderColorPicker(
              name: ValueFieldKeys.colour.id,
              title: context.l10n.valueFormColorLabel,
              showLabel: false,
              compact: true,
              validator: toFormBuilderValidator<Color>(
                (value) => ValueValidators.color(
                  value == null ? null : ColorUtils.toHex(value),
                ),
                context,
              ),
            ),
            SizedBox(height: tokens.spaceMd),
            TasklyFormSectionLabel(text: context.l10n.priorityLabel),
            SizedBox(height: tokens.spaceSm),
            TasklyFormPrioritySegmented(
              segments: [
                TasklyFormPrioritySegment(
                  label: context.l10n.valuePriorityLowLabel,
                  value: ValuePriority.low.index,
                  selectedColor: scheme.onSurfaceVariant,
                ),
                TasklyFormPrioritySegment(
                  label: context.l10n.valuePriorityMediumLabel,
                  value: ValuePriority.medium.index,
                  selectedColor: scheme.primary,
                ),
                TasklyFormPrioritySegment(
                  label: context.l10n.valuePriorityHighLabel,
                  value: ValuePriority.high.index,
                  selectedColor: scheme.secondary,
                ),
              ],
              value: _priority.index,
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _priority = ValuePriority.values[value];
                });
              },
            ),
            SizedBox(height: tokens.spaceLg),
            FilledButton(
              onPressed: _handleSave,
              child: const Text('Add value'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSave() {
    final formState = _formKey.currentState;
    if (formState == null) return;
    if (!formState.saveAndValidate()) return;

    final values = formState.value;
    final name = (values[ValueFieldKeys.name.id] as String? ?? '').trim();
    final iconName = (values[ValueFieldKeys.iconName.id] as String?)?.trim();
    final colorValue = values[ValueFieldKeys.colour.id] as Color?;
    final colorHex = colorValue != null
        ? ColorUtils.valuePaletteIdOrHex(colorValue)
        : ColorUtils.valueBlueId;

    Navigator.pop(
      context,
      ValueDraft(
        name: name,
        color: colorHex,
        priority: _priority,
        iconName: iconName,
      ),
    );
  }
}

class _PlanMyDayStep extends StatelessWidget {
  const _PlanMyDayStep({required this.tokens});

  final TasklyTokens tokens;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

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
            'Plan My Day',
            style: theme.textTheme.displaySmall,
          ),
          SizedBox(height: tokens.spaceSm),
          Text(
            'Taskly uses your values, routines, and urgent items to build '
            "today's focus list. You confirm the final picks.",
            style: theme.textTheme.bodyLarge,
          ),
          SizedBox(height: tokens.spaceLg),
          Text(
            'Plan My Day (4 steps)',
            style: theme.textTheme.titleMedium,
          ),
          SizedBox(height: tokens.spaceSm),
          _InfoGrid(
            items: const [
              _InfoCardData(
                title: 'Values',
                body: 'Tasks linked to what matters most.',
                detail:
                    'Values lead the plan. Taskly looks at your value '
                    'priorities and surfaces tasks that support them.',
              ),
              _InfoCardData(
                title: 'Routines',
                body: 'Optional habits you want to keep on track.',
                detail:
                    'Routines can appear in your plan when you want them. '
                    'They stay optional.',
              ),
              _InfoCardData(
                title: 'Urgent / Planned',
                body: "Time-sensitive items you shouldn't miss.",
                detail:
                    'Due or planned tasks are shown so you can balance '
                    "today's focus with timing.",
              ),
              _InfoCardData(
                title: 'Summary',
                body: 'Your final focus list for today.',
                detail: 'You confirm the list. Nothing is auto-committed.',
              ),
            ],
          ),
          SizedBox(height: tokens.spaceLg),
          Text(
            'My Day',
            style: theme.textTheme.titleMedium,
          ),
          SizedBox(height: tokens.spaceSm),
          _InfoCard(
            title: "Today's focus list",
            body: 'Built from your values, routines, and urgent items.',
            tint: scheme.primaryContainer,
            onTap: () => _showInfoSheet(
              context,
              title: 'My Day',
              body:
                  'My Day is your focus list for today. It pulls from values, '
                  'routines, and time-sensitive items so you can choose what '
                  'to work on now.',
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewStep extends StatelessWidget {
  const _OverviewStep({required this.tokens});

  final TasklyTokens tokens;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

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
            'Anytime',
            style: theme.textTheme.displaySmall,
          ),
          SizedBox(height: tokens.spaceSm),
          _InfoCard(
            title: 'Your full list',
            body:
                'Anytime is where all your tasks and projects live. '
                'My Day brings the right ones forward when it matters.',
            tint: scheme.secondaryContainer,
          ),
          SizedBox(height: tokens.spaceLg),
          Text(
            'Scheduled',
            style: theme.textTheme.titleMedium,
          ),
          SizedBox(height: tokens.spaceSm),
          _InfoCard(
            title: 'A calendar lens',
            body: 'Upcoming tasks and projects, grouped by date.',
            tint: scheme.tertiaryContainer,
          ),
          SizedBox(height: tokens.spaceLg),
          Text(
            'Routines are optional',
            style: theme.textTheme.titleMedium,
          ),
          SizedBox(height: tokens.spaceSm),
          Text(
            'Routines are habits linked to your values. They can show up in '
            'Plan My Day when you want them to.',
            style: theme.textTheme.bodyLarge,
          ),
          SizedBox(height: tokens.spaceSm),
          _RoutineSampleTile(),
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.items});

  final List<_InfoCardData> items;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.15,
      crossAxisSpacing: tokens.spaceSm,
      mainAxisSpacing: tokens.spaceSm,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: [
        for (final item in items)
          _InfoCard(
            title: item.title,
            body: item.body,
            onTap: () => _showInfoSheet(
              context,
              title: item.title,
              body: item.detail,
            ),
          ),
      ],
    );
  }
}

class _InfoCardData {
  const _InfoCardData({
    required this.title,
    required this.body,
    required this.detail,
  });

  final String title;
  final String body;
  final String detail;
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.body,
    this.tint,
    this.onTap,
  });

  final String title;
  final String body;
  final Color? tint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final background = tint == null
        ? scheme.surfaceContainerLow
        : Color.alphaBlend(tint!.withValues(alpha: 0.22), scheme.surface);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(tokens.radiusLg),
      child: Container(
        padding: EdgeInsets.all(tokens.spaceSm),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(tokens.radiusLg),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            SizedBox(height: tokens.spaceXs),
            Text(
              body,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutineSampleTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final routineRow = TasklyRowSpec.routine(
      key: 'onboarding-routine-sample',
      data: TasklyRoutineRowData(
        id: 'r-sample-1',
        title: 'Morning walk',
        targetLabel: '3x/week',
        remainingLabel: '2 left',
        windowLabel: '4 days left',
        statusLabel: 'On track',
        statusTone: TasklyRoutineStatusTone.onPace,
        valueChip: ValueChipData(
          label: 'Health',
          icon: Icons.favorite_rounded,
          color: scheme.primary,
        ),
        labels: const TasklyRoutineRowLabels(primaryActionLabel: 'Do today'),
      ),
      actions: const TasklyRoutineRowActions(
        onTap: _noop,
        onPrimaryAction: _noop,
      ),
    );

    return TasklyFeedRenderer(
      spec: TasklyFeedSpec.content(
        sections: [
          TasklySectionSpec.standardList(
            id: 'onboarding-routine',
            rows: [routineRow],
          ),
        ],
      ),
    );
  }
}

void _showInfoSheet(
  BuildContext context, {
  required String title,
  required String body,
}) {
  final tokens = TasklyTokens.of(context);
  showModalBottomSheet<void>(
    context: _navigatorContext(context),
    useSafeArea: true,
    builder: (_) => Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLg,
        tokens.spaceLg,
        tokens.spaceLg,
        tokens.spaceXl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: tokens.spaceSm),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          SizedBox(height: tokens.spaceLg),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    ),
  );
}

void _noop() {}

BuildContext _navigatorContext(BuildContext context) {
  return GoRouter.of(context).routerDelegate.navigatorKey.currentContext ??
      context;
}
