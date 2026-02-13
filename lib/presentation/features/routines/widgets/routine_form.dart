import 'package:flutter/material.dart';
import 'package:characters/characters.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/shared/utils/form_utils.dart';
import 'package:taskly_bloc/presentation/shared/utils/debouncer.dart';
import 'package:taskly_bloc/presentation/shared/validation/form_builder_validator_adapter.dart';
import 'package:taskly_bloc/presentation/shared/widgets/project_picker_content.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_ui/taskly_ui_forms.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class RoutineForm extends StatefulWidget {
  const RoutineForm({
    required this.formKey,
    required this.availableProjects,
    required this.onSubmit,
    required this.submitTooltip,
    this.defaultProjectId,
    this.openToProjectPicker = false,
    this.initialData,
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
  final Debouncer _draftSyncDebouncer = Debouncer(_draftSyncDebounce);
  final List<String> _recentProjectIds = <String>[];
  bool _didAutoOpen = false;
  bool _submitEnabled = false;

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
        _currentPeriodType == RoutinePeriodType.day) {
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
    final next = isDirty && (widget.formKey.currentState?.isValid ?? false);
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

  Future<ProjectPickerResult?> _showProjectPicker({
    required BuildContext anchorContext,
    required String currentProjectId,
  }) {
    if (_isCompact(context)) {
      return showModalBottomSheet<ProjectPickerResult>(
        context: context,
        useSafeArea: true,
        showDragHandle: true,
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

    final initialValues = <String, dynamic>{
      RoutineFieldKeys.name.id:
          widget.initialData?.name.trim() ?? draft?.name.trim() ?? '',
      RoutineFieldKeys.projectId.id:
          widget.initialData?.projectId ??
          draft?.projectId ??
          widget.defaultProjectId ??
          '',
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
    };

    final submitEnabled = _submitEnabled;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final headerActionStyle = TextButton.styleFrom(
      textStyle: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
    final headerTitle = Text(
      isCreating ? l10n.routineFormNewTitle : l10n.routineFormEditTitle,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );

    final scheduleModeOptions = _currentPeriodType == RoutinePeriodType.day
        ? const <RoutineScheduleMode>[RoutineScheduleMode.flexible]
        : RoutineScheduleMode.values;

    final periodOptions = _currentScheduleMode == RoutineScheduleMode.scheduled
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
      showFooterSubmit: true,
      closeOnLeft: false,
      onDelete: null,
      deleteTooltip: l10n.routineDeleteTitle,
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
      ],
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
              FormBuilderTextField(
                name: RoutineFieldKeys.name.id,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                maxLength: RoutineValidators.maxNameLength,
                decoration:
                    const InputDecoration(
                      border: InputBorder.none,
                      hintText: '',
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ).copyWith(
                      hintText: l10n.routineFormNameHint,
                      suffixIcon: Icon(Icons.edit_rounded),
                    ),
                validator: toFormBuilderValidator<String>(
                  RoutineValidators.name,
                  context,
                ),
              ),
              SizedBox(height: tokens.spaceMd),
              TasklyFormSectionLabel(text: l10n.projectLabel),
              SizedBox(height: tokens.spaceSm),
              FormBuilderField<String>(
                name: RoutineFieldKeys.projectId.id,
                validator: toFormBuilderValidator<String>(
                  RoutineValidators.projectId,
                  context,
                ),
                builder: (field) {
                  final selectedProject = widget.availableProjects
                      .where((project) => project.id == field.value)
                      .firstOrNull;
                  final projectLabel =
                      selectedProject?.name ?? l10n.selectProjectTitle;
                  final hasProject = selectedProject != null;

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
                            preset: TasklyFormPreset.standard(tokens).chip,
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
                      if (field.errorText != null) ...[
                        SizedBox(height: tokens.spaceSm),
                        Text(
                          field.errorText!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
              SizedBox(height: tokens.spaceLg),
              TasklyFormSectionLabel(text: l10n.routineFormFrequencyLabel),
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
                _TargetCountStepperField(
                  name: RoutineFieldKeys.targetCount.id,
                  label: l10n.routineFormTargetPrompt,
                  min: 1,
                  max: switch (_currentPeriodType) {
                    RoutinePeriodType.day => 10,
                    RoutinePeriodType.week => 7,
                    RoutinePeriodType.month => 31,
                  },
                  validator: toFormBuilderValidator<int>(
                    (value) => RoutineValidators.targetCount(
                      value,
                      periodType: _currentPeriodType,
                      scheduleMode: _currentScheduleMode,
                    ),
                    context,
                  ),
                ),
                SizedBox(height: tokens.spaceSm),
                _RepeatDropdown(
                  name: RoutineFieldKeys.periodType.id,
                  label: l10n.routineFormEveryLabel,
                  options: periodOptions,
                  valueLabelBuilder: (value) => _periodLabel(l10n, value),
                  onChanged: (value) {
                    if (value == null) return;
                    _onPeriodTypeChanged(value);
                  },
                ),
              ],
              if (_currentScheduleMode == RoutineScheduleMode.scheduled) ...[
                _RepeatDropdown(
                  name: RoutineFieldKeys.periodType.id,
                  label: l10n.routineFormRepeatLabel,
                  options: periodOptions,
                  valueLabelBuilder: (value) => _periodLabel(l10n, value),
                  onChanged: (value) {
                    if (value == null) return;
                    _onPeriodTypeChanged(value);
                  },
                ),
                if (_currentPeriodType == RoutinePeriodType.week) ...[
                  SizedBox(height: tokens.spaceMd),
                  _WeekdayChipsField(
                    name: RoutineFieldKeys.scheduleDays.id,
                    validator: toFormBuilderValidator<List<int>>(
                      (value) => RoutineValidators.scheduleDays(
                        value ?? const [],
                        periodType: _currentPeriodType,
                        scheduleMode: _currentScheduleMode,
                      ),
                      context,
                    ),
                    onChanged: (value) {
                      _syncTargetCountFromSchedule();
                      _markDirtySafely();
                    },
                  ),
                ],
                if (_currentPeriodType == RoutinePeriodType.month) ...[
                  SizedBox(height: tokens.spaceMd),
                  _MonthDayGridField(
                    name: RoutineFieldKeys.scheduleMonthDays.id,
                    label: l10n.routineFormSelectDaysLabel,
                    validator: toFormBuilderValidator<List<int>>(
                      (value) => RoutineValidators.scheduleMonthDays(
                        value ?? const [],
                        periodType: _currentPeriodType,
                        scheduleMode: _currentScheduleMode,
                      ),
                      context,
                    ),
                    onChanged: (value) {
                      _syncTargetCountFromSchedule();
                      _markDirtySafely();
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
    RoutinePeriodType.month => l10n.routineFormPeriodMonthly,
  };
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

class _TargetCountStepperField extends StatelessWidget {
  const _TargetCountStepperField({
    required this.name,
    required this.label,
    required this.min,
    required this.max,
    required this.validator,
  });

  final String name;
  final String label;
  final int min;
  final int max;
  final String? Function(int?) validator;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;

    return FormBuilderField<int>(
      name: name,
      validator: validator,
      builder: (field) {
        final current = (field.value ?? min).clamp(min, max);

        void update(int next) {
          field.didChange(next);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: tokens.spaceSm),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spaceMd,
                vertical: tokens.spaceSm,
              ),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(tokens.radiusLg),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StepperButton(
                    icon: Icons.remove_rounded,
                    enabled: current > min,
                    onPressed: () => update(current - 1),
                  ),
                  Text(
                    current.toString(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  _StepperButton(
                    icon: Icons.add_rounded,
                    enabled: current < max,
                    onPressed: () => update(current + 1),
                  ),
                ],
              ),
            ),
            if (field.errorText != null) ...[
              SizedBox(height: tokens.spaceSm),
              Text(
                field.errorText!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.error,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final bg = enabled ? scheme.surface : scheme.surfaceContainerHighest;

    return IconButton(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: bg,
        minimumSize: Size.square(tokens.minTapTargetSize),
        padding: EdgeInsets.all(tokens.spaceXs),
      ),
    );
  }
}

class _RepeatDropdown extends StatelessWidget {
  const _RepeatDropdown({
    required this.name,
    required this.label,
    required this.options,
    required this.valueLabelBuilder,
    required this.onChanged,
  });

  final String name;
  final String label;
  final List<RoutinePeriodType> options;
  final String Function(RoutinePeriodType) valueLabelBuilder;
  final ValueChanged<RoutinePeriodType?> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    return FormBuilderDropdown<RoutinePeriodType>(
      name: name,
      items: [
        for (final option in options)
          DropdownMenuItem<RoutinePeriodType>(
            value: option,
            child: Text(valueLabelBuilder(option)),
          ),
      ],
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: onChanged,
    );
  }
}

class _WeekdayChipsField extends StatelessWidget {
  const _WeekdayChipsField({
    required this.name,
    required this.validator,
    this.onChanged,
  });

  final String name;
  final String? Function(List<int>?) validator;
  final ValueChanged<List<int>>? onChanged;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final formatter = DateFormat.E(locale);
    final weekdays = [
      for (var i = 0; i < 7; i++)
        formatter.format(DateTime.utc(2024, 1, 1 + i)),
    ];

    return FormBuilderField<List<int>>(
      name: name,
      validator: validator,
      builder: (field) {
        final selected = (field.value ?? const <int>[]).toSet();
        final tokens = TasklyTokens.of(context);
        final scheme = Theme.of(context).colorScheme;
        final size = tokens.minTapTargetSize;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < weekdays.length; i++)
                  _CircleChip(
                    label: weekdays[i].characters.first,
                    size: size,
                    selected: selected.contains(i + 1),
                    onTap: () {
                      final updated = Set<int>.from(selected);
                      final day = i + 1;
                      if (!updated.add(day)) {
                        updated.remove(day);
                      }
                      final sorted = updated.toList()..sort();
                      field.didChange(sorted);
                      onChanged?.call(sorted);
                    },
                    background: scheme.surfaceContainerLow,
                    activeBackground: scheme.primary,
                    activeForeground: scheme.onPrimary,
                    inactiveForeground: scheme.onSurfaceVariant,
                  ),
              ],
            ),
            if (field.errorText != null) ...[
              SizedBox(height: tokens.spaceSm),
              Text(
                field.errorText!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.error,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _MonthDayGridField extends StatelessWidget {
  const _MonthDayGridField({
    required this.name,
    required this.label,
    required this.validator,
    this.onChanged,
  });

  final String name;
  final String label;
  final String? Function(List<int>?) validator;
  final ValueChanged<List<int>>? onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final size = tokens.minTapTargetSize;

    return FormBuilderField<List<int>>(
      name: name,
      validator: validator,
      builder: (field) {
        final selected = (field.value ?? const <int>[]).toSet();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: tokens.spaceSm),
            Wrap(
              spacing: tokens.spaceXs2,
              runSpacing: tokens.spaceXs2,
              children: [
                for (var day = 1; day <= 31; day++)
                  _CircleChip(
                    label: day.toString(),
                    size: size,
                    selected: selected.contains(day),
                    onTap: () {
                      final updated = Set<int>.from(selected);
                      if (!updated.add(day)) {
                        updated.remove(day);
                      }
                      final sorted = updated.toList()..sort();
                      field.didChange(sorted);
                      onChanged?.call(sorted);
                    },
                    background: scheme.surfaceContainerLow,
                    activeBackground: scheme.primary,
                    activeForeground: scheme.onPrimary,
                    inactiveForeground: scheme.onSurfaceVariant,
                  ),
              ],
            ),
            if (field.errorText != null) ...[
              SizedBox(height: tokens.spaceSm),
              Text(
                field.errorText!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.error,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _CircleChip extends StatelessWidget {
  const _CircleChip({
    required this.label,
    required this.size,
    required this.selected,
    required this.onTap,
    required this.background,
    required this.activeBackground,
    required this.activeForeground,
    required this.inactiveForeground,
  });

  final String label;
  final double size;
  final bool selected;
  final VoidCallback onTap;
  final Color background;
  final Color activeBackground;
  final Color activeForeground;
  final Color inactiveForeground;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? activeForeground : inactiveForeground;
    final bg = selected ? activeBackground : background;

    return Material(
      color: bg,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: fg,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
