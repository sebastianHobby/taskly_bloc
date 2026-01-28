import 'package:flutter/material.dart';
import 'package:fleather/fleather.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
// import 'package:taskly_bloc/presentation/widgets/form_fields/form_builder_tag_picker.dart'; // Removed
import 'package:taskly_bloc/presentation/shared/utils/date_display_utils.dart';
import 'package:taskly_bloc/presentation/shared/utils/form_utils.dart';
import 'package:taskly_bloc/presentation/shared/utils/rich_text_utils.dart';
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
    this.openToValues = false,
    this.onTogglePinned,
    this.onClose,
    this.trailingActions = const <Widget>[],
    super.key,
  });

  final GlobalKey<FormBuilderState> formKey;
  final VoidCallback onSubmit;
  final String submitTooltip;
  final Project? initialData;
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final List<Value> availableValues;

  /// When true, scrolls to the values section and opens the values alignment
  /// sheet on first build.
  final bool openToValues;

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
  State<ProjectForm> createState() => _ProjectFormState();
}

class _ProjectFormState extends State<ProjectForm> with FormDirtyStateMixin {
  @override
  VoidCallback? get onClose => widget.onClose;

  final _scrollController = ScrollController();
  final GlobalKey<State<StatefulWidget>> _valuesKey = GlobalKey();
  bool _didAutoOpen = false;
  String? _recurrenceLabel;
  String? _lastRecurrenceRrule;

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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _didAutoOpen) return;
      if (!widget.openToValues) return;
      _didAutoOpen = true;

      final ctx = _valuesKey.currentContext;
      if (ctx != null) {
        await Scrollable.ensureVisible(
          ctx,
          alignment: 0.1,
          duration: const Duration(milliseconds: 220),
        );
        if (!ctx.mounted) return;
      }
      if (!mounted) return;

      final current = widget
          .formKey
          .currentState
          ?.fields[ProjectFieldKeys.valueIds.id]
          ?.value;
      final valueIds = List<String>.of(current as List<String>? ?? const []);

      final anchorContext = _valuesKey.currentContext;
      if (anchorContext == null || !mounted) return;

      final result = await _showValuesAlignmentPicker(
        anchorContext: anchorContext,
        valueIds: valueIds,
        target: ValuesAlignmentTarget.primary,
      );
      if (!mounted || result == null) return;

      widget.formKey.currentState?.fields[ProjectFieldKeys.valueIds.id]
          ?.didChange(result);
      markDirty();
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant ProjectForm oldWidget) {
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

  Future<List<String>?> _showValuesAlignmentPicker({
    required BuildContext anchorContext,
    required List<String> valueIds,
    required ValuesAlignmentTarget target,
  }) {
    if (_isCompact(context)) {
      return showValuesAlignmentSheetForProject(
        context,
        availableValues: widget.availableValues,
        valueIds: valueIds,
        target: target,
      );
    }

    return _showAnchoredDialog<List<String>>(
      context,
      anchorContext: anchorContext,
      maxWidth: 520,
      maxHeight: 560,
      builder: (dialogContext) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ValuesAlignmentSheet.project(
          availableValues: widget.availableValues,
          valueIds: valueIds,
          target: target,
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
        builder: (sheetContext) => _ProjectDatePickerPanel(
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
      builder: (dialogContext) => _ProjectDatePickerPanel(
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

    final availableValuesById = <String, Value>{
      for (final v in widget.availableValues) v.id: v,
    };

    final normalizedDescription = serializeParchmentDocument(
      parseParchmentDocument(widget.initialData?.description),
    );
    final initialValues = <String, dynamic>{
      ProjectFieldKeys.name.id: widget.initialData?.name.trim() ?? '',
      ProjectFieldKeys.description.id: normalizedDescription,
      ProjectFieldKeys.completed.id: widget.initialData?.completed ?? false,
      ProjectFieldKeys.startDate.id: widget.initialData?.startDate,
      ProjectFieldKeys.deadlineDate.id: widget.initialData?.deadlineDate,
      ProjectFieldKeys.priority.id: widget.initialData?.priority,
      ProjectFieldKeys.valueIds.id:
          (widget.initialData?.values ?? <Value>[]) // Use values property
              .map((Value e) => e.id)
              .take(1)
              .toList(growable: false),
      ProjectFieldKeys.repeatIcalRrule.id:
          widget.initialData?.repeatIcalRrule ?? '',
      ProjectFieldKeys.repeatFromCompletion.id:
          widget.initialData?.repeatFromCompletion ?? false,
      ProjectFieldKeys.seriesEnded.id: widget.initialData?.seriesEnded ?? false,
    };
    final initialDescription = normalizedDescription;

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
      isCreating ? l10n.projectFormNewTitle : l10n.projectFormEditTitle,
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
      deleteTooltip: l10n.deleteProjectAction,
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
            final rrule =
                widget
                        .formKey
                        .currentState
                        ?.fields[ProjectFieldKeys.repeatIcalRrule.id]
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
                        name: ProjectFieldKeys.completed.id,
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
                      name: ProjectFieldKeys.name.id,
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
                            hintText: l10n.projectFormTitleHint,
                          ),
                      validator: toFormBuilderValidator<String>(
                        ProjectValidators.name,
                        context,
                      ),
                    ),
                  ),
                ],
              ),

              if (isCreating)
                FormBuilderField<bool>(
                  name: ProjectFieldKeys.completed.id,
                  builder: (_) => SizedBox.shrink(),
                ),

              SizedBox(height: sectionGap),

              // Meta chips row (values-first): Values, Planned Day, Due Date,
              // Priority, Repeat
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TasklyFormSectionLabel(text: l10n.projectValueTitle),
                  SizedBox(height: TasklyTokens.of(context).spaceSm),
                  Text(
                    l10n.projectValueHelper,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: TasklyTokens.of(context).spaceSm),
                  TasklyFormRowGroup(
                    children: [
                      FormBuilderField<List<String>>(
                        name: ProjectFieldKeys.valueIds.id,
                        validator: toFormBuilderValidator<List<String>>(
                          ProjectValidators.valueIds,
                          context,
                        ),
                        builder: (field) {
                          final valueIds = List<String>.of(
                            field.value ?? const <String>[],
                          ).take(1).toList(growable: false);
                          final primary = valueIds.isEmpty
                              ? null
                              : availableValuesById[valueIds.first];

                          return Builder(
                            builder: (chipContext) {
                              Future<void> open(
                                ValuesAlignmentTarget target,
                              ) async {
                                final result = await _showValuesAlignmentPicker(
                                  anchorContext: chipContext,
                                  valueIds: valueIds,
                                  target: target,
                                );
                                if (!mounted || result == null) return;
                                field.didChange(
                                  result.take(1).toList(growable: false),
                                );
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
                              return KeyedSubtree(
                                key: _valuesKey,
                                child: TasklyFormRowGroup(
                                  spacing: 12,
                                  runSpacing: 8,
                                  children: [
                                    TasklyFormValueChip(
                                      model: primary != null
                                          ? toModel(primary)
                                          : TasklyFormValueChipModel(
                                              label: context
                                                  .l10n
                                                  .valuesPrimaryLabel,
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                              icon: Icons.star_border,
                                              semanticLabel: context
                                                  .l10n
                                                  .valuesPrimaryLabel,
                                            ),
                                      onTap: () =>
                                          open(ValuesAlignmentTarget.primary),
                                      isSelected: primary != null,
                                      isPrimary: true,
                                      preset: TasklyFormChipPreset.standard(
                                        TasklyTokens.of(context),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                  Builder(
                    builder: (context) {
                      final errorText = widget
                          .formKey
                          .currentState
                          ?.fields[ProjectFieldKeys.valueIds.id]
                          ?.errorText;
                      if (errorText == null) return SizedBox.shrink();
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
                  SizedBox(height: sectionGap),
                  Builder(
                    builder: (context) {
                      final startDate =
                          (widget
                                  .formKey
                                  .currentState
                                  ?.fields[ProjectFieldKeys.startDate.id]
                                  ?.value
                              as DateTime?) ??
                          (initialValues[ProjectFieldKeys.startDate.id]
                              as DateTime?);
                      final deadlineDate =
                          (widget
                                  .formKey
                                  .currentState
                                  ?.fields[ProjectFieldKeys.deadlineDate.id]
                                  ?.value
                              as DateTime?) ??
                          (initialValues[ProjectFieldKeys.deadlineDate.id]
                              as DateTime?);
                      final recurrenceRrule =
                          (widget
                                  .formKey
                                  .currentState
                                  ?.fields[ProjectFieldKeys.repeatIcalRrule.id]
                                  ?.value
                              as String?) ??
                          (initialValues[ProjectFieldKeys.repeatIcalRrule.id]
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
                              if (!mounted || decision == null) {
                                return;
                              }
                              if (decision.keep) return;
                              widget
                                  .formKey
                                  .currentState
                                  ?.fields[ProjectFieldKeys.startDate.id]
                                  ?.didChange(decision.date);
                              markDirty();
                              setState(() {});
                            },
                            onClear: plannedLabel != null
                                ? () {
                                    widget
                                        .formKey
                                        .currentState
                                        ?.fields[ProjectFieldKeys.startDate.id]
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
                              if (!mounted || decision == null) {
                                return;
                              }
                              if (decision.keep) return;
                              widget
                                  .formKey
                                  .currentState
                                  ?.fields[ProjectFieldKeys.deadlineDate.id]
                                  ?.didChange(decision.date);
                              markDirty();
                              setState(() {});
                            },
                            onClear: dueLabel != null
                                ? () {
                                    widget
                                        .formKey
                                        .currentState
                                        ?.fields[ProjectFieldKeys
                                            .deadlineDate
                                            .id]
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

                              final result = await _pickRecurrence(
                                anchorContext: context,
                                initialRrule: recurrenceRrule,
                                initialRepeatFromCompletion:
                                    (repeatFromCompletionField?.value
                                        as bool?) ??
                                    false,
                                initialSeriesEnded:
                                    (seriesEndedField?.value as bool?) ?? false,
                              );
                              if (!mounted || result == null) return;

                              widget
                                  .formKey
                                  .currentState
                                  ?.fields[ProjectFieldKeys.repeatIcalRrule.id]
                                  ?.didChange(result.rrule);
                              repeatFromCompletionField?.didChange(
                                result.repeatFromCompletion,
                              );
                              seriesEndedField?.didChange(
                                result.seriesEnded,
                              );
                              _updateRecurrenceLabel(result.rrule);
                              markDirty();
                              setState(() {});
                            },
                            onClear: hasRecurrence
                                ? () {
                                    widget
                                        .formKey
                                        .currentState
                                        ?.fields[ProjectFieldKeys
                                            .repeatIcalRrule
                                            .id]
                                        ?.didChange(null);
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
                                        ?.fields[ProjectFieldKeys
                                            .seriesEnded
                                            .id]
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
                    name: ProjectFieldKeys.priority.id,
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
                  _ProjectNotesField(
                    name: ProjectFieldKeys.description.id,
                    initialValue: initialDescription,
                    hintText: l10n.projectFormDescriptionHint,
                    isCompact: isCompact,
                    contentPadding: denseFieldPadding,
                    validator: toFormBuilderValidator<String>(
                      ProjectValidators.description,
                      context,
                    ),
                  ),
                  SizedBox(height: sectionGap),
                  FormBuilderField<DateTime?>(
                    name: ProjectFieldKeys.startDate.id,
                    builder: (_) => SizedBox.shrink(),
                  ),
                  FormBuilderField<DateTime?>(
                    name: ProjectFieldKeys.deadlineDate.id,
                    builder: (_) => SizedBox.shrink(),
                  ),
                  FormBuilderField<String?>(
                    name: ProjectFieldKeys.repeatIcalRrule.id,
                    builder: (_) => SizedBox.shrink(),
                  ),

                  // Hidden recurrence flags fields (set by the picker)
                  FormBuilderField<bool>(
                    name: ProjectFieldKeys.repeatFromCompletion.id,
                    builder: (_) => SizedBox.shrink(),
                  ),
                  FormBuilderField<bool>(
                    name: ProjectFieldKeys.seriesEnded.id,
                    builder: (_) => SizedBox.shrink(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectNotesField extends StatefulWidget {
  const _ProjectNotesField({
    required this.name,
    required this.initialValue,
    required this.hintText,
    required this.isCompact,
    required this.contentPadding,
    required this.validator,
  });

  final String name;
  final String initialValue;
  final String hintText;
  final bool isCompact;
  final EdgeInsets contentPadding;
  final FormFieldValidator<String>? validator;

  @override
  State<_ProjectNotesField> createState() => _ProjectNotesFieldState();
}

class _ProjectNotesFieldState extends State<_ProjectNotesField> {
  late FleatherController _controller;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  FormFieldState<String?>? _fieldState;
  bool _isEmpty = true;
  bool _syncing = false;
  String? _lastSerialized;

  @override
  void initState() {
    super.initState();
    _controller = FleatherController(
      document: parseParchmentDocument(widget.initialValue),
    );
    _lastSerialized = serializeParchmentDocument(_controller.document);
    _isEmpty = _controller.document.toPlainText().trim().isEmpty;
    _controller.addListener(_handleDocumentChanged);
  }

  @override
  void didUpdateWidget(covariant _ProjectNotesField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _replaceDocument(widget.initialValue);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleDocumentChanged);
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleDocumentChanged() {
    if (_syncing) return;
    final serialized = serializeParchmentDocument(_controller.document);
    if (serialized != _lastSerialized) {
      _lastSerialized = serialized;
      _fieldState?.didChange(serialized);
    }
    final emptyNow = _controller.document.toPlainText().trim().isEmpty;
    if (emptyNow != _isEmpty && mounted) {
      setState(() {
        _isEmpty = emptyNow;
      });
    }
  }

  void _replaceDocument(String? raw) {
    if (raw == _lastSerialized) return;

    _syncing = true;
    _controller.removeListener(_handleDocumentChanged);
    _controller.dispose();
    _controller = FleatherController(
      document: parseParchmentDocument(raw),
    );
    _lastSerialized = serializeParchmentDocument(_controller.document);
    _isEmpty = _controller.document.toPlainText().trim().isEmpty;
    _controller.addListener(_handleDocumentChanged);
    _syncing = false;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final editorHeight = widget.isCompact ? 160.0 : 200.0;

    return FormBuilderField<String?>(
      name: widget.name,
      initialValue: widget.initialValue,
      validator: widget.validator,
      builder: (field) {
        _fieldState = field;
        if (field.value != _lastSerialized) {
          _replaceDocument(field.value);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FleatherToolbar.basic(
              controller: _controller,
              hideStrikeThrough: true,
              hideBackgroundColor: true,
              hideInlineCode: true,
              hideIndentation: true,
              hideCodeBlock: true,
              hideHorizontalRule: true,
              hideDirection: true,
              hideAlignment: true,
            ),
            SizedBox(height: tokens.spaceSm),
            Container(
              height: editorHeight,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(tokens.radiusMd),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Stack(
                children: [
                  FleatherEditor(
                    controller: _controller,
                    focusNode: _focusNode,
                    scrollController: _scrollController,
                    padding: widget.contentPadding,
                  ),
                  if (_isEmpty)
                    IgnorePointer(
                      child: Padding(
                        padding: widget.contentPadding,
                        child: Text(
                          widget.hintText,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
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

class _ProjectDatePickerPanel extends StatefulWidget {
  const _ProjectDatePickerPanel({
    required this.title,
    required this.initialDate,
  });

  final String title;
  final DateTime? initialDate;

  @override
  State<_ProjectDatePickerPanel> createState() =>
      _ProjectDatePickerPanelState();
}

class _ProjectDatePickerPanelState extends State<_ProjectDatePickerPanel> {
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
