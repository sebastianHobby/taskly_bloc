import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/widgets/form_fields/form_fields.dart';
import 'package:taskly_bloc/presentation/shared/utils/form_utils.dart';
import 'package:taskly_bloc/presentation/widgets/form_date_chip.dart';
import 'package:taskly_bloc/presentation/widgets/form_recurrence_chip.dart';
import 'package:taskly_bloc/presentation/widgets/recurrence_picker.dart';
import 'package:taskly_bloc/domain/domain.dart';

/// A modern form for creating or editing tasks.
///
/// Features:
/// - Action buttons in header (always visible)
/// - Unsaved changes confirmation on close
/// - Clear cancel/close affordance
class TaskForm extends StatefulWidget {
  const TaskForm({
    required this.formKey,
    required this.onSubmit,
    required this.submitTooltip,
    this.initialData,
    this.availableProjects = const [],
    this.availableLabels = const [],
    this.defaultProjectId,
    this.onDelete,
    this.onClose,
    super.key,
  });

  final GlobalKey<FormBuilderState> formKey;
  final Task? initialData;
  final VoidCallback onSubmit;
  final String submitTooltip;
  final List<Project> availableProjects;
  final List<Label> availableLabels;
  final String? defaultProjectId;
  final VoidCallback? onDelete;

  /// Called when the user wants to close the form.
  /// If null, no close button is shown.
  final VoidCallback? onClose;

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> with FormDirtyStateMixin {
  @override
  VoidCallback? get onClose => widget.onClose;

  @override
  void initState() {
    super.initState();
  }

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
      'name': widget.initialData?.name ?? '',
      'description': widget.initialData?.description ?? '',
      'completed': widget.initialData?.completed ?? false,
      'startDate': widget.initialData?.startDate,
      'deadlineDate': widget.initialData?.deadlineDate,
      'projectId':
          widget.initialData?.projectId ?? widget.defaultProjectId ?? '',
      'labelIds': (widget.initialData?.labels ?? <Label>[])
          .map((Label e) => e.id)
          .toList(),
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
                    tooltip: 'Delete Task',
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
                    // Task Name with completion checkbox
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Completion checkbox
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: FormBuilderField<bool>(
                              name: 'completed',
                              builder: (field) {
                                return SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: field.value ?? false,
                                    onChanged: (value) {
                                      field.didChange(value);
                                      markDirty();
                                    },
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Task name field
                          Expanded(
                            child: FormBuilderTextField(
                              name: 'name',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                              textCapitalization: TextCapitalization.sentences,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                hintText: l10n.taskFormNameHint,
                                filled: true,
                                fillColor: colorScheme.surfaceContainerLow,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: colorScheme.primary,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              validator: FormBuilderValidators.compose([
                                FormBuilderValidators.required(
                                  errorText: l10n.taskFormNameRequired,
                                ),
                                FormBuilderValidators.minLength(
                                  1,
                                  errorText: l10n.taskFormNameEmpty,
                                ),
                                FormBuilderValidators.maxLength(
                                  120,
                                  errorText: l10n.taskFormNameTooLong,
                                ),
                              ]),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Task Description
                    FormBuilderTextFieldModern(
                      name: 'description',
                      hint: l10n.taskFormDescriptionHint,
                      textInputAction: TextInputAction.newline,
                      fieldType: ModernFieldType.description,
                      maxLines: 3,
                      minLines: 2,
                      validator: FormBuilderValidators.maxLength(
                        200,
                        errorText: l10n.taskFormDescriptionTooLong,
                        checkNullOrEmpty: false,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Chips row: Project, Start Date, Deadline
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // Project chip
                          if (widget.availableProjects.isNotEmpty)
                            FormBuilderField<String>(
                              name: 'projectId',
                              builder: (field) {
                                final selectedProject = widget.availableProjects
                                    .where((p) => p.id == field.value)
                                    .firstOrNull;

                                return _ProjectChip(
                                  project: selectedProject,
                                  onTap: () async {
                                    final selected = await showDialog<Project>(
                                      context: context,
                                      builder: (context) =>
                                          _ProjectPickerDialog(
                                            availableProjects:
                                                widget.availableProjects,
                                            currentProjectId: field.value,
                                          ),
                                    );
                                    if (selected != null) {
                                      field.didChange(selected.id);
                                      markDirty();
                                    }
                                  },
                                  onClear:
                                      field.value != null &&
                                          field.value!.isNotEmpty
                                      ? () {
                                          field.didChange('');
                                          markDirty();
                                        }
                                      : null,
                                );
                              },
                            ),
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
                                rrule: field.value,
                                onTap: () async {
                                  await showDialog<void>(
                                    context: context,
                                    builder: (context) => Dialog(
                                      child: RecurrencePicker(
                                        initialRRule: field.value,
                                        onRRuleChanged: (rrule) {
                                          field.didChange(rrule);
                                          markDirty();
                                        },
                                      ),
                                    ),
                                  );
                                },
                                onClear:
                                    field.value != null &&
                                        field.value!.isNotEmpty
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

                    // Labels and Values Section
                    FormBuilderLabelPickerModern(
                      name: 'labelIds',
                      availableLabels: widget.availableLabels,
                    ),
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
                  label: Text(isCreating ? 'Create Task' : 'Save Changes'),
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

/// A chip widget for displaying and selecting projects.
class _ProjectChip extends StatelessWidget {
  const _ProjectChip({
    required this.project,
    required this.onTap,
    this.onClear,
  });

  final Project? project;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasProject = project != null;

    final chipColor = hasProject
        ? colorScheme.secondaryContainer
        : colorScheme.surfaceContainerHigh;

    final contentColor = hasProject
        ? colorScheme.onSecondaryContainer
        : colorScheme.onSurfaceVariant;

    return Material(
      color: chipColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.only(
            left: 10,
            right: onClear != null && hasProject ? 4 : 10,
            top: 6,
            bottom: 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.folder_rounded,
                size: 16,
                color: contentColor,
              ),
              const SizedBox(width: 6),
              Text(
                hasProject ? project!.name : 'Add project',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: contentColor,
                  fontWeight: hasProject ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
              if (onClear != null && hasProject) ...[
                const SizedBox(width: 2),
                InkWell(
                  onTap: onClear,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: contentColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog for selecting a project.
class _ProjectPickerDialog extends StatelessWidget {
  const _ProjectPickerDialog({
    required this.availableProjects,
    this.currentProjectId,
  });

  final List<Project> availableProjects;
  final String? currentProjectId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Select Project',
                    style: theme.textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: availableProjects.length,
                itemBuilder: (context, index) {
                  final project = availableProjects[index];
                  final isSelected = project.id == currentProjectId;

                  return ListTile(
                    leading: Icon(
                      Icons.folder_rounded,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                    title: Text(project.name),
                    trailing: isSelected
                        ? Icon(Icons.check, color: colorScheme.primary)
                        : null,
                    selected: isSelected,
                    onTap: () => Navigator.of(context).pop(project),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
