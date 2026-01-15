import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/widgets/form_fields/form_builder_priority_picker.dart';
// import 'package:taskly_bloc/presentation/widgets/form_fields/form_builder_tag_picker.dart'; // Removed
import 'package:taskly_bloc/presentation/widgets/form_fields/form_fields.dart';
import 'package:taskly_bloc/presentation/shared/utils/form_utils.dart';
import 'package:taskly_bloc/presentation/widgets/form_date_chip.dart';
import 'package:taskly_bloc/presentation/widgets/form_recurrence_chip.dart';
import 'package:taskly_bloc/presentation/widgets/recurrence_picker.dart';
import 'package:taskly_bloc/presentation/widgets/form_shell.dart';
import 'package:taskly_bloc/presentation/widgets/values_alignment/values_alignment_sheet.dart';
import 'package:taskly_bloc/domain/domain.dart';

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
    this.onDelete,
    this.onTogglePinned,
    this.onClose,
    super.key,
  });

  final GlobalKey<FormBuilderState> formKey;
  final VoidCallback onSubmit;
  final String submitTooltip;
  final Project? initialData;
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final List<Value> availableValues;
  final VoidCallback? onDelete;

  /// Called when the user toggles pinned state from the header.
  ///
  /// Only shown when editing (initialData != null).
  final ValueChanged<bool>? onTogglePinned;

  /// Called when the user wants to close the form.
  /// If null, no close button is shown.
  final VoidCallback? onClose;

  @override
  State<ProjectForm> createState() => _ProjectFormState();
}

class _ProjectFormState extends State<ProjectForm> with FormDirtyStateMixin {
  @override
  VoidCallback? get onClose => widget.onClose;

  Future<void> _showDatePicker(
    BuildContext context,
    DateTime? initialDate,
    ValueChanged<DateTime?> onDateSelected,
  ) async {
    final now = DateTime.now();
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

    return FormShell(
      onSubmit: widget.onSubmit,
      submitTooltip: isCreating ? l10n.actionCreate : l10n.actionUpdate,
      submitIcon: isCreating ? Icons.add : Icons.check,
      onDelete: widget.initialData != null ? widget.onDelete : null,
      deleteTooltip: l10n.deleteProjectAction,
      onClose: widget.onClose != null ? handleClose : null,
      closeTooltip: l10n.closeLabel,
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
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: FormBuilder(
          key: widget.formKey,
          initialValue: initialValues,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: () {
            markDirty();
            final values = widget.formKey.currentState?.value;
            if (values != null) {
              widget.onChanged?.call(values);
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Project Name
              FormBuilderTextFieldModern(
                name: ProjectFieldKeys.name.id,
                hint: l10n.projectFormTitleHint,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                fieldType: ModernFieldType.title,
                isRequired: true,
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
              FormBuilderTextFieldModern(
                name: ProjectFieldKeys.description.id,
                hint: l10n.projectFormDescriptionHint,
                textInputAction: TextInputAction.newline,
                fieldType: ModernFieldType.description,
                maxLines: 3,
                minLines: 2,
                validator: FormBuilderValidators.maxLength(
                  200,
                  errorText: l10n.projectFormDescriptionTooLong,
                  checkNullOrEmpty: false,
                ),
              ),

              const SizedBox(height: 8),

              // Completed
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FormBuilderField<bool>(
                  name: ProjectFieldKeys.completed.id,
                  builder: (field) {
                    return SwitchListTile.adaptive(
                      value: field.value ?? false,
                      onChanged: (value) {
                        field.didChange(value);
                        markDirty();
                      },
                      title: Text(l10n.projectCompletedLabel),
                      contentPadding: EdgeInsets.zero,
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
                    // Start Date chip
                    FormBuilderField<DateTime?>(
                      name: ProjectFieldKeys.startDate.id,
                      builder: (field) {
                        return FormDateChip.startDate(
                          date: field.value,
                          onTap: () => _showDatePicker(
                            context,
                            field.value,
                            (date) => field.didChange(date),
                          ),
                          onClear: field.value != null
                              ? () => field.didChange(null)
                              : null,
                        );
                      },
                    ),
                    // Deadline Date chip
                    FormBuilderField<DateTime?>(
                      name: ProjectFieldKeys.deadlineDate.id,
                      builder: (field) {
                        return FormDateChip.deadline(
                          date: field.value,
                          onTap: () => _showDatePicker(
                            context,
                            field.value,
                            (date) => field.didChange(date),
                          ),
                          onClear: field.value != null
                              ? () => field.didChange(null)
                              : null,
                        );
                      },
                    ),
                    // Recurrence chip
                    FormBuilderField<String?>(
                      name: ProjectFieldKeys.repeatIcalRrule.id,
                      builder: (field) {
                        return FormRecurrenceChip(
                          rrule: field.value?.isEmpty ?? true
                              ? null
                              : field.value,
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

              const SizedBox(height: 16),

              // Priority
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FormBuilderPriorityPicker(
                  name: ProjectFieldKeys.priority.id,
                ),
              ),

              const SizedBox(height: 16),

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
                    final primaryId = valueIds.isEmpty ? null : valueIds.first;
                    final primaryName = primaryId == null
                        ? null
                        : availableValuesById[primaryId]?.name;

                    final summary = primaryName == null
                        ? l10n.valuesNoneSelected
                        : valueIds.length <= 1
                        ? primaryName
                        : '$primaryName + ${valueIds.length - 1}';

                    return Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      child: ListTile(
                        title: Text(l10n.projectFormValuesLabel),
                        subtitle: Text(
                          summary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        leading: const Icon(Icons.star_border),
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
