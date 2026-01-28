import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
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
import 'package:taskly_ui/taskly_ui_tokens.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:provider/provider.dart';

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
  String? _recurrenceLabel;
  String? _lastRecurrenceRrule;

  Project? _findProjectById(String? id) {
    final normalized = (id ?? '').trim();
    if (normalized.isEmpty) return null;
    return widget.availableProjects
        .where((p) => p.id == normalized)
        .firstOrNull;
  }

  bool _projectHasPrimaryValue(Project? project) {
    return project?.primaryValueId?.trim().isNotEmpty ?? false;
  }

  void _clearTagsIfNotAllowed() {
    final formState = widget.formKey.currentState;
    if (formState == null) return;
    final projectId =
        formState.fields[TaskFieldKeys.projectId.id]?.value as String?;
    final project = _findProjectById(projectId);
    final primaryId = project?.primaryValueId?.trim();
    final hasPrimary = primaryId != null && primaryId.isNotEmpty;

    final valuesField = formState.fields[TaskFieldKeys.valueIds.id];
    final valueIds = List<String>.of(
      (valuesField?.value as List<String>?) ?? const <String>[],
    );
    if (valueIds.isEmpty) return;

    if (!hasPrimary) {
      valuesField?.didChange(const <String>[]);
      valuesField?.validate();
      return;
    }

    final next = valueIds.where((id) => id.trim() != primaryId).toList();
    if (next.length == valueIds.length) return;

    valuesField?.didChange(next);
    valuesField?.validate();
  }

  void _recordRecentProjectId(String projectId) {
    final id = projectId.trim();
    if (id.isEmpty) return;
    _recentProjectIds.remove(id);
    _recentProjectIds.insert(0, id);
    if (_recentProjectIds.length > 5) {
      _recentProjectIds.removeRange(5, _recentProjectIds.length);
    }
  }

  void _updateRecurrenceLabel(String? rrule) {
    final normalized = (rrule ?? '').trim();
    if (normalized == _lastRecurrenceRrule) return;
    _lastRecurrenceRrule = normalized;

    if (normalized.isEmpty) {
      if (_recurrenceLabel == null) return;
      setState(() => _recurrenceLabel = null);
      return;
    }

    if (_recurrenceLabel != null) {
      setState(() => _recurrenceLabel = null);
    }

    final requestRrule = normalized;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final label = await resolveRruleLabel(context, requestRrule);
      if (!mounted || _lastRecurrenceRrule != requestRrule) return;
      setState(() => _recurrenceLabel = label);
    });
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _updateRecurrenceLabel(widget.initialData?.repeatIcalRrule);
    });

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

        _clearTagsIfNotAllowed();
        markDirty();
        setState(() {});
        return;
      }

      if (widget.openToValues) {
        final projectId =
            widget
                    .formKey
                    .currentState
                    ?.fields[TaskFieldKeys.projectId.id]
                    ?.value
                as String?;
        final project = _findProjectById(projectId);
        if (!_projectHasPrimaryValue(project)) return;

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

        final result = await _showValuesAlignmentPicker(
          anchorContext: anchorContext,
          explicitValueIds: explicitValueIds,
          target: ValuesAlignmentTarget.primary,
          inheritedValueLabel: project?.primaryValue?.name,
          inheritedValueId: project?.primaryValue?.id,
        );
        if (!context.mounted || result == null) return;

        widget.formKey.currentState?.fields[TaskFieldKeys.valueIds.id]
            ?.didChange(result);
        markDirty();
        setState(() {});
      }
    });
  }

  @override
  void didUpdateWidget(covariant TaskForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialData?.repeatIcalRrule !=
        widget.initialData?.repeatIcalRrule) {
      _updateRecurrenceLabel(widget.initialData?.repeatIcalRrule);
    }
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
    required ValuesAlignmentTarget target,
    String? inheritedValueLabel,
    String? inheritedValueId,
  }) {
    if (_isCompact(context)) {
      return showValuesAlignmentSheetForTask(
        context,
        availableValues: widget.availableValues,
        explicitValueIds: explicitValueIds,
        target: target,
        inheritedValueLabel: inheritedValueLabel,
        inheritedValueId: inheritedValueId,
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
          target: target,
          inheritedValueLabel: inheritedValueLabel,
          inheritedValueId: inheritedValueId,
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
    final now = context.read<NowService>().nowLocal();

    final availableValuesById = <String, Value>{
      for (final v in widget.availableValues) v.id: v,
    };

    final initialProjectId =
        widget.initialData?.projectId ?? widget.defaultProjectId ?? '';
    final initialProject = _findProjectById(initialProjectId);
    final initialTagsEnabled = _projectHasPrimaryValue(initialProject);

    final initialValues = <String, dynamic>{
      TaskFieldKeys.name.id: widget.initialData?.name ?? '',
      TaskFieldKeys.description.id: widget.initialData?.description ?? '',
      TaskFieldKeys.completed.id: widget.initialData?.completed ?? false,
      TaskFieldKeys.startDate.id:
          widget.initialData?.startDate ?? widget.defaultStartDate,
      TaskFieldKeys.deadlineDate.id:
          widget.initialData?.deadlineDate ?? widget.defaultDeadlineDate,
      TaskFieldKeys.projectId.id: initialProjectId,
      TaskFieldKeys.priority.id: widget.initialData?.priority,
      TaskFieldKeys.valueIds.id: initialTagsEnabled
          ? (widget.initialData?.values.map((e) => e.id).toList() ??
                (widget.defaultValueIds ?? const <String>[]))
          : const <String>[],
      TaskFieldKeys.repeatIcalRrule.id:
          widget.initialData?.repeatIcalRrule ?? '',
      TaskFieldKeys.repeatFromCompletion.id:
          widget.initialData?.repeatFromCompletion ?? false,
      TaskFieldKeys.seriesEnded.id: widget.initialData?.seriesEnded ?? false,
    };

    final submitEnabled =
        isDirty && (widget.formKey.currentState?.isValid ?? false);

    final sectionGap = isCompact ? 12.0 : 16.0;
    final denseFieldPadding = EdgeInsets.symmetric(
      horizontal: isCompact ? 12 : 16,
      vertical: isCompact ? 10 : 12,
    );

    final headerActionStyle = TextButton.styleFrom(
      textStyle: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
    final headerTitle = Text(
      isCreating ? l10n.taskFormNewTitle : l10n.taskFormEditTitle,
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
      deleteTooltip: l10n.deleteTaskAction,
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
      trailingActions: [
        ...widget.trailingActions,
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
        padding: EdgeInsets.only(
          bottom: isCompact
              ? TasklyTokens.of(context).spaceLg
              : TasklyTokens.of(context).spaceXl,
        ),
        child: FormBuilder(
          key: widget.formKey,
          initialValue: initialValues,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: () {
            markDirty();
            setState(() {});
            _clearTagsIfNotAllowed();
            final rrule =
                widget
                        .formKey
                        .currentState
                        ?.fields[TaskFieldKeys.repeatIcalRrule.id]
                        ?.value
                    as String?;
            _updateRecurrenceLabel(rrule);
            final values = widget.formKey.currentState?.value;
            if (values != null) {
              widget.onChanged?.call(values);
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: TasklyTokens.of(context).spaceSm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isCreating)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: TasklyTokens.of(context).spaceSm,
                      ),
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
                                borderRadius: BorderRadius.circular(
                                  TasklyTokens.of(context).radiusSm,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  if (!isCreating)
                    SizedBox(height: TasklyTokens.of(context).spaceSm),
                  Expanded(
                    child: FormBuilderTextField(
                      name: TaskFieldKeys.name.id,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      decoration:
                          const InputDecoration(
                            border: InputBorder.none,
                            hintText: '',
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ).copyWith(
                            hintText: l10n.taskFormNameHint,
                          ),
                      validator: toFormBuilderValidator<String>(
                        TaskValidators.name,
                        context,
                      ),
                    ),
                  ),
                ],
              ),

              if (isCreating)
                FormBuilderField<bool>(
                  name: TaskFieldKeys.completed.id,
                  builder: (_) => SizedBox.shrink(),
                ),

              SizedBox(height: sectionGap),

              if (widget.availableProjects.isNotEmpty) ...[
                TasklyFormSectionLabel(text: l10n.projectLabel),
                SizedBox(height: TasklyTokens.of(context).spaceSm),
                FormBuilderField<String>(
                  name: TaskFieldKeys.projectId.id,
                  builder: (field) {
                    final selectedProject = widget.availableProjects
                        .where((p) => p.id == field.value)
                        .firstOrNull;

                    return KeyedSubtree(
                      key: _projectKey,
                      child: Builder(
                        builder: (chipContext) => TasklyFormProjectRow(
                          label:
                              selectedProject?.name ??
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
                            _clearTagsIfNotAllowed();
                            setState(() {});
                          },
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: sectionGap),
              ],

              Builder(
                builder: (context) {
                  final projectId =
                      widget
                              .formKey
                              .currentState
                              ?.fields[TaskFieldKeys.projectId.id]
                              ?.value
                          as String?;
                  final project = _findProjectById(projectId);
                  if (project == null) return SizedBox.shrink();

                  final primaryValue = project.primaryValue;
                  final hasProjectPrimary = _projectHasPrimaryValue(project);

                  TasklyFormValueChipModel? primaryChip;
                  if (primaryValue != null) {
                    final iconData =
                        getIconDataFromName(primaryValue.iconName) ??
                        Icons.star;
                    final color = ColorUtils.valueColorForTheme(
                      context,
                      primaryValue.color,
                    );
                    primaryChip = TasklyFormValueChipModel(
                      label: primaryValue.name,
                      color: color,
                      icon: iconData,
                      semanticLabel: primaryValue.name,
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TasklyFormSectionLabel(
                        text: l10n.taskProjectValueTitle,
                      ),
                      SizedBox(height: TasklyTokens.of(context).spaceSm),
                      if (primaryChip != null)
                        Row(
                          children: [
                            AbsorbPointer(
                              child: TasklyFormValueChip(
                                model: primaryChip,
                                onTap: () {},
                                isSelected: true,
                                isPrimary: true,
                                preset: TasklyFormChipPreset.standard(
                                  TasklyTokens.of(context),
                                ),
                              ),
                            ),
                            SizedBox(height: TasklyTokens.of(context).spaceSm),
                            Icon(
                              Icons.lock_outline,
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            SizedBox(height: TasklyTokens.of(context).spaceSm),
                            Text(
                              l10n.taskProjectValueLockedLabel,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          l10n.taskProjectValueNotSet,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      SizedBox(height: TasklyTokens.of(context).spaceSm),
                      if (!hasProjectPrimary)
                        Text(
                          l10n.taskAdditionalValuesDisabled,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        )
                      else ...[
                        TasklyFormSectionLabel(
                          text: l10n.taskAdditionalValuesTitle,
                        ),
                        SizedBox(height: TasklyTokens.of(context).spaceSm),
                        Text(
                          l10n.taskAdditionalValuesHelper,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: TasklyTokens.of(context).spaceSm),
                        FormBuilderField<List<String>>(
                          name: TaskFieldKeys.valueIds.id,
                          validator: (value) {
                            final projectId =
                                widget
                                        .formKey
                                        .currentState
                                        ?.fields[TaskFieldKeys.projectId.id]
                                        ?.value
                                    as String?;
                            final project = _findProjectById(projectId);
                            return toFormBuilderValidator<List<String>>(
                              (ids) => TaskValidators.valueIds(
                                ids,
                                projectId: projectId,
                                projectPrimaryValueId: project?.primaryValueId,
                              ),
                              context,
                            )(value);
                          },
                          builder: (field) {
                            final explicitValueIds = List<String>.of(
                              field.value ?? const <String>[],
                            );
                            final explicitIds = explicitValueIds
                                .take(2)
                                .toList(growable: false);

                            final primary = explicitIds.isEmpty
                                ? null
                                : availableValuesById[explicitIds.first];
                            final secondary = explicitIds.length < 2
                                ? null
                                : availableValuesById[explicitIds[1]];

                            return Builder(
                              builder: (chipContext) {
                                Future<void> open(
                                  ValuesAlignmentTarget target,
                                ) async {
                                  final result =
                                      await _showValuesAlignmentPicker(
                                        anchorContext: chipContext,
                                        explicitValueIds: explicitValueIds,
                                        target: target,
                                        inheritedValueLabel: primaryValue?.name,
                                        inheritedValueId: primaryValue?.id,
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
                                  final color = ColorUtils.valueColorForTheme(
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
                                final secondaryEnabled = primary != null;
                                final primaryPlaceholder =
                                    TasklyFormValueChipModel(
                                      label: context
                                          .l10n
                                          .taskAdditionalValuePrimaryLabel,
                                      color: theme.colorScheme.onSurfaceVariant,
                                      icon: Icons.label_outline,
                                      semanticLabel: context
                                          .l10n
                                          .taskAdditionalValuePrimaryLabel,
                                    );
                                final secondaryPlaceholder =
                                    TasklyFormValueChipModel(
                                      label: context
                                          .l10n
                                          .taskAdditionalValueSecondaryLabel,
                                      color: theme.colorScheme.onSurfaceVariant,
                                      icon: Icons.label_outline,
                                      semanticLabel: context
                                          .l10n
                                          .taskAdditionalValueSecondaryLabel,
                                    );

                                return KeyedSubtree(
                                  key: _valuesKey,
                                  child: TasklyFormRowGroup(
                                    spacing: 12,
                                    runSpacing: 8,
                                    children: [
                                      TasklyFormValueChip(
                                        model: primary != null
                                            ? toModel(primary)
                                            : primaryPlaceholder,
                                        onTap: () => open(
                                          ValuesAlignmentTarget.primary,
                                        ),
                                        isSelected: primary != null,
                                        isPrimary: true,
                                        preset: TasklyFormChipPreset.standard(
                                          TasklyTokens.of(context),
                                        ),
                                      ),
                                      Opacity(
                                        opacity: secondaryEnabled ? 1 : 0.55,
                                        child: AbsorbPointer(
                                          absorbing: !secondaryEnabled,
                                          child: TasklyFormValueChip(
                                            model: secondary != null
                                                ? toModel(secondary)
                                                : secondaryPlaceholder,
                                            onTap: () => open(
                                              ValuesAlignmentTarget.secondary,
                                            ),
                                            isSelected: secondary != null,
                                            isPrimary: false,
                                            preset:
                                                TasklyFormChipPreset.standard(
                                                  TasklyTokens.of(context),
                                                ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        Builder(
                          builder: (context) {
                            final errorText = widget
                                .formKey
                                .currentState
                                ?.fields[TaskFieldKeys.valueIds.id]
                                ?.errorText;
                            if (errorText == null) {
                              return SizedBox.shrink();
                            }
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: TasklyTokens.of(context).spaceSm,
                              ),
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
                      ],
                      SizedBox(height: sectionGap),
                    ],
                  );
                },
              ),

              Builder(
                builder: (context) {
                  final startDate =
                      (widget
                              .formKey
                              .currentState
                              ?.fields[TaskFieldKeys.startDate.id]
                              ?.value
                          as DateTime?) ??
                      (initialValues[TaskFieldKeys.startDate.id] as DateTime?);
                  final deadlineDate =
                      (widget
                              .formKey
                              .currentState
                              ?.fields[TaskFieldKeys.deadlineDate.id]
                              ?.value
                          as DateTime?) ??
                      (initialValues[TaskFieldKeys.deadlineDate.id]
                          as DateTime?);
                  final recurrenceRrule =
                      (widget
                              .formKey
                              .currentState
                              ?.fields[TaskFieldKeys.repeatIcalRrule.id]
                              ?.value
                          as String?) ??
                      (initialValues[TaskFieldKeys.repeatIcalRrule.id]
                          as String?) ??
                      '';
                  final hasRecurrence = recurrenceRrule.trim().isNotEmpty;

                  final plannedLabel = startDate == null
                      ? null
                      : DateDisplayUtils.formatMonthDayYear(startDate);
                  final dueLabel = deadlineDate == null
                      ? null
                      : DateDisplayUtils.formatMonthDayYear(deadlineDate);
                  final isOverdue = DateDisplayUtils.isOverdue(
                    deadlineDate,
                    now: now,
                  );

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
                          if (decision == null || !mounted) return;
                          if (decision.keep) return;
                          widget
                              .formKey
                              .currentState
                              ?.fields[TaskFieldKeys.startDate.id]
                              ?.didChange(decision.date);
                          markDirty();
                          setState(() {});
                        },
                        onClear: plannedLabel != null
                            ? () {
                                widget
                                    .formKey
                                    .currentState
                                    ?.fields[TaskFieldKeys.startDate.id]
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
                          if (decision == null || !mounted) return;
                          if (decision.keep) return;
                          widget
                              .formKey
                              .currentState
                              ?.fields[TaskFieldKeys.deadlineDate.id]
                              ?.didChange(decision.date);
                          markDirty();
                          setState(() {});
                        },
                        onClear: dueLabel != null
                            ? () {
                                widget
                                    .formKey
                                    .currentState
                                    ?.fields[TaskFieldKeys.deadlineDate.id]
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
                        valueLabel:
                            _recurrenceLabel ??
                            (hasRecurrence ? l10n.loadingTitle : null),
                        hasValue: hasRecurrence,
                        onTap: () async {
                          final repeatFromCompletionField = widget
                              .formKey
                              .currentState
                              ?.fields[TaskFieldKeys.repeatFromCompletion.id];
                          final seriesEndedField = widget
                              .formKey
                              .currentState
                              ?.fields[TaskFieldKeys.seriesEnded.id];

                          final result = await _pickRecurrence(
                            anchorContext: context,
                            initialRrule: recurrenceRrule,
                            initialRepeatFromCompletion:
                                (repeatFromCompletionField?.value as bool?) ??
                                false,
                            initialSeriesEnded:
                                (seriesEndedField?.value as bool?) ?? false,
                          );

                          if (result == null) return;
                          widget
                              .formKey
                              .currentState
                              ?.fields[TaskFieldKeys.repeatIcalRrule.id]
                              ?.didChange(result.rrule);
                          repeatFromCompletionField?.didChange(
                            result.repeatFromCompletion,
                          );
                          seriesEndedField?.didChange(result.seriesEnded);
                          _updateRecurrenceLabel(result.rrule);
                          markDirty();
                          setState(() {});
                        },
                        onClear: hasRecurrence
                            ? () {
                                widget
                                    .formKey
                                    .currentState
                                    ?.fields[TaskFieldKeys.repeatIcalRrule.id]
                                    ?.didChange(null);
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
                                _updateRecurrenceLabel('');
                                markDirty();
                                setState(() {});
                              }
                            : null,
                      ),
                    ],
                  );
                },
              ),

              SizedBox(height: sectionGap),

              TasklyFormSectionLabel(text: l10n.priorityLabel),
              SizedBox(height: TasklyTokens.of(context).spaceSm),
              FormBuilderField<int?>(
                name: TaskFieldKeys.priority.id,
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

              SizedBox(height: sectionGap),

              FormBuilderTextField(
                name: TaskFieldKeys.description.id,
                textInputAction: TextInputAction.newline,
                maxLines: isCompact ? 3 : 4,
                minLines: isCompact ? 2 : 3,
                decoration: InputDecoration(
                  hintText: l10n.taskFormNotesHint,
                  filled: true,
                  fillColor: colorScheme.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      TasklyTokens.of(context).radiusMd,
                    ),
                    borderSide: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      TasklyTokens.of(context).radiusMd,
                    ),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 1.2,
                    ),
                  ),
                  contentPadding: denseFieldPadding,
                ),
                validator: toFormBuilderValidator<String>(
                  TaskValidators.description,
                  context,
                ),
              ),

              SizedBox(height: sectionGap),

              FormBuilderField<DateTime?>(
                name: TaskFieldKeys.startDate.id,
                builder: (_) => SizedBox.shrink(),
              ),
              FormBuilderField<DateTime?>(
                name: TaskFieldKeys.deadlineDate.id,
                builder: (_) => SizedBox.shrink(),
              ),
              FormBuilderField<String?>(
                name: TaskFieldKeys.repeatIcalRrule.id,
                builder: (_) => SizedBox.shrink(),
              ),

              // Hidden recurrence flags fields (set by the picker)
              FormBuilderField<bool>(
                name: TaskFieldKeys.repeatFromCompletion.id,
                builder: (_) => SizedBox.shrink(),
              ),
              FormBuilderField<bool>(
                name: TaskFieldKeys.seriesEnded.id,
                builder: (_) => SizedBox.shrink(),
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
    final now = context.read<NowService>().nowLocal();
    _selected = widget.initialDate ?? now;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final now = context.read<NowService>().nowLocal();
    final today = dateOnly(now);
    final tomorrow = today.add(const Duration(days: 1));
    final nextWeek = today.add(const Duration(days: 7));

    return Padding(
      padding: EdgeInsets.all(TasklyTokens.of(context).spaceLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          SizedBox(height: TasklyTokens.of(context).spaceSm),
          TasklyFormQuickPickChips(
            preset: TasklyFormPreset.standard(TasklyTokens.of(context)),
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
          SizedBox(height: TasklyTokens.of(context).spaceSm),
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(
                TasklyTokens.of(context).radiusMd,
              ),
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
          SizedBox(height: TasklyTokens.of(context).spaceSm),
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
              padding: EdgeInsets.fromLTRB(
                TasklyTokens.of(context).spaceLg,
                TasklyTokens.of(context).spaceLg,
                TasklyTokens.of(context).spaceSm,
                TasklyTokens.of(context).spaceSm,
              ),
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
              padding: EdgeInsets.fromLTRB(
                TasklyTokens.of(context).spaceLg,
                0,
                TasklyTokens.of(context).spaceLg,
                TasklyTokens.of(context).spaceMd,
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.projectPickerSearchHint,
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      TasklyTokens.of(context).radiusMd,
                    ),
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
                      padding: EdgeInsets.fromLTRB(
                        TasklyTokens.of(context).spaceLg,
                        TasklyTokens.of(context).spaceMd,
                        TasklyTokens.of(context).spaceLg,
                        TasklyTokens.of(context).spaceXs,
                      ),
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
                      padding: EdgeInsets.all(TasklyTokens.of(context).spaceLg),
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
