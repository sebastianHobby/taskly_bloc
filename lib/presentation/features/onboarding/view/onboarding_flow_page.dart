import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/features/guided_tour/bloc/guided_tour_bloc.dart';
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
import 'package:taskly_ui/taskly_ui_forms.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class OnboardingFlowPage extends StatelessWidget {
  const OnboardingFlowPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OnboardingBloc(
        authRepository: context.read<AuthRepositoryContract>(),
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
              context.read<GuidedTourBloc>().add(
                const GuidedTourStarted(force: true),
              );
              Routing.toScreenKey(context, 'projects');
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
                      Text(
                        'Step ${state.step.index + 1} of '
                        '${OnboardingStep.values.length}',
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
      OnboardingStep.valuesSetup => 'Finish',
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
            'Meet Taskly',
            style: theme.textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: tokens.spaceSm),
          Text(
            'Your daily plan, shaped by what matters.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: tokens.spaceSm),
          Text(
            'Choose your values to get better suggestions.',
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
              hintText: 'Sebastian',
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
            'Taskly suggests tasks based on these and helps balance what '
            'matters most to you right now.',
            style: theme.textTheme.bodyLarge,
          ),
          SizedBox(height: tokens.spaceSm),
          Text(
            'Pick 1-3 to start.',
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
              final draft = ValueDraft(
                name: template.name,
                color: template.colorId,
                priority: ValuePriority.medium,
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

class _CustomValueSheet extends StatefulWidget {
  const _CustomValueSheet();

  @override
  State<_CustomValueSheet> createState() => _CustomValueSheetState();
}

class _CustomValueSheetState extends State<_CustomValueSheet> {
  final _formKey = GlobalKey<FormBuilderState>();

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
              'Name it, pick an icon and color.',
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
        priority: ValuePriority.medium,
        iconName: iconName,
      ),
    );
  }
}

BuildContext _navigatorContext(BuildContext context) {
  return GoRouter.of(context).routerDelegate.navigatorKey.currentContext ??
      context;
}
