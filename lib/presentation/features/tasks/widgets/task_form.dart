import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/shared/utils/date_display_utils.dart';
import 'package:taskly_bloc/presentation/shared/utils/form_utils.dart';
import 'package:taskly_bloc/presentation/shared/validation/form_builder_validator_adapter.dart';
import 'package:taskly_bloc/presentation/widgets/recurrence_picker.dart';
import 'package:taskly_bloc/presentation/widgets/rrule_form_recurrence_chip.dart';
import 'package:taskly_bloc/presentation/widgets/values_alignment/values_alignment_sheet.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_bloc/presentation/widgets/icon_picker/icon_catalog.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/time.dart';
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
      if (!context.mounted || _didAutoOpen) return;
      if (!widget.openToValues && !widget.openToProjectPicker) return;
      _didAutoOpen = true;

      if (widget.openToProjectPicker) {
        final targetContext = _projectKey.currentContext;
        if (targetContext != null) {
          await Scrollable.ensureVisible(
            targetContext,
            alignment: 0.1,
            duration: const Duration(milliseconds: 220),
          );
          if (!context.mounted) return;
        }

        final anchorContext = _projectKey.currentContext;
        if (anchorContext == null || !context.mounted) return;

        final currentProjectId =
            (widget
                    .formKey
                    .currentState
                    ?.fields[TaskFieldKeys.projectId.id]
                    ?.value
                as String?) ??
            '';

        final result = await _showProjectPicker(
          anchorContext: anchorContext,
          currentProjectId: currentProjectId,
        );
        if (!context.mounted || result == null) return;

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
        final targetContext = _valuesKey.currentContext;
        if (targetContext != null) {
          await Scrollable.ensureVisible(
            targetContext,
            alignment: 0.1,
            duration: const Duration(milliseconds: 220),
          );
          if (!context.mounted) return;
        }

        final anchorContext = _valuesKey.currentContext;
        if (anchorContext == null || !context.mounted) return;

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

        final result = await _showValuesAlignmentPicker(
          anchorContext: anchorContext,
          explicitValueIds: explicitValueIds,
          selectedProject: selectedProject,
        );
        if (!context.mounted || result == null) return;

        widget.formKey.currentState?.fields[TaskFieldKeys.valueIds.id]
            ?.didChange(result);
        markDirty();
        setState(() {});
      }
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

  Future<_ProjectPickerResult?> _showProjectPicker({
    required BuildContext anchorContext,
    required String currentProjectId,
  }) {
    if (_isCompact(context)) {
      return showModalBottomSheet<_ProjectPickerResult>(
        context: context,
        useSafeArea: true,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (sheetContext) => _ProjectPickerDialog(
          availableProjects: widget.availableProjects,
          currentProjectId: currentProjectId,
          recentProjectIds: List<String>.unmodifiable(_recentProjectIds),
        ),
      );
    }

    return _showAnchoredDialog<_ProjectPickerResult>(
      context,
      anchorContext: anchorContext,
      maxWidth: 460,
      maxHeight: 520,
      builder: (dialogContext) => _ProjectPickerDialog(
        availableProjects: widget.availableProjects,
        currentProjectId: currentProjectId,
        recentProjectIds: List<String>.unmodifiable(_recentProjectIds),
      ),
    );
  }

  Future<List<String>?> _showValuesAlignmentPicker({
    required BuildContext anchorContext,
    required List<String> explicitValueIds,
    required Project? selectedProject,
  }) {
    if (_isCompact(context)) {
      return showValuesAlignmentSheetForTask(
        context,
        availableValues: widget.availableValues,
        explicitValueIds: explicitValueIds,
        selectedProject: selectedProject,
      );
    }

    return _showAnchoredDialog<List<String>>(
      context,
      anchorContext: anchorContext,
      maxWidth: 520,
      maxHeight: 560,
      builder: (dialogContext) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ValuesAlignmentSheet.task(
          availableValues: widget.availableValues,
          explicitValueIds: explicitValueIds,
          selectedProject: selectedProject,
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
        builder: (sheetContext) => _TaskDatePickerPanel(
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
      builder: (dialogContext) => _TaskDatePickerPanel(
        title: title,
        initialDate: initialDate,
      ),
    );
  }

  Future<_NullableIntDecision?> _pickPriority({
    required BuildContext anchorContext,
    required int? current,
  }) {
    if (_isCompact(context)) {
      return showModalBottomSheet<_NullableIntDecision>(
        context: context,
        useSafeArea: true,
        showDragHandle: true,
        builder: (sheetContext) => _PriorityPickerPanel(current: current),
      );
    }

    return _showAnchoredDialog<_NullableIntDecision>(
      context,
      anchorContext: anchorContext,
      maxWidth: 320,
      maxHeight: 420,
      builder: (dialogContext) => _PriorityPickerPanel(current: current),
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
            setState(() {});
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
                        validator: toFormBuilderValidator<String>(
                          TaskValidators.name,
                          context,
                        ),
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
                validator: toFormBuilderValidator<String>(
                  TaskValidators.description,
                  context,
                ),
              ),

              SizedBox(height: isCompact ? 6 : 8),

              // Meta chips row (values-first): Values, Project, Planned Day,
              // Due Date, Priority, Repeat
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TasklyFormRowGroup(
                children: [
                    FormBuilderField<List<String>>(
                      name: TaskFieldKeys.valueIds.id,
                      builder: (field) {
                        final explicitValueIds = List<String>.of(
                          field.value ?? const <String>[],
                        );

                        final projectId =
                            (widget
                                        .formKey
                                        .currentState
                                        ?.fields[TaskFieldKeys.projectId.id]
                                        ?.value
                                    as String?)
                                ?.trim();
                        final selectedProject = widget.availableProjects
                            .where((p) => p.id == projectId)
                            .firstOrNull;

                        final hasExplicit = explicitValueIds.isNotEmpty;

                        final explicitIds = explicitValueIds
                            .take(2)
                            .toList(growable: false);

                        final inheritedValues =
                            selectedProject?.values.cast<Value?>() ??
                            const <Value?>[];

                        Value? effectivePrimary;
                        Value? effectiveSecondary;

                        if (hasExplicit) {
                          effectivePrimary = explicitIds.isEmpty
                              ? null
                              : availableValuesById[explicitIds.first];
                          effectiveSecondary = explicitIds.length < 2
                              ? null
                              : availableValuesById[explicitIds[1]];
                        } else if (selectedProject != null) {
                          final primaryId = selectedProject.primaryValueId;
                          effectivePrimary = primaryId == null
                              ? null
                              : inheritedValues.firstWhere(
                                  (v) => v?.id == primaryId,
                                  orElse: () => null,
                                );

                          effectiveSecondary = inheritedValues.firstWhere(
                            (v) =>
                                v != null &&
                                (effectivePrimary == null ||
                                    v.id != effectivePrimary.id),
                            orElse: () => null,
                          );
                        }

                        return Builder(
                          builder: (chipContext) {
                            Future<void> open() async {
                              final result = await _showValuesAlignmentPicker(
                                anchorContext: chipContext,
                                explicitValueIds: explicitValueIds,
                                selectedProject: selectedProject,
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
                              final color =
                                  ColorUtils.fromHexWithThemeFallback(
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
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  TasklyFormValueChip(
                                    model: effectivePrimary != null
                                        ? toModel(effectivePrimary)
                                        : TasklyFormValueChipModel(
                                            label: context
                                                .l10n
                                                .valuesAlignedToTitle,
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                            icon: Icons.favorite_outline,
                                            semanticLabel: context
                                                .l10n
                                                .valuesAlignedToTitle,
                                          ),
                                    onTap: open,
                                    isPrimary: true,
                                    preset: TasklyFormPreset.standard.chip,
                                  ),
                                  if (effectiveSecondary != null)
                                    TasklyFormValueChip(
                                      model: toModel(effectiveSecondary),
                                      onTap: open,
                                      isPrimary: false,
                                      preset: TasklyFormPreset.standard.chip,
                                    ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),

                    if (widget.availableProjects.isNotEmpty)
                      FormBuilderField<String>(
                        name: TaskFieldKeys.projectId.id,
                        builder: (field) {
                          final selectedProject = widget.availableProjects
                              .where((p) => p.id == field.value)
                              .firstOrNull;

                          return KeyedSubtree(
                            key: _projectKey,
                            child: Builder(
                              builder: (chipContext) => TasklyFormProjectChip(
                                label: selectedProject?.name ??
                                    context.l10n.addProjectAction,
                                hasValue: selectedProject != null,
                                onTap: () async {
                                  final result = await _showProjectPicker(
                                    anchorContext: chipContext,
                                    currentProjectId: field.value ?? '',
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
                                    field.value != null &&
                                        field.value!.isNotEmpty
                                    ? () {
                                        field.didChange('');
                                        markDirty();
                                        setState(() {});
                                      }
                                    : null,
                                preset: TasklyFormPreset.standard.chip,
                              ),
                            ),
                          );
                        },
                      ),

                    FormBuilderField<DateTime?>(
                      name: TaskFieldKeys.startDate.id,
                      builder: (field) {
                        final hasValue = field.value != null;
                        final valueLabel = hasValue
                            ? DateDisplayUtils.formatMonthDayYear(field.value!)
                            : null;
                        return Builder(
                          builder: (chipContext) => TasklyFormDateChip(
                            icon: Icons.calendar_today_rounded,
                            label: context.l10n.dateChipAddPlannedDay,
                            valueLabel: valueLabel,
                            hasValue: hasValue,
                            onTap: () async {
                              final decision = await _pickDate(
                                anchorContext: chipContext,
                                title: context.l10n.dateChipAddPlannedDay,
                                initialDate: field.value,
                              );
                              if (decision == null || !mounted) return;
                              if (decision.keep) return;
                              field.didChange(decision.date);
                              markDirty();
                              setState(() {});
                            },
                            onClear: hasValue
                                ? () {
                                    field.didChange(null);
                                    markDirty();
                                    setState(() {});
                                  }
                                : null,
                            preset: TasklyFormPreset.standard.chip,
                          ),
                        );
                      },
                    ),

                    FormBuilderField<DateTime?>(
                      name: TaskFieldKeys.deadlineDate.id,
                      builder: (field) {
                        final hasValue = field.value != null;
                        final valueLabel = hasValue
                            ? DateDisplayUtils.formatMonthDayYear(field.value!)
                            : null;
                        final isOverdue = DateDisplayUtils.isOverdue(
                          field.value,
                        );
                        return Builder(
                          builder: (chipContext) => TasklyFormDateChip(
                            icon: Icons.flag_rounded,
                            label: context.l10n.dateChipAddDueDate,
                            valueLabel: valueLabel,
                            hasValue: hasValue,
                            isDeadline: true,
                            isOverdue: isOverdue,
                            onTap: () async {
                              final decision = await _pickDate(
                                anchorContext: chipContext,
                                title: context.l10n.dateChipAddDueDate,
                                initialDate: field.value,
                              );
                              if (decision == null || !mounted) return;
                              if (decision.keep) return;
                              field.didChange(decision.date);
                              markDirty();
                              setState(() {});
                            },
                            onClear: hasValue
                                ? () {
                                    field.didChange(null);
                                    markDirty();
                                    setState(() {});
                                  }
                                : null,
                            preset: TasklyFormPreset.standard.chip,
                          ),
                        );
                      },
                    ),

                    FormBuilderField<int?>(
                      name: TaskFieldKeys.priority.id,
                      builder: (field) {
                        return Builder(
                          builder: (chipContext) => TasklyFormPriorityChip(
                            label: field.value == null
                                ? l10n.priorityLabel
                                : 'P${field.value}',
                            hasValue: field.value != null,
                            onTap: () async {
                              final decision = await _pickPriority(
                                anchorContext: chipContext,
                                current: field.value,
                              );
                              if (decision == null || !mounted) return;
                              if (decision.keep) return;
                              field.didChange(decision.value);
                              markDirty();
                              setState(() {});
                            },
                            onClear: field.value != null
                                ? () {
                                    field.didChange(null);
                                    markDirty();
                                    setState(() {});
                                  }
                                : null,
                            preset: TasklyFormPreset.standard.chip,
                          ),
                        );
                      },
                    ),

                    FormBuilderField<String?>(
                      name: TaskFieldKeys.repeatIcalRrule.id,
                      builder: (field) {
                        return Builder(
                          builder: (chipContext) => RruleFormRecurrenceChip(
                            rrule: field.value,
                            emptyLabel: context.l10n.recurrenceRepeatTitle,
                            onTap: () async {
                              final repeatFromCompletionField =
                                  widget
                                      .formKey
                                      .currentState
                                      ?.fields[TaskFieldKeys
                                      .repeatFromCompletion
                                      .id];
                              final seriesEndedField = widget
                                  .formKey
                                  .currentState
                                  ?.fields[TaskFieldKeys.seriesEnded.id];

                              final result = await _pickRecurrence(
                                anchorContext: chipContext,
                                initialRrule: field.value,
                                initialRepeatFromCompletion:
                                    (repeatFromCompletionField?.value
                                        as bool?) ??
                                    false,
                                initialSeriesEnded:
                                    (seriesEndedField?.value as bool?) ?? false,
                              );

                              if (result == null) return;
                              field.didChange(result.rrule);
                              repeatFromCompletionField?.didChange(
                                result.repeatFromCompletion,
                              );
                              seriesEndedField?.didChange(result.seriesEnded);
                              markDirty();
                              setState(() {});
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
                                    setState(() {});
                                  }
                                : null,
                          ),
                        );
                      },
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

final class _NullableIntDecision {
  const _NullableIntDecision.keep() : keep = true, value = null;

  const _NullableIntDecision.set(this.value) : keep = false;

  final bool keep;
  final int? value;
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

class _TaskDatePickerPanel extends StatefulWidget {
  const _TaskDatePickerPanel({required this.title, required this.initialDate});

  final String title;
  final DateTime? initialDate;

  @override
  State<_TaskDatePickerPanel> createState() => _TaskDatePickerPanelState();
}

class _TaskDatePickerPanelState extends State<_TaskDatePickerPanel> {
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

class _PriorityPickerPanel extends StatelessWidget {
  const _PriorityPickerPanel({required this.current});

  final int? current;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    Widget item({
      required String label,
      required int? value,
      required bool emphasized,
    }) {
      final selected = current == value;
      return ListTile(
        title: Text(label),
        leading: Icon(
          emphasized ? Icons.flag_rounded : Icons.flag_outlined,
          color: emphasized
              ? scheme.primary
              : scheme.onSurfaceVariant.withValues(alpha: 0.8),
        ),
        trailing: selected ? const Icon(Icons.check) : null,
        onTap: () => Navigator.of(context).pop(
          _NullableIntDecision.set(selected ? null : value),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.priorityLabel,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ),
        item(label: 'P1', value: 1, emphasized: true),
        item(label: 'P2', value: 2, emphasized: true),
        item(label: 'P3', value: 3, emphasized: false),
        item(label: 'P4', value: 4, emphasized: false),
        const Divider(height: 1),
        ListTile(
          title: Text(l10n.cancelLabel),
          onTap: () =>
              Navigator.of(context).pop(const _NullableIntDecision.keep()),
        ),
      ],
    );
  }
}

/// A chip widget for displaying and selecting projects.
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
