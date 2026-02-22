import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_tracker_wizard_bloc.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class JournalTrackerWizardPage extends StatelessWidget {
  const JournalTrackerWizardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<JournalTrackerWizardBloc>(
      create: (context) => JournalTrackerWizardBloc(
        repository: context.read<JournalRepositoryContract>(),
        errorReporter: context.read<AppErrorReporter>(),
        nowUtc: context.read<NowService>().nowUtc,
      )..add(const JournalTrackerWizardStarted()),
      child: const _JournalTrackerWizardView(),
    );
  }
}

class _JournalTrackerWizardView extends StatefulWidget {
  const _JournalTrackerWizardView();

  @override
  State<_JournalTrackerWizardView> createState() =>
      _JournalTrackerWizardViewState();
}

class _JournalTrackerWizardViewState extends State<_JournalTrackerWizardView> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _choiceController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _choiceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<JournalTrackerWizardBloc, JournalTrackerWizardState>(
      listenWhen: (prev, next) =>
          prev.status.runtimeType != next.status.runtimeType,
      listener: (context, state) {
        if (state.status is JournalTrackerWizardSaved) {
          Navigator.of(context).pop(true);
          return;
        }
        if (state.status case final JournalTrackerWizardError status) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(status.message)),
          );
        }
      },
      builder: (context, state) {
        final theme = Theme.of(context);
        final tokens = TasklyTokens.of(context);
        final isSaving = state.status is JournalTrackerWizardSaving;
        final step = state.step;

        if (_nameController.text != state.name) {
          _nameController.text = state.name;
          _nameController.selection = TextSelection.fromPosition(
            TextPosition(offset: _nameController.text.length),
          );
        }

        bool canContinue() {
          if (step == 0) return state.name.trim().isNotEmpty;
          if (step == 1) return state.scope != null;
          if (step == 2) {
            if (state.measurement == null) return false;
            if (state.measurement == JournalTrackerMeasurementType.choice) {
              return state.choiceLabels.any((label) => label.trim().isNotEmpty);
            }
            return true;
          }
          return false;
        }

        return Scaffold(
          appBar: AppBar(title: Text(context.l10n.journalNewTrackerTitle)),
          body: Stepper(
            currentStep: step,
            onStepCancel: isSaving
                ? null
                : () {
                    if (step == 0) {
                      Navigator.of(context).pop();
                      return;
                    }
                    context.read<JournalTrackerWizardBloc>().add(
                      JournalTrackerWizardStepChanged(step - 1),
                    );
                  },
            onStepContinue: isSaving
                ? null
                : () {
                    if (!canContinue()) return;
                    if (step < 2) {
                      context.read<JournalTrackerWizardBloc>().add(
                        JournalTrackerWizardStepChanged(step + 1),
                      );
                    } else {
                      context.read<JournalTrackerWizardBloc>().add(
                        const JournalTrackerWizardSaveRequested(),
                      );
                    }
                  },
            controlsBuilder: (context, details) {
              if (!details.isActive) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: EdgeInsets.only(top: tokens.spaceSm),
                child: Row(
                  children: [
                    FilledButton(
                      key: ValueKey('journal_tracker_wizard_next_step_$step'),
                      onPressed: canContinue() ? details.onStepContinue : null,
                      child: isSaving && step == 2
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                          : Text(
                              step == 2
                                  ? context.l10n.createLabel
                                  : context.l10n.nextLabel,
                            ),
                    ),
                    SizedBox(width: tokens.spaceSm),
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: Text(
                        step == 0
                            ? context.l10n.cancelLabel
                            : context.l10n.backLabel,
                      ),
                    ),
                  ],
                ),
              );
            },
            steps: [
              Step(
                title: Text(context.l10n.nameLabel),
                isActive: step >= 0,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _nameController,
                      enabled: !isSaving,
                      decoration: InputDecoration(
                        labelText: context.l10n.nameLabel,
                        hintText: context.l10n.journalTrackerNameHint,
                      ),
                      textInputAction: TextInputAction.next,
                      onChanged: (value) => context
                          .read<JournalTrackerWizardBloc>()
                          .add(JournalTrackerWizardNameChanged(value)),
                    ),
                    SizedBox(height: tokens.spaceSm),
                    DropdownButtonFormField<String?>(
                      value: state.groupId,
                      decoration: InputDecoration(
                        labelText: context.l10n.groupLabel,
                      ),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(context.l10n.journalGroupUngrouped),
                        ),
                        for (final g in state.groups)
                          DropdownMenuItem<String?>(
                            value: g.id,
                            child: Text(g.name),
                          ),
                      ],
                      onChanged: isSaving
                          ? null
                          : (value) => context
                                .read<JournalTrackerWizardBloc>()
                                .add(JournalTrackerWizardGroupChanged(value)),
                    ),
                  ],
                ),
              ),
              Step(
                title: Text(context.l10n.journalScopeTitle),
                isActive: step >= 1,
                content: Column(
                  children: [
                    RadioListTile<JournalTrackerScopeOption>(
                      value: JournalTrackerScopeOption.day,
                      groupValue: state.scope,
                      onChanged: isSaving
                          ? null
                          : (value) =>
                                context.read<JournalTrackerWizardBloc>().add(
                                  JournalTrackerWizardScopeChanged(value!),
                                ),
                      title: Text(context.l10n.journalScopeDailyTotal),
                      subtitle: Text(
                        context.l10n.journalScopeDailyTotalSubtitle,
                      ),
                    ),
                    RadioListTile<JournalTrackerScopeOption>(
                      value: JournalTrackerScopeOption.entry,
                      groupValue: state.scope,
                      onChanged: isSaving
                          ? null
                          : (value) =>
                                context.read<JournalTrackerWizardBloc>().add(
                                  JournalTrackerWizardScopeChanged(value!),
                                ),
                      title: Text(context.l10n.journalScopeMomentary),
                      subtitle: Text(
                        context.l10n.journalScopeMomentarySubtitle,
                      ),
                    ),
                    RadioListTile<JournalTrackerScopeOption>(
                      value: JournalTrackerScopeOption.sleepNight,
                      groupValue: state.scope,
                      onChanged: isSaving
                          ? null
                          : (value) =>
                                context.read<JournalTrackerWizardBloc>().add(
                                  JournalTrackerWizardScopeChanged(value!),
                                ),
                      title: Text(context.l10n.journalScopeSleepNight),
                      subtitle: Text(
                        context.l10n.journalScopeSleepNightSubtitle,
                      ),
                    ),
                  ],
                ),
              ),
              Step(
                title: Text(context.l10n.journalMeasurementTitle),
                isActive: step >= 2,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MeasurementOption(
                      title: context.l10n.journalMeasurementToggleTitle,
                      subtitle: context.l10n.journalMeasurementToggleSubtitle,
                      selected:
                          state.measurement ==
                          JournalTrackerMeasurementType.toggle,
                      onTap: isSaving
                          ? null
                          : () => context.read<JournalTrackerWizardBloc>().add(
                              const JournalTrackerWizardMeasurementChanged(
                                JournalTrackerMeasurementType.toggle,
                              ),
                            ),
                    ),
                    _MeasurementOption(
                      title: context.l10n.journalMeasurementRatingTitle,
                      subtitle: context.l10n.journalMeasurementRatingSubtitle,
                      selected:
                          state.measurement ==
                          JournalTrackerMeasurementType.rating,
                      onTap: isSaving
                          ? null
                          : () => context.read<JournalTrackerWizardBloc>().add(
                              const JournalTrackerWizardMeasurementChanged(
                                JournalTrackerMeasurementType.rating,
                              ),
                            ),
                    ),
                    _MeasurementOption(
                      title: context.l10n.journalMeasurementQuantityTitle,
                      subtitle: state.scope == JournalTrackerScopeOption.entry
                          ? context.l10n.journalMeasurementQuantityEntrySubtitle
                          : context.l10n.journalMeasurementQuantityDaySubtitle,
                      selected:
                          state.measurement ==
                          JournalTrackerMeasurementType.quantity,
                      onTap: isSaving
                          ? null
                          : () => context.read<JournalTrackerWizardBloc>().add(
                              const JournalTrackerWizardMeasurementChanged(
                                JournalTrackerMeasurementType.quantity,
                              ),
                            ),
                    ),
                    _MeasurementOption(
                      title: context.l10n.journalMeasurementChoiceTitle,
                      subtitle: context.l10n.journalMeasurementChoiceSubtitle,
                      selected:
                          state.measurement ==
                          JournalTrackerMeasurementType.choice,
                      onTap: isSaving
                          ? null
                          : () => context.read<JournalTrackerWizardBloc>().add(
                              const JournalTrackerWizardMeasurementChanged(
                                JournalTrackerMeasurementType.choice,
                              ),
                            ),
                    ),
                    SizedBox(height: tokens.spaceSm),
                    if (state.measurement ==
                        JournalTrackerMeasurementType.rating)
                      _RatingConfigForm(
                        min: state.ratingMin,
                        max: state.ratingMax,
                        step: state.ratingStep,
                        enabled: !isSaving,
                        onChanged: (min, max, step) =>
                            context.read<JournalTrackerWizardBloc>().add(
                              JournalTrackerWizardRatingConfigChanged(
                                min: min,
                                max: max,
                                step: step,
                              ),
                            ),
                      ),
                    if (state.measurement ==
                        JournalTrackerMeasurementType.quantity)
                      _QuantityConfigForm(
                        unit: state.quantityUnit,
                        min: state.quantityMin,
                        max: state.quantityMax,
                        step: state.quantityStep,
                        enabled: !isSaving,
                        onChanged: (unit, min, max, step) =>
                            context.read<JournalTrackerWizardBloc>().add(
                              JournalTrackerWizardQuantityConfigChanged(
                                unit: unit,
                                min: min,
                                max: max,
                                step: step,
                              ),
                            ),
                      ),
                    if (state.measurement ==
                        JournalTrackerMeasurementType.choice)
                      _ChoiceConfigForm(
                        controller: _choiceController,
                        choices: state.choiceLabels,
                        enabled: !isSaving,
                        onAdd: (label) => context
                            .read<JournalTrackerWizardBloc>()
                            .add(JournalTrackerWizardChoiceAdded(label)),
                        onRemove: (index) => context
                            .read<JournalTrackerWizardBloc>()
                            .add(JournalTrackerWizardChoiceRemoved(index)),
                        onUpdate: (index, label) =>
                            context.read<JournalTrackerWizardBloc>().add(
                              JournalTrackerWizardChoiceUpdated(
                                index: index,
                                label: label,
                              ),
                            ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MeasurementOption extends StatelessWidget {
  const _MeasurementOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: selected ? const Icon(Icons.check) : null,
        onTap: onTap,
      ),
    );
  }
}

class _RatingConfigForm extends StatelessWidget {
  const _RatingConfigForm({
    required this.min,
    required this.max,
    required this.step,
    required this.enabled,
    required this.onChanged,
  });

  final int min;
  final int max;
  final int step;
  final bool enabled;
  final void Function(int min, int max, int step) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _NumberField(
          label: context.l10n.minLabel,
          value: min,
          enabled: enabled,
          onChanged: (value) => onChanged(value ?? min, max, step),
        ),
        _NumberField(
          label: context.l10n.maxLabel,
          value: max,
          enabled: enabled,
          onChanged: (value) => onChanged(min, value ?? max, step),
        ),
        _NumberField(
          label: context.l10n.stepLabel,
          value: step,
          enabled: enabled,
          onChanged: (value) => onChanged(min, max, value ?? step),
        ),
      ],
    );
  }
}

class _QuantityConfigForm extends StatelessWidget {
  const _QuantityConfigForm({
    required this.unit,
    required this.min,
    required this.max,
    required this.step,
    required this.enabled,
    required this.onChanged,
  });

  final String unit;
  final int? min;
  final int? max;
  final int step;
  final bool enabled;
  final void Function(String unit, int? min, int? max, int step) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SyncedTextField(
          value: unit,
          decoration: InputDecoration(
            labelText: context.l10n.journalUnitOptionalLabel,
          ),
          enabled: enabled,
          onChanged: (value) => onChanged(value, min, max, step),
        ),
        _NumberField(
          label: context.l10n.minOptionalLabel,
          value: min,
          enabled: enabled,
          onChanged: (value) => onChanged(unit, value, max, step),
        ),
        _NumberField(
          label: context.l10n.maxOptionalLabel,
          value: max,
          enabled: enabled,
          onChanged: (value) => onChanged(unit, min, value, step),
        ),
        _NumberField(
          label: context.l10n.stepLabel,
          value: step,
          enabled: enabled,
          onChanged: (value) => onChanged(unit, min, max, value ?? step),
        ),
      ],
    );
  }
}

class _ChoiceConfigForm extends StatelessWidget {
  const _ChoiceConfigForm({
    required this.controller,
    required this.choices,
    required this.enabled,
    required this.onAdd,
    required this.onRemove,
    required this.onUpdate,
  });

  final TextEditingController controller;
  final List<String> choices;
  final bool enabled;
  final ValueChanged<String> onAdd;
  final ValueChanged<int> onRemove;
  final void Function(int index, String label) onUpdate;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                decoration: InputDecoration(
                  labelText: context.l10n.journalOptionLabel,
                  hintText: context.l10n.journalOptionHint,
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (value) {
                  onAdd(value);
                  controller.clear();
                },
              ),
            ),
            SizedBox(width: tokens.spaceSm),
            FilledButton(
              onPressed: enabled
                  ? () {
                      onAdd(controller.text);
                      controller.clear();
                    }
                  : null,
              child: Text(context.l10n.addLabel),
            ),
          ],
        ),
        SizedBox(height: tokens.spaceSm),
        if (choices.isEmpty)
          Text(
            context.l10n.journalAddOptionHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          )
        else
          for (var i = 0; i < choices.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: tokens.spaceXs),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: choices[i],
                      enabled: enabled,
                      decoration: InputDecoration(
                        labelText: context.l10n.labelLabel,
                      ),
                      onChanged: (value) => onUpdate(i, value),
                    ),
                  ),
                  IconButton(
                    tooltip: context.l10n.removeLabel,
                    onPressed: enabled ? () => onRemove(i) : null,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final int? value;
  final bool enabled;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SyncedTextField(
      value: value == null ? '' : value.toString(),
      enabled: enabled,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      onChanged: (value) => onChanged(int.tryParse(value)),
    );
  }
}

class _SyncedTextField extends StatefulWidget {
  const _SyncedTextField({
    required this.value,
    required this.enabled,
    required this.onChanged,
    this.decoration,
    this.keyboardType,
  });

  final String value;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;

  @override
  State<_SyncedTextField> createState() => _SyncedTextFieldState();
}

class _SyncedTextFieldState extends State<_SyncedTextField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void didUpdateWidget(covariant _SyncedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value == _controller.text) return;
    _controller.value = _controller.value.copyWith(
      text: widget.value,
      selection: TextSelection.collapsed(offset: widget.value.length),
      composing: TextRange.empty,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      enabled: widget.enabled,
      keyboardType: widget.keyboardType,
      decoration: widget.decoration,
      onChanged: widget.onChanged,
    );
  }
}
