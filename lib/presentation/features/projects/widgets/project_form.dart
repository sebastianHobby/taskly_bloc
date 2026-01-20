import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/widgets/form_fields/form_builder_priority_picker.dart';
// import 'package:taskly_bloc/presentation/widgets/form_fields/form_builder_tag_picker.dart'; // Removed
import 'package:taskly_bloc/presentation/shared/utils/form_utils.dart';
import 'package:taskly_bloc/presentation/widgets/form_date_chip.dart';
import 'package:taskly_bloc/presentation/widgets/recurrence_picker.dart';
import 'package:taskly_bloc/presentation/widgets/rrule_form_recurrence_chip.dart';
import 'package:taskly_bloc/presentation/widgets/values_alignment/values_alignment_sheet.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_bloc/presentation/widgets/icon_picker/icon_catalog.dart';
import 'package:taskly_domain/core.dart';
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
      }
      if (!mounted) return;

      final current = widget
          .formKey
          .currentState
          ?.fields[ProjectFieldKeys.valueIds.id]
          ?.value;
      final valueIds = List<String>.of(current as List<String>? ?? const []);

      final result = await showValuesAlignmentSheetForProject(
        context,
        availableValues: widget.availableValues,
        valueIds: valueIds,
      );
      if (!mounted || result == null) return;

      widget.formKey.currentState?.fields[ProjectFieldKeys.valueIds.id]
          ?.didChange(result);
      markDirty();
      setState(() {});
    });
  }

  Future<void> _showDatePicker(
    BuildContext context,
    DateTime? initialDate,
    ValueChanged<DateTime?> onDateSelected,
  ) async {
    final now = getIt<NowService>().nowLocal();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      onDateSelected(picked);
      markDirty();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isCompact = MediaQuery.sizeOf(context).width < 600;
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

    final effectiveStartDate =
        (widget
                .formKey
                .currentState
                ?.fields[ProjectFieldKeys.startDate.id]
                ?.value
            as DateTime?) ??
        (initialValues[ProjectFieldKeys.startDate.id] as DateTime?);
    final effectiveDeadlineDate =
        (widget
                .formKey
                .currentState
                ?.fields[ProjectFieldKeys.deadlineDate.id]
                ?.value
            as DateTime?) ??
        (initialValues[ProjectFieldKeys.deadlineDate.id] as DateTime?);
    final showScheduleHelper =
        effectiveStartDate == null && effectiveDeadlineDate == null;

    final submitEnabled =
        isDirty && (widget.formKey.currentState?.isValid ?? false);

    final sectionGap = isCompact ? 12.0 : 16.0;
    final denseFieldPadding = EdgeInsets.symmetric(
      horizontal: isCompact ? 12 : 16,
      vertical: isCompact ? 10 : 12,
    );

    const valuesWhyCopy = 'Helps Taskly prioritize and suggest the right work.';

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
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(
                    errorText: l10n.projectFormTitleRequired,
                  ),
                  FormBuilderValidators.minLength(
                    1,
                    errorText: l10n.projectFormTitleEmpty,
                  ),
                  FormBuilderValidators.maxLength(
                    120,
                    errorText: l10n.projectFormTitleTooLong,
                  ),
                ]),
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
                validator: FormBuilderValidators.maxLength(
                  200,
                  errorText: l10n.projectFormDescriptionTooLong,
                  checkNullOrEmpty: false,
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

              // Date chips row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Planned day chip
                    FormBuilderField<DateTime?>(
                      name: ProjectFieldKeys.startDate.id,
                      builder: (field) {
                        return FormDateChip.startDate(
                          label: context.l10n.dateChipAddPlannedDay,
                          date: field.value,
                          onTap: () => _showDatePicker(
                            context,
                            field.value,
                            (date) {
                              field.didChange(date);
                              setState(() {});
                            },
                          ),
                          onClear: field.value != null
                              ? () {
                                  field.didChange(null);
                                  setState(() {});
                                }
                              : null,
                        );
                      },
                    ),
                    // Due date chip
                    FormBuilderField<DateTime?>(
                      name: ProjectFieldKeys.deadlineDate.id,
                      builder: (field) {
                        return FormDateChip.deadline(
                          label: context.l10n.dateChipAddDueDate,
                          date: field.value,
                          onTap: () => _showDatePicker(
                            context,
                            field.value,
                            (date) {
                              field.didChange(date);
                              setState(() {});
                            },
                          ),
                          onClear: field.value != null
                              ? () {
                                  field.didChange(null);
                                  setState(() {});
                                }
                              : null,
                        );
                      },
                    ),
                    // Recurrence chip
                    FormBuilderField<String?>(
                      name: ProjectFieldKeys.repeatIcalRrule.id,
                      builder: (field) {
                        final rrule = field.value?.isEmpty ?? true
                            ? null
                            : field.value;

                        return RruleFormRecurrenceChip(
                          rrule: rrule,
                          emptyLabel: context.l10n.recurrenceRepeatTitle,
                          onTap: () async {
                            final repeatFromCompletionField =
                                widget
                                    .formKey
                                    .currentState
                                    ?.fields[ProjectFieldKeys
                                    .repeatFromCompletion
                                    .id];
                            final seriesEndedField = widget
                                .formKey
                                .currentState
                                ?.fields[ProjectFieldKeys.seriesEnded.id];

                            final result =
                                await showDialog<RecurrencePickerResult>(
                                  context: context,
                                  builder: (context) => Dialog(
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 500,
                                        maxHeight: 600,
                                      ),
                                      child: RecurrencePicker(
                                        initialRRule:
                                            field.value?.isEmpty ?? true
                                            ? null
                                            : field.value,
                                        initialRepeatFromCompletion:
                                            (repeatFromCompletionField?.value
                                                as bool?) ??
                                            false,
                                        initialSeriesEnded:
                                            (seriesEndedField?.value
                                                as bool?) ??
                                            false,
                                      ),
                                    ),
                                  ),
                                );
                            if (result != null) {
                              field.didChange(result.rrule);
                              repeatFromCompletionField?.didChange(
                                result.repeatFromCompletion,
                              );
                              seriesEndedField?.didChange(
                                result.seriesEnded,
                              );
                              markDirty();
                            }
                          },
                          onClear: field.value?.isNotEmpty ?? false
                              ? () {
                                  field.didChange(null);
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
                                      ?.fields[ProjectFieldKeys.seriesEnded.id]
                                      ?.didChange(false);
                                  markDirty();
                                }
                              : null,
                        );
                      },
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

              if (showScheduleHelper)
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
                  child: Text(
                    l10n.scheduleHelperText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),

              SizedBox(height: sectionGap),
              // Priority
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FormBuilderPriorityPicker(
                  name: ProjectFieldKeys.priority.id,
                ),
              ),

              SizedBox(height: sectionGap),

              // Values
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FormBuilderField<List<String>>(
                  name: ProjectFieldKeys.valueIds.id,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.projectFormValuesRequired;
                    }
                    return null;
                  },
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

                    return KeyedSubtree(
                      key: _valuesKey,
                      child: Card(
                        elevation: 0,
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerLow,
                        child: ListTile(
                          title: Text(l10n.projectFormValuesLabel),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                valuesWhyCopy,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _ProjectValueSlotRow(
                                label: 'Primary',
                                value: primary,
                                showNone: true,
                              ),
                              const SizedBox(height: 6),
                              _ProjectValueSlotRow(
                                label: 'Secondary',
                                value: secondary,
                                showNone: true,
                              ),
                              if (field.errorText != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  field.errorText!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            final result =
                                await showValuesAlignmentSheetForProject(
                                  context,
                                  availableValues: widget.availableValues,
                                  valueIds: valueIds,
                                );
                            if (result != null) {
                              field.didChange(result);
                              markDirty();
                              setState(() {});
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectValueSlotRow extends StatelessWidget {
  const _ProjectValueSlotRow({
    required this.label,
    required this.value,
    required this.showNone,
  });

  final String label;
  final Value? value;
  final bool showNone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 84,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: value == null
              ? Text(
                  showNone ? 'None' : '',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                )
              : Row(
                  children: [
                    _ProjectSmallValueIcon(value: value!),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        value!.name,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ProjectSmallValueIcon extends StatelessWidget {
  const _ProjectSmallValueIcon({required this.value});

  final Value value;

  @override
  Widget build(BuildContext context) {
    final iconData = getIconDataFromName(value.iconName) ?? Icons.star;
    final valueColor = ColorUtils.fromHexWithThemeFallback(
      context,
      value.color,
    );
    final color = valueColor.withValues(alpha: 0.95);

    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.8), width: 1.25),
      ),
      child: Center(
        child: Icon(
          iconData,
          size: 12,
          color: color,
          semanticLabel: value.name,
        ),
      ),
    );
  }
}
