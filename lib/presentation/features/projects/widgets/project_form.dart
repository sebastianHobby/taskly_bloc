import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/widgets/form_fields/form_builder_priority_picker.dart';
// import 'package:taskly_bloc/presentation/widgets/form_fields/form_builder_tag_picker.dart'; // Removed
import 'package:taskly_bloc/presentation/widgets/form_fields/form_fields.dart';
import 'package:taskly_bloc/presentation/shared/utils/form_utils.dart';
import 'package:taskly_bloc/presentation/widgets/form_date_chip.dart';
import 'package:taskly_bloc/presentation/widgets/form_recurrence_chip.dart';
import 'package:taskly_bloc/presentation/widgets/recurrence_picker.dart';
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
    this.availableValues = const <Value>[],
    this.onDelete,
    this.onClose,
    super.key,
  });

  final GlobalKey<FormBuilderState> formKey;
  final VoidCallback onSubmit;
  final String submitTooltip;
  final Project? initialData;
  final List<Value> availableValues;
  final VoidCallback? onDelete;

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

    final Map<String, dynamic> initialValues = {
      'name': widget.initialData?.name.trim() ?? '',
      'description': widget.initialData?.description ?? '',
      'completed': widget.initialData?.completed ?? false,
      'startDate': widget.initialData?.startDate,
      'deadlineDate': widget.initialData?.deadlineDate,
      'priority': widget.initialData?.priority,
      'valueIds':
          (widget.initialData?.values ?? <Value>[]) // Use values property
              .map((Value e) => e.id)
              .toList(growable: false),
      'repeatIcalRrule': widget.initialData?.repeatIcalRrule ?? '',
    };

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: colorScheme.outline.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Action buttons row
          Container(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Delete button (if editing)
                if (widget.initialData != null && widget.onDelete != null)
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: colorScheme.error,
                    ),
                    onPressed: widget.onDelete,
                    tooltip: 'Delete Project',
                  ),

                // Close button (X) in top right
                if (widget.onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: handleClose,
                    tooltip: 'Close',
                    style: IconButton.styleFrom(
                      foregroundColor: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: FormBuilder(
                key: widget.formKey,
                initialValue: initialValues,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged: markDirty,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Project Name
                    FormBuilderTextFieldModern(
                      name: 'name',
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
                      name: 'description',
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

                    // Date chips row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // Start Date chip
                          FormBuilderField<DateTime?>(
                            name: 'startDate',
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
                            name: 'deadlineDate',
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
                            name: 'repeatIcalRrule',
                            builder: (field) {
                              return FormRecurrenceChip(
                                rrule: field.value?.isEmpty ?? true
                                    ? null
                                    : field.value,
                                onTap: () async {
                                  final result = await showDialog<String?>(
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
                                          onRRuleChanged: (rrule) {
                                            Navigator.of(context).pop(rrule);
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                  if (result != null) {
                                    field.didChange(result);
                                    markDirty();
                                  }
                                },
                                onClear: field.value?.isNotEmpty ?? false
                                    ? () {
                                        field.didChange(null);
                                        markDirty();
                                      }
                                    : null,
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Priority
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: FormBuilderPriorityPicker(
                        name: 'priority',
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Values
                    // TODO: Implement Value Picker
                    // FormBuilderValuePicker(
                    //   name: 'valueIds',
                    //   availableValues: widget.availableValues,
                    // ),
                  ],
                ),
              ),
            ),
          ),

          // Sticky footer with action button - always visible at bottom right
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton.icon(
                  onPressed: widget.onSubmit,
                  icon: Icon(
                    isCreating ? Icons.add : Icons.check,
                    size: 18,
                  ),
                  label: Text(isCreating ? 'Create Project' : 'Save Changes'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
