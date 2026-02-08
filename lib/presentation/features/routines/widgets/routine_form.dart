import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/shared/utils/form_utils.dart';
import 'package:taskly_bloc/presentation/shared/utils/debouncer.dart';
import 'package:taskly_bloc/presentation/shared/validation/form_builder_validator_adapter.dart';
import 'package:taskly_bloc/presentation/widgets/icon_picker/icon_catalog.dart';
import 'package:taskly_bloc/presentation/widgets/values_alignment/values_alignment_sheet.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_ui/taskly_ui_forms.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class RoutineForm extends StatefulWidget {
  const RoutineForm({
    required this.formKey,
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
  static const _draftSyncDebounce = Duration(milliseconds: 400);

  late RoutineType _currentType;
  final _scrollController = ScrollController();
  final GlobalKey<State<StatefulWidget>> _valueKey = GlobalKey();
  final Debouncer _draftSyncDebouncer = Debouncer(_draftSyncDebounce);
  bool _submitEnabled = false;

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
      RoutineType.monthlyFixed => RoutineType.monthlyFlexible,
      _ => rawType,
    };
  }

  @override
  void dispose() {
    _draftSyncDebouncer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onRoutineTypeChanged(
    FormFieldState<RoutineType> field,
    RoutineType next,
  ) {
    field.didChange(next);
    setState(() {
      _currentType = next;
    });
    if (next == RoutineType.weeklyFixed) {
      final days =
          (widget
                  .formKey
                  .currentState
                  ?.fields[RoutineFieldKeys.scheduleDays.id]
                  ?.value
              as List<int>?) ??
          const <int>[];
      final count = days.isEmpty ? null : days.length;
      widget.formKey.currentState?.fields[RoutineFieldKeys.targetCount.id]
          ?.didChange(count);
    } else {
      widget.formKey.currentState?.fields[RoutineFieldKeys.scheduleDays.id]
          ?.didChange(const <int>[]);
    }
    _markDirtySafely();
  }

  void _markDirtySafely() {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        markDirty();
      });
      return;
    }
    markDirty();
  }

  void _handleFormChanged() {
    _markDirtySafely();
    _scheduleDraftSync();
    _refreshSubmitEnabled();
  }

  void _scheduleDraftSync() {
    final onChanged = widget.onChanged;
    if (onChanged == null) return;
    _draftSyncDebouncer.schedule(() {
      if (!mounted) return;
      final values = widget.formKey.currentState?.value;
      if (values != null) {
        onChanged(values);
      }
    });
  }

  void _refreshSubmitEnabled() {
    final next = isDirty && (widget.formKey.currentState?.isValid ?? false);
    if (next == _submitEnabled || !mounted) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _submitEnabled = next);
      });
      return;
    }
    setState(() => _submitEnabled = next);
  }

  bool _isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 600;

  Rect _anchorRect(BuildContext anchorContext) {
    final box = anchorContext.findRenderObject()! as RenderBox;
    final topLeft = box.localToGlobal(Offset.zero);
    return topLeft & box.size;
  }

  Future<T?> _showAnchoredDialog<T>(
    BuildContext context, {
    required BuildContext anchorContext,
    required WidgetBuilder builder,
    double maxWidth = 420,
    double maxHeight = 520,
  }) {
    final anchor = _anchorRect(anchorContext);
    final theme = Theme.of(context);

    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: theme.colorScheme.surface.withValues(alpha: 0),
      pageBuilder: (dialogContext, _, __) {
        return Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(dialogContext).maybePop(),
              child: ColoredBox(
                color: theme.colorScheme.surface.withValues(alpha: 0),
              ),
            ),
            CustomSingleChildLayout(
              delegate: _AnchoredDialogLayoutDelegate(
                anchor: anchor,
                margin: EdgeInsets.all(TasklyTokens.of(context).spaceLg),
                maxWidth: maxWidth,
                maxHeight: maxHeight,
              ),
              child: Material(
                elevation: 6,
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    TasklyTokens.of(context).radiusMd,
                  ),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.6,
                    ),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: builder(dialogContext),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<List<String>?> _showValuePicker({
    required BuildContext anchorContext,
    required List<String> valueIds,
  }) {
    final l10n = context.l10n;

    if (_isCompact(context)) {
      return showModalBottomSheet<List<String>>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (context) => ValuesAlignmentSheet.singleValue(
          availableValues: widget.availableValues,
          valueIds: valueIds,
          title: l10n.routineFormValueLabel,
          helperText: l10n.routineFormValueHint,
        ),
      );
    }

    return _showAnchoredDialog<List<String>>(
      context,
      anchorContext: anchorContext,
      maxWidth: 520,
      maxHeight: 560,
      builder: (dialogContext) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ValuesAlignmentSheet.singleValue(
          availableValues: widget.availableValues,
          valueIds: valueIds,
          title: l10n.routineFormValueLabel,
          helperText: l10n.routineFormValueHint,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isCreating = widget.initialData == null;
    final preset = TasklyFormPreset.standard(TasklyTokens.of(context));

    final RoutineDraft? draft = widget.initialData == null
        ? (widget.initialDraft ?? RoutineDraft.empty())
        : null;

    final scheduleDays =
        widget.initialData?.scheduleDays ?? draft?.scheduleDays ?? <int>[];
    final initialTargetCount =
        widget.initialData?.targetCount ?? draft?.targetCount;
    final resolvedScheduleDays = _currentType == RoutineType.weeklyFixed
        ? scheduleDays
        : <int>[];
    final resolvedTargetCount = _currentType == RoutineType.weeklyFixed
        ? (scheduleDays.isNotEmpty ? scheduleDays.length : initialTargetCount)
        : initialTargetCount;

    final initialValues = <String, dynamic>{
      RoutineFieldKeys.name.id:
          widget.initialData?.name.trim() ?? draft?.name.trim() ?? '',
      RoutineFieldKeys.valueId.id:
          widget.initialData?.valueId ?? draft?.valueId ?? '',
      RoutineFieldKeys.routineType.id: _currentType,
      RoutineFieldKeys.targetCount.id: resolvedTargetCount,
      RoutineFieldKeys.scheduleDays.id: resolvedScheduleDays,
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

    final submitEnabled = _submitEnabled;

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
          onChanged: _handleFormChanged,
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
              TasklyFormSectionLabel(text: l10n.routineFormValueLabel),
              SizedBox(height: TasklyTokens.of(context).spaceSm),
              FormBuilderField<String>(
                name: RoutineFieldKeys.valueId.id,
                validator: toFormBuilderValidator<String>(
                  RoutineValidators.valueId,
                  context,
                ),
                builder: (field) {
                  final selectedValue = widget.availableValues
                      .where((value) => value.id == field.value)
                      .firstOrNull;
                  final label =
                      selectedValue?.name ?? l10n.routineFormValueHint;
                  final iconName = selectedValue?.iconName;
                  final iconData = iconName == null
                      ? Icons.star
                      : (getIconDataFromName(iconName) ?? Icons.star);

                  return KeyedSubtree(
                    key: _valueKey,
                    child: Builder(
                      builder: (chipContext) => TasklyFormProjectRow(
                        label: label,
                        hasValue: selectedValue != null,
                        icon: iconData,
                        onTap: () async {
                          final currentId = (field.value ?? '').trim();
                          final valueIds = currentId.isEmpty
                              ? const <String>[]
                              : <String>[currentId];

                          final result = await _showValuePicker(
                            anchorContext: chipContext,
                            valueIds: valueIds,
                          );
                          if (result == null) return;

                          field.didChange(result.isEmpty ? '' : result.first);
                          _markDirtySafely();
                          setState(() {});
                        },
                      ),
                    ),
                  );
                },
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
                        label: l10n.routineTypeWeeklyScheduled,
                        selected: current == RoutineType.weeklyFixed,
                        onTap: () => _onRoutineTypeChanged(
                          field,
                          RoutineType.weeklyFixed,
                        ),
                      ),
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
              if (_currentType == RoutineType.weeklyFixed) ...[
                TasklyFormSectionLabel(
                  text: l10n.routineFormScheduledDaysLabel,
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
                  onChanged: (value) {
                    final count = value.isEmpty ? null : value.length;
                    final fieldState = widget
                        .formKey
                        .currentState
                        ?.fields[RoutineFieldKeys.targetCount.id];
                    if (fieldState?.value != count) {
                      fieldState?.didChange(count);
                    }
                  },
                ),
                SizedBox(height: TasklyTokens.of(context).spaceSm),
                FormBuilderField<int>(
                  name: RoutineFieldKeys.targetCount.id,
                  builder: (_) => const SizedBox.shrink(),
                  validator: toFormBuilderValidator<int>(
                    (value) => RoutineValidators.targetCount(
                      value,
                      routineType: _currentType,
                    ),
                    context,
                  ),
                ),
              ],
              if (_currentType == RoutineType.weeklyFlexible) ...[
                _TargetCountField(
                  name: RoutineFieldKeys.targetCount.id,
                  label: l10n.routineFormTargetWeeklyLabel,
                  options: const [1, 2, 3, 4, 5, 6, 7],
                  routineType: _currentType,
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

class _AnchoredDialogLayoutDelegate extends SingleChildLayoutDelegate {
  _AnchoredDialogLayoutDelegate({
    required this.anchor,
    required this.margin,
    required this.maxWidth,
    required this.maxHeight,
  });

  final Rect anchor;
  final EdgeInsets margin;
  final double maxWidth;
  final double maxHeight;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final maxW = (constraints.maxWidth - margin.horizontal).clamp(
      0.0,
      maxWidth,
    );
    final maxH = (constraints.maxHeight - margin.vertical).clamp(
      0.0,
      maxHeight,
    );
    return BoxConstraints(
      maxWidth: maxW,
      maxHeight: maxH,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final availableBelow = size.height - anchor.bottom - margin.bottom;
    final availableAbove = anchor.top - margin.top;

    final showBelow =
        availableBelow >= childSize.height || availableBelow >= availableAbove;

    final y = showBelow
        ? (anchor.bottom + 6).clamp(margin.top, size.height - margin.bottom)
        : (anchor.top - childSize.height - 6).clamp(
            margin.top,
            size.height - margin.bottom,
          );

    final desiredX = anchor.left;
    final x = desiredX.clamp(
      margin.left,
      size.width - margin.right - childSize.width,
    );

    return Offset(x, y);
  }

  @override
  bool shouldRelayout(covariant _AnchoredDialogLayoutDelegate oldDelegate) {
    return anchor != oldDelegate.anchor ||
        margin != oldDelegate.margin ||
        maxWidth != oldDelegate.maxWidth ||
        maxHeight != oldDelegate.maxHeight;
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
    this.onChanged,
  });

  final String name;
  final TasklyFormPreset preset;
  final String? Function(List<int>?)? validator;
  final ValueChanged<List<int>>? onChanged;

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
                onChanged?.call(sorted);
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
