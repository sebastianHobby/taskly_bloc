import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/widgets/form_fields/form_builder_priority_picker.dart';
import 'package:taskly_bloc/presentation/widgets/form_fields/form_fields.dart';
import 'package:taskly_bloc/presentation/shared/utils/form_utils.dart';
import 'package:taskly_bloc/presentation/widgets/form_date_chip.dart';
import 'package:taskly_bloc/presentation/widgets/form_recurrence_chip.dart';
import 'package:taskly_bloc/presentation/widgets/recurrence_picker.dart';
import 'package:taskly_bloc/presentation/widgets/form_shell.dart';
import 'package:taskly_bloc/presentation/widgets/values_alignment/values_alignment_sheet.dart';
import 'package:taskly_domain/core.dart';

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
    this.onChanged,
    this.initialData,
    this.availableProjects = const [],
    this.availableValues = const [],
    this.defaultProjectId,
    this.defaultValueIds,
    this.openToValues = false,
    this.openToProjectPicker = false,
    this.onDelete,
    this.onTogglePinned,
    this.onClose,
    super.key,
  });

  final GlobalKey<FormBuilderState> formKey;
  final Task? initialData;
  final VoidCallback onSubmit;
  final String submitTooltip;
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final List<Project> availableProjects;
  final List<Value> availableValues;
  final String? defaultProjectId;
  final List<String>? defaultValueIds;

  /// When true, scrolls to the values section and opens the values sheet.
  final bool openToValues;

  /// When true, scrolls to the project picker and opens the picker dialog.
  final bool openToProjectPicker;
  final VoidCallback? onDelete;

  /// Called when the user toggles pinned state from the header.
  ///
  /// Only shown when editing (initialData != null).
  final ValueChanged<bool>? onTogglePinned;

  /// Called when the user wants to close the form.
  /// If null, no close button is shown.
  final VoidCallback? onClose;

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> with FormDirtyStateMixin {
  @override
  VoidCallback? get onClose => widget.onClose;

  final _scrollController = ScrollController();
  final GlobalKey<State<StatefulWidget>> _valuesKey = GlobalKey();
  final GlobalKey<State<StatefulWidget>> _projectKey = GlobalKey();
  bool _didAutoOpen = false;

  @override
  void initState() {
    super.initState();

    // Auto-open is a one-shot affordance for deep-links (e.g., from "+N").
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _didAutoOpen) return;
      if (!widget.openToValues && !widget.openToProjectPicker) return;
      _didAutoOpen = true;

      if (widget.openToProjectPicker) {
        final ctx = _projectKey.currentContext;
        if (ctx != null) {
          await Scrollable.ensureVisible(
            ctx,
            alignment: 0.1,
            duration: const Duration(milliseconds: 220),
          );
        }

        if (!mounted) return;
        final currentProjectId =
            (widget
                    .formKey
                    .currentState
                    ?.fields[TaskFieldKeys.projectId.id]
                    ?.value
                as String?) ??
            '';
        final selected = await showDialog<Project>(
          context: context,
          builder: (context) => _ProjectPickerDialog(
            availableProjects: widget.availableProjects,
            currentProjectId: currentProjectId,
          ),
        );
        if (!mounted || selected == null) return;
        widget.formKey.currentState?.fields[TaskFieldKeys.projectId.id]
            ?.didChange(selected.id);
        markDirty();
        setState(() {});
        return;
      }

      if (widget.openToValues) {
        final ctx = _valuesKey.currentContext;
        if (ctx != null) {
          await Scrollable.ensureVisible(
            ctx,
            alignment: 0.1,
            duration: const Duration(milliseconds: 220),
          );
        }
        if (!mounted) return;

        final valueIdsFieldState =
            widget.formKey.currentState?.fields[TaskFieldKeys.valueIds.id];
        final explicitValueIds = List<String>.of(
          (valueIdsFieldState?.value as List<String>?) ?? const <String>[],
        );

        final projectId =
            (widget
                        .formKey
                        .currentState
                        ?.fields[TaskFieldKeys.projectId.id]
                        ?.value
                    as String?)
                ?.trim() ??
            '';
        final selectedProject = widget.availableProjects
            .where((p) => p.id == projectId)
            .firstOrNull;

        final result = await showValuesAlignmentSheetForTask(
          context,
          availableValues: widget.availableValues,
          explicitValueIds: explicitValueIds,
          selectedProject: selectedProject,
        );
        if (!mounted || result == null) return;
        widget.formKey.currentState?.fields[TaskFieldKeys.valueIds.id]
            ?.didChange(result);
        markDirty();
        setState(() {});
      }
    });
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

    final availableValuesById = <String, Value>{
      for (final v in widget.availableValues) v.id: v,
    };

    final initialValues = <String, dynamic>{
      TaskFieldKeys.name.id: widget.initialData?.name ?? '',
      TaskFieldKeys.description.id: widget.initialData?.description ?? '',
      TaskFieldKeys.completed.id: widget.initialData?.completed ?? false,
      TaskFieldKeys.startDate.id: widget.initialData?.startDate,
      TaskFieldKeys.deadlineDate.id: widget.initialData?.deadlineDate,
      TaskFieldKeys.projectId.id:
          widget.initialData?.projectId ?? widget.defaultProjectId ?? '',
      TaskFieldKeys.priority.id: widget.initialData?.priority,
      TaskFieldKeys.valueIds.id:
          widget.initialData?.values.map((e) => e.id).toList() ??
          (widget.defaultValueIds ?? const <String>[]),
      TaskFieldKeys.repeatIcalRrule.id:
          widget.initialData?.repeatIcalRrule ?? '',
      TaskFieldKeys.repeatFromCompletion.id:
          widget.initialData?.repeatFromCompletion ?? false,
      TaskFieldKeys.seriesEnded.id: widget.initialData?.seriesEnded ?? false,
    };

    return FormShell(
      onSubmit: widget.onSubmit,
      submitTooltip: isCreating ? l10n.actionCreate : l10n.actionUpdate,
      submitIcon: isCreating ? Icons.add : Icons.check,
      onDelete: widget.initialData != null ? widget.onDelete : null,
      deleteTooltip: l10n.deleteTaskAction,
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
                        name: TaskFieldKeys.completed.id,
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
                        name: TaskFieldKeys.name.id,
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
                name: TaskFieldKeys.description.id,
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
                        name: TaskFieldKeys.projectId.id,
                        builder: (field) {
                          final selectedProject = widget.availableProjects
                              .where((p) => p.id == field.value)
                              .firstOrNull;

                          return KeyedSubtree(
                            key: _projectKey,
                            child: _ProjectChip(
                              project: selectedProject,
                              onTap: () async {
                                final selected = await showDialog<Project>(
                                  context: context,
                                  builder: (context) => _ProjectPickerDialog(
                                    availableProjects: widget.availableProjects,
                                    currentProjectId: field.value,
                                  ),
                                );
                                if (selected != null) {
                                  field.didChange(selected.id);
                                  markDirty();
                                  setState(() {});
                                }
                              },
                              onClear:
                                  field.value != null && field.value!.isNotEmpty
                                  ? () {
                                      field.didChange('');
                                      markDirty();
                                      setState(() {});
                                    }
                                  : null,
                            ),
                          );
                        },
                      ),
                    // Start Date chip
                    FormBuilderField<DateTime?>(
                      name: TaskFieldKeys.startDate.id,
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
                      name: TaskFieldKeys.deadlineDate.id,
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
                      name: TaskFieldKeys.repeatIcalRrule.id,
                      builder: (field) {
                        return FormRecurrenceChip(
                          rrule: field.value,
                          onTap: () async {
                            final repeatFromCompletionField = widget
                                .formKey
                                .currentState
                                ?.fields[TaskFieldKeys.repeatFromCompletion.id];
                            final seriesEndedField = widget
                                .formKey
                                .currentState
                                ?.fields[TaskFieldKeys.seriesEnded.id];

                            final result =
                                await showDialog<RecurrencePickerResult>(
                                  context: context,
                                  builder: (context) => Dialog(
                                    child: RecurrencePicker(
                                      initialRRule: field.value,
                                      initialRepeatFromCompletion:
                                          (repeatFromCompletionField?.value
                                              as bool?) ??
                                          false,
                                      initialSeriesEnded:
                                          (seriesEndedField?.value as bool?) ??
                                          false,
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
                          onClear:
                              field.value != null && field.value!.isNotEmpty
                              ? () {
                                  field.didChange(null);
                                  widget
                                      .formKey
                                      .currentState
                                      ?.fields[TaskFieldKeys
                                          .repeatFromCompletion
                                          .id]
                                      ?.didChange(false);
                                  widget
                                      .formKey
                                      .currentState
                                      ?.fields[TaskFieldKeys.seriesEnded.id]
                                      ?.didChange(false);
                                  markDirty();
                                }
                              : null,
                        );
                      },
                    ),

                    // Hidden recurrence flags fields (set by the picker)
                    FormBuilderField<bool>(
                      name: TaskFieldKeys.repeatFromCompletion.id,
                      builder: (_) => const SizedBox.shrink(),
                    ),
                    FormBuilderField<bool>(
                      name: TaskFieldKeys.seriesEnded.id,
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
                  name: TaskFieldKeys.priority.id,
                ),
              ),

              const SizedBox(height: 16),

              // Values
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FormBuilderField<List<String>>(
                  name: TaskFieldKeys.valueIds.id,
                  builder: (field) {
                    final explicitValueIds = List<String>.of(
                      field.value ?? const <String>[],
                    );

                    final projectId =
                        widget
                                .formKey
                                .currentState
                                ?.fields[TaskFieldKeys.projectId.id]
                                ?.value
                            as String?;
                    final selectedProject = widget.availableProjects
                        .where((p) => p.id == projectId)
                        .firstOrNull;

                    final hasExplicit = explicitValueIds.isNotEmpty;
                    final isInheriting =
                        !hasExplicit && selectedProject != null;

                    final primaryValueId = hasExplicit
                        ? explicitValueIds.first
                        : selectedProject?.primaryValueId;

                    final primaryName = primaryValueId == null
                        ? null
                        : (hasExplicit
                              ? availableValuesById[primaryValueId]?.name
                              : selectedProject?.values
                                    .cast<Value?>()
                                    .firstWhere(
                                      (v) => v?.id == primaryValueId,
                                      orElse: () => null,
                                    )
                                    ?.name);

                    final count = hasExplicit
                        ? explicitValueIds.length
                        : (selectedProject?.values.length ?? 0);

                    final summary = primaryName == null
                        ? (isInheriting
                              ? l10n.valuesNoneInherited
                              : l10n.valuesNoneSelected)
                        : count <= 1
                        ? primaryName
                        : '$primaryName + ${count - 1}';

                    return KeyedSubtree(
                      key: _valuesKey,
                      child: Card(
                        elevation: 0,
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerLow,
                        child: ListTile(
                          title: Text(l10n.valuesAlignedToTitle),
                          subtitle: Text(
                            summary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          leading: Icon(
                            isInheriting && !hasExplicit
                                ? Icons.call_merge
                                : Icons.star_border,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            final result =
                                await showValuesAlignmentSheetForTask(
                                  context,
                                  availableValues: widget.availableValues,
                                  explicitValueIds: explicitValueIds,
                                  selectedProject: selectedProject,
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
                hasProject ? project!.name : context.l10n.addProjectAction,
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
                    context.l10n.selectProjectTitle,
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
