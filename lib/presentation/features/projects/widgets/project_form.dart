import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
// import 'package:taskly_bloc/presentation/widgets/form_fields/form_builder_tag_picker.dart'; // Removed
import 'package:taskly_bloc/presentation/shared/utils/date_display_utils.dart';
import 'package:taskly_bloc/presentation/shared/utils/form_utils.dart';
import 'package:taskly_bloc/presentation/shared/utils/rrule_label_utils.dart';
import 'package:taskly_bloc/presentation/shared/validation/form_builder_validator_adapter.dart';
import 'package:taskly_bloc/presentation/widgets/recurrence_picker.dart';
import 'package:taskly_bloc/presentation/widgets/values_alignment/values_alignment_sheet.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_bloc/presentation/widgets/icon_picker/icon_catalog.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/time.dart';
import 'package:taskly_ui/taskly_ui_forms.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';


/// A modern form for creating or editing projects.
///
/// Features:
/// - Action buttons in header (always visible)
/// - Unsaved changes confirmation on close
/// - Clear cancel/close affordance
class ProjectForm extends StatefulWidget {
  const ProjectForm({
    required this.formKey,
    required this.initialData,
    required this.onSubmit,
    required this.submitTooltip,
    this.onChanged,
    this.availableValues = const <Value>[],
    this.openToValues = false,
    this.onDelete,
    this.onTogglePinned,
    this.onClose,
    this.trailingActions = const <Widget>[],
    super.key,
  });


  final GlobalKey<FormBuilderState> formKey;
  final VoidCallback onSubmit;
  final String submitTooltip;
  final Project? initialData;
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final List<Value> availableValues;


  /// When true, scrolls to the values section and opens the values alignment
  /// sheet on first build.
  final bool openToValues;
  final VoidCallback? onDelete;


  /// Called when the user toggles pinned state from the header.
  ///
  /// Only shown when editing (initialData != null).
  final ValueChanged<bool>? onTogglePinned;


  /// Called when the user wants to close the form.
  /// If null, no close button is shown.
  final VoidCallback? onClose;


  /// Optional action widgets to render in the header row (right side).
  final List<Widget> trailingActions;


  @override
  State<ProjectForm> createState() => _ProjectFormState();
}


class _ProjectFormState extends State<ProjectForm> with FormDirtyStateMixin {
  @override
  VoidCallback? get onClose => widget.onClose;


  final _scrollController = ScrollController();
  final GlobalKey<State<StatefulWidget>> _valuesKey = GlobalKey();
  bool _didAutoOpen = false;
  String? _recurrenceLabel;
  String? _lastRecurrenceRrule;

  void _scheduleRecurrenceLabelUpdate(String? rrule) {
    final normalized = (rrule ?? '').trim();
    if (normalized == _lastRecurrenceRrule) return;
    _lastRecurrenceRrule = normalized;

    if (normalized.isEmpty) {
      setState(() {
        _recurrenceLabel = null;
      });
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final label = await resolveRruleLabel(context, normalized);
      if (!mounted) return;
      setState(() {
        _recurrenceLabel = label;
      });
    });
  }

  @override
  void initState() {
    super.initState();


    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _didAutoOpen) return;
      if (!widget.openToValues) return;
      _didAutoOpen = true;


      final ctx = _valuesKey.currentContext;
      if (ctx != null) {
        await Scrollable.ensureVisible(
          ctx,
          alignment: 0.1,
          duration: const Duration(milliseconds: 220),
        );
        if (!ctx.mounted) return;
      }
      if (!mounted) return;


      final current = widget
          .formKey
          .currentState
          ?.fields[ProjectFieldKeys.valueIds.id]
          ?.value;
      final valueIds = List<String>.of(current as List<String>? ?? const []);


      final anchorContext = _valuesKey.currentContext;
      if (anchorContext == null || !mounted) return;


      final result = await _showValuesAlignmentPicker(
        anchorContext: anchorContext,
        valueIds: valueIds,
      );
      if (!mounted || result == null) return;


      widget.formKey.currentState?.fields[ProjectFieldKeys.valueIds.id]
          ?.didChange(result);
      markDirty();
      setState(() {});
    });
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
                margin: const EdgeInsets.all(8),
                maxWidth: maxWidth,
                maxHeight: maxHeight,
              ),
              child: Material(
                elevation: 6,
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
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


  Future<List<String>?> _showValuesAlignmentPicker({
    required BuildContext anchorContext,
    required List<String> valueIds,
  }) {
    if (_isCompact(context)) {
      return showValuesAlignmentSheetForProject(
        context,
        availableValues: widget.availableValues,
        valueIds: valueIds,
      );
    }


    return _showAnchoredDialog<List<String>>(
      context,
      anchorContext: anchorContext,
      maxWidth: 520,
      maxHeight: 560,
      builder: (dialogContext) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ValuesAlignmentSheet.project(
          availableValues: widget.availableValues,
          valueIds: valueIds,
        ),
      ),
    );
  }


  Future<_NullableDateDecision?> _pickDate({
    required BuildContext anchorContext,
    required String title,
    required DateTime? initialDate,
  }) {
    if (_isCompact(context)) {
      return showModalBottomSheet<_NullableDateDecision>(
        context: context,
        useSafeArea: true,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (sheetContext) => _ProjectDatePickerPanel(
          title: title,
          initialDate: initialDate,
        ),
      );
    }


    return _showAnchoredDialog<_NullableDateDecision>(
      context,
      anchorContext: anchorContext,
      maxWidth: 360,
      maxHeight: 520,
      builder: (dialogContext) => _ProjectDatePickerPanel(
        title: title,
        initialDate: initialDate,
      ),
    );
  }



  Future<RecurrencePickerResult?> _pickRecurrence({
    required BuildContext anchorContext,
    required String? initialRrule,
    required bool initialRepeatFromCompletion,
    required bool initialSeriesEnded,
  }) {
    final picker = RecurrencePicker(
      initialRRule: initialRrule,
      initialRepeatFromCompletion: initialRepeatFromCompletion,
      initialSeriesEnded: initialSeriesEnded,
    );


    if (_isCompact(context)) {
      return showModalBottomSheet<RecurrencePickerResult>(
        context: context,
        useSafeArea: true,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (sheetContext) => picker,
      );
    }


    return _showAnchoredDialog<RecurrencePickerResult>(
      context,
      anchorContext: anchorContext,
      maxWidth: 520,
      maxHeight: 640,
      builder: (dialogContext) => picker,
    );
  }


  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCompact = _isCompact(context);
    final isCreating = widget.initialData == null;


    final availableValuesById = <String, Value>{
      for (final v in widget.availableValues) v.id: v,
    };


    final initialValues = <String, dynamic>{
      ProjectFieldKeys.name.id: widget.initialData?.name.trim() ?? '',
      ProjectFieldKeys.description.id: widget.initialData?.description ?? '',
      ProjectFieldKeys.completed.id: widget.initialData?.completed ?? false,
      ProjectFieldKeys.startDate.id: widget.initialData?.startDate,
      ProjectFieldKeys.deadlineDate.id: widget.initialData?.deadlineDate,
      ProjectFieldKeys.priority.id: widget.initialData?.priority,
      ProjectFieldKeys.valueIds.id:
          (widget.initialData?.values ?? <Value>[]) // Use values property
              .map((Value e) => e.id)
              .toList(growable: false),
      ProjectFieldKeys.repeatIcalRrule.id:
          widget.initialData?.repeatIcalRrule ?? '',
      ProjectFieldKeys.repeatFromCompletion.id:
          widget.initialData?.repeatFromCompletion ?? false,
      ProjectFieldKeys.seriesEnded.id: widget.initialData?.seriesEnded ?? false,
    };


    final submitEnabled =
        isDirty && (widget.formKey.currentState?.isValid ?? false);

    final denseFieldPadding = EdgeInsets.symmetric(
      horizontal: isCompact ? 12 : 16,
      vertical: isCompact ? 10 : 12,
    );


    return FormShell(
      onSubmit: widget.onSubmit,
      submitTooltip: isCreating ? l10n.actionCreate : l10n.actionUpdate,
      submitIcon: isCreating ? Icons.add : Icons.check,
      submitEnabled: submitEnabled,
      showHeaderSubmit: true,
      showFooterSubmit: false,
      closeOnLeft: true,
      onDelete: widget.initialData != null ? widget.onDelete : null,
      deleteTooltip: l10n.deleteProjectAction,
      onClose: widget.onClose != null ? handleClose : null,
      closeTooltip: l10n.closeLabel,
      scrollController: _scrollController,
      leadingActions: [
        if (widget.initialData != null && widget.onTogglePinned != null)
          IconButton(
            onPressed: () {
              final nextPinned = !(widget.initialData?.isPinned ?? false);
              widget.onTogglePinned?.call(nextPinned);
            },
            icon: Icon(
              (widget.initialData?.isPinned ?? false)
                  ? Icons.push_pin
                  : Icons.push_pin_outlined,
              color: (widget.initialData?.isPinned ?? false)
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            tooltip: (widget.initialData?.isPinned ?? false)
                ? l10n.unpinAction
                : l10n.pinAction,
          ),
      ],
      trailingActions: widget.trailingActions,
      child: Padding(
        padding: EdgeInsets.only(bottom: isCompact ? 16 : 24),
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
              // Project Name
              FormBuilderTextField(
                name: ProjectFieldKeys.name.id,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                decoration: InputDecoration(
                  hintText: l10n.projectFormTitleHint,
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: denseFieldPadding,
                ),
                validator: toFormBuilderValidator<String>(
                  ProjectValidators.name,
                  context,
                ),
              ),


              // Project Description
              FormBuilderTextField(
                name: ProjectFieldKeys.description.id,
                textInputAction: TextInputAction.newline,
                maxLines: isCompact ? 2 : 3,
                minLines: isCompact ? 1 : 2,
                decoration: InputDecoration(
                  hintText: l10n.projectFormDescriptionHint,
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: denseFieldPadding,
                ),
                validator: toFormBuilderValidator<String>(
                  ProjectValidators.description,
                  context,
                ),
              ),


              SizedBox(height: isCompact ? 6 : 8),


              // Completed
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FormBuilderField<bool>(
                  name: ProjectFieldKeys.completed.id,
                  builder: (field) {
                    return CheckboxListTile.adaptive(
                      value: field.value ?? false,
                      onChanged: (value) {
                        field.didChange(value);
                        markDirty();
                      },
                      title: Text(l10n.projectCompletedLabel),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  },
                ),
              ),


              // Meta chips row (values-first): Values, Planned Day, Due Date,
              // Priority, Repeat
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TasklyFormSectionLabel(text: l10n.valuesAlignedToTitle),
                    const SizedBox(height: 8),
                    TasklyFormRowGroup(
                      children: [
                        FormBuilderField<List<String>>(
                          name: ProjectFieldKeys.valueIds.id,
                          validator: toFormBuilderValidator<List<String>>(
                            ProjectValidators.valueIds,
                            context,
                          ),
                          builder: (field) {
                            final valueIds = List<String>.of(
                              field.value ?? const <String>[],
                            );
                            final effectiveIds = valueIds
                                .take(2)
                                .toList(
                                  growable: false,
                                );
                            final primary = effectiveIds.isEmpty
                                ? null
                                : availableValuesById[effectiveIds.first];
                            final secondary = effectiveIds.length < 2
                                ? null
                                : availableValuesById[effectiveIds[1]];

                            return Builder(
                              builder: (chipContext) {
                                Future<void> open() async {
                                  final result =
                                      await _showValuesAlignmentPicker(
                                        anchorContext: chipContext,
                                        valueIds: valueIds,
                                      );
                                  if (!mounted || result == null) return;
                                  field.didChange(result);
                                  markDirty();
                                  setState(() {});
                                }

                                TasklyFormValueChipModel toModel(Value value) {
                                  final iconData =
                                      getIconDataFromName(value.iconName) ??
                                      Icons.star;
                                  final color = ColorUtils
                                      .fromHexWithThemeFallback(
                                    context,
                                    value.color,
                                  );
                                  return TasklyFormValueChipModel(
                                    label: value.name,
                                    color: color,
                                    icon: iconData,
                                    semanticLabel: value.name,
                                  );
                                }

                                final theme = Theme.of(context);

                                return KeyedSubtree(
                                  key: _valuesKey,
                                  child: TasklyFormRowGroup(
                                    spacing: 12,
                                    runSpacing: 8,
                                    children: [
                                      TasklyFormValueChip(
                                        model: primary != null
                                            ? toModel(primary)
                                            : TasklyFormValueChipModel(
                                                label: context
                                                    .l10n
                                                    .valuesAlignedToTitle,
                                                color:
                                                    theme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                icon: Icons.favorite_outline,
                                                semanticLabel: context
                                                    .l10n
                                                    .valuesAlignedToTitle,
                                              ),
                                        onTap: open,
                                        isSelected: primary != null,
                                        isPrimary: true,
                                        preset: TasklyFormPreset.standard.chip,
                                      ),
                                      if (secondary != null)
                                        TasklyFormValueChip(
                                          model: toModel(secondary),
                                          onTap: open,
                                          isSelected: true,
                                          isPrimary: false,
                                          preset:
                                              TasklyFormPreset.standard.chip,
                                        ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                    Builder(
                      builder: (context) {
                        final errorText = widget
                            .formKey
                            .currentState
                            ?.fields[ProjectFieldKeys.valueIds.id]
                            ?.errorText;
                        if (errorText == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            errorText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Builder(
                      builder: (context) {
                        final startDate =
                            (widget
                                    .formKey
                                    .currentState
                                    ?.fields[ProjectFieldKeys.startDate.id]
                                    ?.value
                                as DateTime?) ??
                            (initialValues[ProjectFieldKeys.startDate.id]
                                as DateTime?);
                        final deadlineDate =
                            (widget
                                    .formKey
                                    .currentState
                                    ?.fields[ProjectFieldKeys.deadlineDate.id]
                                    ?.value
                                as DateTime?) ??
                            (initialValues[ProjectFieldKeys.deadlineDate.id]
                                as DateTime?);
                        final recurrenceRrule =
                            (widget
                                        .formKey
                                        .currentState
                                        ?.fields[ProjectFieldKeys
                                            .repeatIcalRrule
                                            .id]
                                        ?.value
                                    as String?) ??
                            (initialValues[ProjectFieldKeys.repeatIcalRrule.id]
                                as String?) ??
                            '';
                        final hasRecurrence = recurrenceRrule.trim().isNotEmpty;
                        _scheduleRecurrenceLabelUpdate(recurrenceRrule);

                        final plannedLabel = startDate == null
                            ? null
                            : DateDisplayUtils.formatMonthDayYear(startDate);
                        final dueLabel = deadlineDate == null
                            ? null
                            : DateDisplayUtils.formatMonthDayYear(deadlineDate);
                        final isOverdue = DateDisplayUtils.isOverdue(deadlineDate);

                        return TasklyFormDateCard(
                          rows: [
                            TasklyFormDateRow(
                              icon: Icons.calendar_today_rounded,
                              label: l10n.plannedLabel,
                              placeholderLabel: l10n.dateChipAddPlannedDay,
                              valueLabel: plannedLabel,
                              hasValue: plannedLabel != null,
                              onTap: () async {
                                final decision = await _pickDate(
                                  anchorContext: context,
                                  title: l10n.dateChipAddPlannedDay,
                                  initialDate: startDate,
                                );
                                if (!mounted || decision == null) {
                                  return;
                                }
                                if (decision.keep) return;
                                widget
                                    .formKey
                                    .currentState
                                    ?.fields[ProjectFieldKeys.startDate.id]
                                    ?.didChange(decision.date);
                                markDirty();
                                setState(() {});
                              },
                              onClear: plannedLabel != null
                                  ? () {
                                      widget
                                          .formKey
                                          .currentState
                                          ?.fields[ProjectFieldKeys
                                              .startDate
                                              .id]
                                          ?.didChange(null);
                                      markDirty();
                                      setState(() {});
                                    }
                                  : null,
                            ),
                            TasklyFormDateRow(
                              icon: Icons.flag_rounded,
                              label: l10n.dueLabel,
                              placeholderLabel: l10n.dateChipAddDueDate,
                              valueLabel: dueLabel,
                              hasValue: dueLabel != null,
                              valueColor: isOverdue
                                  ? colorScheme.error
                                  : colorScheme.primary,
                              onTap: () async {
                                final decision = await _pickDate(
                                  anchorContext: context,
                                  title: l10n.dateChipAddDueDate,
                                  initialDate: deadlineDate,
                                );
                                if (!mounted || decision == null) {
                                  return;
                                }
                                if (decision.keep) return;
                                widget
                                    .formKey
                                    .currentState
                                    ?.fields[ProjectFieldKeys.deadlineDate.id]
                                    ?.didChange(decision.date);
                                markDirty();
                                setState(() {});
                              },
                              onClear: dueLabel != null
                                  ? () {
                                      widget
                                          .formKey
                                          .currentState
                                          ?.fields[ProjectFieldKeys
                                              .deadlineDate
                                              .id]
                                          ?.didChange(null);
                                      markDirty();
                                      setState(() {});
                                    }
                                  : null,
                            ),
                            TasklyFormDateRow(
                              icon: Icons.repeat,
                              label: l10n.recurrenceRepeatTitle,
                              placeholderLabel: l10n.repeatAddLabel,
                              valueLabel: _recurrenceLabel ??
                                  (hasRecurrence ? l10n.loadingTitle : null),
                              hasValue: hasRecurrence,
                              onTap: () async {
                                final repeatFromCompletionField =
                                    widget
                                        .formKey
                                        .currentState
                                        ?.fields[ProjectFieldKeys
                                            .repeatFromCompletion
                                            .id];
                                final seriesEndedField =
                                    widget
                                        .formKey
                                        .currentState
                                        ?.fields[ProjectFieldKeys
                                            .seriesEnded
                                            .id];

                                final result = await _pickRecurrence(
                                  anchorContext: context,
                                  initialRrule: recurrenceRrule,
                                  initialRepeatFromCompletion:
                                      (repeatFromCompletionField?.value
                                          as bool?) ??
                                      false,
                                  initialSeriesEnded:
                                      (seriesEndedField?.value as bool?) ??
                                      false,
                                );
                                if (!mounted || result == null) return;

                                widget
                                    .formKey
                                    .currentState
                                    ?.fields[ProjectFieldKeys
                                        .repeatIcalRrule
                                        .id]
                                    ?.didChange(result.rrule);
                                repeatFromCompletionField?.didChange(
                                  result.repeatFromCompletion,
                                );
                                seriesEndedField?.didChange(
                                  result.seriesEnded,
                                );
                                markDirty();
                                setState(() {});
                              },
                              onClear: hasRecurrence
                                  ? () {
                                      widget
                                          .formKey
                                          .currentState
                                          ?.fields[ProjectFieldKeys
                                              .repeatIcalRrule
                                              .id]
                                          ?.didChange(null);
                                      widget
                                          .formKey
                                          .currentState
                                          ?.fields[ProjectFieldKeys
                                              .repeatFromCompletion
                                              .id]
                                          ?.didChange(false);
                                      widget
                                          .formKey
                                          .currentState
                                          ?.fields[ProjectFieldKeys
                                              .seriesEnded
                                              .id]
                                          ?.didChange(false);
                                      markDirty();
                                      setState(() {});
                                    }
                                  : null,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    TasklyFormSectionLabel(text: l10n.priorityLabel),
                    const SizedBox(height: 8),
                    FormBuilderField<int?>(
                      name: ProjectFieldKeys.priority.id,
                      builder: (field) {
                        return TasklyFormPrioritySegmented(
                          segments: [
                            TasklyFormPrioritySegment(
                              label: 'P1',
                              value: 1,
                              selectedColor: colorScheme.error,
                            ),
                            TasklyFormPrioritySegment(
                              label: 'P2',
                              value: 2,
                              selectedColor: colorScheme.tertiary,
                            ),
                            TasklyFormPrioritySegment(
                              label: 'P3',
                              value: 3,
                              selectedColor: colorScheme.primary,
                            ),
                            TasklyFormPrioritySegment(
                              label: 'P4',
                              value: 4,
                              selectedColor: colorScheme.onSurfaceVariant,
                            ),
                          ],
                          value: field.value,
                          onChanged: (value) {
                            field.didChange(value);
                            markDirty();
                            setState(() {});
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    FormBuilderField<DateTime?>(
                      name: ProjectFieldKeys.startDate.id,
                      builder: (_) => const SizedBox.shrink(),
                    ),
                    FormBuilderField<DateTime?>(
                      name: ProjectFieldKeys.deadlineDate.id,
                      builder: (_) => const SizedBox.shrink(),
                    ),
                    FormBuilderField<String?>(
                      name: ProjectFieldKeys.repeatIcalRrule.id,
                      builder: (_) => const SizedBox.shrink(),
                    ),

                    // Hidden recurrence flags fields (set by the picker)
                    FormBuilderField<bool>(
                      name: ProjectFieldKeys.repeatFromCompletion.id,
                      builder: (_) => const SizedBox.shrink(),
                    ),
                    FormBuilderField<bool>(
                      name: ProjectFieldKeys.seriesEnded.id,
                      builder: (_) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


final class _NullableDateDecision {
  const _NullableDateDecision.keep() : keep = true, date = null;


  const _NullableDateDecision.set(this.date) : keep = false;


  final bool keep;
  final DateTime? date;
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


class _ProjectDatePickerPanel extends StatefulWidget {
  const _ProjectDatePickerPanel({
    required this.title,
    required this.initialDate,
  });


  final String title;
  final DateTime? initialDate;


  @override
  State<_ProjectDatePickerPanel> createState() =>
      _ProjectDatePickerPanelState();
}


class _ProjectDatePickerPanelState extends State<_ProjectDatePickerPanel> {
  late DateTime _selected;


  @override
  void initState() {
    super.initState();
    final now = getIt<NowService>().nowLocal();
    _selected = widget.initialDate ?? now;
  }


  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final now = getIt<NowService>().nowLocal();
    final today = dateOnly(now);
    final tomorrow = today.add(const Duration(days: 1));
    final nextWeek = today.add(const Duration(days: 7));


    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 10),
          TasklyFormQuickPickChips(
            preset: TasklyFormPreset.standard,
            items: [
              TasklyFormQuickPickItem(
                label: l10n.dateToday,
                onTap: () => Navigator.of(context).pop(
                  _NullableDateDecision.set(today),
                ),
              ),
              TasklyFormQuickPickItem(
                label: l10n.dateTomorrow,
                onTap: () => Navigator.of(context).pop(
                  _NullableDateDecision.set(tomorrow),
                ),
              ),
              TasklyFormQuickPickItem(
                label: l10n.dateNextWeek,
                onTap: () => Navigator.of(context).pop(
                  _NullableDateDecision.set(nextWeek),
                ),
              ),
              TasklyFormQuickPickItem(
                label: l10n.sortFieldNoneLabel,
                emphasized: true,
                onTap: () => Navigator.of(context).pop(
                  const _NullableDateDecision.set(null),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            child: CalendarDatePicker(
              initialDate: _selected,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
              onDateChanged: (date) {
                setState(() => _selected = date);
                Navigator.of(context).pop(
                  _NullableDateDecision.set(dateOnly(date)),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(
              const _NullableDateDecision.keep(),
            ),
            child: Text(l10n.cancelLabel),
          ),
        ],
      ),
    );
  }
}








