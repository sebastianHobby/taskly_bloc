import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/shared/utils/form_utils.dart';
import 'package:taskly_bloc/presentation/shared/validation/form_builder_validator_adapter.dart';
import 'package:taskly_bloc/presentation/widgets/form_fields/form_builder_project_picker_modern.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_ui/taskly_ui_forms.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class RoutineForm extends StatefulWidget {
  const RoutineForm({
    required this.formKey,
    required this.availableProjects,
    required this.availableValues,
    required this.onSubmit,
    required this.submitTooltip,
    this.initialData,
    this.initialDraft,
    this.onChanged,
    this.onDelete,
    this.onClose,
    super.key,
  });

  final GlobalKey<FormBuilderState> formKey;
  final List<Project> availableProjects;
  final List<Value> availableValues;
  final VoidCallback onSubmit;
  final String submitTooltip;
  final Routine? initialData;
  final RoutineDraft? initialDraft;
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final VoidCallback? onDelete;
  final VoidCallback? onClose;

  @override
  State<RoutineForm> createState() => _RoutineFormState();
}

class _RoutineFormState extends State<RoutineForm> with FormDirtyStateMixin {
  late RoutineType _currentType;
  final _scrollController = ScrollController();

  @override
  VoidCallback? get onClose => widget.onClose;

  @override
  void initState() {
    super.initState();
    final routine = widget.initialData;
    final draft = widget.initialDraft;
    final rawType =
        routine?.routineType ??
        draft?.routineType ??
        RoutineType.weeklyFlexible;
    _currentType = switch (rawType) {
      RoutineType.weeklyFixed => RoutineType.weeklyFlexible,
      RoutineType.monthlyFixed => RoutineType.monthlyFlexible,
      _ => rawType,
    };
  }

  void _onRoutineTypeChanged(
    FormFieldState<RoutineType> field,
    RoutineType next,
  ) {
    field.didChange(next);
    setState(() {
      _currentType = next;
    });
    markDirty();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isCreating = widget.initialData == null;
    final preset = TasklyFormPreset.standard(TasklyTokens.of(context));

    final RoutineDraft? draft = widget.initialData == null
        ? (widget.initialDraft ?? RoutineDraft.empty())
        : null;

    final initialValues = <String, dynamic>{
      RoutineFieldKeys.name.id:
          widget.initialData?.name.trim() ?? draft?.name.trim() ?? '',
      RoutineFieldKeys.valueId.id:
          widget.initialData?.valueId ?? draft?.valueId ?? '',
      RoutineFieldKeys.projectId.id:
          widget.initialData?.projectId ?? draft?.projectId ?? '',
      RoutineFieldKeys.routineType.id: _currentType,
      RoutineFieldKeys.targetCount.id:
          widget.initialData?.targetCount ?? draft?.targetCount,
      RoutineFieldKeys.scheduleDays.id:
          widget.initialData?.scheduleDays ?? draft?.scheduleDays ?? <int>[],
      RoutineFieldKeys.minSpacingDays.id:
          widget.initialData?.minSpacingDays ?? draft?.minSpacingDays,
      RoutineFieldKeys.restDayBuffer.id:
          widget.initialData?.restDayBuffer ?? draft?.restDayBuffer,
      RoutineFieldKeys.preferredWeeks.id:
          widget.initialData?.preferredWeeks ??
          draft?.preferredWeeks ??
          <int>[],
      RoutineFieldKeys.fixedDayOfMonth.id:
          widget.initialData?.fixedDayOfMonth ?? draft?.fixedDayOfMonth,
      RoutineFieldKeys.fixedWeekday.id:
          widget.initialData?.fixedWeekday ?? draft?.fixedWeekday,
      RoutineFieldKeys.fixedWeekOfMonth.id:
          widget.initialData?.fixedWeekOfMonth ?? draft?.fixedWeekOfMonth,
      RoutineFieldKeys.isActive.id:
          widget.initialData?.isActive ?? draft?.isActive ?? true,
    };

    final submitEnabled =
        isDirty && (widget.formKey.currentState?.isValid ?? false);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final headerActionStyle = TextButton.styleFrom(
      textStyle: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
    final headerTitle = Text(
      isCreating ? l10n.routineFormNewTitle : l10n.routineFormEditTitle,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );

    return FormShell(
      onSubmit: widget.onSubmit,
      submitTooltip: l10n.saveLabel,
      submitIcon: isCreating ? Icons.add : Icons.check,
      submitEnabled: submitEnabled,
      showHeaderSubmit: false,
      showFooterSubmit: false,
      closeOnLeft: false,
      onDelete: null,
      deleteTooltip: l10n.routineDeleteTitle,
      onClose: null,
      closeTooltip: l10n.closeLabel,
      scrollController: _scrollController,
      headerTitle: headerTitle,
      centerHeaderTitle: true,
      leadingActions: [
        if (widget.onClose != null)
          TextButton(
            onPressed: handleClose,
            style: headerActionStyle,
            child: Text(l10n.cancelLabel),
          ),
      ],
      trailingActions: [
        if (widget.initialData != null && widget.onDelete != null)
          PopupMenuButton<int>(
            tooltip: l10n.moreOptionsLabel,
            itemBuilder: (context) => [
              PopupMenuItem<int>(
                value: 0,
                child: Text(
                  l10n.routineDeleteTitle,
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            ],
            onSelected: (_) => widget.onDelete?.call(),
          ),
        Tooltip(
          message: widget.submitTooltip,
          child: TextButton(
            onPressed: submitEnabled ? widget.onSubmit : null,
            style: headerActionStyle.copyWith(
              foregroundColor: WidgetStateProperty.resolveWith<Color?>(
                (states) => states.contains(WidgetState.disabled)
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.primary,
              ),
            ),
            child: Text(l10n.saveLabel),
          ),
        ),
      ],
      child: Padding(
        padding: EdgeInsets.only(bottom: TasklyTokens.of(context).spaceSm),
        child: FormBuilder(
          key: widget.formKey,
          initialValue: initialValues,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: () {
            markDirty();
            setState(() {});
            final values = widget.formKey.currentState?.value;
            if (values != null) {
              widget.onChanged?.call(values);
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: TasklyTokens.of(context).spaceSm),
              FormBuilderTextField(
                name: RoutineFieldKeys.name.id,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                maxLength: RoutineValidators.maxNameLength,
                decoration:
                    const InputDecoration(
                      border: InputBorder.none,
                      hintText: '',
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ).copyWith(
                      hintText: l10n.routineFormNameHint,
                    ),
                validator: toFormBuilderValidator<String>(
                  RoutineValidators.name,
                  context,
                ),
              ),
              SizedBox(height: TasklyTokens.of(context).spaceSm),
              FormBuilderDropdown<String>(
                name: RoutineFieldKeys.valueId.id,
                items: [
                  for (final value in widget.availableValues)
                    DropdownMenuItem(
                      value: value.id,
                      child: Text(value.name),
                    ),
                ],
                decoration: InputDecoration(
                  labelText: l10n.routineFormValueLabel,
                  hintText: l10n.routineFormValueHint,
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      TasklyTokens.of(context).radiusMd,
                    ),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: toFormBuilderValidator<String>(
                  RoutineValidators.valueId,
                  context,
                ),
              ),
              SizedBox(height: TasklyTokens.of(context).spaceSm),
              FormBuilderProjectPickerModern(
                name: RoutineFieldKeys.projectId.id,
                availableProjects: widget.availableProjects,
                label: l10n.routineFormProjectLabel,
                hint: l10n.routineFormProjectHint,
                allowNoProject: true,
                noProjectText: l10n.routineFormProjectNone,
              ),
              SizedBox(height: TasklyTokens.of(context).spaceSm),
              TasklyFormSectionLabel(text: l10n.routineFormTypeLabel),
              SizedBox(height: TasklyTokens.of(context).spaceSm),
              FormBuilderField<RoutineType>(
                name: RoutineFieldKeys.routineType.id,
                builder: (field) {
                  final current = field.value ?? _currentType;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _RoutineTypeChip(
                        label: l10n.routineTypeWeeklyFlexible,
                        selected: current == RoutineType.weeklyFlexible,
                        onTap: () => _onRoutineTypeChanged(
                          field,
                          RoutineType.weeklyFlexible,
                        ),
                      ),
                      _RoutineTypeChip(
                        label: l10n.routineTypeMonthlyFlexible,
                        selected: current == RoutineType.monthlyFlexible,
                        onTap: () => _onRoutineTypeChanged(
                          field,
                          RoutineType.monthlyFlexible,
                        ),
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: TasklyTokens.of(context).spaceSm),
              if (_currentType == RoutineType.weeklyFlexible) ...[
                _TargetCountField(
                  name: RoutineFieldKeys.targetCount.id,
                  label: l10n.routineFormTargetWeeklyLabel,
                  options: const [1, 2, 3, 4, 5, 6, 7],
                  routineType: _currentType,
                ),
                SizedBox(height: TasklyTokens.of(context).spaceSm),
                TasklyFormSectionLabel(
                  text: l10n.routineFormSuggestedDaysLabel,
                ),
                SizedBox(height: TasklyTokens.of(context).spaceSm),
                _MultiSelectWeekdaysField(
                  name: RoutineFieldKeys.scheduleDays.id,
                  preset: preset,
                  validator: toFormBuilderValidator<List<int>>(
                    (value) => RoutineValidators.scheduleDays(
                      value ?? const [],
                      routineType: _currentType,
                    ),
                    context,
                  ),
                ),
                SizedBox(height: TasklyTokens.of(context).spaceSm),
              ],
              if (_currentType == RoutineType.monthlyFlexible) ...[
                _TargetCountField(
                  name: RoutineFieldKeys.targetCount.id,
                  label: l10n.routineFormTargetMonthlyLabel,
                  options: const [1, 2, 3, 4],
                  routineType: _currentType,
                ),
                SizedBox(height: TasklyTokens.of(context).spaceSm),
                TasklyFormSectionLabel(
                  text: l10n.routineFormPreferredWeeksLabel,
                ),
                SizedBox(height: TasklyTokens.of(context).spaceSm),
                _MultiSelectWeeksField(
                  name: RoutineFieldKeys.preferredWeeks.id,
                  preset: preset,
                  validator: toFormBuilderValidator<List<int>>(
                    (value) => RoutineValidators.preferredWeeks(
                      value ?? const [],
                      routineType: _currentType,
                    ),
                    context,
                  ),
                ),
                SizedBox(height: TasklyTokens.of(context).spaceSm),
              ],
              FormBuilderSwitch(
                name: RoutineFieldKeys.isActive.id,
                title: Text(l10n.routineFormActiveLabel),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoutineTypeChip extends StatelessWidget {
  const _RoutineTypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: scheme.primaryContainer,
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
      ),
    );
  }
}

class _TargetCountField extends StatelessWidget {
  const _TargetCountField({
    required this.name,
    required this.label,
    required this.options,
    required this.routineType,
  });

  final String name;
  final String label;
  final List<int> options;
  final RoutineType routineType;

  @override
  Widget build(BuildContext context) {
    return FormBuilderDropdown<int>(
      name: name,
      items: [
        for (final value in options)
          DropdownMenuItem<int>(
            value: value,
            child: Text(value.toString()),
          ),
      ],
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            TasklyTokens.of(context).radiusMd,
          ),
          borderSide: BorderSide.none,
        ),
      ),
      validator: toFormBuilderValidator<int>(
        (value) => RoutineValidators.targetCount(
          value,
          routineType: routineType,
        ),
        context,
      ),
    );
  }
}

class _MultiSelectWeekdaysField extends StatelessWidget {
  const _MultiSelectWeekdaysField({
    required this.name,
    required this.preset,
    this.validator,
  });

  final String name;
  final TasklyFormPreset preset;
  final String? Function(List<int>?)? validator;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final formatter = DateFormat.E(locale);
    final weekdays = [
      for (var i = 0; i < 7; i++)
        formatter.format(DateTime.utc(2024, 1, 1 + i)),
    ];

    return FormBuilderField<List<int>>(
      name: name,
      validator: validator,
      builder: (field) {
        final selected = (field.value ?? const <int>[]).toSet();
        final chips = <TasklyFormQuickPickItem>[];

        for (var i = 0; i < weekdays.length; i++) {
          final day = i + 1;
          chips.add(
            TasklyFormQuickPickItem(
              label: weekdays[i],
              emphasized: selected.contains(day),
              onTap: () {
                final updated = Set<int>.from(selected);
                if (!updated.add(day)) {
                  updated.remove(day);
                }
                final sorted = updated.toList()..sort();
                field.didChange(sorted);
              },
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TasklyFormQuickPickChips(items: chips, preset: preset),
            if (field.errorText != null) ...[
              SizedBox(height: TasklyTokens.of(context).spaceSm),
              Text(
                field.errorText!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _MultiSelectWeeksField extends StatelessWidget {
  const _MultiSelectWeeksField({
    required this.name,
    required this.preset,
    this.validator,
  });

  final String name;
  final TasklyFormPreset preset;
  final String? Function(List<int>?)? validator;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final labels = [
      l10n.routineWeek1Label,
      l10n.routineWeek2Label,
      l10n.routineWeek3Label,
      l10n.routineWeek4Label,
      l10n.routineWeekLastLabel,
    ];

    return FormBuilderField<List<int>>(
      name: name,
      validator: validator,
      builder: (field) {
        final selected = (field.value ?? const <int>[]).toSet();
        final chips = <TasklyFormQuickPickItem>[];

        for (var i = 0; i < labels.length; i++) {
          final week = i + 1;
          chips.add(
            TasklyFormQuickPickItem(
              label: labels[i],
              emphasized: selected.contains(week),
              onTap: () {
                final updated = Set<int>.from(selected);
                if (!updated.add(week)) {
                  updated.remove(week);
                }
                final sorted = updated.toList()..sort();
                field.didChange(sorted);
              },
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TasklyFormQuickPickChips(items: chips, preset: preset),
            if (field.errorText != null) ...[
              SizedBox(height: TasklyTokens.of(context).spaceSm),
              Text(
                field.errorText!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
