import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
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
          appBar: AppBar(title: const Text('New tracker')),
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
                          : Text(step == 2 ? 'Create' : 'Next'),
                    ),
                    SizedBox(width: tokens.spaceSm),
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: Text(step == 0 ? 'Cancel' : 'Back'),
                    ),
                  ],
                ),
              );
            },
            steps: [
              Step(
                title: const Text('Name'),
                isActive: step >= 0,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _nameController,
                      enabled: !isSaving,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'e.g. Read, Walk, Stretch',
                      ),
                      textInputAction: TextInputAction.next,
                      onChanged: (value) => context
                          .read<JournalTrackerWizardBloc>()
                          .add(JournalTrackerWizardNameChanged(value)),
                    ),
                    SizedBox(height: tokens.spaceSm),
                    DropdownButtonFormField<String?>(
                      value: state.groupId,
                      decoration: const InputDecoration(labelText: 'Group'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Ungrouped'),
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
                title: const Text('Scope'),
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
                      title: const Text('Daily total'),
                      subtitle: const Text(
                        'Applies to the whole day.',
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
                      title: const Text('Momentary'),
                      subtitle: const Text(
                        'Applies only to this entry.',
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
                      title: const Text('Sleep / night'),
                      subtitle: const Text(
                        'Tracks a nightly total.',
                      ),
                    ),
                  ],
                ),
              ),
              Step(
                title: const Text('Measurement'),
                isActive: step >= 2,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MeasurementOption(
                      title: 'Toggle',
                      subtitle: 'Stats compare days with vs without.',
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
                      title: 'Rating',
                      subtitle: 'Stats use daily average.',
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
                      title: 'Quantity',
                      subtitle: state.scope == JournalTrackerScopeOption.entry
                          ? 'Stats can use total + frequency + typical amount.'
                          : 'Stats use daily total.',
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
                      title: 'Choice',
                      subtitle: 'Stats compare outcomes by option (per event).',
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
          label: 'Min',
          value: min,
          enabled: enabled,
          onChanged: (value) => onChanged(value ?? min, max, step),
        ),
        _NumberField(
          label: 'Max',
          value: max,
          enabled: enabled,
          onChanged: (value) => onChanged(min, value ?? max, step),
        ),
        _NumberField(
          label: 'Step',
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
        TextField(
          controller: TextEditingController(text: unit),
          decoration: const InputDecoration(labelText: 'Unit (optional)'),
          enabled: enabled,
          onChanged: (value) => onChanged(value, min, max, step),
        ),
        _NumberField(
          label: 'Min (optional)',
          value: min,
          enabled: enabled,
          onChanged: (value) => onChanged(unit, value, max, step),
        ),
        _NumberField(
          label: 'Max (optional)',
          value: max,
          enabled: enabled,
          onChanged: (value) => onChanged(unit, min, value, step),
        ),
        _NumberField(
          label: 'Step',
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
                decoration: const InputDecoration(
                  labelText: 'Option',
                  hintText: 'e.g. Home, Work, Social',
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
              child: const Text('Add'),
            ),
          ],
        ),
        SizedBox(height: tokens.spaceSm),
        if (choices.isEmpty)
          Text(
            'Add at least one option.',
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
                      decoration: const InputDecoration(labelText: 'Label'),
                      onChanged: (value) => onUpdate(i, value),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove',
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
    final controller = TextEditingController(
      text: value == null ? '' : value.toString(),
    );
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      onChanged: (value) {
        final parsed = int.tryParse(value);
        onChanged(parsed);
      },
    );
  }
}
