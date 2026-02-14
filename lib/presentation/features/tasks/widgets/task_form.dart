import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/shared/utils/date_display_utils.dart';
import 'package:taskly_bloc/presentation/shared/utils/form_utils.dart';
import 'package:taskly_bloc/presentation/shared/utils/rrule_label_utils.dart';
import 'package:taskly_bloc/presentation/shared/validation/form_builder_validator_adapter.dart';
import 'package:taskly_bloc/presentation/widgets/recurrence_picker.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_bloc/presentation/shared/utils/debouncer.dart';
import 'package:taskly_bloc/presentation/shared/widgets/project_picker_content.dart';
import 'package:taskly_bloc/presentation/shared/widgets/form_footer_bar.dart';
import 'package:taskly_bloc/presentation/shared/widgets/anchored_dialog_layout_delegate.dart';
import 'package:taskly_bloc/presentation/shared/widgets/inline_date_editor_panel.dart';
import 'package:taskly_bloc/presentation/widgets/icon_picker/icon_catalog.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_ui/taskly_ui_forms.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:provider/provider.dart';
import 'package:taskly_bloc/presentation/features/navigation/services/navigation_icon_resolver.dart';

abstract final class TaskFormFieldKeys {
  static const includeInMyDay = 'task.includeInMyDay';
}

enum _TaskDateEditorTarget { planned, due }

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
    this.defaultStartDate,
    this.defaultDeadlineDate,
    this.openToProjectPicker = false,
    this.includeInMyDayDefault = false,
    this.showMyDayToggle = false,
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

  /// Optional planned day to prefill when creating a new task.
  final DateTime? defaultStartDate;

  /// Optional due date to prefill when creating a new task.
  final DateTime? defaultDeadlineDate;

  /// When true, scrolls to the project picker and opens the picker dialog.
  final bool openToProjectPicker;

  /// When true, defaults the include-in-My-Day toggle to on.
  final bool includeInMyDayDefault;

  /// When true, shows the include-in-My-Day toggle.
  final bool showMyDayToggle;

  /// Called when the user wants to close the form.
  /// If null, no close button is shown.
  final VoidCallback? onClose;

  /// Optional action widgets to render in the header row (right side).
  final List<Widget> trailingActions;

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> with FormDirtyStateMixin {
  static const _draftSyncDebounce = Duration(milliseconds: 400);

  @override
  VoidCallback? get onClose => widget.onClose;

  final _scrollController = ScrollController();
  final GlobalKey<State<StatefulWidget>> _projectKey = GlobalKey();
  final FocusNode _descriptionFocusNode = FocusNode();
  final Debouncer _draftSyncDebouncer = Debouncer(_draftSyncDebounce);
  bool _didAutoOpen = false;
  bool _submitEnabled = false;
  final List<String> _recentProjectIds = <String>[];
  String? _recurrenceLabel;
  String? _lastRecurrenceRrule;
  _TaskDateEditorTarget? _activeDateEditor;

  Project? _findProjectById(String? id) {
    final normalized = (id ?? '').trim();
    if (normalized.isEmpty) return null;
    return widget.availableProjects
        .where((p) => p.id == normalized)
        .firstOrNull;
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

  void _handleFormChanged() {
    markDirty();
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
    setState(() => _submitEnabled = next);
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
      if (!widget.openToProjectPicker) return;
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
          case ProjectPickerResultCleared():
            widget.formKey.currentState?.fields[TaskFieldKeys.projectId.id]
                ?.didChange('');
          case ProjectPickerResultSelected(:final project):
            widget.formKey.currentState?.fields[TaskFieldKeys.projectId.id]
                ?.didChange(project.id);
            _recordRecentProjectId(project.id);
        }

        markDirty();
        setState(() {});
        return;
      }
    });
  }

  @override
  void dispose() {
    _draftSyncDebouncer.dispose();
    _scrollController.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
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
              delegate: AnchoredDialogLayoutDelegate(
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

  Future<ProjectPickerResult?> _showProjectPicker({
    required BuildContext anchorContext,
    required String currentProjectId,
  }) {
    if (_isCompact(context)) {
      return showModalBottomSheet<ProjectPickerResult>(
        context: context,
        useSafeArea: true,
        showDragHandle: false,
        isScrollControlled: true,
        builder: (sheetContext) => ProjectPickerContent(
          availableProjects: widget.availableProjects,
          currentProjectId: currentProjectId,
          recentProjectIds: List<String>.unmodifiable(_recentProjectIds),
        ),
      );
    }

    return _showAnchoredDialog<ProjectPickerResult>(
      context,
      anchorContext: anchorContext,
      maxWidth: 460,
      maxHeight: 520,
      builder: (dialogContext) => ProjectPickerContent(
        availableProjects: widget.availableProjects,
        currentProjectId: currentProjectId,
        recentProjectIds: List<String>.unmodifiable(_recentProjectIds),
      ),
    );
  }

  void _toggleDateEditor(_TaskDateEditorTarget target) {
    setState(() {
      _activeDateEditor = _activeDateEditor == target ? null : target;
    });
  }

  void _setDateForTarget(_TaskDateEditorTarget target, DateTime? value) {
    final fieldKey = target == _TaskDateEditorTarget.planned
        ? TaskFieldKeys.startDate.id
        : TaskFieldKeys.deadlineDate.id;
    widget.formKey.currentState?.fields[fieldKey]?.didChange(value);
    markDirty();
    setState(() => _activeDateEditor = null);
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
        showDragHandle: false,
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

  Future<_PrioritySelectionResult?> _pickPriority({
    required BuildContext anchorContext,
    required int? initialPriority,
  }) {
    if (_isCompact(context)) {
      return _showPriorityMenu(anchorContext: anchorContext);
    }

    return _showAnchoredDialog<_PrioritySelectionResult>(
      context,
      anchorContext: anchorContext,
      maxWidth: 280,
      maxHeight: 320,
      builder: (dialogContext) {
        final l10n = dialogContext.l10n;
        final current = initialPriority;
        final options = [
          (value: null as int?, label: l10n.sortFieldNoneLabel),
          (value: 1 as int?, label: l10n.priorityP1Label),
          (value: 2 as int?, label: l10n.priorityP2Label),
          (value: 3 as int?, label: l10n.priorityP3Label),
          (value: 4 as int?, label: l10n.priorityP4Label),
        ];

        return ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 240),
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            children: [
              for (final option in options)
                ListTile(
                  dense: true,
                  leading: Icon(
                    current == option.value
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                  ),
                  title: Text(option.label),
                  onTap: () => Navigator.of(dialogContext).pop(
                    _PrioritySelectionResult(priority: option.value),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<_PrioritySelectionResult?> _showPriorityMenu({
    required BuildContext anchorContext,
  }) async {
    final l10n = context.l10n;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final anchor = _anchorRect(anchorContext);
    final selected = await showMenu<int>(
      context: context,
      position: RelativeRect.fromRect(anchor, Offset.zero & overlay.size),
      items: [
        PopupMenuItem<int>(
          value: -1,
          child: Text(l10n.sortFieldNoneLabel),
        ),
        PopupMenuItem<int>(
          value: 1,
          child: Text(l10n.priorityP1Label),
        ),
        PopupMenuItem<int>(
          value: 2,
          child: Text(l10n.priorityP2Label),
        ),
        PopupMenuItem<int>(
          value: 3,
          child: Text(l10n.priorityP3Label),
        ),
        PopupMenuItem<int>(
          value: 4,
          child: Text(l10n.priorityP4Label),
        ),
      ],
    );
    if (selected == null) return null;
    return _PrioritySelectionResult(priority: selected == -1 ? null : selected);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = TasklyTokens.of(context);
    final isCompact = _isCompact(context);
    final isCreating = widget.initialData == null;
    final now = context.read<NowService>().nowLocal();
    final myDayIcon = const NavigationIconResolver().resolve(
      screenId: 'my_day',
      iconName: null,
    );

    final initialProjectId =
        widget.initialData?.projectId ?? widget.defaultProjectId ?? '';

    final initialValues = <String, dynamic>{
      TaskFieldKeys.name.id: widget.initialData?.name ?? '',
      TaskFieldKeys.description.id: widget.initialData?.description ?? '',
      TaskFieldKeys.completed.id: widget.initialData?.completed ?? false,
      TaskFormFieldKeys.includeInMyDay: widget.includeInMyDayDefault,
      TaskFieldKeys.startDate.id:
          widget.initialData?.startDate ?? widget.defaultStartDate,
      TaskFieldKeys.deadlineDate.id:
          widget.initialData?.deadlineDate ?? widget.defaultDeadlineDate,
      TaskFieldKeys.projectId.id: initialProjectId,
      TaskFieldKeys.priority.id: widget.initialData?.priority,
      TaskFieldKeys.repeatIcalRrule.id:
          widget.initialData?.repeatIcalRrule ?? '',
      TaskFieldKeys.repeatFromCompletion.id:
          widget.initialData?.repeatFromCompletion ?? false,
      TaskFieldKeys.seriesEnded.id: widget.initialData?.seriesEnded ?? false,
    };

    final submitEnabled = _submitEnabled;

    final formPreset = TasklyFormPreset.standard(tokens);
    final sectionGap = isCompact
        ? formPreset.ux.sectionGapCompact
        : formPreset.ux.sectionGapRegular;
    return FormShell(
      onSubmit: widget.onSubmit,
      submitTooltip: widget.submitTooltip,
      submitIcon: isCreating ? Icons.add_rounded : Icons.check_rounded,
      submitEnabled: submitEnabled,
      showHeaderSubmit: false,
      showFooterSubmit: true,
      closeOnLeft: false,
      onDelete: null,
      deleteTooltip: l10n.deleteTaskAction,
      onClose: handleClose,
      closeTooltip: l10n.closeLabel,
      scrollController: _scrollController,
      showHandleBar: false,
      headerPadding: EdgeInsets.fromLTRB(
        tokens.spaceSm,
        tokens.spaceSm,
        tokens.spaceSm,
        0,
      ),
      footer: Builder(
        builder: (context) {
          final footerPreset = formPreset.chip;
          final submitLabel = widget.submitTooltip;

          return FormFooterBar(
            submitLabel: submitLabel,
            submitEnabled: submitEnabled,
            onSubmit: widget.onSubmit,
            leading: FormBuilderField<String>(
              name: TaskFieldKeys.projectId.id,
              builder: (field) {
                final selectedProject = widget.availableProjects
                    .where((p) => p.id == field.value)
                    .firstOrNull;
                final isInbox = (field.value ?? '').trim().isEmpty;
                final projectLabel =
                    selectedProject?.name ?? (isInbox ? l10n.inboxLabel : null);
                final projectIcon = isInbox
                    ? Icons.inbox_outlined
                    : Icons.folder_rounded;
                final hasProjectValue = selectedProject != null || isInbox;

                return Align(
                  alignment: Alignment.centerLeft,
                  child: KeyedSubtree(
                    key: _projectKey,
                    child: Builder(
                      builder: (chipContext) => TasklyFormInlineChip(
                        label: l10n.projectLabel,
                        valueLabel: projectLabel,
                        hasValue: hasProjectValue,
                        icon: projectIcon,
                        preset: footerPreset,
                        onTap: () async {
                          final result = await _showProjectPicker(
                            anchorContext: chipContext,
                            currentProjectId: field.value ?? '',
                          );
                          if (result == null) return;

                          switch (result) {
                            case ProjectPickerResultCleared():
                              field.didChange('');
                            case ProjectPickerResultSelected(
                              :final project,
                            ):
                              field.didChange(project.id);
                              _recordRecentProjectId(project.id);
                          }

                          markDirty();
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      trailingActions: widget.trailingActions,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: isCompact ? tokens.spaceLg : tokens.spaceXl,
        ),
        child: FormBuilder(
          key: widget.formKey,
          initialValue: initialValues,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: _handleFormChanged,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: tokens.spaceMd),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isCreating)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: tokens.spaceSm,
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
                    child: TasklyFormTitleField(
                      name: TaskFieldKeys.name.id,
                      hintText: l10n.taskFormNameHint,
                      autofocus: isCreating,
                      onSubmitted: (_) => _descriptionFocusNode.requestFocus(),
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

              TasklyFormNotesField(
                name: TaskFieldKeys.description.id,
                hintText: l10n.taskFormNotesHint,
                contentPadding: formPreset.ux.notesContentPadding,
                maxLines: isCompact
                    ? formPreset.ux.notesMaxLinesCompact
                    : formPreset.ux.notesMaxLinesRegular,
                minLines: isCompact
                    ? formPreset.ux.notesMinLinesCompact
                    : formPreset.ux.notesMinLinesRegular,
                focusNode: _descriptionFocusNode,
                validator: toFormBuilderValidator<String>(
                  TaskValidators.description,
                  context,
                ),
              ),

              SizedBox(height: sectionGap),

              Builder(
                builder: (context) {
                  final chipPreset = formPreset.chip;
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
                  final priority =
                      (widget
                              .formKey
                              .currentState
                              ?.fields[TaskFieldKeys.priority.id]
                              ?.value
                          as int?) ??
                      (initialValues[TaskFieldKeys.priority.id] as int?);
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

                  String? priorityLabel;
                  Color? priorityColor;
                  if (priority == 1) {
                    priorityLabel = l10n.priorityP1Label;
                    priorityColor = colorScheme.error;
                  } else if (priority == 2) {
                    priorityLabel = l10n.priorityP2Label;
                    priorityColor = colorScheme.tertiary;
                  } else if (priority == 3) {
                    priorityLabel = l10n.priorityP3Label;
                    priorityColor = colorScheme.primary;
                  } else if (priority == 4) {
                    priorityLabel = l10n.priorityP4Label;
                    priorityColor = colorScheme.onSurfaceVariant;
                  }

                  final repeatValueLabel = hasRecurrence
                      ? (_recurrenceLabel ?? l10n.loadingTitle)
                      : null;

                  final chips = <Widget>[
                    TasklyFormInlineChip(
                      label: l10n.plannedLabel,
                      icon: Icons.calendar_today_rounded,
                      valueLabel: plannedLabel,
                      hasValue: plannedLabel != null,
                      showLabelWhenEmpty: false,
                      preset: chipPreset,
                      onTap: () => _toggleDateEditor(
                        _TaskDateEditorTarget.planned,
                      ),
                    ),
                    TasklyFormInlineChip(
                      label: l10n.dueLabel,
                      icon: Icons.flag_rounded,
                      valueLabel: dueLabel,
                      hasValue: dueLabel != null,
                      valueColor: isOverdue
                          ? colorScheme.error
                          : colorScheme.primary,
                      showLabelWhenEmpty: false,
                      preset: chipPreset,
                      onTap: () => _toggleDateEditor(_TaskDateEditorTarget.due),
                    ),
                    TasklyFormInlineChip(
                      label: l10n.recurrenceRepeatTitle,
                      icon: Icons.repeat,
                      valueLabel: repeatValueLabel,
                      hasValue: hasRecurrence,
                      showLabelWhenEmpty: false,
                      preset: chipPreset,
                      onTap: () async {
                        if (_activeDateEditor != null) {
                          setState(() => _activeDateEditor = null);
                        }
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
                    ),
                    Builder(
                      builder: (chipContext) => TasklyFormInlineChip(
                        label: l10n.priorityLabel,
                        icon: Icons.priority_high_rounded,
                        valueLabel: priorityLabel,
                        hasValue: priority != null,
                        valueColor: priorityColor,
                        showLabelWhenEmpty: false,
                        preset: chipPreset,
                        onTap: () async {
                          if (_activeDateEditor != null) {
                            setState(() => _activeDateEditor = null);
                          }
                          final result = await _pickPriority(
                            anchorContext: chipContext,
                            initialPriority: priority,
                          );
                          if (!mounted || result == null) return;
                          widget
                              .formKey
                              .currentState
                              ?.fields[TaskFieldKeys.priority.id]
                              ?.didChange(result.priority);
                          markDirty();
                          setState(() {});
                        },
                      ),
                    ),
                  ];

                  if (widget.showMyDayToggle) {
                    chips.add(
                      FormBuilderField<bool>(
                        name: TaskFormFieldKeys.includeInMyDay,
                        builder: (field) {
                          final isSelected = field.value ?? false;
                          final label = l10n.myDayInMyDayLabel;
                          final icon = isSelected
                              ? myDayIcon.selectedIcon
                              : myDayIcon.icon;

                          return TasklyFormInlineChip(
                            label: l10n.myDayAddToMyDayAction,
                            valueLabel: label,
                            hasValue: isSelected,
                            icon: icon,
                            valueColor: colorScheme.primary,
                            showLabelWhenEmpty: false,
                            preset: chipPreset,
                            onTap: () {
                              field.didChange(!isSelected);
                              markDirty();
                              setState(() {});
                            },
                          );
                        },
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TasklyFormChipRow(chips: chips),
                      if (_activeDateEditor != null) ...[
                        SizedBox(height: sectionGap),
                        InlineDateEditorPanel(
                          label:
                              _activeDateEditor == _TaskDateEditorTarget.planned
                              ? l10n.plannedLabel
                              : l10n.dueLabel,
                          icon:
                              _activeDateEditor == _TaskDateEditorTarget.planned
                              ? Icons.calendar_today_rounded
                              : Icons.flag_rounded,
                          now: now,
                          selectedDate:
                              _activeDateEditor == _TaskDateEditorTarget.planned
                              ? startDate
                              : deadlineDate,
                          onDateSelected: (value) {
                            _setDateForTarget(_activeDateEditor!, value);
                          },
                          onClose: () {
                            setState(() => _activeDateEditor = null);
                          },
                        ),
                      ],
                    ],
                  );
                },
              ),

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
                  final iconData = primaryValue == null
                      ? Icons.favorite_border_rounded
                      : (getIconDataFromName(primaryValue.iconName) ??
                            Icons.favorite_rounded);
                  final iconColor = primaryValue == null
                      ? colorScheme.onSurfaceVariant
                      : ColorUtils.valueColorForTheme(
                          context,
                          primaryValue.color,
                        );
                  final valueLabel =
                      primaryValue?.name ?? l10n.taskProjectValueNotSet;

                  return Padding(
                    padding: EdgeInsets.only(top: sectionGap),
                    child: _TaskProjectValueRow(
                      label: l10n.taskProjectValueRowLabel,
                      value: valueLabel,
                      icon: iconData,
                      iconColor: iconColor,
                      hasValue: primaryValue != null,
                    ),
                  );
                },
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
              FormBuilderField<int?>(
                name: TaskFieldKeys.priority.id,
                builder: (_) => SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _PrioritySelectionResult {
  const _PrioritySelectionResult({required this.priority});

  final int? priority;
}

class _TaskProjectValueRow extends StatelessWidget {
  const _TaskProjectValueRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.hasValue,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final bool hasValue;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final valueColor = hasValue ? scheme.onSurface : scheme.onSurfaceVariant;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceMd2,
          vertical: tokens.spaceMd,
        ),
        child: Row(
          children: [
            Container(
              width: tokens.spaceXl + tokens.spaceXs,
              height: tokens.spaceXl + tokens.spaceXs,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: tokens.spaceLg,
                color: iconColor,
              ),
            ),
            SizedBox(width: tokens.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: tokens.spaceXxs),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: valueColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
