import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/widgets/form_fields/form_builder_priority_picker.dart';
import 'package:taskly_bloc/presentation/shared/utils/form_utils.dart';
import 'package:taskly_bloc/presentation/widgets/form_date_chip.dart';
import 'package:taskly_bloc/presentation/widgets/recurrence_picker.dart';
import 'package:taskly_bloc/presentation/widgets/rrule_form_recurrence_chip.dart';
import 'package:taskly_bloc/presentation/widgets/values_alignment/values_alignment_sheet.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_ui/taskly_ui_forms.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';

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
    this.defaultStartDate,
    this.defaultDeadlineDate,
    this.openToValues = false,
    this.openToProjectPicker = false,
    this.onDelete,
    this.onTogglePinned,
    this.onClose,
    this.trailingActions = const <Widget>[],
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

  /// Optional planned day to prefill when creating a new task.
  final DateTime? defaultStartDate;

  /// Optional due date to prefill when creating a new task.
  final DateTime? defaultDeadlineDate;

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

  /// Optional action widgets to render in the header row (right side).
  final List<Widget> trailingActions;

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
  final List<String> _recentProjectIds = <String>[];

  void _recordRecentProjectId(String projectId) {
    final id = projectId.trim();
    if (id.isEmpty) return;
    _recentProjectIds.remove(id);
    _recentProjectIds.insert(0, id);
    if (_recentProjectIds.length > 5) {
      _recentProjectIds.removeRange(5, _recentProjectIds.length);
    }
  }

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
        final result = await showDialog<_ProjectPickerResult>(
          context: context,
          builder: (context) => _ProjectPickerDialog(
            availableProjects: widget.availableProjects,
            currentProjectId: currentProjectId,
            recentProjectIds: List<String>.unmodifiable(_recentProjectIds),
          ),
        );
        if (!mounted || result == null) return;

        switch (result) {
          case _ProjectPickerResultCleared():
            widget.formKey.currentState?.fields[TaskFieldKeys.projectId.id]
                ?.didChange('');
          case _ProjectPickerResultSelected(:final project):
            widget.formKey.currentState?.fields[TaskFieldKeys.projectId.id]
                ?.didChange(project.id);
            _recordRecentProjectId(project.id);
        }

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
      TaskFieldKeys.name.id: widget.initialData?.name ?? '',
      TaskFieldKeys.description.id: widget.initialData?.description ?? '',
      TaskFieldKeys.completed.id: widget.initialData?.completed ?? false,
      TaskFieldKeys.startDate.id:
          widget.initialData?.startDate ?? widget.defaultStartDate,
      TaskFieldKeys.deadlineDate.id:
          widget.initialData?.deadlineDate ?? widget.defaultDeadlineDate,
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

    final effectiveStartDate =
        (widget.formKey.currentState?.fields[TaskFieldKeys.startDate.id]?.value
            as DateTime?) ??
        (initialValues[TaskFieldKeys.startDate.id] as DateTime?);
    final effectiveDeadlineDate =
        (widget
                .formKey
                .currentState
                ?.fields[TaskFieldKeys.deadlineDate.id]
                ?.value
            as DateTime?) ??
        (initialValues[TaskFieldKeys.deadlineDate.id] as DateTime?);
    final showScheduleHelper =
        effectiveStartDate == null && effectiveDeadlineDate == null;

    final submitEnabled =
        isDirty && (widget.formKey.currentState?.isValid ?? false);

    final sectionGap = isCompact ? 12.0 : 16.0;
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
      trailingActions: widget.trailingActions,
      child: Padding(
        padding: EdgeInsets.only(bottom: isCompact ? 16 : 24),
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
                          contentPadding: denseFieldPadding,
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
              FormBuilderTextField(
                name: TaskFieldKeys.description.id,
                textInputAction: TextInputAction.newline,
                maxLines: isCompact ? 2 : 3,
                minLines: isCompact ? 1 : 2,
                decoration: InputDecoration(
                  hintText: l10n.taskFormDescriptionHint,
                  filled: true,
                  fillColor: colorScheme.surfaceContainerLow,
                  border: OutlineInputBorder(
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
                  contentPadding: denseFieldPadding,
                ),
                validator: FormBuilderValidators.maxLength(
                  200,
                  errorText: l10n.taskFormDescriptionTooLong,
                  checkNullOrEmpty: false,
                ),
              ),

              SizedBox(height: isCompact ? 6 : 8),

              // Chips row: Project, Planned Day, Due Date
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
                                final result =
                                    await showDialog<_ProjectPickerResult>(
                                      context: context,
                                      builder: (context) =>
                                          _ProjectPickerDialog(
                                            availableProjects:
                                                widget.availableProjects,
                                            currentProjectId: field.value,
                                            recentProjectIds:
                                                List<String>.unmodifiable(
                                                  _recentProjectIds,
                                                ),
                                          ),
                                    );
                                if (result == null) return;

                                switch (result) {
                                  case _ProjectPickerResultCleared():
                                    field.didChange('');
                                  case _ProjectPickerResultSelected(
                                    :final project,
                                  ):
                                    field.didChange(project.id);
                                    _recordRecentProjectId(project.id);
                                }

                                markDirty();
                                setState(() {});
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
                    // Planned day chip
                    FormBuilderField<DateTime?>(
                      name: TaskFieldKeys.startDate.id,
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
                      name: TaskFieldKeys.deadlineDate.id,
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
                      name: TaskFieldKeys.repeatIcalRrule.id,
                      builder: (field) {
                        return RruleFormRecurrenceChip(
                          rrule: field.value,
                          emptyLabel: context.l10n.recurrenceRepeatTitle,
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
                  name: TaskFieldKeys.priority.id,
                ),
              ),

              SizedBox(height: sectionGap),

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

                    final inheritedCount = selectedProject?.values.length ?? 0;
                    final hasInheritedValues =
                        selectedProject != null && inheritedCount > 0;

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
                        : inheritedCount;

                    final summary = primaryName == null
                        ? (isInheriting
                              ? (hasInheritedValues
                                    ? l10n.valuesNoneInherited
                                    : l10n.valuesProjectHasNoValues)
                              : l10n.valuesNoneSelected)
                        : count <= 1
                        ? primaryName
                        : '$primaryName + ${count - 1}';

                    final secondary = primaryName == null
                        ? (selectedProject == null
                              ? l10n.valuesAlignmentHelperText
                              : null)
                        : (isInheriting && !hasExplicit
                              ? '${l10n.valuesInheritedFromProject} ${selectedProject.name}'
                              : l10n.valuesExplicitSelectionLabel);

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
                            secondary == null
                                ? summary
                                : '$summary\n$secondary',
                            maxLines: 3,
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
sealed class _ProjectPickerResult {
  const _ProjectPickerResult();
}

final class _ProjectPickerResultSelected extends _ProjectPickerResult {
  const _ProjectPickerResultSelected(this.project);
  final Project project;
}

final class _ProjectPickerResultCleared extends _ProjectPickerResult {
  const _ProjectPickerResultCleared();
}

class _ProjectPickerDialog extends StatefulWidget {
  const _ProjectPickerDialog({
    required this.availableProjects,
    required this.recentProjectIds,
    this.currentProjectId,
  });

  final List<Project> availableProjects;
  final List<String> recentProjectIds;
  final String? currentProjectId;

  @override
  State<_ProjectPickerDialog> createState() => _ProjectPickerDialogState();
}

class _ProjectPickerDialogState extends State<_ProjectPickerDialog> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;
    final currentId = (widget.currentProjectId ?? '').trim();
    final query = _searchController.text.trim().toLowerCase();

    final projectsById = <String, Project>{
      for (final p in widget.availableProjects) p.id: p,
    };

    final recentProjects = widget.recentProjectIds
        .map((id) => projectsById[id])
        .whereType<Project>()
        .where((p) => p.id != currentId)
        .toList(growable: false);

    final filteredProjects = query.isEmpty
        ? widget.availableProjects
        : widget.availableProjects
              .where((p) => p.name.toLowerCase().contains(query))
              .toList(growable: false);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  Text(
                    l10n.selectProjectTitle,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.projectPickerSearchHint,
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.inbox_outlined,
                      color: currentId.isEmpty
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                    title: Text(l10n.projectPickerNoProjectInbox),
                    trailing: currentId.isEmpty
                        ? Icon(Icons.check, color: colorScheme.primary)
                        : null,
                    selected: currentId.isEmpty,
                    onTap: () => Navigator.of(context).pop(
                      const _ProjectPickerResultCleared(),
                    ),
                  ),
                  if (recentProjects.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(
                        l10n.projectPickerRecentTitle,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    ...recentProjects.map((project) {
                      final isSelected = project.id == currentId;
                      return ListTile(
                        leading: Icon(
                          Icons.history,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        title: Text(project.name),
                        trailing: isSelected
                            ? Icon(Icons.check, color: colorScheme.primary)
                            : null,
                        selected: isSelected,
                        onTap: () => Navigator.of(context).pop(
                          _ProjectPickerResultSelected(project),
                        ),
                      );
                    }),
                    const Divider(height: 1),
                  ],
                  if (filteredProjects.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        l10n.projectPickerNoMatchingProjects,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    ...filteredProjects.map((project) {
                      final isSelected = project.id == currentId;
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
                        onTap: () => Navigator.of(context).pop(
                          _ProjectPickerResultSelected(project),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
