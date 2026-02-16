import 'package:flutter/material.dart';
import 'package:characters/characters.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/shared/utils/form_utils.dart';
import 'package:taskly_bloc/presentation/shared/utils/debouncer.dart';
import 'package:taskly_bloc/presentation/shared/validation/form_builder_validator_adapter.dart';
import 'package:taskly_bloc/presentation/shared/widgets/anchored_dialog_layout_delegate.dart';
import 'package:taskly_bloc/presentation/shared/widgets/checklist_editor_section.dart';
import 'package:taskly_bloc/presentation/shared/widgets/project_picker_content.dart';
import 'package:taskly_bloc/presentation/shared/widgets/form_footer_bar.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_ui/taskly_ui_forms.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

abstract final class RoutineFormFieldKeys {
  static const checklistTitles = 'routine.checklistTitles';
}

class RoutineForm extends StatefulWidget {
  const RoutineForm({
    required this.formKey,
    required this.availableProjects,
    required this.onSubmit,
    required this.submitTooltip,
    this.defaultProjectId,
    this.openToProjectPicker = false,
    this.initialData,
    this.initialChecklistTitles = const <String>[],
    this.initialDraft,
    this.onChanged,
    this.onDelete,
    this.onClose,
    super.key,
  });

  final GlobalKey<FormBuilderState> formKey;
  final List<Project> availableProjects;
  final VoidCallback onSubmit;
  final String submitTooltip;
  final String? defaultProjectId;
  final bool openToProjectPicker;
  final Routine? initialData;
  final List<String> initialChecklistTitles;
  final RoutineDraft? initialDraft;
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final VoidCallback? onDelete;
  final VoidCallback? onClose;

  @override
  State<RoutineForm> createState() => _RoutineFormState();
}

class _RoutineFormState extends State<RoutineForm> with FormDirtyStateMixin {
  static const _draftSyncDebounce = Duration(milliseconds: 400);

  late RoutinePeriodType _currentPeriodType;
  late RoutineScheduleMode _currentScheduleMode;
  final _scrollController = ScrollController();
  final GlobalKey<State<StatefulWidget>> _projectKey = GlobalKey();
  final GlobalKey<State<StatefulWidget>> _frequencyKey = GlobalKey();
  final Debouncer _draftSyncDebouncer = Debouncer(_draftSyncDebounce);
  final List<String> _recentProjectIds = <String>[];
  bool _didAutoOpen = false;
  bool _submitEnabled = false;
  bool _showChecklistEditor = false;

  String _resolveInitialProjectId(RoutineDraft? draft) {
    final fromInitialData = widget.initialData?.projectId.trim();
    if (fromInitialData != null && fromInitialData.isNotEmpty) {
      return fromInitialData;
    }

    final fromDraft = draft?.projectId.trim();
    if (fromDraft != null && fromDraft.isNotEmpty) {
      return fromDraft;
    }

    final fromDefault = widget.defaultProjectId?.trim();
    if (fromDefault != null && fromDefault.isNotEmpty) {
      return fromDefault;
    }

    return '';
  }

  @override
  VoidCallback? get onClose => widget.onClose;

  @override
  void initState() {
    super.initState();
    final routine = widget.initialData;
    final draft = widget.initialDraft;
    final period =
        routine?.periodType ?? draft?.periodType ?? RoutinePeriodType.week;
    final schedule =
        routine?.scheduleMode ??
        draft?.scheduleMode ??
        RoutineScheduleMode.flexible;
    _currentPeriodType = period;
    _currentScheduleMode = period == RoutinePeriodType.day
        ? RoutineScheduleMode.flexible
        : schedule;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted || _didAutoOpen) return;
      if (!widget.openToProjectPicker) return;
      _didAutoOpen = true;

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
                  ?.fields[RoutineFieldKeys.projectId.id]
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
          return;
        case ProjectPickerResultSelected(:final project):
          widget.formKey.currentState?.fields[RoutineFieldKeys.projectId.id]
              ?.didChange(project.id);
          _recordRecentProjectId(project.id);
      }

      _markDirtySafely();
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refreshSubmitEnabled();
    });
  }

  @override
  void dispose() {
    _draftSyncDebouncer.dispose();
    _scrollController.dispose();
    super.dispose();
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

  void _onPeriodTypeChanged(RoutinePeriodType next) {
    setState(() {
      _currentPeriodType = next;
    });

    if (next == RoutinePeriodType.day) {
      final scheduleField =
          widget.formKey.currentState?.fields[RoutineFieldKeys.scheduleMode.id];
      if (scheduleField?.value != RoutineScheduleMode.flexible) {
        scheduleField?.didChange(RoutineScheduleMode.flexible);
      }
      _currentScheduleMode = RoutineScheduleMode.flexible;
    }

    _resetScheduleFieldsForPeriod(next);
    _syncTargetCountFromSchedule();
    _markDirtySafely();
  }

  void _onScheduleModeChanged(RoutineScheduleMode next) {
    if (_currentPeriodType == RoutinePeriodType.day) {
      return;
    }
    setState(() {
      _currentScheduleMode = next;
    });

    if (next == RoutineScheduleMode.scheduled &&
        (_currentPeriodType == RoutinePeriodType.day ||
            _currentPeriodType == RoutinePeriodType.fortnight)) {
      final periodField =
          widget.formKey.currentState?.fields[RoutineFieldKeys.periodType.id];
      periodField?.didChange(RoutinePeriodType.week);
      _currentPeriodType = RoutinePeriodType.week;
    }

    _syncTargetCountFromSchedule();
    _markDirtySafely();
  }

  void _resetScheduleFieldsForPeriod(RoutinePeriodType periodType) {
    final form = widget.formKey.currentState;
    if (form == null) return;
    if (periodType != RoutinePeriodType.week) {
      form.fields[RoutineFieldKeys.scheduleDays.id]?.didChange(const <int>[]);
    }
    if (periodType != RoutinePeriodType.month) {
      form.fields[RoutineFieldKeys.scheduleMonthDays.id]?.didChange(
        const <int>[],
      );
    }
  }

  void _syncTargetCountFromSchedule() {
    if (_currentScheduleMode != RoutineScheduleMode.scheduled) return;
    final form = widget.formKey.currentState;
    if (form == null) return;

    int? count;
    if (_currentPeriodType == RoutinePeriodType.week) {
      final days =
          (form.fields[RoutineFieldKeys.scheduleDays.id]?.value
              as List<int>?) ??
          const <int>[];
      count = days.isEmpty ? null : days.length;
    } else if (_currentPeriodType == RoutinePeriodType.month) {
      final days =
          (form.fields[RoutineFieldKeys.scheduleMonthDays.id]?.value
              as List<int>?) ??
          const <int>[];
      count = days.isEmpty ? null : days.length;
    }

    form.fields[RoutineFieldKeys.targetCount.id]?.didChange(count);
  }

  void _markDirtySafely() {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        markDirty();
      });
      return;
    }
    markDirty();
  }

  void _handleFormChanged() {
    _markDirtySafely();
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
    final isCreating = widget.initialData == null;
    final formValid = widget.formKey.currentState?.isValid ?? false;
    final next = isCreating && !isDirty
        ? _hasValidCreateDefaults()
        : (isDirty && formValid);
    if (next == _submitEnabled || !mounted) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _submitEnabled = next);
      });
      return;
    }
    setState(() => _submitEnabled = next);
  }

  bool _isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 600;

  bool _hasValidCreateDefaults() {
    if (widget.initialData != null) return false;
    final draft = widget.initialDraft ?? RoutineDraft.empty();
    final periodType = _currentPeriodType;
    final scheduleMode = _currentScheduleMode;
    final projectId = _resolveInitialProjectId(draft);

    return RoutineValidators.name(draft.name).isEmpty &&
        RoutineValidators.projectId(projectId).isEmpty &&
        RoutineValidators.targetCount(
          draft.targetCount,
          periodType: periodType,
          scheduleMode: scheduleMode,
        ).isEmpty &&
        RoutineValidators.scheduleDays(
          draft.scheduleDays,
          periodType: periodType,
          scheduleMode: scheduleMode,
        ).isEmpty &&
        RoutineValidators.scheduleMonthDays(
          draft.scheduleMonthDays,
          periodType: periodType,
          scheduleMode: scheduleMode,
        ).isEmpty;
  }

  Future<void> _focusFrequencySection() async {
    final targetContext = _frequencyKey.currentContext;
    if (targetContext == null) return;
    await Scrollable.ensureVisible(
      targetContext,
      alignment: 0.08,
      duration: const Duration(milliseconds: 220),
    );
  }

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
          allowNoProject: false,
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
        allowNoProject: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isCreating = widget.initialData == null;
    final tokens = TasklyTokens.of(context);

    final RoutineDraft? draft = widget.initialData == null
        ? (widget.initialDraft ?? RoutineDraft.empty())
        : null;

    final scheduleDays =
        widget.initialData?.scheduleDays ?? draft?.scheduleDays ?? <int>[];
    final scheduleMonthDays =
        widget.initialData?.scheduleMonthDays ??
        draft?.scheduleMonthDays ??
        <int>[];
    final initialTargetCount =
        widget.initialData?.targetCount ?? draft?.targetCount;
    final formPreset = TasklyFormPreset.standard(tokens);
    final chipPreset = formPreset.chip;
    final initialProjectId = _resolveInitialProjectId(draft);

    final initialValues = <String, dynamic>{
      RoutineFieldKeys.name.id:
          widget.initialData?.name.trim() ?? draft?.name.trim() ?? '',
      RoutineFieldKeys.projectId.id: initialProjectId,
      RoutineFieldKeys.periodType.id: _currentPeriodType,
      RoutineFieldKeys.scheduleMode.id: _currentScheduleMode,
      RoutineFieldKeys.targetCount.id: initialTargetCount,
      RoutineFieldKeys.scheduleDays.id: scheduleDays,
      RoutineFieldKeys.scheduleMonthDays.id: scheduleMonthDays,
      RoutineFieldKeys.scheduleTimeMinutes.id:
          widget.initialData?.scheduleTimeMinutes ?? draft?.scheduleTimeMinutes,
      RoutineFieldKeys.minSpacingDays.id:
          widget.initialData?.minSpacingDays ?? draft?.minSpacingDays,
      RoutineFieldKeys.restDayBuffer.id:
          widget.initialData?.restDayBuffer ?? draft?.restDayBuffer,
      RoutineFieldKeys.isActive.id:
          widget.initialData?.isActive ?? draft?.isActive ?? true,
      RoutineFormFieldKeys.checklistTitles: widget.initialChecklistTitles,
    };

    final submitEnabled = _submitEnabled;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final headerTitle = Text(
      isCreating ? l10n.routineFormNewTitle : l10n.routineFormEditTitle,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );

    final currentScheduleMode =
        (widget
                .formKey
                .currentState
                ?.fields[RoutineFieldKeys.scheduleMode.id]
                ?.value
            as RoutineScheduleMode?) ??
        _currentScheduleMode;
    final currentPeriodType =
        (widget
                .formKey
                .currentState
                ?.fields[RoutineFieldKeys.periodType.id]
                ?.value
            as RoutinePeriodType?) ??
        _currentPeriodType;
    final scheduleModeOptions = currentPeriodType == RoutinePeriodType.day
        ? const <RoutineScheduleMode>[RoutineScheduleMode.flexible]
        : RoutineScheduleMode.values;
    final periodOptions = currentScheduleMode == RoutineScheduleMode.scheduled
        ? const <RoutinePeriodType>[
            RoutinePeriodType.week,
            RoutinePeriodType.month,
          ]
        : RoutinePeriodType.values;

    return FormShell(
      onSubmit: widget.onSubmit,
      submitTooltip: widget.submitTooltip,
      submitIcon: isCreating ? Icons.add : Icons.check,
      submitEnabled: submitEnabled,
      showHeaderSubmit: false,
      showFooterSubmit: false,
      closeOnLeft: false,
      onDelete: null,
      deleteTooltip: l10n.routineDeleteTitle,
      onClose: widget.onClose == null ? null : handleClose,
      closeTooltip: l10n.closeLabel,
      scrollController: _scrollController,
      showHandleBar: false,
      headerTitle: headerTitle,
      centerHeaderTitle: true,
      trailingActions: [
        if (widget.initialData != null && widget.onDelete != null)
          PopupMenuButton<int>(
            tooltip: l10n.moreOptionsLabel,
            itemBuilder: (context) => [
              PopupMenuItem<int>(
                value: 0,
                child: Text(
                  l10n.routineDeleteTitle,
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            ],
            onSelected: (_) => widget.onDelete?.call(),
          ),
      ],
      footer: Builder(
        builder: (context) {
          return FormFooterBar(
            submitLabel: widget.submitTooltip,
            submitEnabled: submitEnabled,
            onSubmit: widget.onSubmit,
          );
        },
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: tokens.spaceSm),
        child: FormBuilder(
          key: widget.formKey,
          initialValue: initialValues,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: _handleFormChanged,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: tokens.spaceSm),
              TasklyFormTitleField(
                name: RoutineFieldKeys.name.id,
                hintText: l10n.routineFormNameHint,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                autofocus: isCreating,
                onSubmitted: (_) => FocusScope.of(context).unfocus(),
                maxLength: RoutineValidators.maxNameLength,
                suffixIcon: const Icon(Icons.edit_rounded),
                validator: toFormBuilderValidator<String>(
                  RoutineValidators.name,
                  context,
                ),
              ),
              SizedBox(height: tokens.spaceMd),
              Builder(
                builder: (context) {
                  final checklistTitles =
                      ((widget
                                      .formKey
                                      .currentState
                                      ?.fields[RoutineFormFieldKeys
                                          .checklistTitles]
                                      ?.value
                                  as List<dynamic>?) ??
                              (initialValues[RoutineFormFieldKeys
                                      .checklistTitles]
                                  as List<dynamic>?))
                          ?.whereType<String>()
                          .toList(growable: false) ??
                      const <String>[];
                  final checklistCount = checklistTitles.length;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TasklyFormChipRow(
                        chips: [
                          TasklyFormInlineChip(
                            label: l10n.routineFormTypeLabel,
                            icon: Icons.tune_rounded,
                            valueLabel:
                                currentScheduleMode ==
                                    RoutineScheduleMode.flexible
                                ? l10n.routineCadenceFlexibleLabel
                                : l10n.routineCadenceScheduledLabel,
                            hasValue: true,
                            showLabelWhenEmpty: false,
                            preset: chipPreset,
                            onTap: _focusFrequencySection,
                          ),
                          TasklyFormInlineChip(
                            label:
                                currentScheduleMode ==
                                    RoutineScheduleMode.flexible
                                ? l10n.routineFormEveryLabel
                                : l10n.routineFormRepeatLabel,
                            icon: Icons.calendar_month_rounded,
                            valueLabel: _periodLabel(l10n, currentPeriodType),
                            hasValue: true,
                            showLabelWhenEmpty: false,
                            preset: chipPreset,
                            onTap: _focusFrequencySection,
                          ),
                          TasklyFormInlineChip(
                            label: l10n.checklistLabel,
                            icon: Icons.checklist_rounded,
                            valueLabel: checklistCount == 0
                                ? l10n.checklistAddStepsLabel
                                : l10n.checklistProgressLabel(
                                    checklistCount,
                                    20,
                                  ),
                            hasValue: checklistCount > 0,
                            showLabelWhenEmpty: false,
                            preset: chipPreset,
                            onTap: () {
                              setState(() {
                                _showChecklistEditor = !_showChecklistEditor;
                              });
                            },
                          ),
                        ],
                      ),
                      if (_showChecklistEditor) ...[
                        SizedBox(height: tokens.spaceMd),
                        FormBuilderField<List<String>>(
                          name: RoutineFormFieldKeys.checklistTitles,
                          builder: (field) {
                            final titles = (field.value ?? const <String>[])
                                .whereType<String>()
                                .toList(growable: false);
                            return ChecklistEditorSection(
                              title: l10n.checklistLabel,
                              addItemFieldLabel: l10n.checklistAddItemLabel,
                              addItemButtonLabel: l10n.addLabel,
                              deleteItemTooltip: l10n.checklistDeleteStepLabel,
                              titles: titles,
                              maxItems: 20,
                              onChanged: (next) {
                                field.didChange(next);
                                _markDirtySafely();
                                setState(() {});
                              },
                            );
                          },
                        ),
                      ],
                    ],
                  );
                },
              ),
              SizedBox(height: tokens.spaceLg),
              TasklyFormSectionLabel(text: l10n.projectLabel),
              SizedBox(height: tokens.spaceSm),
              FormBuilderField<String>(
                name: RoutineFieldKeys.projectId.id,
                validator: toFormBuilderValidator<String>(
                  RoutineValidators.projectId,
                  context,
                ),
                builder: (field) {
                  final projectId = (field.value ?? '').trim();
                  final selectedProject = widget.availableProjects
                      .where((project) => project.id == projectId)
                      .firstOrNull;
                  final projectLabel =
                      selectedProject?.name ?? l10n.selectProjectTitle;
                  final hasProject = selectedProject != null;
                  final isMissingProject = projectId.isEmpty;
                  final helperText =
                      field.errorText ??
                      (isMissingProject ? l10n.validationRequired : null);
                  final helperColor = field.errorText != null
                      ? colorScheme.error
                      : colorScheme.onSurfaceVariant;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      KeyedSubtree(
                        key: _projectKey,
                        child: Builder(
                          builder: (chipContext) => TasklyFormInlineChip(
                            label: l10n.projectLabel,
                            valueLabel: projectLabel,
                            hasValue: hasProject,
                            icon: Icons.folder_rounded,
                            preset: chipPreset,
                            onTap: () async {
                              final result = await _showProjectPicker(
                                anchorContext: chipContext,
                                currentProjectId: field.value ?? '',
                              );
                              if (result == null) return;

                              switch (result) {
                                case ProjectPickerResultCleared():
                                  return;
                                case ProjectPickerResultSelected(
                                  :final project,
                                ):
                                  field.didChange(project.id);
                                  _recordRecentProjectId(project.id);
                              }

                              _markDirtySafely();
                              setState(() {});
                            },
                          ),
                        ),
                      ),
                      if (helperText != null) ...[
                        SizedBox(height: tokens.spaceSm),
                        Text(
                          helperText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: helperColor,
                            fontWeight: field.errorText != null
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
              SizedBox(height: tokens.spaceLg),
              KeyedSubtree(
                key: _frequencyKey,
                child: TasklyFormSectionLabel(
                  text: l10n.routineFormFrequencyLabel,
                ),
              ),
              SizedBox(height: tokens.spaceSm),
              FormBuilderSegmentedField<RoutineScheduleMode>(
                name: RoutineFieldKeys.scheduleMode.id,
                values: scheduleModeOptions,
                labelBuilder: (value) => Text(
                  value == RoutineScheduleMode.flexible
                      ? l10n.routineCadenceFlexibleLabel
                      : l10n.routineCadenceScheduledLabel,
                ),
                onChanged: (value) {
                  if (value == null) return;
                  _onScheduleModeChanged(value);
                },
              ),
              SizedBox(height: tokens.spaceMd),
              if (_currentScheduleMode == RoutineScheduleMode.flexible) ...[
                FormBuilderField<int>(
                  name: RoutineFieldKeys.targetCount.id,
                  validator: toFormBuilderValidator<int>(
                    (value) => RoutineValidators.targetCount(
                      value,
                      periodType: _currentPeriodType,
                      scheduleMode: _currentScheduleMode,
                    ),
                    context,
                  ),
                  builder: (field) {
                    const min = 1;
                    final max = switch (_currentPeriodType) {
                      RoutinePeriodType.day => 10,
                      RoutinePeriodType.week => 7,
                      RoutinePeriodType.fortnight => 14,
                      RoutinePeriodType.month => 31,
                    };
                    final current = (field.value ?? min).clamp(min, max);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TasklyFormSelectorRow(
                          label: l10n.routineFormTargetPrompt,
                          child: TasklyFormStepper(
                            value: current,
                            min: min,
                            max: max,
                            onChanged: (next) => field.didChange(next),
                          ),
                        ),
                        if (field.errorText != null) ...[
                          SizedBox(height: tokens.spaceSm),
                          Text(
                            field.errorText!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.error,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                SizedBox(height: tokens.spaceSm),
                FormBuilderDropdown<RoutinePeriodType>(
                  name: RoutineFieldKeys.periodType.id,
                  items: [
                    for (final option in periodOptions)
                      DropdownMenuItem<RoutinePeriodType>(
                        value: option,
                        child: Text(_periodLabel(l10n, option)),
                      ),
                  ],
                  decoration: InputDecoration(
                    labelText: l10n.routineFormEveryLabel,
                    filled: formPreset.ux.selectorFill,
                    fillColor: colorScheme.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(tokens.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    if (value == null) return;
                    _onPeriodTypeChanged(value);
                  },
                ),
              ],
              if (_currentScheduleMode == RoutineScheduleMode.scheduled) ...[
                FormBuilderDropdown<RoutinePeriodType>(
                  name: RoutineFieldKeys.periodType.id,
                  items: [
                    for (final option in periodOptions)
                      DropdownMenuItem<RoutinePeriodType>(
                        value: option,
                        child: Text(_periodLabel(l10n, option)),
                      ),
                  ],
                  decoration: InputDecoration(
                    labelText: l10n.routineFormRepeatLabel,
                    filled: formPreset.ux.selectorFill,
                    fillColor: colorScheme.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(tokens.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    if (value == null) return;
                    _onPeriodTypeChanged(value);
                  },
                ),
                if (_currentPeriodType == RoutinePeriodType.week) ...[
                  SizedBox(height: tokens.spaceMd),
                  FormBuilderField<List<int>>(
                    name: RoutineFieldKeys.scheduleDays.id,
                    validator: toFormBuilderValidator<List<int>>(
                      (value) => RoutineValidators.scheduleDays(
                        value ?? const [],
                        periodType: _currentPeriodType,
                        scheduleMode: _currentScheduleMode,
                      ),
                      context,
                    ),
                    builder: (field) {
                      final locale = Localizations.localeOf(context).toString();
                      final formatter = DateFormat.E(locale);
                      final weekdays = [
                        for (var i = 0; i < 7; i++)
                          formatter.format(DateTime.utc(2024, 1, 1 + i)),
                      ];
                      final selected = (field.value ?? const <int>[]).toSet();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TasklyFormChoiceGrid(
                            values: const [1, 2, 3, 4, 5, 6, 7],
                            labelBuilder: (value) =>
                                weekdays[value - 1].characters.first,
                            isSelected: selected.contains,
                            onTap: (day) {
                              final updated = Set<int>.from(selected);
                              if (!updated.add(day)) updated.remove(day);
                              final sorted = updated.toList()..sort();
                              field.didChange(sorted);
                              _syncTargetCountFromSchedule();
                              _markDirtySafely();
                            },
                          ),
                          if (field.errorText != null) ...[
                            SizedBox(height: tokens.spaceSm),
                            Text(
                              field.errorText!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.error,
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
                if (_currentPeriodType == RoutinePeriodType.month) ...[
                  SizedBox(height: tokens.spaceMd),
                  FormBuilderField<List<int>>(
                    name: RoutineFieldKeys.scheduleMonthDays.id,
                    validator: toFormBuilderValidator<List<int>>(
                      (value) => RoutineValidators.scheduleMonthDays(
                        value ?? const [],
                        periodType: _currentPeriodType,
                        scheduleMode: _currentScheduleMode,
                      ),
                      context,
                    ),
                    builder: (field) {
                      final selected = (field.value ?? const <int>[]).toSet();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TasklyFormSelectorRow(
                            label: l10n.routineFormSelectDaysLabel,
                            child: TasklyFormChoiceGrid(
                              values: [for (var d = 1; d <= 31; d++) d],
                              labelBuilder: (value) => value.toString(),
                              isSelected: selected.contains,
                              onTap: (day) {
                                final updated = Set<int>.from(selected);
                                if (!updated.add(day)) updated.remove(day);
                                final sorted = updated.toList()..sort();
                                field.didChange(sorted);
                                _syncTargetCountFromSchedule();
                                _markDirtySafely();
                              },
                            ),
                          ),
                          if (field.errorText != null) ...[
                            SizedBox(height: tokens.spaceSm),
                            Text(
                              field.errorText!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.error,
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
                FormBuilderField<int>(
                  name: RoutineFieldKeys.targetCount.id,
                  builder: (_) => const SizedBox.shrink(),
                  validator: toFormBuilderValidator<int>(
                    (value) => RoutineValidators.targetCount(
                      value,
                      periodType: _currentPeriodType,
                      scheduleMode: _currentScheduleMode,
                    ),
                    context,
                  ),
                ),
              ],
              if (!isCreating) ...[
                SizedBox(height: tokens.spaceLg),
                FormBuilderSwitch(
                  name: RoutineFieldKeys.isActive.id,
                  title: Text(l10n.routineFormActiveLabel),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _periodLabel(AppLocalizations l10n, RoutinePeriodType value) {
  return switch (value) {
    RoutinePeriodType.day => l10n.routineFormPeriodDaily,
    RoutinePeriodType.week => l10n.routineFormPeriodWeekly,
    RoutinePeriodType.fortnight => l10n.routineFormPeriodFortnight,
    RoutinePeriodType.month => l10n.routineFormPeriodMonthly,
  };
}
